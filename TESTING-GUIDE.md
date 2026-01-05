# S-4 Rival Testing Guide
## Phase 15 Features - Ready for Testing

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
