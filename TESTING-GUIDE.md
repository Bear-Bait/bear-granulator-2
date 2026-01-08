# S-4 Rival Testing Guide
## v2.1 Engine - Ready for Testing

**Last Updated:** 2026-01-08
**Previous Guide:** Phase 15 (2026-01-04)

---

## 🎯 v2.1 DEPLOYMENT TESTING

### Quick Verification
Run the automated deployment test:
```supercollider
"tests/v2.1-deployment-test.scd".loadRelative;
```

This tests all v2.1 features in ~30 seconds:
- Click-free effect switching
- 64-step sequencer arrays
- Decoupled time/pitch
- grainMode parameter

**Expected Output:** "ALL TESTS PASSED" with no clicks/pops during effect switching.

---

### Feature-Specific Tests

#### 1. Click-Free Effect Switching (Issue #2 Fix)
**Test Script:** `tests/v2.1-deployment-test.scd` (included)

**Manual Test:**
```supercollider
x = Synth(\s4GrainEngine, [\bufnum, buf]);

// Should be SILENT (no clicks)
x.set(\filterOn, 1);  // Filter ON
x.set(\filterOn, 0);  // Filter OFF

x.set(\colorOn, 1);   // Color FX ON
x.set(\colorOn, 0);   // Color FX OFF

x.set(\spaceOn, 1);   // Space FX ON
x.set(\spaceOn, 0);   // Space FX OFF
```

**Success Criteria:**
- No audible clicks or pops when toggling effects
- Smooth crossfade over 50ms
- Works for filter, color, and space FX

---

#### 2. 64-Step Sequencer
**Test Script:** `tests/v2.1-sequencer-test.scd`
**Examples:** `examples/v2.1-sequencer-examples.scd`

**Manual Test:**
```supercollider
x = Synth(\s4GrainEngine, [\bufnum, buf]);

// Pentatonic arpeggio
var pentatonic = [0, 2, 4, 7, 9];
var pitchSeq = Array.fill(64, { pentatonic.choose });
x.set(\pitchSeq, pitchSeq);
x.set(\pitchJitter, 1);  // Turn on sequence
```

**Success Criteria:**
- Hear repeating melodic pattern (not random)
- Pattern loops every 64 grains
- posJitter/pitchJitter act as amplitude controls (0=off, 1=full)

**Key Difference from v2.0:**
- v2.0: Random LFNoise modulation (unpredictable)
- v2.1: Sequenced Demand UGens (musical, repeatable)

---

#### 3. Decoupled Time/Pitch
**Test Script:** `tests/v2.1-timestretch-test.scd`

**Manual Test:**
```supercollider
x = Synth(\s4GrainEngine, [\bufnum, buf]);

// Slow down time (pitch stays same)
x.set(\timeStretch, 0.5);  // Half speed

// Speed up time (pitch stays same)
x.set(\timeStretch, 2.0);  // Double speed

// Compare with legacy pitch parameter
x.set(\pitch, 12);  // Changes BOTH speed and pitch
```

**Success Criteria:**
- `timeStretch` changes grain rate (tempo) but NOT pitch
- `pitch` parameter still changes both speed and pitch (legacy)
- Can achieve "tape stop" effect (timeStretch → 0.25) without pitch drop

**Use Cases:**
- Tape stop effects (slow to freeze)
- Time-stretched ambient textures
- Independent tempo and pitch control

---

#### 4. Parameter Collision Fix (Issue #5)
**Fixed:** `mode` → `grainMode`

**Manual Test:**
```supercollider
x = Synth(\s4GrainEngine, [\bufnum, buf]);

// v2.1: Use grainMode parameter
x.set(\grainMode, 0);  // TAPE
x.set(\grainMode, 1);  // POLY
x.set(\grainMode, 2);  // LIVE

// v2.0: Would use 'mode' (conflicted with engineMode)
```

**Success Criteria:**
- No conflicts when switching between engineMode (granular/direct/spectral)
- All three material modes work correctly

---

### Edge Cases Test
**Test Script:** `tests/v2.1-edge-cases-test.scd`

