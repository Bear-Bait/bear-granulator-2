# 🚀 Phase 15+ TODO List

**Extracted from commit 16c4a7d** (removed from README but still needed)

---

## ✅ **Already Complete (Phase 13-14)**

- [x] **Audio-Rate LFOs** (Phase 13) - `core/modulator.scd` uses `.ar` throughout
- [x] **KeyStep Pro MIDI Integration** (Phase 12) - `core/midi-mapping.scd` exists
  - [x] 5 encoder CC mappings (74, 71, 76, 77, 78)
  - [x] Polyphonic note triggering (4 MIDI channels → 4 tracks)
  - [x] Visual feedback (green pulses, cyan overlays in viewfinder)

---

## 🎯 **Phase 15: Core Audio Upgrades (The "M4 Special")**

### Task 1: ZDF Filter Integration
**Status:** ❌ Not Started
**Priority:** High
**Estimated Time:** 2-3 hours

**Description:**
Replace standard filters with Zero-Delay Feedback (ZDF) filters for more analog character.

**Current State:**
- Grain engine uses basic filters (see `grain-engine.scd` line 40-49)
- Filter parameters exist: `filterFreq`, `filterMorph`, `filterRes`, `filterDecay`, `filterMix`

**Tasks:**
```supercollider
// In grain-engine.scd:
// 1. Replace RLPF.ar with DFM1.ar (Zero-Delay Feedback filter)
// 2. Implement ZDF Ladder filter (Moog-style)
// 3. Keep existing SVF (State Variable Filter) for comparison
// 4. Add A/B toggle between ZDF and standard filters
// 5. Test CPU impact (target: <5% increase)
```

**Files to Modify:**
- `core/grain-engine.scd` (main filter implementation)
- `gui/four-track-view.scd` (add filter type selector if needed)

**Acceptance Criteria:**
- ZDF filter sounds more "liquid" at high resonance
- No phase cancellation at high Q
- CPU usage stays under 30% total
- Backwards compatible with existing presets

---

### Task 2: 128-Band DynKlank Resonator
**Status:** ❌ Not Started
**Priority:** Medium
**Estimated Time:** 3-4 hours

**Description:**
Upgrade the master filterbank to 128 bands (from current 48-band system).

**Current State:**
- No `master-filterbank.scd` file exists yet
- Master bus has basic glue compressor + limiter
- Current CPU usage: ~25% at full capacity

**Tasks:**
```supercollider
// Create core/master-filterbank.scd:
// 1. Implement 128-band DynKlank resonator
// 2. Frequency distribution: 20Hz - 18kHz (log-spaced)
// 3. Envelope followers per band (amplitude tracking)
// 4. Resonance control (Q factor per band or global)
// 5. Optimize for M4 (target: <5% CPU overhead)
```

**Design Decisions:**
- Use DynKlank (efficient polyphonic filter bank)
- Consider bank splitting: 4 × 32-band banks (parallel processing)
- Frequency ranges:
  - Sub: 20-80 Hz (8 bands)
  - Low: 80-320 Hz (16 bands)
  - Mid: 320-2.5k Hz (48 bands)
  - High: 2.5k-10k Hz (40 bands)
  - Air: 10k-18k Hz (16 bands)

**Files to Create:**
- `core/master-filterbank.scd` (new file)
- `gui/filterbank-visualizer.scd` (optional - spectrum visualization)

**Files to Modify:**
- `core/mix-bus.scd` (integrate filterbank)
- `main.scd` (load filterbank module)

**Acceptance Criteria:**
- 128 bands active simultaneously
- Total CPU usage stays under 30% (including all 4 tracks)
- Visual feedback (optional spectrum display)
- Global resonance control (0-1 range)
- Wet/dry mix control

---

## 🎹 **Phase 16: KeyStep Pro "Bridge" Enhancements**

### Task 3: Enhanced Channel Routing
**Status:** ⚠️ Partially Complete
**Priority:** Medium
**Estimated Time:** 1-2 hours

**Current State:**
- MIDI mapping exists (`core/midi-mapping.scd`)
- Only Track 1 controlled by encoders
- Polyphonic notes work across 4 channels

**Remaining Work:**
```supercollider
// Enhance midi-mapping.scd:
// 1. Add encoder → track routing table
//    - Encoder set A (CCs 74-78) → Track 1
//    - Encoder set B (CCs 79-83) → Track 2  [NEW]
//    - Encoder set C (CCs 84-88) → Track 3  [NEW]
//    - Encoder set D (CCs 89-93) → Track 4  [NEW]
//
// 2. Add encoder bank switching
//    - CC 94 = Bank selector (0-3 = Tracks 1-4)
//    - Visual feedback: show which track is "focused"
//
// 3. Add "global" mode
//    - All encoders control master parameters
//    - Master volume, master filter, etc.
```

**Files to Modify:**
- `core/midi-mapping.scd` (expand CC mappings)
- `gui/four-track-view.scd` (show MIDI focus indicator)

**Acceptance Criteria:**
- Bank switching works (4 encoder banks)
- Visual feedback shows active bank
- All 4 tracks controllable via MIDI
- Global mode for master controls

---

### Task 4: Musical Scaling Logic
**Status:** ❌ Not Started
**Priority:** High
**Estimated Time:** 2 hours

**Description:**
Implement proper scaling for MIDI CC values to make physical knob movement feel "musical".

**Current State:**
- Basic linear scaling exists (0-127 → 0.0-1.0)
- Some parameters use `linexp` (grain size)
- No unified scaling system

