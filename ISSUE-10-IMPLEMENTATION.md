# Issue #10: Rhythmic and Melodic Quantization - Implementation Summary

**Status:** ✅ PHASES 1-3 COMPLETE | Phase 4 (Pitch Quantization) PENDING
**Date:** 2026-01-08

---

## Overview

Issue #10 from TESTING-NOTES.md addresses the need for rhythmic coherence and melodic control when switching between Direct, Granular, and Spectral engines.

**Four-Part Solution:**
1. ✅ **Phase 1: Re-Wiring** - Parameter collision fix (mode → grainMode)
2. ✅ **Phase 2: MIDI Learn** - 64-step sequencer capture from hardware
3. ✅ **Phase 3: Visual Sync** - Smooth playhead export
4. ⏳ **Phase 4: Pitch Quantization** - Snap to musical scales (PENDING)

---

## Phase 1: Re-Wiring (Bridge) ✅ COMPLETE

### Problem
GUI calls `trackManager.setMode()` which sent `\mode` parameter, but v2.1 engine uses `\grainMode`.

### Solution
**File:** `core/track-manager.scd:384`
```supercollider
track.grainSynth.set(\grainMode, newMode);  // v2.1: renamed to grainMode
```

### Verification
```supercollider
// Test all three material modes
~trackManager.setMode(0, 0);  // TAPE
~trackManager.setMode(0, 1);  // POLY
~trackManager.setMode(0, 2);  // LIVE
// All work without conflicts with engineMode
```

**Status:** ✅ Verified working in v2.1 deployment test

---

## Phase 2: MIDI Learn (Secret Weapon) ✅ COMPLETE

### Problem
64-step sequencer arrays (posSeq/pitchSeq) exist but no GUI to input them.

### Solution
**File:** `core/midi-mapping.scd`

Added MIDI Learn system:
- **Lines 35-40:** State variables (learnMode, learnType, learnTrack, learnBuffer, learnCount)
- **Lines 139-143:** Note handler intercepts notes during learn mode
- **Lines 271-366:** Learn mode methods (enableLearn, disableLearn, captureLearnNote, finishLearn)

### API
```supercollider
// Enable learn mode for pitch sequence on Track 1
~midiMapping.enableLearn(trackNum: 0, type: \pitch);
// Play up to 64 notes on MIDI controller
// Auto-finishes at 64 notes or call manually:
~midiMapping.finishLearn;

// Enable learn mode for position sequence on Track 2
~midiMapping.enableLearn(trackNum: 1, type: \position);
```

### Features
- Captures MIDI notes into 64-step arrays
- Two types: `\pitch` (semitone offsets) or `\position` (buffer positions)
- Auto-finishes at 64 notes
- Repeats short patterns to fill 64 steps
- Automatically enables jitter parameters
- Progress indicators every 16 notes
- Works with any MIDI keyboard or controller

### Example Usage
**File:** `examples/midi-learn-guide.scd` (comprehensive guide with 10+ examples)

```supercollider
// Capture pentatonic melody
~midiMapping.enableLearn(0, \pitch);
// Play: C-D-E-G-A-C-D-E-G-A... (up to 64 notes)
~midiMapping.finishLearn;
// Result: Repeating melodic pattern on Track 1
```

**Status:** ✅ Implemented and documented

---

## Phase 3: Visual Sync (Quantum Fix) ✅ COMPLETE

### Problem
GUI playhead jittered due to modulators affecting position parameter.

### Solution (Already Fixed in v2.1)
**File:** `core/grain-engine.scd:197`
```supercollider
// v2.1 FIX: GUI Feedback uses smooth scanPos (Fixes Quantum Jitter Bug)
SendReply.ar(Impulse.ar(60), '/grainPlayhead', [scanPos]);
```

**File:** `gui/viewfinder.scd:587`
```supercollider
grainOSCListener = OSCFunc({ arg msg, time, addr, recvPort;
    var position = msg[3];  // Receives smooth scanPos
    grainPlayheadPos = position;
}, '/grainPlayhead');
```

### How It Works
- Engine exports smooth `scanPos` (blended phasor + position)
- Viewfinder receives at 60Hz
- No jitter from grain-level position modulation
- Clean, smooth playhead movement

**Status:** ✅ Verified working (viewfinder receives smooth updates)

---

## Phase 4: Pitch Quantization ⏳ PENDING

### Planned Features

#### A. Shared Phase Bus (Rhythmic Sync)
**Current Status:** Phase bus exists (track-manager.scd:81)
```supercollider
track.phaseBus = Bus.control(server, 1);
```

**Next Step:** Verify all engines read from shared phase bus for synchronized playback position when switching engines.

#### B. Pitch Quantization (Melodic Control)
**Goal:** Snap pitch values to musical scales instead of random microtonality.

**Implementation Plan:**
```supercollider
// In track-manager.scd defaultParams:
scale: [0, 2, 4, 5, 7, 9, 11],  // Major scale (already exists)
quantizePitch: 0,                // Enable pitch quantization (already exists)

// In track-manager.scd setParam:
if((param == \pitch or: { param == \spectralPitch }) and: { track.params[\quantizePitch] == 1 }, {
    var scale = track.params[\scale];
    var nearestDegree = scale.minItem({ |deg|
        (value.round - deg).abs
    });
    value = nearestDegree;  // Snap to scale
});
```

**Use Cases:**
- Pentatonic scales for ambient textures
- Chromatic scales for melodic sequences
- Microtonal scales (24-TET, 31-TET, 53-TET) for intentional microtonality
- Avoids out-of-tune randomness

#### C. Engine Morph Parameter (Smooth Switching)
**Goal:** Crossfade between engines instead of hard switching.

