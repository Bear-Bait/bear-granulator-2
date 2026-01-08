# Next Session: Independent Sequencer Amplitude Control

**Date Created:** 2026-01-08
**Priority:** HIGH
**Estimated Time:** 30-45 minutes
**Status:** READY FOR IMPLEMENTATION

---

## Problem Statement

**Current Behavior:**
- Sequencer patterns (pitch/position modulation) and base grains share the same amplitude
- User hears: Base xylophone hit every 2.51s at full volume, beautiful fluttering sequences around it at same volume
- **Desired:** Base grain quieter, sequencer patterns louder (independent volume control)

**User Quote:**
> "I would like to be able to slide down the volume on the grain and also adjust volume on the sequences."

**Why This Matters:**
- Sequencer patterns are the "melody" - should be prominent
- Base grain is the "pulse" - should be background rhythm
- Independent control = better mixing, more expressive performance

---

## Technical Approach

### Current Architecture (v2.1)

**File:** `core/grain-engine.scd`

The engine uses Demand UGens for sequencer patterns:
```supercollider
// Current implementation (line ~150-170)
musicalPitchJitter = Demand.ar(trig, 0, pitchPattern) * pitchJitter;
musicalPosJitter = Demand.ar(trig, 0, posPattern) * posJitter;

// Applied to grain trigger
var grainFreq = (pitch + pitchShift + musicalPitchJitter).midiratio;
var grainPos = (scanPos + musicalPosJitter).wrap(0, 1);

// PROBLEM: Same amplitude for all grains
sig = TGrains.ar(..., amp, ...);
```

### Proposed Solution

Add **amplitude modulation** based on jitter activity:

```supercollider
// NEW PARAMETERS (add to SynthDef args):
arg baseAmp = 1.0,      // Base grain amplitude multiplier (0-1)
    seqAmp = 1.0,       // Sequencer amplitude multiplier (0-1)

// NEW LOGIC (inside grain loop):
var isSequenced = (musicalPitchJitter.abs > 0.01) | (musicalPosJitter.abs > 0.01);
var ampMod = Select.kr(isSequenced, [baseAmp, seqAmp]);
var finalAmp = amp * ampMod;

// Use finalAmp in TGrains
sig = TGrains.ar(..., finalAmp, ...);
```

**Key Insight:** When jitter values are non-zero (sequence is active), scale amplitude by `seqAmp`. Otherwise use `baseAmp`.

---

## Implementation Plan

### Phase 1: Engine Modification (15 min)

**File:** `core/grain-engine.scd`

1. **Add parameters to SynthDef** (line ~30):
   ```supercollider
   arg baseAmp = 1.0,
       seqAmp = 1.0,
   ```

2. **Detect sequencer activity** (line ~170, after jitter calculation):
   ```supercollider
   // Detect if this grain is part of a sequence
   var pitchActive = musicalPitchJitter.abs > 0.01;
   var posActive = musicalPosJitter.abs > 0.01;
   var isSequenced = pitchActive | posActive;
   ```

3. **Apply amplitude modulation** (before TGrains call):
   ```supercollider
   // Select amplitude based on sequence activity
   var ampMod = Select.kr(isSequenced, [baseAmp, seqAmp]);
   var finalAmp = amp * ampMod.lag(0.01);  // Smooth transitions
   ```

4. **Update TGrains call** (line ~190):
   ```supercollider
   sig = TGrains.ar(
       2,
       trig,
       bufnum,
       grainRate,
       grainPos,
       grainSize,
       grainPan,
       finalAmp,  // CHANGED from 'amp'
       2
   );
   ```

### Phase 2: Track Manager Integration (10 min)

**File:** `core/track-manager.scd`

1. **Add to defaultParams** (line ~102):
   ```supercollider
   baseAmp: 1.0,
   seqAmp: 1.0,
   ```

2. **Add to setParam** (already works - no changes needed):
   - Parameters will automatically route to grain synth

### Phase 3: GUI Integration (15 min)

**File:** `gui/viewfinder.scd`

Add sliders to each track window:

```supercollider
// After existing amp slider (line ~800)
makeSlider.value(win, xPos, yPos, "Base Amp",
    ControlSpec(0, 1, \lin),
    \baseAmp,
    track.params[\baseAmp] ? 1.0
);

makeSlider.value(win, xPos, yPos + 30, "Seq Amp",
    ControlSpec(0, 1, \lin),
    \seqAmp,
    track.params[\seqAmp] ? 1.0
);
```

**Alternative:** Add to pattern browser as global controls.

---

## Testing Plan

### Test 1: Isolated Base Grain
```supercollider
// Load xylophone sample
~trackManager.loadSample(0, "/path/to/xylophone.wav");

// Set base grain quiet
~trackManager.setParam(0, \baseAmp, 0.2);
~trackManager.setParam(0, \seqAmp, 1.0);

// No sequence active - should hear quiet xylophone
~trackManager.setParam(0, \pitchJitter, 0);
~trackManager.setParam(0, \posJitter, 0);

// Result: Quiet base grain at original pitch
```

