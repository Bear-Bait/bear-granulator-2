# Third-Party Technical Audit Package
**BEARULATOR Granular Synthesis Workstation**
**Date:** 2026-01-17
**Version:** v2.2 (deployed 2026-01-09)
**Platform:** SuperCollider 3.13+ on macOS (M4 optimized)

---

## System Overview

4-track granular synthesis workstation with 3 concurrent engines per track (Grain/Spectral/Direct), modulation system, effects chains, and quad spatial audio. Target: <50% CPU on M4 Mac Mini.

**Key Stats:**
- Total codebase: ~13,000 LOC
- Core audio: ~5,400 LOC
- GUI: ~7,400 LOC
- Architecture: Event-based server/client, group-based execution order

---

## Critical Files for Audit

### TIER 1: Core Audio Engine (Must Review)

#### 1. `main.scd` (410 lines)
**Purpose:** Boot sequence, module loader, system initialization
**Critical sections:**
- Lines 1-60: Configuration and server setup
- Lines 95-230: Module load sequence (defines architecture)
- Known issue: Version strings outdated (shows v0.4, should be v2.2)

#### 2. `core/track-manager.scd` (956 lines) ⚠️ LARGEST CORE FILE
**Purpose:** Orchestrates 4 tracks, parameter routing, synth lifecycle
**Critical sections:**
- Lines 66-238: `createTrack()` - instantiates all 3 engines per track
- Lines 275-400: `setParam()` - parameter routing with spectral remapping
- Lines 290-310: Pitch quantization implementation (Phase 16)
- Lines 40-52: Execution order groups (modGroup → instrumentGroup)
- **Audit focus:** Parameter flow, execution order, nil handling

#### 3. `core/grain-engine.scd` (327 lines)
**Purpose:** TGrains-based granular synthesis (up to 256 grains)
**Critical sections:**
- Lines 35-98: SynthDef arguments (80+ parameters)
- Lines 116-119: Deprecated filter params (marked but still present)
- Lines 200-250: Three material modes (TAPE/POLY/LIVE)
- Lines 290-320: Grain scheduling (overlap vs density modes)
- **Audit focus:** CPU efficiency, phase alignment (line 102), grain distribution

#### 4. `core/spectral-engine.scd` (147 lines)
**Purpose:** Warp1-based spectral time-stretching
**Critical sections:**
- Lines 35-48: SynthDef args (amp vs spectralAmp parameter naming)
- Lines 60-83: Warp1 implementation (quality vs CPU tradeoff)
- **Audit focus:** Parameter mismatch (amp/spectralAmp), CPU load at high overlaps

#### 5. `core/direct-playback.scd` (158 lines)
**Purpose:** PlayBuf-based clean sample playback
**Critical sections:**
- Lines 30-80: PlayBuf with loop region support
- Lines 95-120: Time stretch via rate scaling
- **Audit focus:** Crossfade with grain engine, loop boundary handling

#### 6. `core/modulator.scd` (195 lines)
**Purpose:** Audio-rate modulation system (4 modulators × 4 tracks)
**Critical sections:**
- Lines 50-120: Modulator types (LFO, EnvFollow, Random, Manual)
- Lines 140-180: Mapper synth (routes mod bus → synth parameter)
- **Audit focus:** Audio-rate vs control-rate, bus routing, zipper noise prevention

---

### TIER 2: Effects & Signal Flow (Important)

#### 7. `core/per-track-effects.scd` (133 lines)
**Purpose:** Dual-topology filter (Moog Ladder + SVF morph)
**Critical sections:**
- Lines 40-75: Ladder filter (0.0-0.33 morph range)
- Lines 76-110: SVF with LP/BP/HP morphing (0.33-1.0)
- **Audit focus:** Filter stability at high resonance, drive stage clipping