**Current:** engineMode (0=GRANULAR, 1=DIRECT, 2=MIX)
**Proposed:** engineMorph (0.0-2.0 continuous)

**Implementation:**
```supercollider
// In combined engine synth:
var engineMorph = \engineMorph.kr(0).lag(0.05);
var sig = SelectX.ar(engineMorph.clip(0, 2), [
    directSig,
    grainSig,
    spectralSig
]);
```

**Use Cases:**
- Modulate engineMorph with LFO for rhythmic switching
- Manual crossfades between engine types
- "Hits" effect (burst of spectral over direct playback)

---

## Implementation Status Summary

| Phase | Feature | Status | File | Lines |
|-------|---------|--------|------|-------|
| 1 | Parameter collision fix | ✅ Complete | track-manager.scd | 384 |
| 2 | MIDI Learn state vars | ✅ Complete | midi-mapping.scd | 35-40 |
| 2 | MIDI Learn methods | ✅ Complete | midi-mapping.scd | 271-366 |
| 2 | Note handler intercept | ✅ Complete | midi-mapping.scd | 139-143 |
| 2 | MIDI Learn guide | ✅ Complete | examples/midi-learn-guide.scd | 300+ lines |
| 3 | Smooth playhead export | ✅ Complete | grain-engine.scd | 197 |
| 3 | OSC listener verified | ✅ Complete | viewfinder.scd | 587 |
| 4 | Shared phase bus exists | ✅ Complete | track-manager.scd | 81 |
| 4 | Scale parameter exists | ✅ Complete | track-manager.scd | 105 |
| 4 | quantizePitch exists | ✅ Complete | track-manager.scd | 106 |
| 4 | Pitch quantization logic | ⏳ Pending | track-manager.scd | TBD |
| 4 | Engine morph parameter | ⏳ Pending | New/Modified | TBD |

---

## Testing

### Phase 1 Test
```supercollider
"tests/v2.1-deployment-test.scd".loadRelative;
// Step 8 tests grainMode parameter switching
```

### Phase 2 Test
```supercollider
// Manual test:
~midiMapping.enableLearn(0, \pitch);
// Play 8 notes on MIDI controller
~midiMapping.finishLearn;
// Verify: Melodic pattern plays back
```

### Phase 3 Test
```supercollider
// Open viewfinder and observe playhead
// Should move smoothly without jitter
// Even with posJitter/pitchJitter enabled
```

### Phase 4 Test (When Implemented)
```supercollider
// Enable pitch quantization to major scale
~trackManager.setParam(0, \quantizePitch, 1);
~trackManager.setParam(0, \scale, [0, 2, 4, 5, 7, 9, 11]);

// Set pitch (should snap to nearest scale degree)
~trackManager.setParam(0, \pitch, 3);  // Should snap to 2 or 4
```

---

## Benefits Achieved

### Rhythmic Coherence
- ✅ Smooth engine switching (no parameter conflicts)
- ✅ Clean playhead visualization
- ⏳ Shared phase bus for synchronized playback (pending verification)

### Melodic Control
- ✅ 64-step pitch sequences (musical, repeatable)
- ✅ MIDI Learn for easy melody capture
- ✅ Hardware integration (KeyStep Pro, Digitone)
- ⏳ Pitch quantization to scales (pending implementation)

### Workflow Improvements
- ✅ No need to manually program 64-step arrays
- ✅ Play melodies directly from MIDI keyboard
- ✅ Short patterns auto-repeat to 64 steps
- ✅ Visual feedback during capture
- ✅ Multiple tracks, different sequences

---

## Next Steps (Phase 4 Completion)

1. **Implement Pitch Quantization Logic**
   - Add scale snapping to setParam in track-manager.scd
   - Test with major, minor, pentatonic, chromatic scales
   - Test with microtonal scales (24-TET)

2. **Add Engine Morph Parameter** (Optional)
   - Create combined engine synth with SelectX crossfading
   - Add engineMorph to modulation targets
   - Test LFO modulation for rhythmic switching

3. **Create Phase 4 Test Script**
   - tests/issue-10-quantization-test.scd
   - Test all scale types
   - Test engine morph crossfading

4. **Documentation**
   - Update FEATURES.md with pitch quantization
   - Add examples/pitch-quantization-guide.scd
   - Update TESTING-GUIDE.md

---

## Files Modified

### Core Files
- `core/track-manager.scd` - Parameter translation fix
- `core/midi-mapping.scd` - MIDI Learn system (100+ lines added)
- `core/grain-engine.scd` - Smooth scanPos export (v2.1)

### GUI Files
- `gui/viewfinder.scd` - OSC listener (already correct)

### Documentation
- `examples/midi-learn-guide.scd` - Complete MIDI Learn guide (300+ lines)
- `ISSUE-10-IMPLEMENTATION.md` - This file

### Tests
- `tests/v2.1-deployment-test.scd` - Includes grainMode test

---

## User Testing Checklist

Before marking Issue #10 as complete:

- [x] Phase 1: Parameter collision fixed
- [x] Phase 2: MIDI Learn implemented
- [x] Phase 2: MIDI Learn documented
- [x] Phase 3: Smooth playhead verified
- [x] Phase 3: OSC listener working
- [ ] Phase 4: Pitch quantization logic implemented
- [ ] Phase 4: Pitch quantization tested
- [ ] Phase 4: Engine morph implemented (optional)
- [ ] Phase 4: Comprehensive test script created

---

**Current Status:** 75% Complete (Phases 1-3 done, Phase 4 pending)
**Blocking:** Awaiting user approval for Phase 4 implementation approach
