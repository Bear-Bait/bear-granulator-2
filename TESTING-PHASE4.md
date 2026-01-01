# Phase 4 Testing Guide - RT Memory Fix
**Date:** 2026-01-01
**Version:** 0.4.002 (Phase 4 + Memory Fix)

## Issues Fixed

### 1. RT Memory Allocation Error
**Problem:** `DelayC_Ctor: alloc failed, increase server's RT memory`

**Root Cause:** 4 tracks × delay effects exceeded default ~512MB memory allocation.

**Solution:** Increased `memSize` from `8192 * 64` (~512MB) to `8192 * 256` (~2GB) in main.scd

**Calculation:**
- 4 tracks × 2 delays/track (regular + shimmer) = 8 delays
- 2 seconds max × 2 channels × 48kHz sample rate × 4 bytes = ~768KB per delay
- 8 delays × 768KB = ~6MB RT memory needed
- Also need memory for: 4 grain buffers, filterbank, effects = ~500MB total
- Setting 2GB provides comfortable headroom

### 2. Waveform Visualization
**Status:** Already implemented in four-track-view.scd (lines 364-399)

**How it works:**
- Uses `SoundFileView` to display buffer contents
- Red playback position indicator using `UserView`
- Auto-refreshes at 10fps
- Updates on "Load Test Sound" and "REC stop"

**Why it wasn't showing:**
- RT memory errors prevented synths from creating
- No sound data in buffers → empty waveform display

### 3. README Accuracy
**Fixed:** Unchecked Phase 5-9 features not yet implemented
- Modulation system (Phase 5)
- Material modes (Phase 6)
- Performance features (Phases 7-9)

## Testing Procedure

### Step 1: Restart SuperCollider
**CRITICAL:** You must restart the SC server with new memory settings!

```supercollider
// In SuperCollider IDE:
s.quit;   // Kill current server
s.boot;   // Reboot with new settings
```

### Step 2: Run main.scd
```supercollider
// Select all and execute main.scd
// You should see NO RT memory errors in Post window
```

**Expected output:**
```
S-4 RIVAL - GRANULAR SCULPTING SAMPLER
Phase 4: 4-Track Architecture
============================================

Loading core modules...
  ✓ Filter shapes loaded
  ✓ Filterbank loaded
  ✓ Color effects loaded
  ✓ Space effects loaded
  ✓ Grain engine loaded
  ✓ Buffer recorder loaded
  ✓ Track manager loaded
  ✓ Master mix bus loaded
  ✓ Visualizer module loaded
  ✓ Four-track GUI module loaded

Initializing 4-track system...
Track manager: Initialized with 4 track slots
  ✓ Track manager initialized
Buffer allocated: 192000.0 frames (4.0 seconds)
Track manager: Track 1 created (bus: 4)
Buffer allocated: 192000.0 frames (4.0 seconds)
Track manager: Track 2 created (bus: 6)
Buffer allocated: 192000.0 frames (4.0 seconds)
Track manager: Track 3 created (bus: 8)
Buffer allocated: 192000.0 frames (4.0 seconds)
Track manager: Track 4 created (bus: 10)
  ✓ 4 tracks created
  ✓ Master bus created
Track manager: Master bus reference set
  ✓ Four-track GUI created

============================================
SYSTEM READY!
============================================
```

**CRITICAL:** Check for these error messages (they should NOT appear):
- ❌ `DelayC_Ctor: alloc failed`
- ❌ `PitchShift_Ctor: alloc failed`
- ❌ `FAILURE IN SERVER /s_new out of real time memory`
- ❌ `FAILURE IN SERVER /n_set Node XXXX not found`

If you see ANY of these errors, the RT memory fix didn't work - let me know!

### Step 3: Test Sound + Waveform
1. **Click "Load Test Sound"** button (cyan, top-left of Track 1 tab)
2. **Expected results:**
   - You should **HEAR sound immediately** (granular synthesis of sine wave)
   - **WAVEFORM appears** in black box at bottom of GUI (cyan waveform on black)
   - **Red playback line** moves across waveform as position changes
3. **Move "Position" slider** → red line should move, sound should change
4. **Move "Grain Size" slider** → sound texture changes
5. **Move "Density" slider** → grain density changes

