# Phase 15.5 Testing Guide
**Date:** January 5, 2026
**Purpose:** Systematic testing of new features and bugfixes

---

## 🎯 What to Test

### 1. Direct Playback Mode ✅
**Files:** `core/direct-playback.scd`, `core/track-manager.scd`

**Test Steps:**
```supercollider
// Load a sample
~trackManager.loadSample(0, "/path/to/sample.wav");

// Switch to DIRECT mode
~trackManager.setParam(0, \engineMode, 1);

// Test playback rate (changes pitch)
~trackManager.setParam(0, \rate, 2.0);  // Double speed
~trackManager.setParam(0, \rate, 0.5);  // Half speed
~trackManager.setParam(0, \rate, 1.0);  // Normal

// Test time stretch (preserves pitch)
~trackManager.setParam(0, \timeStretch, 0.5);  // Slow motion
~trackManager.setParam(0, \timeStretch, 2.0);  // Fast forward
~trackManager.setParam(0, \timeStretch, 1.0);  // Normal
```

**What to Listen For:**
- ✅ Clean playback without artifacts
- ✅ Rate changes pitch (like vinyl speed)
- ✅ Time stretch preserves pitch
- ✅ Playhead moves smoothly in viewfinder
- ✅ No clicks when switching modes

**What to Watch For:**
- ❌ Audio dropouts
- ❌ Clicks/pops when changing parameters
- ❌ CPU spikes

---

### 2. Stereo Balance (CRITICAL) ✅
**Files:** `core/grain-engine.scd`, `core/direct-playback.scd`

**Test Steps:**
```supercollider
// Use the stereo monitor utility
(thisProcess.nowExecutingPath.dirname +/+ "util/monitor-stereo.scd").load;

// Test DIRECT mode
~trackManager.setParam(0, \engineMode, 1);
// Wait for readings... should see: L: 0.3 | R: 0.3 (balanced)

// Test GRANULAR mode
~trackManager.setParam(0, \engineMode, 0);
// Wait for readings... should see balanced after 2-3 seconds
```

**What to Listen For:**
- ✅ Centered stereo image
- ✅ Both speakers equal volume
- ✅ No phantom panning

**What to Watch For:**
- ❌ One channel louder than the other
- ❌ Image shifts left/right unexpectedly

---

### 3. Sample Loading (NO BURST) ✅
**Files:** `gui/four-track-view.scd`

**Test Steps:**
```supercollider
// Open viewfinder
~viewfinder.createWindow(0);

// Load sample via GUI (drag & drop or file selector)
// Listen carefully during the load

// Load another sample immediately after
// Should be completely silent during load
```

**What to Listen For:**
- ✅ Complete silence during sample load
- ✅ No click, pop, or burst sound

**What to Watch For:**
- ❌ Audio burst/click when loading
- ❌ Continued playback of old sample during load

---

### 4. Tempo Sync (MIDI Clock) 🎹
**Files:** `core/modulator.scd`, `core/midi-mapping.scd`, `gui/modulation-window.scd`

**Test Steps:**
```supercollider
// Open modulation window
~modulationWindow.createWindow(0, 0);  // Track 1, Modulator 1

// In GUI:
// 1. Click "Tempo Sync" button to ON
// 2. Select sync mode (1/4, 1/8, 1/16, etc)
// 3. Route modulator to a parameter (e.g., Grain Size)

// Start MIDI clock from KeyStep Pro or DAW
// LFO should now sync to tempo

// Or test via code:
var track = ~trackManager.getTrack(0);
track.modulators[0].set(\tempoSync, 1);  // Enable sync
track.modulators[0].set(\syncMode, 1);   // 1/8 note
```

**What to Listen For:**
- ✅ LFO locks to MIDI clock tempo
- ✅ Rate changes with BPM changes
- ✅ Smooth tempo tracking

**What to Watch For:**
- ❌ LFO drifts out of sync
- ❌ Tempo jumps/jitter
- ❌ No response to MIDI clock

---

### 5. Conditional PitchShift (CPU Test) 🔋
**Files:** `core/direct-playback.scd`

**Test Steps:**
```supercollider
// Monitor CPU with server meter
s.meter;

// Set timeStretch to 1.0 (PitchShift should bypass)
~trackManager.setParam(0, \timeStretch, 1.0);
// Note CPU usage

// Set timeStretch to 0.5 (PitchShift should activate)
~trackManager.setParam(0, \timeStretch, 0.5);
// CPU should increase by ~15-20%

// Back to 1.0 (PitchShift should bypass again)
~trackManager.setParam(0, \timeStretch, 1.0);
// CPU should drop back down
```

