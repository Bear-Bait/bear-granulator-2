# S-4 RIVAL: Afternoon Session - January 8, 2026

**Session Goal:** Address critical bugs, implement sequencer amplitude control, continue Issue #10

---

## SESSION PRIORITIES (In Order)

### 1. CRITICAL BLOCKERS (45 min)
Must fix before continuing development.

### 2. Sequencer Amplitude Control (30-45 min)
User-requested feature from morning session.

### 3. Issue #10 Phase 4 (30 min)
Complete pitch quantization implementation.

### 4. Known Bugs & Features (As time allows)
Address from list below.

---

## CRITICAL / BLOCKERS

### ❌ Fix Viewfinder OSC Listeners ("Quantum Playhead")
**Priority:** CRITICAL
**Time Estimate:** 20 minutes

**Issue:**
Viewfinder windows listen to *all* `/grainPlayhead` messages, causing Track 1 to display Track 2's playback position.

**File:** `gui/viewfinder.scd`

**Fix:**
Update OSC listeners to filter by synth node ID:

```supercollider
// BEFORE (line ~587):
grainOSCListener = OSCFunc({ arg msg, time, addr, recvPort;
    var position = msg[3];
    grainPlayheadPos = position;
}, '/grainPlayhead');

// AFTER:
grainOSCListener = OSCFunc({ arg msg, time, addr, recvPort;
    var nodeID = msg[1];
    if(nodeID == track.grainSynth.nodeID, {
        var position = msg[3];
        grainPlayheadPos = position;
    });
}, '/grainPlayhead');
```

**Also fix:**
- `spectralOSCListener` (line ~595)
- `directOSCListener` (line ~603)

**Test:**
```supercollider
// Load different samples on Track 1 and Track 2
~trackManager.loadSample(0, "/path/to/sample1.wav");
~trackManager.loadSample(1, "/path/to/sample2.wav");

// Open both viewfinders
// Track 1 should show Track 1's playhead, NOT Track 2's
```

---

### ❌ Fix Grain Overlap Crash
**Priority:** CRITICAL
**Time Estimate:** 15 minutes

**Issue:**
`v2.1-edge-cases-test` revealed that overlap > 64 (specifically 128) triggers server-side "Too many grains!" errors.

**Options:**

**Option A: Cap UI Slider (Recommended)**
**File:** `gui/viewfinder.scd` (line ~900)

```supercollider
// BEFORE:
makeSlider.value(win, xPos, yPos, "Overlap", ControlSpec(1, 128, \lin), \overlap, ...);

// AFTER:
makeSlider.value(win, xPos, yPos, "Overlap", ControlSpec(1, 64, \lin), \overlap, ...);
```

**Option B: Increase maxGrains**
**File:** `core/grain-engine.scd` (line ~30)

```supercollider
// BEFORE:
arg maxGrains = 128,

// AFTER:
arg maxGrains = 256,
```

**Recommendation:** Use Option A (cap at 64). Overlap > 64 is rarely musically useful and causes CPU spikes.

**Test:**
```supercollider
// Should not crash:
~trackManager.setParam(0, \overlap, 64);

// Should be prevented by UI:
~trackManager.setParam(0, \overlap, 128);  // UI slider won't go this high
```

---

## PRIORITY 2: SEQUENCER AMPLITUDE CONTROL

### ✅ Independent Volume for Base Grain vs. Sequencer Patterns
**Priority:** HIGH (User-requested)
**Time Estimate:** 30-45 minutes
**Status:** Implementation plan ready

**User Request:**
> "I would like to be able to slide down the volume on the grain and also adjust volume on the sequences."

**Current Behavior:**
- Base xylophone hit every 2.51s (loud)
- Fluttering sequencer patterns (same volume)

**Desired Behavior:**
- Base grain quieter (background pulse)
- Sequencer patterns louder (foreground melody)

**Implementation:**
See `NEXT-SESSION-SEQUENCER-AMPLITUDE.md` for complete plan.