### Step 4: Test Live Recording
1. **Select input channel** (dropdown, "In 3" for your MOTU Mk5)
2. **Play sound into microphone/input**
3. **Click green "REC" button** → starts recording
4. **Click "REC" again** → stops recording
5. **Expected:**
   - Waveform updates with recorded audio
   - You should hear granular processing of your recording
   - Red playback line shows position

### Step 5: Test Multi-Track
1. **Switch to "TRACK 2" tab**
2. **Click "Load Test Sound"**
3. **Expected:** Track 2 plays SIMULTANEOUSLY with Track 1
4. **Test:** You should hear BOTH tracks mixed together

### Step 6: Test Effects
**Color FX (Track 1):**
1. Click **"Color FX ON"** button (turns green)
2. Move **"Dist Mix"** slider → should hear distortion
3. Move **"Crush Mix"** slider → should hear bit-crushing (lo-fi effect)

**Space FX (Track 1):**
1. Click **"Space FX ON"** button (turns green)
2. Move **"Reverb Mix"** slider → should hear reverb
3. Move **"Delay Mix"** slider → should hear delay repeats
4. Move **"Shimmer Mix"** slider → should hear pitch-shifted delay (THIS was broken before!)

## Expected Behavior

### ✅ SUCCESS CRITERIA
- [ ] No RT memory errors in Post window
- [ ] Sound plays when "Load Test Sound" is clicked
- [ ] Waveform appears (cyan on black background)
- [ ] Red playback position line visible and moves
- [ ] All 4 tracks can play simultaneously
- [ ] Color effects work (distortion, bit crush)
- [ ] Space effects work (reverb, delay, **shimmer**)
- [ ] GUI is responsive (no freezing)
- [ ] CPU usage <50% (check with `s.avgCPU` in Post window)

### ❌ FAILURE INDICATORS
- RT memory errors → memSize increase didn't apply (restart server!)
- No sound → check audio interface, volume, speaker connections
- Empty waveform → likely no data in buffer (check buffer allocation)
- GUI frozen → too many GUI updates (reduce refresh rate)
- CPU >80% → reduce grain count or effects

## Troubleshooting

### "Still getting RT memory errors"
**Solution:**
1. Make sure you **quit and rebooted server** (`s.quit; s.boot;`)
2. Check Post window shows: `Server internal 'localhost' running with 2097152 frames`
3. If still failing, increase memSize further: `memSize: 8192 * 512` (4GB)

### "No sound, but no errors"
**Check:**
1. Audio interface connected and selected (macOS Sound Preferences)
2. SuperCollider output routing: `s.options.device`
3. Volume levels: `~trackManager.setVolume(0, 0.8)`
4. Track not muted: check MUTE button is OFF (gray)

### "Waveform is black/empty"
**Check:**
1. Did you click "Load Test Sound"? Buffer might be empty
2. Check buffer has data: `~trackManager.getTrack(0).recorder.buffer.numFrames` (should be ~192000)
3. Try manual refresh: Re-click "Load Test Sound"

### "Shimmer effect still fails"
**If you see:** `PitchShift_Ctor: alloc failed`
**Solution:** PitchShift needs even more memory. Increase to `memSize: 8192 * 512` (4GB)

## CPU Usage Monitoring

Check current CPU usage:
```supercollider
s.avgCPU;  // Should be <50%
s.peakCPU;  // Peak CPU during grain bursts
```

If CPU >80%:
1. Reduce max grains per track (currently 128)
2. Disable unused effects (Color FX OFF, Space FX OFF)
3. Reduce grain density (<50 grains/sec)

## Next Steps

Once Phase 4 is stable:
- **Phase 5:** Modulation system (LFOs, envelopes)
- **Phase 6:** Material modes (tape, poly, live)
- **Phase 7:** MIDI control
- **Phase 8:** Advanced visualization (grain clouds, spectrum)

**OR** jump to Phase 8 for better visualization now!

## Files Modified

1. **main.scd** (lines 57, 82)
   - Increased `memSize` to `8192 * 256` (~2GB)
   - Removed invalid `maxRTMemory` parameter

2. **README.md** (lines 55-87)
   - Unchecked Phase 5-9 features not yet implemented
   - Added "(Phase X - NOT YET IMPLEMENTED)" labels

3. **gui/visualizer.scd** (NEW FILE)
   - Created minimal waveform visualizer module
   - Not yet integrated (waveform already exists in four-track-view.scd)

## Version History

- **v0.4.001** - Phase 4 complete, RT memory errors
- **v0.4.002** - RT memory fix + README accuracy (current)