**Required Scaling Functions:**
```supercollider
// Add to midi-mapping.scd:

~scalingFunctions = (
    // Logarithmic (frequencies, cutoff)
    \frequency: { arg midi; midi.linexp(0, 127, 20, 18000) },

    // Exponential (grain size, time-based)
    \grainSize: { arg midi; midi.linexp(0, 127, 0.001, 2.0) },
    \delayTime: { arg midi; midi.linexp(0, 127, 0.01, 2.0) },

    // Linear (dry/wet, volume)
    \mix: { arg midi; midi.linlin(0, 127, 0.0, 1.0) },
    \volume: { arg midi; midi.linlin(0, 127, 0.0, 1.0) },

    // Integer (overlap, bits)
    \overlap: { arg midi; midi.linlin(0, 127, 1, 128).round(1) },
    \crushBits: { arg midi; midi.linlin(0, 127, 1, 16).round(1) },

    // Bipolar (pitch, pan)
    \pitch: { arg midi; midi.linlin(0, 127, -24, 24) },
    \pan: { arg midi; midi.linlin(0, 127, -1.0, 1.0) },

    // Custom curves (resonance)
    \resonance: { arg midi;
        // Gentle at low end, steep at high end
        (midi / 127.0).pow(2.0)
    }
);
```

**Files to Modify:**
- `core/midi-mapping.scd` (add scaling system)

**Acceptance Criteria:**
- All parameters use appropriate scaling
- Knob movement feels natural
- Low-end control is precise (frequency sweeps)
- High-end has full range (no wasted movement)

---

## 🎨 **Phase 17: "Flash" & Visuals (The "Doom" Aesthetic)**

### Task 5: "Success Green" Note Pulse
**Status:** ❌ Not Started
**Priority:** Low
**Estimated Time:** 1 hour

**Description:**
Add visual feedback when MIDI notes are received.

**Implementation:**
```supercollider
// In gui/viewfinder.scd drawFunc:
// 1. Add ring expansion effect on note trigger
// 2. Color: #c3e88d (Doom Material Success Green)
// 3. Animation: 0.5 second fade out
// 4. Position: Current playhead location

if(~noteReceived, {
    var ringSize = (Main.elapsedTime - ~noteTimestamp) * 100;
    Pen.strokeColor = Color.fromHexString("#c3e88d").alpha_(0.8 - (ringSize / 50));
    Pen.addArc(~notePosition, ringSize, 0, 2pi);
    Pen.stroke;
});
```

**Files to Modify:**
- `gui/viewfinder.scd` (add pulse rendering)
- `core/midi-mapping.scd` (set note trigger flags)

**Acceptance Criteria:**
- Green ring expands on note trigger
- Smooth fade-out animation
- Works for all 4 tracks
- No performance impact (<0.5% CPU)

---

### Task 6: Playhead Glow Effect
**Status:** ❌ Not Started
**Priority:** Low
**Estimated Time:** 1-2 hours

**Description:**
Add a glow/shadow effect to the playhead for better visibility.

**Implementation:**
```supercollider
// In gui/viewfinder.scd drawFunc:
// 1. Render playhead line twice:
//    - First pass: 10px blur, color #89DDFF (Doom Cyan), alpha 0.5
//    - Second pass: 2px sharp line, color #89DDFF, alpha 1.0
//
// 2. Use Pen blur (if available in SC GUI)
// 3. Or fake it with multiple offset lines with decreasing alpha

// Pseudo-code:
Pen.strokeColor = Color.fromHexString("#89DDFF");
10.do({ arg i;
    var alpha = 0.5 * (1 - (i / 10));
    Pen.width = 1 + (i * 0.5);
    Pen.alpha = alpha;
    Pen.line(playheadX @ 0, playheadX @ height);
    Pen.stroke;
});
```

**Challenge:**
- SuperCollider GUI doesn't have native blur
- May need to fake it with layered rendering

**Files to Modify:**
- `gui/viewfinder.scd` (playhead rendering)

**Acceptance Criteria:**
- Playhead has visible glow
- Cyan color (#89DDFF) matches Doom Material theme
- Doesn't obscure waveform too much
- Optional: toggle glow on/off

---

## 📊 **Priority Summary**

### **High Priority (Do First):**
1. ✅ Preset System (Phase 14) - **COMPLETE**
2. ⚠️ Musical Scaling Logic (Task 4) - Makes MIDI usable
3. ❌ ZDF Filter Integration (Task 1) - Core audio quality

### **Medium Priority:**
4. ❌ 128-Band Resonator (Task 2) - Big feature, but complex
5. ⚠️ Enhanced Channel Routing (Task 3) - Improves MIDI workflow

### **Low Priority (Polish):**
6. ❌ Success Green Pulse (Task 5) - Visual candy
7. ❌ Playhead Glow (Task 6) - Visual polish

---

## 🧪 **Testing Requirements**

Each task should include:
- Unit tests (if applicable)
- CPU benchmarking
- Preset compatibility check
- User acceptance testing

---

## 📝 **Notes**

**From commit 16c4a7d:**
- Audio-Rate LFOs → **Already done in Phase 13**
- KeyStep Pro bridge → **Partially done in Phase 12, needs enhancements**
- Doom visuals → **Not started**
- Scaling logic → **Critical missing piece**

**Current System State:**
- CPU usage: ~25% average (leaves 5% headroom for new features)
- RAM usage: ~2GB synth memory
- M4 optimization: Already well-tuned

**Blockers:**
- None currently
- All tasks can proceed in parallel

---

**Last Updated:** January 4, 2026
**Next Phase:** Phase 15 - Core Audio Upgrades