**Summary:**
1. Add `baseAmp` and `seqAmp` parameters to grain-engine.scd
2. Detect sequencer activity (jitter > 0.01)
3. Apply appropriate amplitude multiplier
4. Add to track-manager defaultParams
5. Add sliders to viewfinder GUI

**Test Script:**
```supercollider
// Load pattern
var pattern = ~patternLibrary.generate(\yoshimuraCreek);
~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);

// Set quiet base, loud sequences
~trackManager.setParam(0, \baseAmp, 0.2);  // Quiet pulse
~trackManager.setParam(0, \seqAmp, 0.9);   // Loud melody

// Result: Background xylophone with foreground flutters
```

---

## PRIORITY 3: ISSUE #10 PHASE 4

### ✅ Pitch Quantization (Complete Issue #10)
**Priority:** HIGH
**Time Estimate:** 30 minutes
**Status:** 75% complete (Phases 1-3 done)

**Goal:** Snap pitch values to musical scales instead of random microtonality.

**File:** `core/track-manager.scd`

**Implementation:**
Add scale snapping logic to `setParam` method (line ~280):

```supercollider
// After line 280 (in setParam):
if((param == \pitch or: { param == \spectralPitch }) and: { track.params[\quantizePitch] == 1 }, {
    var scale = track.params[\scale];
    var nearestDegree = scale.minItem({ |deg|
        (value.round - deg).abs
    });
    value = nearestDegree;  // Snap to scale
});
```

**Parameters Already Exist:**
- `scale: [0, 2, 4, 5, 7, 9, 11]` (major scale, line ~105)
- `quantizePitch: 0` (line ~106)

**Test:**
```supercollider
// Enable pitch quantization to major scale
~trackManager.setParam(0, \quantizePitch, 1);
~trackManager.setParam(0, \scale, [0, 2, 4, 5, 7, 9, 11]);

// Set pitch (should snap to nearest scale degree)
~trackManager.setParam(0, \pitch, 3);   // Should snap to 2 or 4
~trackManager.setParam(0, \pitch, 6);   // Should snap to 5 or 7
~trackManager.setParam(0, \pitch, 11);  // Should snap to 11

"Pitch quantization test complete".postln;
```

**UI Integration (Optional):**
Add to viewfinder:
- Checkbox: "Quantize Pitch"
- Dropdown: Scale selection (Major, Minor, Pentatonic, etc.)

---

## KNOWN BUGS

### ⚠️ Viewfinder Pitch UI Sync
**Priority:** MEDIUM
**Time Estimate:** 15 minutes

**Issue:**
The Master Pitch number box does not correlate with the slider in the Viewfinder.

**File:** `gui/viewfinder.scd`

**Likely Cause:**
NumberBox and Slider have different ControlSpecs or aren't linked bidirectionally.

**Fix:**
Ensure both UI elements share the same action and update each other:

```supercollider
// Slider updates NumberBox
pitchSlider.action = { |sl|
    pitchNumberBox.value = sl.value;
    ~trackManager.setParam(trackNum, \pitch, sl.value);
};

// NumberBox updates Slider
pitchNumberBox.action = { |nb|
    pitchSlider.value = nb.value;
    ~trackManager.setParam(trackNum, \pitch, nb.value);
};
```

---

### ⚠️ Engine Mode System Glitchy
**Priority:** MEDIUM
**Time Estimate:** 30 minutes

**Issue:**
Engine mode buttons are reportedly glitchy.

**Investigation Needed:**
1. Which buttons? (Grain/Spectral/Direct?)
2. What behavior? (Not responding? Wrong engine activating?)
3. Visual state mismatch?

**File:** `gui/viewfinder.scd` (engine mode buttons)
**File:** `core/track-manager.scd` (setEngineMode method)

**Test:**
```supercollider
// Cycle through engine modes
~trackManager.setEngineMode(0, 0);  // GRANULAR
~trackManager.setEngineMode(0, 1);  // DIRECT
~trackManager.setEngineMode(0, 2);  // MIX

// Verify synths running:
~trackManager.getTrack(0).grainSynth.isRunning;
~trackManager.getTrack(0).directPlaybackSynth.isRunning;
```

---

