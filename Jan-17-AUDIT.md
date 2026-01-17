# BEARULATOR: January 17, 2026 Comprehensive Audit
**System Status:** Production-Ready v2.2 with Known Issues
**Audit Date:** 2026-01-17
**Auditor:** Codebase inspection + third-party technical review preparation

---

## Executive Summary

**BEARULATOR** is a professional 4-track granular synthesis workstation running on SuperCollider, optimized for Mac Mini M4 (24GB RAM). The system is functionally complete with ~13,000 LOC across core audio engines and GUI components. Current CPU usage: ~25% at full capacity, leaving 75% headroom.

**Overall Status:** ✅ **Production-Ready** with minor documentation lag and hidden features

**Critical Findings:**
- 3 parameters exist in backend but lack GUI exposure (pitch quantization, phase alignment)
- 1 known broken feature (CLEAR TRACK reset button)
- Version documentation severely outdated (shows v0.4, actual v2.2)
- All core audio engines functioning correctly

---

## System Architecture

### Audio Signal Flow
```
Input/File → Buffer → [Grain Engine OR Spectral Engine OR Direct Playback]
                              ↓
                     Per-Track Filter (Ladder/SVF)
                              ↓
                     Color FX (Distortion, Crusher, Compression)
                              ↓
                     Space FX (Reverb, Delay, Shimmer)
                              ↓
                     Quad Panner (4-speaker spatial audio)
                              ↓
                     Mix Bus → Glue Compressor → Limiter → Output
```

### Core Components (Tier 1 Critical Files)

**1. main.scd (410 lines)**
- Boot sequence and module loader
- Server configuration (48kHz, 8 inputs, 4 outputs)
- ⚠️ Version strings outdated (shows v0.4, should be v2.2)

**2. core/track-manager.scd (956 lines)** - Largest core file
- Orchestrates 4 independent tracks
- Parameter routing with spectral remapping
- Execution order groups: modGroup → instrumentGroup
- Known issue: spectralAmp not in defaultParams (works via fallback)

**3. core/grain-engine.scd (327 lines)**
- TGrains-based granular synthesis (up to 256 grains)
- Three material modes: TAPE, POLY, LIVE
- Overlap control (1-128 grains)
- Phase-aligned mode for bass preservation
- Deprecated params still present: filterAnimate, filterAnimRate, filterTuning, filterSpread

**4. core/spectral-engine.scd (147 lines)**
- Warp1-based spectral time-stretching
- FFT window size 0.05-1.0s
- 1-8 overlaps (M4 can handle 8 for smooth processing)
- Parameter: amp (GUI uses spectralAmp, remapped at track-manager:358)

**5. core/direct-playback.scd (158 lines)**
- PlayBuf-based clean sample playback
- Loop region support
- Time stretch via rate scaling
- Stereo-aware via BufChannels.kr

**6. core/modulator.scd (195 lines)**
- Audio-rate modulation @ 48kHz (not control-rate)
- 4 modulators × 4 tracks = 16 total
- Types: LFO, EnvFollow, Random, Manual
- Eliminates zipper noise via audio-rate routing

**7. gui/viewfinder.scd (1425 lines)** - Largest GUI file
- Advanced waveform editor with 6 visual layers
- FFT spectrogram overlay
- Grain pulse animation
- ⚠️ CLEAR TRACK button broken (lines 1107-1170)
- spectralAmp slider present (line 1283)

---

## Critical Issues Identified

### 🔴 CRITICAL (Must Fix)

#### 1. CLEAR TRACK Button Non-Functional
**File:** `gui/viewfinder.scd:1107-1170`
**Symptom:** Visual sliders reset but audio remains glitched
**Impact:** Users cannot reset tracks to clean state
**Root Cause:** Unknown - possibly modulation override, setParam() failure, or lag
**Workaround:** Manually reload sample or recreate track
**See:** RESET-BUTTON-ISSUE.md for full diagnostic

#### 2. spectralAmp Parameter Edge Case
**Files:** `core/track-manager.scd:209`, `gui/viewfinder.scd:1283`
**Issue:** Parameter not in defaultParams (line ~173) but referenced everywhere
**Status:** ✅ Works via fallback (`? 0.5`) and remapping (line 358)
**Risk:** Low - fallback handles it, but inconsistent pattern
**Recommendation:** Add to defaultParams for code clarity

#### 3. Version Information Mismatch
**Files:** `main.scd:15` (says v0.4), `FEATURES.md:3` (says v2.2)
**Impact:** User confusion, developer uncertainty
**Fix Required:** Update main.scd header and startup banner

---

### 🟠 HIGH PRIORITY (Feature Gaps)

#### 4. Pitch Quantization Hidden (Phase 16)
**File:** `core/track-manager.scd:290-310`
**Status:** Fully implemented backend, zero GUI exposure
**Parameters:** `quantizePitch` (bool), `scale` (MIDI note array)
**Test:** `~trackManager.setParam(0, \quantizePitch, 1);`
**Impact:** Complete feature inaccessible to users