#### 8. `core/effects-color.scd` (212 lines)
**Purpose:** Distortion, bitcrusher, compression
**Critical sections:**
- Lines 40-90: Dual-band distortion with crossover
- Lines 120-160: Bitcrusher (sample rate + bit depth reduction)
- **Audit focus:** DC offset, clipping protection

#### 9. `core/effects-space.scd` (176 lines)
**Purpose:** Reverb, delay, shimmer
**Critical sections:**
- Lines 40-80: JPverb implementation
- Lines 100-140: Ping-pong delay with filtering
- **Audit focus:** Reverb tail handling, feedback stability

#### 10. `core/mix-bus-quad.scd` (321 lines)
**Purpose:** 4-channel master bus with quad panning
**Critical sections:**
- Lines 80-120: Equal-power quad panning algorithm
- Lines 200-280: 48-band resonator (filterbank)
- **Audit focus:** CPU load (filterbank), quad panning math

---

### TIER 3: GUI & Integration (Review if Time)

#### 11. `gui/viewfinder.scd` (1425 lines) ⚠️ LARGEST GUI FILE
**Purpose:** Waveform editor with 6-layer visualization
**Critical sections:**
- Lines 850-900: Spectral engine controls (spectralAmp issue here)
- Lines 1050-1100: Engine mode switching (grain/direct crossfade)
- Lines 1100-1170: CLEAR TRACK button (known broken - see RESET-BUTTON-ISSUE.md)
- **Audit focus:** Parameter initialization (nil fallbacks), reset logic

#### 12. `gui/four-track-view.scd` (1093 lines)
**Purpose:** Main tabbed interface
**Critical sections:**
- Lines 200-400: Per-track control layout
- Lines 600-800: Master tab with transport controls
- **Audit focus:** GUI update threading (.defer usage)

#### 13. `core/keystep-pro-mapping.scd` (272 lines)
**Purpose:** MIDI CC/note mapping system
**Critical sections:**
- Lines 50-120: CC → parameter routing with warp curves
- Lines 150-200: Note-on handling (pitch control + panic reset)
- **Audit focus:** MIDI timing, parameter collision

---

## Known Issues Requiring Expert Review

### 🔴 CRITICAL

**1. spectralAmp Parameter Initialization**
- **Files:** `core/track-manager.scd:209`, `gui/viewfinder.scd:1283`
- **Issue:** `spectralAmp` not in defaultParams (line ~173), but GUI references it. Remapping exists at line 358 (`spectralAmp → amp`), works via fallback (`? 0.5`)
- **Question:** Is this safe? Could track creation fail if fallback is removed?

**2. CLEAR TRACK Button Non-Functional**
- **File:** `gui/viewfinder.scd:1107-1170`
- **Issue:** Visual sliders reset but audio remains in glitched state
- **See:** `/RESET-BUTTON-ISSUE.md` for full diagnostic
- **Question:** Is this a setParam() issue, modulation override, or lag problem?

**3. Version Information Mismatch**
- **Files:** `main.scd:15` (says v0.4), `FEATURES.md:3` (says v2.2)
- **Impact:** User-facing confusion about capabilities
- **Question:** Non-technical, but creates audit uncertainty

### 🟠 HIGH

**4. Pitch Quantization Hidden**
- **File:** `core/track-manager.scd:290-310`
- **Issue:** Fully implemented (Phase 16) but no GUI controls
- **Question:** Is implementation correct? Test via `~trackManager.setParam(0, \quantizePitch, 1)`

**5. phaseAlign Parameter Not Exposed**
- **File:** `core/grain-engine.scd:102`
- **Issue:** Bass-optimized phase alignment exists but no GUI access
- **Question:** Does this actually prevent phase cancellation in low frequencies?

**6. Deprecated Parameters Still Present**
- **File:** `core/grain-engine.scd:116-119`
- **Params:** `filterAnimate`, `filterAnimRate`, `filterTuning`, `filterSpread`
- **Marked:** "DEPRECATED - kept for compatibility"
- **Question:** CPU/memory cost? Can they be removed safely?

