# Spectral Engine Test Procedure

## Issue Found
The spectral engine had two problems:
1. **Warp1 pointer was static** - It wasn't advancing through the buffer
2. **spectralMix defaults to 0** - Silent by default

## Fixes Applied
1. Added `Phasor.ar` to create moving playhead for Warp1
2. Integrated freeze control into Phasor rate

## Test Steps

### Step 1: Reload the System
```supercollider
// In SuperCollider:
~cleanup.value;  // Clean up old system
// Then reload main.scd (Cmd+A, Cmd+Enter on main.scd)
```

### Step 2: Run Diagnostic
```supercollider
// Open test-spectral.scd and run it (Cmd+Enter)
// Should show:
// ✓ SynthDef \s4SpectralEngine is loaded
// ✓ Spectral synth exists
// ⚠ WARNING: spectralMix is 0 (silent)
```

### Step 3: Quick Audio Test
```supercollider
// In Track 1 tab:
1. Click "Load Audio File" (load any audio)
2. Press green PLAY button
3. You should hear GRAIN engine (no spectral yet)

4. Move "Spectral Mix" slider to 0.5 (halfway)
   → You should NOW hear spectral layer!

5. Move "Window Size" slider to maximum (1.0)
   → Spectral smearing increases

6. Click "Freeze" button to ON
   → Spectral playback freezes (infinite sustain)
```

### Step 4: Verify CPU
- Check CPU meter in GUI
- With spectral at 50% mix, should see ~15-20% CPU on M4
- This is GOOD - leaves 75% headroom for 128-band resonator

## Expected Behavior

### With Spectral Mix = 0 (default):
- Silent spectral layer
- Only grain engine audible
- ~9% CPU (grain only)

### With Spectral Mix = 0.5:
- 50% grain, 50% spectral (summed)
- Spectral layer adds smooth "bed" under grains
- ~15-20% CPU

### With Spectral Mix = 1.0:
- 100% spectral, grain still playing
- Very dense, smeared texture
- ~20-25% CPU

## Troubleshooting

### "I don't hear spectral even with Mix at 1.0"
```supercollider
// Check if synth is running:
~trackManager.getTrack(0).spectralSynth.isRunning
// Should return: true

// If false, press PLAY button in GUI
```

### "I hear crackling"
```supercollider
// Increase buffer size:
s.options.blockSize = 128;
s.reboot;
```

### "CPU too high"
```supercollider
// Reduce overlaps:
// In GUI, move "Overlaps" slider to 2 or 1
```

## Success Criteria
✅ Spectral layer audible when Mix > 0
✅ Freeze button works (locks playback)
✅ Window Size affects spectral smearing
✅ CPU < 30% on M4

---

**If all tests pass, spectral engine is working!**