**What to Watch For:**
- ✅ CPU drops when timeStretch=1.0
- ✅ No audio clicks when bypassing
- ✅ ~15-20% CPU savings

---

### 6. Logarithmic Velocity 🎹
**Files:** `core/midi-mapping.scd`

**Test Steps:**
```supercollider
// Play notes with varying velocity on KeyStep Pro
// Soft hits (vel 1-30) should still be audible
// Medium hits (vel 50-80) should feel natural
// Hard hits (vel 100-127) should be punchy but not distorted
```

**What to Listen For:**
- ✅ Soft notes are audible (not silent)
- ✅ Velocity response feels "analog"
- ✅ No sudden jumps in volume

**What to Watch For:**
- ❌ Soft notes inaudible
- ❌ Velocity feels linear/unnatural
- ❌ Distortion at high velocity

---

## 🎹 KeyStep Pro MIDI Testing

**Hardware:** Arturia KeyStep Pro
**First time using MIDI with SuperCollider?** This section covers everything!

### Setup: Check MIDI Connection

**Step 1: Verify MIDI is connected**
```supercollider
// Check if MIDI devices are detected
MIDIClient.init;
MIDIClient.sources;  // Should list your KeyStep Pro

// You should see something like:
// MIDIEndPoint("Arturia KeyStep Pro", "Arturia KeyStep Pro MIDI 1")
```