Tests extreme parameter values:
- Minimum/maximum timeStretch (0.25 / 4.0)
- Maximum overlap (128 grains)
- Minimum grain size (0.001s = 1ms)
- Zero/maximum sequence values
- Rapid effect toggling (testing lag smoothing)
- Extreme pitch values (±24 semitones)

**Success Criteria:**
- No crashes or audio glitches
- No NaN/inf values in output
- Stable at parameter extremes

---

## 📋 REGRESSION TESTING

**Ensure v2.1 didn't break existing features:**

1. **Viewfinder waveform display** - Still works
2. **Spectral engine** - Still functional
3. **Modulation system** - Still routes correctly
4. **Preset save/load** - Still preserves state
5. **MIDI input** - Still triggers notes
6. **Recording** - Still captures audio
7. **Quad panner** - Still positions tracks

**Quick Regression Test:**
```supercollider
"main.scd".loadRelative;  // Reload everything
// Test each feature briefly
```

---

## 🔧 TROUBLESHOOTING v2.1

### Problem: Still hearing clicks when toggling effects
**Cause:** v2.0 engine still loaded
**Fix:** Reload main.scd to pick up v2.1 engine

### Problem: grainMode parameter not recognized
**Cause:** Old engine or track-manager still loaded
**Fix:**
```supercollider
s.freeAll;
"core/grain-engine.scd".loadRelative;
"core/track-manager.scd".loadRelative;
```

### Problem: 64-step sequences not working
**Cause:** Arrays not initialized in track params
**Fix:** Check track-manager.scd includes posSeq/pitchSeq in defaultParams

### Problem: timeStretch not affecting audio
**Cause:** Parameter not wired to engine
**Fix:** Verify viewfinder.scd line 1038 has timeStretch slider

---

## ✅ COMPLETION CHECKLIST

Before marking v2.1 as fully tested:

- [ ] Deployment test passes (no clicks)
- [ ] Sequencer test passes (melodic patterns)
- [ ] Time stretch test passes (tempo independent of pitch)
- [ ] Edge cases test passes (no crashes)
- [ ] Regression tests pass (old features work)
- [ ] GUI timeStretch slider functional
- [ ] Example presets load correctly
- [ ] No console errors during normal operation

---

## 📖 OLDER TESTING GUIDES (Pre-v2.1)

### Phase 15 Features - Previously Tested

Generated: 2026-01-04

---

## ✅ COMPLETED FEATURES

### 1. Crop Mode - FIXED
**Issue**: Inverted logic - small selections worked, large selections failed
**Fix**: Modified validation to skip 1% minimum check when in crop mode

**Test Procedure**:
1. Reload main.scd
2. Load a sample on Track 1 or record on Track 2
3. Open viewfinder
4. Click bright BLUE "CROP MODE" button
5. Select ANY SIZE region in the waveform
6. Click green "✂ APPLY CROP" button
7. **Expected**: Crop succeeds regardless of selection size

**Success Criteria**:
- Large selections (>50% of buffer) should crop successfully
- Small selections (<10% of buffer) should also crop successfully
- Console shows: "✓ Crop complete! New buffer: X frames (X seconds)"

---

### 2. Recording Waveform Display - FIXED
**Issue**: Callback passing entire recorder object instead of path
**Fix**: Callback now accesses tempFilePath directly from recorder

**Test Procedure**:
1. Open viewfinder for Track 2
2. Click REC button to start recording (make noise into input!)
3. Click REC again to stop after a few seconds
4. **Watch console** for boxed "RECORDING COMPLETE" message
5. Click "Refresh" button in viewfinder
6. **Expected**: Waveform displays the recorded audio

**Success Criteria**:
- Console shows clean file path (not entire Event object)
- Waveform appears after clicking Refresh
- Can play back the recording using grain/spectral engines

---

### 3. Direct Playback Mode - NEW! 🎉
**Feature**: Play samples without granulation using PlayBuf engine

**What It Does**:
- **GRANULAR mode** (default): Uses TGrains for grain synthesis
- **DIRECT mode**: Uses PlayBuf for straight sample playback (no grains!)
- Compatible with modulation system
- Shows dedicated playhead in viewfinder