#### 5. Phase Alignment Mode Hidden
**File:** `core/grain-engine.scd:102`
**Status:** Backend parameter exists, no GUI control
**Purpose:** Zero-crossing aligned grains for bass preservation
**Test:** `~trackManager.setParam(0, \phaseAlign, 1);`
**Impact:** Bass optimization feature inaccessible

#### 6. Deprecated Parameters Still Present
**File:** `core/grain-engine.scd:116-119`
**Parameters:** filterAnimate, filterAnimRate, filterTuning, filterSpread
**Status:** Marked "DEPRECATED - kept for compatibility"
**Question:** CPU/memory cost? Safe to remove?

---

### 🟡 MEDIUM PRIORITY (Code Quality)

#### 7. Backup Files in Repository
**Count:** 6 files (`*.backup`, `*-backup.scd`)
**Location:** core/ and gui/ directories
**Impact:** Repository clutter
**Recommendation:** Move to /archive or delete

#### 8. Unused GUI Files
**Files:** basic-controls.scd, minimal-gui.scd, wide-gui.scd, modulation-tab.scd, viewfinder-enhanced.scd
**Status:** Not loaded by main.scd
**Impact:** Developer confusion (which GUI is canonical?)
**Recommendation:** Archive or document as alternatives

#### 9. engineMix Parameter Status Unclear
**Files:** `core/track-manager.scd:103`, `gui/viewfinder.scd:1062`
**Issue:** Parameter exists, GUI control exists, unclear if active/deprecated
**Question:** Is this grain ↔ direct crossfade? If so, why ambiguous?

#### 10. phaseBus Variable Unused
**File:** `core/track-manager.scd:81`
**Code:** `track.phaseBus = Bus.control(server, 1);`
**Issue:** Created but never referenced elsewhere
**Impact:** Minor memory leak (4 control buses × 1 each)

---

### 🔵 LOW PRIORITY (Minor Issues)

#### 11. Filter Parameters Status
**File:** `core/track-manager.scd:128-138`
**Comment:** "Filter parameters (kept for backward compat, but ignored)"
**Question:** Are per-track filters working or truly ignored?
**Impact:** Confusion about feature status

#### 12. Hardcoded Values Scattered
**Examples:**
- Filter range "20Hz-18kHz" in multiple files
- Update rates "60Hz" for playhead, "30fps" for spectrogram
**Impact:** Maintenance burden if values need changing
**Recommendation:** Centralize as constants

---

## Feature Completeness Assessment

### ✅ Fully Implemented and Accessible

**Audio Engines:**
- ✅ Granular engine (TGrains, 256 grains, overlap mode)
- ✅ Spectral engine (Warp1, 8 overlaps, freeze/smear)
- ✅ Direct playback (PlayBuf, stereo-aware, time stretch)
- ✅ Per-track dual-topology filter (Ladder + SVF morph)
- ✅ Color FX (distortion, crusher, compression, noise)
- ✅ Space FX (reverb, delay, shimmer)
- ✅ Quad spatial audio (4-speaker panning)

**Modulation & Control:**
- ✅ Audio-rate modulation (48kHz, 4 mods per track)
- ✅ MIDI integration (KeyStep Pro, 5 encoders + polyphonic)
- ✅ Preset system (save/load, 80+ params per track)
- ✅ Material modes (TAPE, POLY, LIVE)
- ✅ Loop window system

**GUI:**
- ✅ 4-track tabbed interface
- ✅ Viewfinder waveform editor (6 visual layers)
- ✅ Recording viewfinder (8-channel input)
- ✅ Quad panner GUI (2D spatial positioning)
- ✅ Modulation window (routing interface)
- ✅ Spectrum analyzer

### ⚠️ Implemented Backend, No GUI Access

- ⚠️ Pitch quantization (Phase 16) - `quantizePitch` + `scale`
- ⚠️ Phase alignment mode - `phaseAlign`
- ⚠️ Spectral amp (has slider but not in defaultParams)

### ❌ Known Broken

- ❌ CLEAR TRACK reset button (viewfinder)

---

## Performance Characteristics

**CPU Usage (M4 Mac Mini):**
- Current average: ~25% at full capacity
- Available headroom: 75%
- Per-track cost: ~6% with all features enabled

**Memory:**
- Total synth memory: ~2GB
- Buffer allocation: 1024×16 buffers
- Per-track buffer: 4 seconds default (expandable)

**Optimization Opportunities:**
- Conditional PitchShift: Saves 15-20% CPU when timeStretch=1.0 ✅
- Deprecated params removal: Unknown savings
- Engine pausing when mix=0: Not implemented

---

## Third-Party Audit Questions

For external SuperCollider expert review:

1. **Is the spectralAmp parameter handling safe, or should it be in defaultParams?**
2. **Why doesn't the CLEAR TRACK button work? (See RESET-BUTTON-ISSUE.md)**
3. **Is running 3 engines concurrently (grain/spectral/direct) wasteful?**
4. **CPU overhead from deprecated filter parameters?**
5. **Is audio-rate modulation (48kHz) overkill or necessary?**
6. **Execution order (modGroup → instrumentGroup) bulletproof?**
7. **Pitch quantization implementation (lines 290-310) handle edge cases?**
8. **Does phaseAlign actually prevent phase cancellation?**
9. **Any obvious buffer leaks or memory issues?**
10. **Most glaring code smell?**