### Test 2: Sequencer Only
```supercollider
// Load pattern
var pattern = ~patternLibrary.generate(\yoshimuraCreek);
~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);

// Set sequencer loud, base quiet
~trackManager.setParam(0, \baseAmp, 0.1);  // Very quiet base
~trackManager.setParam(0, \seqAmp, 1.0);   // Full volume sequences

// Result: Quiet pulse, loud melodic patterns
```

### Test 3: Mixed (User's Desired Behavior)
```supercollider
// Base: subtle pulse
~trackManager.setParam(0, \baseAmp, 0.3);

// Sequencer: prominent melody
~trackManager.setParam(0, \seqAmp, 0.9);

// Load Creek pattern
var pattern = ~patternLibrary.generate(\yoshimuraCreek);
~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);

// Result: Background xylophone hits with foreground melodic flutters
```

### Test 4: Extreme Values
```supercollider
// Silent base, loud sequences
~trackManager.setParam(0, \baseAmp, 0.0);
~trackManager.setParam(0, \seqAmp, 1.0);
// Should hear ONLY sequencer patterns, no base pulse

// Silent sequences, loud base
~trackManager.setParam(0, \baseAmp, 1.0);
~trackManager.setParam(0, \seqAmp, 0.0);
// Should hear ONLY base grain, no melodic patterns
```

---

## Potential Issues & Solutions

### Issue 1: Detection Threshold
**Problem:** What if jitter is very small (< 0.01)?
**Solution:** Make threshold a parameter:
```supercollider
arg seqThreshold = 0.01,  // Minimum jitter to trigger seqAmp
```

### Issue 2: Smooth Transitions
**Problem:** Clicking when switching between baseAmp and seqAmp?
**Solution:** Already addressed with `.lag(0.01)` on `ampMod`

### Issue 3: Overlapping Grains
**Problem:** Multiple grains active - some base, some sequenced?
**Solution:** Per-grain amplitude (TGrains handles this correctly)

### Issue 4: CPU Impact
**Problem:** Extra Select.kr calls per grain?
**Solution:** Negligible - control-rate logic, very cheap

---

## Alternative Approaches (If Main Approach Fails)

### Approach B: Separate Grain Streams
Create two parallel TGrains:
- One for base grain (no jitter)
- One for sequencer (with jitter)
- Mix with separate amplitudes

**Pros:** True separation, no detection logic
**Cons:** 2x CPU usage, more complex

### Approach C: Envelope Follower
Use jitter amount to create amplitude envelope:
```supercollider
var seqEnv = (musicalPitchJitter.abs + musicalPosJitter.abs).lag(0.01);
var finalAmp = amp * baseAmp.linlin(0, 1, 1, seqAmp, seqEnv);
```

**Pros:** Smooth amplitude following jitter intensity
**Cons:** More complex, harder to reason about

---

## Files to Modify

1. ✅ `core/grain-engine.scd` - Add baseAmp/seqAmp parameters and logic
2. ✅ `core/track-manager.scd` - Add to defaultParams
3. ✅ `gui/viewfinder.scd` - Add sliders (optional)
4. ✅ Create test script: `tests/sequencer-amplitude-test.scd`

---

## Success Criteria

- [ ] User can set `baseAmp = 0.2` and hear quiet base grain
- [ ] User can set `seqAmp = 1.0` and hear loud sequencer patterns
- [ ] Base grain and sequencer patterns have independent volume
- [ ] No clicks or artifacts when switching
- [ ] Works with all 30 built-in patterns
- [ ] CPU usage < 5% increase

---

## User's Additional Notes

(User will add notes below)

### Xylophone Sample Details
- Path:
- Characteristics:
- Desired behavior:

### Musical Use Cases
-

### Additional Feature Requests
-

---

## Context for Next Claude Instance

**What was accomplished in this session:**
1. ✅ Created pattern library with 30 patterns (Yoshimura, Eno, world music, microtonal)
2. ✅ Built pattern browser GUI with waveform previews
3. ✅ Added "Clear Track" buttons to disable sequences
4. ✅ Integrated with main.scd (loads automatically)
5. ✅ Comprehensive documentation created

**Current state:**
- Pattern browser is **fully functional** and ready to use
- User discovered amplitude issue when testing with xylophone sample
- Sequencer patterns work perfectly, just need independent volume control

**Next session priority:**
- Implement baseAmp/seqAmp parameters (this document)
- Test with user's xylophone sample
- Possibly add GUI controls

**Files recently modified:**
- `core/pattern-library.scd` - 30 patterns
- `gui/pattern-browser.scd` - Browser window
- `main.scd` - Added pattern system loading
- `examples/SEQUENCER-PATTERN-GUIDE.scd` - Educational guide

**Key user preferences:**
- Minimal aesthetic (no icons/images)
- Useful "flare" like LFO spectrograms is good
- Highly customizable systems (for years of tinkering)
- Yoshimura and Eno are musical heroes
- Familiar with world music theory

---

**Status:** READY FOR NEXT SESSION
**Estimated completion:** 30-45 minutes
**Difficulty:** Medium (straightforward engine modification)