**Test Procedure**:
1. Load a sample on Track 1
2. Open viewfinder for Track 1
3. Look for "ENGINE MODE:" toggle in Grain Controls section
4. Default should show cyan "GRANULAR" button
5. Click PLAY to hear granular version
6. Click "ENGINE MODE" button to switch to blue "DIRECT"
7. **Expected**: Hear clean sample playback without granulation

**Success Criteria**:
- GRANULAR mode: Grainy texture, grains visible/audible
- DIRECT mode: Clean playback, like a traditional sampler
- Position slider works in both modes
- Pitch parameter works in both modes
- Loop start/end works in both modes

---

## 📝 MATERIAL MODES EXPLAINED

**All three existing modes use granulation!**

| Mode | Name | Behavior | Use Case |
|------|------|----------|----------|
| 0 | TAPE | Loops through buffer with grains | Texture loops |
| 1 | POLY | Fixed position per grain | Percussive sounds |
| 2 | LIVE | Lookback from current position | Live processing |

**NEW Mode** (via ENGINE MODE toggle):
- **DIRECT**: No grains, uses PlayBuf for clean playback

---

## 🔧 HOW TO TEST DIRECT VS GRANULAR

**Good Test Sample**: Use a vocal or melodic sample with clear pitch

**GRANULAR Mode**:
1. Set engineMode to GRANULAR (cyan button)
2. Set grainSize to 0.01 (10ms)
3. Set overlap to 4
4. **Expected**: Stuttery, granular texture

**DIRECT Mode**:
1. Set engineMode to DIRECT (blue button)
2. **Expected**: Smooth, continuous playback
3. Try changing position slider → playback jumps to new position
4. Try changing pitch slider → pitch shifts via time-stretching

---

## 🎛️ MODULATION COMPATIBILITY

**Both modes support modulation!**

**Test Modulation in DIRECT Mode**:
1. Switch to DIRECT mode
2. Open modulation window (MOD button)
3. Create LFO modulator (Sine, 0.5 Hz)
4. Route to Pitch with range -12 to +12
5. **Expected**: Smooth pitch sweep (no zipper noise!)

---

## 🐛 KNOWN ISSUES (If Any)

### Recording Playhead (Red Line)
- **Status**: May not advance during recording
- **Workaround**: Recording still works, just no visual feedback
- **Priority**: Low (audio works correctly)

### Preset GUI
- **Status**: Not implemented yet
- **Workaround**: Use command line: `~presetSystem.savePreset("mySound")`
- **Priority**: Medium

---

## 📋 CONSOLE OUTPUT REFERENCE

**Good Messages**:
```
✓ Direct playback engine loaded
✓ Track 1: Switched to DIRECT playback
✓ Track 1: Switched to GRANULAR engine
✓ Crop complete! New buffer: 4146 frames (0.09 seconds)
═══════════════════════════════════════════
  RECORDING COMPLETE - Track 2
═══════════════════════════════════════════
  File: /path/to/file.wav
```

**Bad Messages** (report these):
```
Loop window too small (minimum 1%)  ← Should NOT appear in crop mode
ERROR: Message 'mapa' not understood
ERROR: Non Boolean in test
File: ('buffer': Buffer(1, 192000.0...  ← Event object instead of path
```

---

## 🧪 QUICK TEST CHECKLIST

- [ ] Load sample, open viewfinder
- [ ] Crop works with large selection
- [ ] Crop works with small selection
- [ ] Record audio, click Refresh, waveform appears
- [ ] Switch to DIRECT mode, hear clean playback
- [ ] Switch back to GRANULAR, hear grains
- [ ] Modulate pitch in DIRECT mode
- [ ] Position slider works in both modes

---

## 📞 REPORTING ISSUES

When reporting bugs, please include:
1. Console output (copy/paste full error)
2. Steps to reproduce
3. Expected vs actual behavior
4. Which track/engine mode you were using

**Happy Testing!** 🎹🎚️🎛️