### 🟡 MEDIUM

**7. Execution Order Groups**
- **File:** `core/track-manager.scd:40-42`
- **Pattern:** `modGroup → instrumentGroup` ensures modulators run before instruments
- **Question:** Is this sufficient? Any race conditions with audio-rate modulation?

**8. engineMix Parameter Status**
- **Files:** `core/track-manager.scd:103`, `gui/viewfinder.scd:1062`
- **Issue:** Parameter exists, GUI control exists, but unclear if feature is active or deprecated
- **Question:** Is this the grain ↔ direct crossfade mechanism? If so, why ambiguous status?

**9. phaseBus Variable Unused**
- **File:** `core/track-manager.scd:81`
- **Issue:** `track.phaseBus = Bus.control(server, 1);` created but never referenced
- **Question:** Dead code or incomplete feature? Memory leak concern?

---

## Test Procedures

### Audio Quality Tests

**Test 1: Grain Engine Stability**
```supercollider
// Boot and load
s.boot;
"main.scd".loadRelative;

// Stress test: maximum grains
~trackManager.setParam(0, \overlap, 128);
~trackManager.setParam(0, \grainSize, 0.005); // 5ms grains
// Listen for: clicks, pops, CPU spikes
s.avgCPU; // Should be <50%
```

**Test 2: Spectral Amp Parameter**
```supercollider
// Load sample
~trackManager.loadSample(0, "path/to/sample.wav");

// Enable spectral
~viewfinder.openTrack(0);
// In GUI: enable spectral engine, move Spectral Amp slider 0→1
// Listen for: volume change (should work)
// Check Post window for: nil errors (should be none)
```

**Test 3: Pitch Quantization**
```supercollider
// Enable quantization
~trackManager.setParam(0, \quantizePitch, 1);
~trackManager.setParam(0, \scale, [0, 2, 4, 5, 7, 9, 11]); // Major scale

// Modulate pitch
~trackManager.setParam(0, \pitchShift, 3.5); // Should snap to 4 semitones
~trackManager.setParam(0, \pitchShift, 7.8); // Should snap to 7 semitones
// Listen for: discrete pitch steps (not smooth glides)
```

**Test 4: Phase Alignment**
```supercollider
// Load bass-heavy sample (kick drum loop)
~trackManager.setParam(0, \grainSize, 0.01); // Small grains

// Compare:
~trackManager.setParam(0, \phaseAlign, 0); // Off - may sound thin
~trackManager.setParam(0, \phaseAlign, 1); // On - should sound fuller
```

### CPU & Performance

**Stress Test:**
```supercollider
// All 4 tracks active
4.do({ |i|
    ~trackManager.createTrack(i);
    ~trackManager.loadSample(i, "sample.wav");
    ~trackManager.setParam(i, \overlap, 64);
    ~trackManager.setParam(i, \spectralMix, 0.5);
    ~trackManager.setParam(i, \spectralOverlaps, 8);
    ~trackManager.setParam(i, \colorOn, 1);
    ~trackManager.setParam(i, \spaceOn, 1);
});

// Check CPU
s.avgCPU; // Target: <50% on M4
s.peakCPU; // Should not exceed 80%
```

---

## Architecture Concerns for Expert Review

### 1. Audio-Rate Modulation (Phase 13)
**Claim:** All modulation runs at 48kHz (not 750Hz control-rate)
**Files:** `core/modulator.scd`, `core/track-manager.scd:40-48`
**Question:** Is this truly eliminating zipper noise? Are there performance implications?

### 2. Three Concurrent Engines Per Track
**Pattern:** Grain + Spectral + Direct run simultaneously, controlled by mix parameters
**Files:** `core/track-manager.scd:186-231`
**Question:** Is running all 3 always (even when muted) wasteful? Should engines pause when mix=0?

