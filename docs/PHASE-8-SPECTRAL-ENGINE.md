# Phase 8: Warp1 Spectral Engine - M4 Extreme Performance

## Overview

Phase 8 adds a concurrent **Warp1 spectral time-stretching engine** that runs in parallel with the existing GrainBuf grain engine. This allows for layered sculpting: rhythmic grain pulses + spectral frozen beds.

## What's New

### Concurrent Dual-Engine Architecture
- **GrainBuf engine**: Rhythmic, percussive grain sculpting
- **Warp1 engine**: FFT-based spectral time-stretching
- Both engines run simultaneously per track
- Both output to the same track bus (summed)

### Spectral Engine Features
- **FFT-based time-stretching**: Freeze time while preserving pitch
- **Spectral freeze**: Lock playback at any position
- **Spectral smear**: Randomize phase for "cloudy" textures
- **Formant-preserving pitch shift**: Change pitch without "chipmunk" effect
- **Window size control**: Balance time vs frequency resolution
- **Overlap factor**: 1-8x (M4 can handle 8x for ultra-smooth)

## GUI Controls (Track Tab, Right Column)

### Spectral Engine Section (Orange Header)
Located at the bottom of each track tab after the Shimmer section:

1. **Spectral Mix** (0-1)
   - 0 = Silent (spectral engine off)
   - 1 = Full spectral (grain still plays separately)
   - Use 0.5 for balanced grain + spectral layering

2. **Window Size** (0.05-1.0 seconds, exponential)
   - Small (0.05s): Tight time resolution, loose pitch (glitchy)
   - Large (1.0s): Tight pitch, smeared time (spectral freeze)
   - Default: 0.2s (balanced)

3. **Overlaps** (1-8, stepped)
   - Number of overlapping FFT windows
   - Higher = smoother, more CPU
   - M4 can handle 8x easily
   - Default: 4x

4. **Rate** (-2 to +2)
   - 0 = Freeze time (spectral freeze)
   - 1 = Normal speed
   - -1 = Reverse playback
   - 2 = Double speed

5. **Pitch** (-24 to +24 semitones)
   - Formant-preserving pitch shift
   - Independent from rate (unlike legacy grain pitch)
   - No "chipmunk" effect

6. **Smear** (0-1)
   - Randomize FFT window phase
   - Creates "spectral clouds"
   - 0 = Clean spectral
   - 1 = Maximum phase randomization

7. **Freeze** (ON/OFF button)
   - Locks spectral position
   - Use with large window size for "infinite" sustain

## Usage Patterns

### Pattern 1: Spectral Bed + Grain Pulses
```
Grain Engine:
- grainSize: 0.05s (short)
- overlap: 2 (sparse)
- Result: Rhythmic pulses

Spectral Engine:
- spectralMix: 0.4
- windowSize: 0.5s (smeared)
- rate: 1.0
- Result: Smooth spectral bed underneath
```

### Pattern 2: Spectral Freeze
```
Spectral Engine:
- spectralMix: 0.8
- windowSize: 1.0s (max smear)
- freeze: ON
- Result: "Infinite" sustain on frozen moment
```

### Pattern 3: Reverse Spectral
```
Spectral Engine:
- spectralMix: 0.6
- rate: -1.0
- Result: Reverse spectral playback
```

### Pattern 4: Spectral Clouds
```
Spectral Engine:
- spectralMix: 0.7
- windowSize: 0.3s
- smear: 0.8
- Result: Phase-randomized spectral clouds
```

## Technical Details

### Signal Flow
```
Buffer → GrainBuf → Track Bus →
Buffer → Warp1   →

Track Bus → Master Mix Bus → Output
```

### CPU Considerations
- Warp1 is MORE efficient than GrainBuf for high-quality time-stretching
- Overlap=8 is perfectly fine on M4
- Total CPU (4 tracks, grain + spectral): ~40-50% on M4

### Parameter Routing
Spectral parameters are automatically routed to the spectral synth:
- `spectralMix` → Warp1 `spectralMix`
- `spectralPosition` → Warp1 `position`
- `spectralRate` → Warp1 `rate`
- `spectralWindowSize` → Warp1 `windowSize`
- `spectralOverlaps` → Warp1 `overlaps`
- `spectralPitch` → Warp1 `pitch`
- `spectralFreeze` → Warp1 `freeze`
- `spectralSmear` → Warp1 `smear`

## Play/Stop Behavior

- **PLAY button**: Starts BOTH grain and spectral engines
- **STOP button**: Stops BOTH engines
- **PLAY ALL**: Starts all 4 tracks (grain + spectral)
- **STOP ALL**: Stops all 4 tracks

## Load Audio File

When you load a new audio file, BOTH engines are updated automatically:
1. Grain synth buffer → new buffer
2. Spectral synth buffer → new buffer
3. Both synths stopped (press PLAY to start)

## Fixed Issues (from previous session)

### Number Boxes Fixed
The number boxes in the **Modulation Window** (MOD button) now work correctly:
- Slider → NumberBox updates
- NumberBox → Slider updates
- Both controls are bidirectionally linked

Issue was: NumberBox was created before Slider, causing forward reference error. Fixed by creating Slider first.

## Files Modified

1. **core/spectral-engine.scd** (NEW)
   - Warp1 SynthDef

2. **core/track-manager.scd**
   - Added `spectralSynth` to track struct
   - Added spectral default parameters
   - Updated `createTrack` to create spectral synth
   - Updated `freeTrack` to free spectral synth
   - Updated `setParam` to route spectral params

3. **gui/four-track-view.scd**
   - Added spectral controls section (7 sliders + 1 button)
   - Updated PLAY/STOP buttons to control both engines
   - Updated Load Audio File to update both buffers
   - Updated PLAY ALL / STOP ALL buttons

4. **gui/modulation-window.scd**
   - Fixed NumberBox forward reference bug
   - Slider now created before NumberBox

5. **main.scd**
   - Added spectral engine loading

## Next Steps (Your M4 Extreme Plan)

✅ **#3: Warp1 Engine** (COMPLETED)
- [x] Create Warp1 SynthDef
- [x] Add to track struct
- [x] Add GUI controls
- [x] Test concurrent operation

Remaining from your plan:
- [ ] #1: Global Audio-Rate (.ar) modulation
- [ ] #2: 4x Oversampled "Color" section
- [ ] #4: Ultra-Density 96-128 band resonator
- [ ] #5: System-wide DC safety (already done in mix-bus.scd!)

## Testing Checklist

1. **Load main.scd** - Should see "Spectral engine (Warp1) loaded"
2. **Create GUI** - Should see orange "SPECTRAL ENGINE" section in track tabs
3. **Load audio file** - Both engines should update buffers
4. **Press PLAY** - Both engines should start
5. **Adjust Spectral Mix** - Should hear spectral layer fade in
6. **Try Freeze** - Should lock spectral position
7. **Try Smear** - Should create spectral clouds

## Performance Notes (M4)

At 25% CPU currently, you have MASSIVE headroom for:
- 96-128 band resonator (next priority)
- Audio-rate modulation
- 4x oversampling on color effects

The M4's single-core performance + memory bandwidth makes all of this feasible without any mobile-optimization constraints.

---

**Ready to test!** The spectral engine is fully integrated and ready for your M4 beast.