### ⚠️ Mix Mode Non-Functional
**Priority:** MEDIUM
**Time Estimate:** 20 minutes

**Issue:**
Mix mode appears non-functional.

**Expected Behavior:**
- Mode 0 (GRANULAR): Only grain engine
- Mode 1 (DIRECT): Only direct playback
- Mode 2 (MIX): Both engines active, blended

**File:** `core/track-manager.scd` (setEngineMode, line ~400)

**Check:**
- Are both synths running in MIX mode?
- Are both synths audible?
- Is there a crossfade or hard switch?

---

### ⚠️ Direct Mode Issue
**Priority:** LOW
**Time Estimate:** 30 minutes

**Issue:**
"Direct" switch still plays the sample (should likely pass through audio input or silence the sample).

**Clarification Needed:**
What should Direct mode do?
- Option A: Play sample with no granulation (current behavior)
- Option B: Pass through live audio input
- Option C: Silence

**User Decision Required**

---

## FEATURE REQUESTS

### 🎯 Grain Envelope (ADSR)
**Priority:** MEDIUM
**Time Estimate:** 60 minutes

**Goal:**
Add Attack, Decay, Sustain, Release parameters to grain envelope.

**File:** `core/grain-engine.scd`

**Draft Code (User Provided):**

```supercollider
SynthDef(\s4GrainEngine, {
    arg out=0, bufnum=0, gate=1,
        attack=0.01, decay=0.1, sustain=0.7, release=1.0,
        // ... other existing args

    var env, sig;

    // Create the envelope
    env = EnvGen.kr(Env.adsr(attack, decay, sustain, release), gate, doneAction: 2);

    // [Existing grain code generating 'sig']

    // Apply the envelope to signal
    sig = sig * env;

    Out.ar(out, sig);
});
```

**Note:** This applies an overall envelope to the grain stream. Individual grains already have built-in envelopes via TGrains.

**Clarification Needed:**
- Per-grain ADSR? (Requires TGrains envelope shaping)
- Overall stream ADSR? (Use code above)

**UI:**
Add 4 sliders to viewfinder:
- Attack (0.001 - 5s, exponential)
- Decay (0.01 - 5s, exponential)
- Sustain (0 - 1, linear)
- Release (0.01 - 10s, exponential)

---

### 🎯 "Reset Params" Button
**Priority:** LOW
**Time Estimate:** 20 minutes

**Goal:**
Add button to Track Window that resets all params to default (0) except `grainLength` (auto-generated).

**File:** `gui/viewfinder.scd`

**Implementation:**

```supercollider
// Add button to viewfinder (near top)
Button(win, Rect(10, 10, 100, 30))
    .states_([["Reset Params", Color.white, Color.red(0.6)]])
    .action_({
        // Get default params from track manager
        var defaults = ~trackManager[\defaultParams];

        // Reset all params except grainLength
        defaults.keysValuesDo({ |key, value|
            if(key != \grainLength, {
                ~trackManager.setParam(trackNum, key, value);
            });
        });

        // Update UI to reflect reset values
        self.updateAllControls;  // Need to implement this

        "✓ Track % params reset to defaults".format(trackNum + 1).postln;
    });
```

---

### 🎯 "Clear Track" Button
**Priority:** LOW
**Time Estimate:** 15 minutes

**Goal:**
Add button to clear the track buffer and settings entirely.

**File:** `gui/viewfinder.scd`

**Implementation:**

```supercollider
// Add button to viewfinder
Button(win, Rect(120, 10, 100, 30))
    .states_([["Clear Track", Color.white, Color.red(0.8)]])
    .action_({
        // Confirm dialog (optional)
        if(true, {  // Replace with confirmation dialog
            // Stop synth
            track.grainSynth.run(false);

            // Clear buffer (silent)
            track.buffer.zero;

            // Reset all params
            var defaults = ~trackManager[\defaultParams];
            defaults.keysValuesDo({ |key, value|
                ~trackManager.setParam(trackNum, key, value);
            });

            "✓ Track % cleared".format(trackNum + 1).postln;
        });
    });
```

---

## GUI ENHANCEMENTS (Issues #7/8/11)