### 3. Parameter Remapping in setParam()
**Pattern:** GUI uses `spectralAmp`, backend uses `amp`, remapped at line 358
**Files:** `core/track-manager.scd:350-360`
**Question:** Why not rename in GUI? Is this abstraction layer necessary?

### 4. Execution Order Dependencies
**Pattern:** Groups ensure mod → instrument ordering, but forks may bypass
**Files:** `core/track-manager.scd:40-42`
**Question:** Are there any code paths that violate execution order guarantees?

### 5. Buffer Management
**Pattern:** Each track has 4-second buffer, temp files for waveform display
**Files:** `core/buffer-recorder.scd:257`
**Question:** Is buffer lifecycle managed safely? Risk of leaks on track deletion?

---

## Audit Priorities (Recommended Focus)

### High Priority (Must Audit)
1. **track-manager.scd setParam()** - Parameter routing correctness
2. **grain-engine.scd grain scheduling** - CPU efficiency, audio quality
3. **modulator.scd audio-rate routing** - Execution order, bus leaks
4. **spectral-engine.scd Warp1 usage** - Quality vs performance tradeoff
5. **RESET-BUTTON-ISSUE.md** - Why doesn't reset work?

### Medium Priority (Should Audit)
6. **per-track-effects.scd filter topology** - Stability at extreme settings
7. **mix-bus-quad.scd quad panning** - Panning algorithm correctness
8. **viewfinder.scd parameter initialization** - Nil handling, fallback safety
9. **keystep-pro-mapping.scd MIDI routing** - Timing, parameter collision

### Low Priority (If Time Permits)
10. **preset-system.scd** - Save/load completeness
11. **pattern-library.scd** - Sequencer pattern quality
12. **effects-space.scd shimmer** - Feedback stability

---

## Questions for Third-Party Expert

1. **Is the spectralAmp parameter handling safe, or is this a ticking time bomb?**
2. **Why doesn't the CLEAR TRACK reset function work? (See RESET-BUTTON-ISSUE.md)**
3. **Is running 3 engines concurrently per track (even when muted) a bad pattern?**
4. **Are the deprecated filter parameters causing measurable CPU overhead?**
5. **Is audio-rate modulation (48kHz) overkill, or correctly eliminating zipper noise?**
6. **Is the execution order (modGroup → instrumentGroup) bulletproof?**
7. **Can pitch quantization implementation (lines 290-310) handle edge cases correctly?**
8. **Is phaseAlign actually preventing phase cancellation, or is it placebo?**
9. **Are there any obvious buffer leaks or memory issues?**
10. **What's the most glaring code smell you see?**

---

## Supporting Documents

- **FEATURES.md** - Complete feature list with v2.2 spec
- **CLAUDE.md** - Development guide with architecture overview
- **RESET-BUTTON-ISSUE.md** - Full diagnostic on broken reset function
- **CODEBASE-AUDIT-CHECKLIST.md** - 20 specific testable issues
- **bearulator_project_state.org** - Original design document with v2.1 engine code

---

## File Manifest for Third-Party Auditor

**Minimum send (core audio only):**
```
main.scd
core/track-manager.scd
core/grain-engine.scd
core/spectral-engine.scd
core/direct-playback.scd
core/modulator.scd
core/per-track-effects.scd
core/effects-color.scd
core/effects-space.scd
core/mix-bus-quad.scd
core/buffer-recorder.scd
FEATURES.md
CLAUDE.md
RESET-BUTTON-ISSUE.md
CODEBASE-AUDIT-CHECKLIST.md
```

**Full send (audio + GUI):**
Add to above:
```
gui/viewfinder.scd
gui/four-track-view.scd
gui/modulation-window.scd
core/keystep-pro-mapping.scd
core/preset-system.scd
```

**Total LOC for core audio audit:** ~3,000 lines
**Total LOC for full audit:** ~6,500 lines

---

**End of audit package. Contact with questions or findings.**
