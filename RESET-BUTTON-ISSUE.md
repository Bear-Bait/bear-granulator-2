# Reset Button Issue - Diagnostic Summary

## The Problem

**Symptom:** The "✖ CLEAR TRACK" button in the viewfinder GUI updates sliders visually but does NOT reset the audio to default state. Sound remains "glitched" after clicking reset.

**Location:** `/gui/viewfinder.scd` lines 1107-1170

## What Works

1. ✅ Button action fires correctly (console output appears)
2. ✅ GUI sliders snap back to default positions visually
3. ✅ `localTrackManager.setParam()` calls execute without errors
4. ✅ Manual individual `setParam()` calls work: `~trackManager.setParam(0, \timeStretch, 1.0)` → updates correctly

## What Doesn't Work

1. ❌ Audio does not reset despite visual feedback
2. ❌ Sound remains "glitched/mangled" after reset
3. ❌ `resetParams()` function (in track-manager.scd) crashes silently - never reaches the final confirmation message

## Code Flow

```supercollider
// Current CLEAR TRACK button implementation:
Button action →
  Stop synths →
  Call setParam() for each default →
  Update GUI sliders →
  Reload sample

// What SHOULD happen:
Params reset → Synth actually changes → Audio sounds clean

// What ACTUALLY happens:
Params reset → track.params updated → GUI updates → Audio unchanged
```

## Critical Information Needed

### 1. Verify setParam() Actually Updates Synth
**Test:** Does `setParam()` update both `track.params` AND `synth.set()`?

```supercollider
// Run this diagnostic:
~trackManager.setParam(0, \grainSize, 2.0);  // Change to 2.0
~trackManager.getTrack(0).params[\grainSize].postln;  // Check track.params
~trackManager.getTrack(0).grainSynth.get(\grainSize, { |val| val.postln });  // Check actual synth
```

**Expected:** Both should show 2.0
**If different:** setParam() is not updating the synth

### 2. Check for Modulation Override
**Question:** Are modulation routings overriding the parameter changes?

```supercollider
// Check if modulators are active:
~trackManager.getTrack(0).modulators.postln;  // Should be [nil, nil, nil, nil] if none active
```

### 3. Check for Parameter Lag/Smoothing
**Question:** Do synth parameters have lag/smoothing that delays changes?

Look in `/core/grain-engine.scd` for `.lag()` or `Lag.kr()` on parameters.

### 4. Verify Synth State
**Question:** Is the synth actually running when we call setParam?

```supercollider
~trackManager.getTrack(0).grainSynth.isRunning.postln;  // Should be true or false
```

## Possible Solutions

### Path A: Bypass setParam and Use Direct Synth Control
**Pros:** Guaranteed to update synth immediately
**Cons:** Bypasses the trackManager abstraction

```supercollider
// Instead of:
localTrackManager.setParam(trackNum, \grainSize, 0.1);

// Do:
track.grainSynth.set(\grainSize, 0.1);
track.params[\grainSize] = 0.1;  // Keep track.params in sync
```

### Path B: Force Synth Restart After Reset
**Pros:** Nuclear option - definitely works
**Cons:** Audio glitch during restart

```supercollider
track.grainSynth.run(false);
// Set all params
track.grainSynth.run(true);
```

### Path C: Fix resetParams() Function
**Pros:** Solves root cause
**Cons:** Need to debug why it crashes

The `.do` loop in `track-manager.scd:778-781` crashes silently. Need to debug why.

### Path D: Clear Modulation Routings First
**Pros:** May be the actual issue
**Cons:** Only works if modulation is the problem

```supercollider
// Before resetting params:
track.modulators.do({ |mod, i|
    if(mod.notNil, {
        localTrackManager.freeModulator(trackNum, i);
    });
});
```

### Path E: Recreate Track from Scratch
**Pros:** 100% guaranteed clean slate
**Cons:** Overkill, loses sample

```supercollider
~trackManager.freeTrack(trackNum);
~trackManager.createTrack(trackNum);
```

## Recommended Next Steps

1. **First:** Run diagnostic to check if `setParam()` updates the actual synth (Path A test)
2. **If setParam works:** Check for modulation override (Path D)
3. **If setParam fails:** Use direct synth.set() approach (Path A)
4. **Last resort:** Force synth restart (Path B) or full track recreation (Path E)

## Files Involved

- `/gui/viewfinder.scd` - CLEAR TRACK button (lines 1107-1170)
- `/core/track-manager.scd` - setParam() and resetParams() functions
- `/core/grain-engine.scd` - Actual synth that should be updated
- `/core/spectral-engine.scd` - Spectral synth parameters
- `/core/direct-playback.scd` - Direct playback synth parameters

## Key Variables in Scope

```supercollider
track              // Current track object (has grainSynth, spectralSynth, params)
trackNum           // Track index (0-3)
localTrackManager  // Reference to ~trackManager
uiWidgets          // Dictionary of GUI slider/numbox pairs
```

## Success Criteria

After clicking CLEAR TRACK:
1. ✅ All sliders return to default positions (WORKS NOW)
2. ✅ Audio sounds clean/reset (BROKEN)
3. ✅ Sample reloads successfully (WORKS NOW)
4. ✅ No "glitched" or mangled sound remains