**Step 2: Monitor incoming MIDI (see what's being received)**
```supercollider
// This will print ALL MIDI messages - great for debugging!
MIDIIn.connectAll;

// Note On/Off monitor
MIDIFunc.noteOn({ arg vel, num, chan, src;
    "NOTE ON  | Channel: % | Note: % | Velocity: %".format(chan + 1, num, vel).postln;
});

MIDIFunc.noteOff({ arg vel, num, chan, src;
    "NOTE OFF | Channel: % | Note: %".format(chan + 1, num).postln;
});

// CC (encoder) monitor
MIDIFunc.cc({ arg val, num, chan, src;
    "CC       | Channel: % | CC#: % | Value: %".format(chan + 1, num, val).postln;
});

// MIDI Clock monitor
MIDIFunc.clock({ arg src;
    "CLOCK    | Tick".postln;  // Prints 24 times per quarter note
});
```

**What you should see:**
- Turn encoder → `CC | Channel: 1 | CC#: 74 | Value: 64`
- Press key → `NOTE ON | Channel: 1 | Note: 60 | Velocity: 100`
- Release key → `NOTE OFF | Channel: 1 | Note: 60`
- Start clock → `CLOCK | Tick` (repeated rapidly)

**If you see nothing:** Check KeyStep Pro USB cable, power, and MIDI settings

---

### Test 1: Encoder Control (CC Messages) 🎛️

**KeyStep Pro Setup:**
- Set sequencer track 1 to MIDI Channel 1

**Test Steps:**
```supercollider
// Granulator should already be listening to these CCs:
// Encoder 1 (CC 74) → Filter Cutoff
// Encoder 2 (CC 71) → Grain Size
// Encoder 3 (CC 76) → Overlap/Density
// Encoder 4 (CC 77) → Spectral Mix
// Encoder 5 (CC 78) → Filter Drive

// Just turn the encoders and listen!
// You should hear immediate parameter changes

// Optional: Watch parameter values change
~trackManager.getTrack(0).params.postln;
```

**What to Listen For:**
- ✅ Encoder 1 (CC 74): Filter cutoff sweeps (bright → dark)
- ✅ Encoder 2 (CC 71): Grain size changes (short grains → long grains)
- ✅ Encoder 3 (CC 76): Density increases (sparse → thick texture)
- ✅ Encoder 4 (CC 77): Spectral mix (dry → wet spectral processing)
- ✅ Encoder 5 (CC 78): Filter drive/resonance

**What to Watch For:**
- ❌ No response to encoder turns
- ❌ Parameters jump instead of smooth changes
- ❌ Wrong parameter responds

---

### Test 2: Note Triggering (4-Track Polyphonic) 🎹

**KeyStep Pro Setup:**
- Sequencer Track 1 → MIDI Channel 1 → Granulator Track 1
- Sequencer Track 2 → MIDI Channel 2 → Granulator Track 2
- Sequencer Track 3 → MIDI Channel 3 → Granulator Track 3
- Sequencer Track 4 → MIDI Channel 4 → Granulator Track 4

**Test Steps:**
```supercollider
// Load samples on all 4 tracks first
~trackManager.loadSample(0, "/path/to/sample1.wav");
~trackManager.loadSample(1, "/path/to/sample2.wav");
~trackManager.loadSample(2, "/path/to/sample3.wav");
~trackManager.loadSample(3, "/path/to/sample4.wav");

// Play notes on KeyStep Pro keyboard
// MIDI Channel 1 (Track 1 on KeyStep) = Granulator Track 1
```

**Note Number → Pitch Mapping:**
```
C3 (MIDI 60) = Normal pitch (1.0x)
C4 (MIDI 72) = Octave up (2.0x)
C2 (MIDI 48) = Octave down (0.5x)
```

**Velocity → Grain Density:**
```
Soft hit (vel 1-30)    = Sparse grains (subtle)
Medium hit (vel 50-80) = Normal density
Hard hit (vel 100-127) = Dense grains (aggressive)
```

**What to Listen For:**
- ✅ Higher notes = higher pitch
- ✅ Lower notes = lower pitch
- ✅ Soft hits = quieter, fewer grains
- ✅ Hard hits = louder, more grains
- ✅ Different tracks respond to different MIDI channels

**What to Watch For:**
- ❌ All notes same pitch
- ❌ Velocity has no effect
- ❌ Wrong track responds to wrong channel

---

### Test 3: MIDI Clock Sync (Tempo-Synced LFOs) ⏱️

**KeyStep Pro Setup:**
- Enable "MIDI Clock Out" in KeyStep settings
- Set tempo (e.g., 120 BPM)

**Test Steps:**
```supercollider
// Method 1: Via GUI (NEW!)
~modulationWindow.createWindow(0, 0);  // Track 1, Modulator 1

// In the modulation window:
// 1. Click "Tempo Sync" button to ON (turns cyan)
// 2. Select sync mode from dropdown:
//    - 1/4 = quarter notes
//    - 1/8 = eighth notes
//    - 1/16 = sixteenth notes
//    - 1/8t = eighth note triplets
//    - 1/16t = sixteenth note triplets
// 3. Route modulator to "Grain Size" or "Position"
// 4. Start clock on KeyStep Pro

// Method 2: Via code
var track = ~trackManager.getTrack(0);
track.modulators[0].set(\tempoSync, 1);    // Enable sync
track.modulators[0].set(\syncMode, 1);     // 1/8 note
~trackManager.routeModulator(0, 0, \grainSize, 0.01, 1.0);

// Start KeyStep clock and watch modulation sync!
```

**What to Listen For:**
- ✅ LFO rate locks to KeyStep tempo
- ✅ Changing KeyStep tempo changes LFO rate
- ✅ Different sync modes = different rates

**What to Watch For:**
- ❌ LFO drifts out of sync
- ❌ Tempo doesn't follow KeyStep changes
- ❌ Sync mode has no effect

---

### Test 4: Visual Feedback ✨

**Test Steps:**
```supercollider
// Open viewfinder
~viewfinder.createWindow(0);

// Play notes on KeyStep Pro
// You should see:
// - Green pulses on note attacks
// - Brighter pulses for harder velocity
// - Cyan overlays during sustained notes
```

**What to Watch For:**
- ✅ Pulses appear on note hits
- ✅ Pulse brightness matches velocity
- ✅ Visual feedback is immediate (< 20ms latency)

---

### Troubleshooting MIDI Issues

**Problem: No MIDI messages received**
```supercollider
// Re-initialize MIDI
MIDIClient.init;
MIDIIn.connectAll;

// List all sources
MIDIClient.sources.do({ arg src, i;
    "  [%] %".format(i, src.name).postln;
});

// If KeyStep not listed:
// 1. Check USB cable connection
// 2. Restart KeyStep Pro
// 3. Check macOS MIDI settings (Audio MIDI Setup app)
```

**Problem: Wrong CC numbers**
```supercollider
// Check what CCs your KeyStep is actually sending
MIDIFunc.cc({ arg val, num, chan, src;
    "CC#: % = %".format(num, val).postln;
}).permanent_(true);

// Turn encoders and note the CC numbers
// Update mappings if needed in core/midi-mapping.scd
```

**Problem: Tempo sync not working**
```supercollider
// Check if clock is being received
MIDIFunc.clock({ arg src;
    "Clock tick".postln;
}).permanent_(true);

// Start KeyStep clock - should print rapidly (24x per beat)
// If nothing: Enable "MIDI Clock Out" in KeyStep settings
```

**Problem: Note velocity not working**
```supercollider
// Check velocity values
MIDIFunc.noteOn({ arg vel, num, chan, src;
    "Velocity: %".format(vel).postln;
});

// Play soft → hard
// Should see values from 1-127
// If always 127: Check KeyStep velocity curve settings
```

---

### Advanced: Custom CC Mappings

Want to map different encoders to different parameters?

**Edit:** `core/midi-mapping.scd` (lines 36-42)
```supercollider
ccMappings: (
    74: (\filterFreq, 0),    // Encoder 1 → Track 1 Filter
    71: (\grainSize, 0),     // Encoder 2 → Track 1 Grain Size
    76: (\overlap, 0),       // Encoder 3 → Track 1 Density
    77: (\spectralMix, 0),   // Encoder 4 → Track 1 Spectral Mix
    78: (\filterDecay, 0)    // Encoder 5 → Track 1 Drive
),

// Change to any parameter:
// \position, \pitch, \pitchShift, \stereoSpread, \amp, \pan, etc.
```

---

## 🧪 Stress Tests

### Test 1: Rapid Mode Switching
```supercollider
// Rapidly switch between DIRECT and GRANULAR
fork {
    10.do {
        ~trackManager.setParam(0, \engineMode, 1);  // DIRECT
        0.5.wait;
        ~trackManager.setParam(0, \engineMode, 0);  // GRANULAR
        0.5.wait;
    };
};
```
**Expected:** No clicks, no audio dropouts, no crashes

### Test 2: Extreme Parameter Values
```supercollider
// Test edge cases
~trackManager.setParam(0, \timeStretch, 0.25);  // Very slow
~trackManager.setParam(0, \timeStretch, 4.0);   // Very fast
~trackManager.setParam(0, \rate, 0.25);         // Very low pitch
~trackManager.setParam(0, \rate, 4.0);          // Very high pitch
```
**Expected:** No crashes, no NaN errors, sound quality degradation is acceptable

### Test 3: Multiple Sample Loads
```supercollider
// Load 5 different samples rapidly
// Check for memory leaks, buffer issues
```
**Expected:** No memory growth, no buffer allocation errors

---

## 📊 Performance Benchmarks

### CPU Usage Targets (M4 Mac)
- **Idle (1 track, GRANULAR):** < 10%
- **DIRECT mode:** < 5%
- **4 tracks active:** < 30%
- **With master filter ON:** < 40%

### Known CPU Spikes (Acceptable)
- Initial grain buildup: Brief spike on playback start
- PitchShift activation: +15-20% when timeStretch != 1.0
- Master filter: +10-15% when enabled

---

## 🐛 Bug Hunting Checklist

While testing, watch for:
- [ ] Audio clicks/pops
- [ ] Stereo imbalance
- [ ] CPU spikes
- [ ] Memory leaks
- [ ] Parameter jumps (non-smooth changes)
- [ ] GUI freezes
- [ ] Unexpected silences
- [ ] "Too many grains!" warnings (reduce density/overlap)
- [ ] NaN/Inf errors in post window
- [ ] Buffer allocation failures

---

## 📝 Reporting Bugs

If you find issues, note:
1. **What you were doing** (exact steps)
2. **What happened** (actual behavior)
3. **What you expected** (expected behavior)
4. **Console output** (copy error messages)
5. **Parameter values** (what settings triggered it)

Example:
```
BUG: Audio burst when loading sample
Steps:
1. Loaded A3.wav on track 1
2. Immediately loaded B2.wav
3. Heard loud click/burst

Expected: Silent load
Console: (no errors)
Parameters: engineMode=0, amp=0.5
```

---

## ✅ Sign-Off Criteria

Phase 15.5 is ready for production when:
- ✅ All 6 main tests pass
- ✅ All 3 stress tests pass without crashes
- ✅ CPU usage within targets
- ✅ No critical bugs found
- ✅ Stereo balance confirmed perfect
- ✅ Sample loading completely silent

---

**Testing Duration:** Recommended 2-3 days casual use
**Focus Areas:** Direct mode, stereo balance, sample loading
**Low Priority:** Tempo sync (needs MIDI hardware to fully test)

Good luck! 🎛️