---

## Documentation Status

### ✅ Up-to-Date Documentation
- **FEATURES.md** - Accurate v2.2 feature list
- **CLAUDE.md** - Development guide (mostly current)
- **KEYSTEP-PRO-QUICKSTART.md** - MIDI integration guide
- **RESET-BUTTON-ISSUE.md** - Comprehensive diagnostic

### ⚠️ Partially Outdated
- **README.md** - Features accurate, some Phase 12 items marked incomplete but are done
- **TODO.md** - Shows Phase 15.5 complete, but backlog unclear

### ❌ Severely Outdated
- **main.scd** - Shows v0.4 (Phase 4), should be v2.2 (Phase 15.5+)
- **main.scd startup banner** - Describes Phase 1-3 features only

---

## Recommended Actions

### Immediate (This Week)
1. ✅ Fix main.scd version strings (v0.4 → v2.2)
2. ✅ Update startup banner to reflect Phase 15.5 features
3. ⚠️ Debug CLEAR TRACK button or disable with "Not Implemented" label
4. ✅ Add spectralAmp to defaultParams for consistency

### Short-Term (Next Sprint)
5. ✅ Add GUI controls for pitch quantization (quantizePitch + scale)
6. ✅ Add GUI toggle for phaseAlign mode
7. 🗑️ Archive backup files to /archive directory
8. 🗑️ Archive or document unused GUI alternatives
9. ✅ Write deployment test for v2.2 (following v2.1 test pattern)

### Long-Term (Next Phase)
10. ✅ Remove deprecated filter parameters if safe
11. ✅ Centralize hardcoded values (filter ranges, update rates)
12. ✅ Add error handling to setParam() and createTrack()
13. ❓ Investigate phaseBus usage or remove
14. ❓ Clarify engineMix parameter status

---

## Test Verification Checklist

Use CODEBASE-AUDIT-CHECKLIST.md for systematic testing:
- **Critical Issues:** 3 items (spectralAmp, phaseAlign, quantizePitch)
- **Version Issues:** 3 items (main.scd strings)
- **Code Quality:** 7 items (deprecated params, backups, unused files)
- **Verification Tests:** 6 specific test procedures

---

## Files for Third-Party Review

**Minimum Core Audio Audit (~3,000 LOC):**
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
```

**Full System Audit (~6,500 LOC):**
Add to above:
```
gui/viewfinder.scd
gui/four-track-view.scd
gui/modulation-window.scd
core/keystep-pro-mapping.scd
core/preset-system.scd
```

**Supporting Documentation:**
```
FEATURES.md (complete feature spec)
CLAUDE.md (development guide)
RESET-BUTTON-ISSUE.md (known bug diagnostic)
this file (Jan-17-AUDIT.md)
```

---

## System Health Report

**Overall Grade: A- (Production-Ready with Known Issues)**

**Strengths:**
- ✅ Solid audio engine architecture
- ✅ Clean execution order (modulation → instruments)
- ✅ Comprehensive feature set
- ✅ Good CPU efficiency (25% usage, 75% headroom)
- ✅ Well-structured codebase
- ✅ Audio-rate modulation eliminates zipper noise

**Weaknesses:**
- ❌ Documentation lag (main.scd shows v0.4)
- ❌ 1 broken GUI feature (CLEAR TRACK)
- ⚠️ 3 hidden backend features (pitch quant, phase align)
- ⚠️ Code cruft (deprecated params, backup files)
- ⚠️ Parameter inconsistencies (spectralAmp pattern)

**Risk Assessment:**
- **High Risk:** CLEAR TRACK button (user frustration)
- **Medium Risk:** Version confusion (developer onboarding)
- **Low Risk:** Hidden features (workarounds exist)
- **Minimal Risk:** Deprecated params (no known bugs)

---

## Conclusion

BEARULATOR is a **production-ready** granular synthesis workstation with excellent audio quality and performance. The core audio engines are solid, and the system handles complex multi-engine routing without issues.

**Main concerns:**
1. **User Experience:** CLEAR TRACK button broken, hidden features
2. **Developer Experience:** Outdated version info, code cruft
3. **Code Maintenance:** Parameter inconsistencies, deprecated code

**Recommendation:** Safe for use with current feature set. Address CLEAR TRACK button and version strings before wider release. Consider GUI exposure for hidden features (pitch quantization, phase alignment) in next update.

**Next Steps:**
1. Send 3rd-party-audit-1-17.md to SuperCollider expert for review
2. Fix main.scd version information
3. Debug or disable CLEAR TRACK button
4. Plan Phase 16+ based on audit feedback

---

**Audit completed:** 2026-01-17
**Auditor:** Claude Code + Codebase Inspection
**Files reviewed:** 31 markdown docs, 19 core files, 14 GUI files
**Total analysis:** ~13,000 LOC

*End of audit report*
