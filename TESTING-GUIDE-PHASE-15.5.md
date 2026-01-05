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