### 🎨 Grain Size Range Extension
**Priority:** MEDIUM
**Time Estimate:** 10 minutes

**Current:** 0.001s - 2s
**Requested:** 0.005s - 5s

**File:** `gui/viewfinder.scd`

```supercollider
// Find grain size slider (line ~850)
// BEFORE:
makeSlider.value(win, xPos, yPos, "Grain Size", ControlSpec(0.001, 2, \exp), \grainSize, ...);

// AFTER:
makeSlider.value(win, xPos, yPos, "Grain Size", ControlSpec(0.005, 5, \exp), \grainSize, ...);
```

---

### 🎨 Logarithmic Scaling for Time Parameters
**Priority:** LOW
**Time Estimate:** 30 minutes

**Apply to:**
- Attack, Decay, Release (if ADSR implemented)
- Delay times
- Reverb decay

**Example:**
```supercollider
ControlSpec(0.001, 10, \exp)  // Exponential = logarithmic feel
```

---

### 🎨 XY Pads for Paired Parameters
**Priority:** LOW
**Time Estimate:** 90 minutes

**Candidates:**
- X: Filter Cutoff, Y: Resonance
- X: Reverb Mix, Y: Reverb Size
- X: Grain Size, Y: Overlap

**Implementation:** Use `Slider2D` or `UserView` with custom drawing.

---

### 🎨 Relative MIDI Encoder Mode
**Priority:** LOW
**Time Estimate:** 45 minutes

**Goal:** MIDI encoders send relative values (increment/decrement) instead of absolute.

**File:** `core/midi-mapping.scd`

**Requires:** Detecting relative MIDI messages (CC with values 1-127 for up, 127-1 for down).

---

## MASTER TAB REDESIGN (Issue #15)

**Priority:** LOW (Future session)
**Time Estimate:** 2-3 hours

### Components Needed:
1. **Master EQ** (3-band parametric)
2. **Master Compressor** (threshold, ratio, attack, release)
3. **Master Reverb** (global space, separate from per-track)
4. **Master Limiter** (output protection, ceiling)

**File:** Create `core/master-effects.scd`
**File:** Create `gui/master-tab.scd`

---

## SESSION CHECKLIST

### Must Complete:
- [ ] Fix Viewfinder OSC listeners (nodeID filtering)
- [ ] Fix Grain Overlap crash (cap at 64)
- [ ] Implement sequencer amplitude control (baseAmp/seqAmp)

### Should Complete:
- [ ] Issue #10 Phase 4 (pitch quantization)
- [ ] Fix Viewfinder pitch UI sync
- [ ] Grain size range (0.005 - 5s)

### If Time Allows:
- [ ] Investigate engine mode glitchiness
- [ ] Fix Mix mode
- [ ] Grain ADSR implementation
- [ ] Reset Params button
- [ ] Clear Track button

---

## TESTING PROTOCOL

After each fix:

```supercollider
// 1. Reload system
(thisProcess.nowExecutingPath.dirname +/+ "main.scd").load;

// 2. Test the specific fix
// (See test scripts in each section above)

// 3. Run regression tests
"tests/v2.1-deployment-test.scd".loadRelative;
"tests/v2.1-sequencer-test.scd".loadRelative;
"tests/v2.1-edge-cases-test.scd".loadRelative;

// 4. Verify no new issues introduced
```

---

## NOTES

### User Preferences Reminder:
- Work autonomously when possible
- Comprehensive documentation
- Educational features valued
- Minimal aesthetic (no unnecessary icons)
- Test scripts are "brilliant" - create more

### From Morning Session:
- ✅ Pattern library complete (30 patterns)
- ✅ Pattern browser GUI complete
- ✅ Yoshimura & Eno patterns implemented
- ✅ Clear Track buttons added to pattern browser

### Token Budget:
- Remaining: ~85k tokens
- Save for implementation work
- Document as you go

---

**Status:** Ready to begin
**Start with:** Critical blockers (Viewfinder OSC + Overlap crash)
**Then:** Sequencer amplitude control
**Then:** Issue #10 Phase 4

**Good luck! 🎵**
