# BEARULATOR v0.3.001 - Getting Started

## Welcome!

You've built a powerful granular synthesis workstation inspired by the $1000 Torso Electronics S-4 hardware.

## Quick Start (5 Minutes to Sound)

### Step 1: Boot SuperCollider Server
```supercollider
s.boot;
```
Wait for "Server 'localhost' running" message.

### Step 2: Run Main Script
1. Open `main.scd`
2. Select all: **Cmd+A**
3. Execute: **Cmd+Enter**
4. Wait for **"SYSTEM READY!"** message

### Step 3: Get Sound Immediately
**Click the cyan "Load Test Sound" button** in the top-left corner of the GUI.

**You should hear granular synthesis right away!**

### Step 4: Explore
Try moving these sliders:
- **Grain Size** - Changes texture (small = grainy, large = smooth)
- **Density** - How many grains per second
- **Position** - Where in the buffer to read
- **Pitch** - Transpose up/down

## What You Have

### Phase 1: Core Granular Engine
- 128 simultaneous grains
- 4-second rolling buffer
- Live input recording (MOTU Mk5 support)
- Multiple envelope shapes
- Stereo spread control

### Phase 2: 48-Band Morphing Resonator
- Morph between LP/BP/HP filters
- Harmonic & inharmonic tuning modes
- Band animation with rate control
- Resonance and decay controls
- Dry/wet mixing

### Phase 3: Effects Chain

**COLOR Effects:**
- Dual-band distortion (separate low/high processing)
- Bit crusher (lo-fi degradation)
- Compressor (dynamics control)
- Noise generator (white/pink/brown)

**SPACE Effects:**
- Reverb with freeze function
- Ping-pong delay with filtering
- Shimmer (pitch-shifted delay)

## Live Recording with MOTU Mk5

1. **Select input**: Use dropdown menu (In 1-8, default is In 3)
2. **Click REC**: Green button starts recording
3. **Play your instrument**: Recording fills the 4-second buffer
4. **Click STOP**: Red button stops recording
5. **Hear it granulated**: The grain engine plays continuously from buffer

You can overdub by clicking REC again while playing.

## The Interface

The wide horizontal layout has 4 main sections:

### Column 1: Recording + Grain
- Input selection and recording controls
- Load Test Sound button
- Core grain parameters
- Envelope selection

### Column 2: 48-Band Resonator
- Filter enable toggle
- Filter type morphing (LP → BP → HP)
- Resonance and decay
- Animation controls
- Harmonic/inharmonic tuning

### Column 3: Color Effects
- Color FX enable toggle
- Distortion (dual-band)
- Bit crusher
- Compressor
- Noise generator

### Column 4: Space Effects
- Space FX enable toggle
- Reverb (with freeze!)
- Delay (with ping-pong)
- Shimmer (pitch-shift delay)

### Bottom: Waveform Display
Shows your 4-second buffer with playback position cursor.

**Note:** The waveform display currently shows harmless Qt threading warnings - these don't affect sound quality.

## Recommended Starting Points

### 1. Classic Granular Texture
```
Grain Size: 0.05
Density: 80
Position: 0.5
Pos Jitter: 0.3
Pitch Jitter: 2
```

### 2. Smooth Clouds
```
Grain Size: 0.2
Density: 30
Envelope: Sine
Stereo Spread: 0.8
```

### 3. Resonant Textures
```
Enable Filter
Frequency: 200
Morph: 0.5 (bandpass)
Resonance: 0.7
Animate Amount: 0.5
Animate Rate: 1.0
```

### 4. Shimmer Pad
```
Enable Space FX
Reverb Mix: 0.5
Reverb Size: 0.9
Shimmer Mix: 0.6
Shimmer Pitch: +12
```

### 5. Lo-Fi Crush
```
Enable Color FX
Crush Rate: 2000
Crush Bits: 4
Crush Mix: 1.0
```

## Testing the System

### Run Automated Tests
```supercollider
// Load and run Phase 3 test suite
(thisProcess.nowExecutingPath.dirname +/+ "tests/phase3-test.scd").load;
```

This will automatically test all effects in sequence.

### Manual Testing
```supercollider
// Load quick sound test
(thisProcess.nowExecutingPath.dirname +/+ "tests/quick-sound-test.scd").load;
```

## Troubleshooting

### No Sound?
1. ✓ Check volume on your audio interface
2. ✓ Verify server is running: `s.serverRunning;`
3. ✓ Check synth is running: `~grainSynth.isRunning;`
4. ✓ Increase amplitude: `~grainSynth.set(\amp, 0.7);`
5. ✓ Load test sound: Click "Load Test Sound" button

### Buffer is Silent?
Click "Load Test Sound" or record from a live input.

### CPU Usage High?
Monitor in post window. Target: <15% for single track.

**Reduce CPU by:**
- Lower Density (fewer grains)
- Increase Grain Size (longer grains)
- Disable unused effects
- Turn off filter animation

### GUI Shows Qt Errors?
These are **harmless** threading warnings from the waveform display. Sound quality is not affected. You can ignore them.

### Recording Not Working?
1. Check input selection (dropdown menu)
2. Verify audio interface is connected
3. Check input gain on your interface
4. Make sure channel is not muted

## Performance Tips

**Optimize for Live Performance:**
1. Pre-load interesting sounds before performing
2. Keep Density < 100 for most uses
3. Disable effects when not needed (saves CPU)
4. Use Grain Size > 0.05 for smoother performance

**Creative Tips:**
1. **Freeze + Shimmer** = Infinite rising tones
2. **High Resonance + Animation** = Evolving spectral textures
3. **Short Grains + High Density** = Granular synthesis classic sound
4. **Long Grains + Low Density** = Tape loop feel
5. **Distortion + Bit Crush** = Extreme degradation

## Global Variables

Access these in the SuperCollider console:

```supercollider
~recorder      // Buffer recording system
~grainSynth    // Main grain synthesis engine
~gui           // GUI controller
~config        // System configuration
~filterShapes  // Filter morphing functions
~filterbank    // 48-band resonator functions
~cleanup       // Cleanup function
```

## Manual Control Examples

```supercollider
// Increase volume
~grainSynth.set(\amp, 0.8);

// Smaller grains
~grainSynth.set(\grainSize, 0.03);

// More density
~grainSynth.set(\density, 100);

// Pitch up an octave
~grainSynth.set(\pitch, 12);

// Enable filter with bandpass
~grainSynth.set(\filterOn, 1, \filterMorph, 0.5, \filterRes, 0.7);

// Add reverb
~grainSynth.set(\spaceOn, 1, \reverbMix, 0.6, \reverbSize, 0.9);

// Freeze reverb
~grainSynth.set(\reverbFreeze, 1);
```

## Cleanup

When you're done:

```supercollider
~cleanup.value;  // Stops everything and frees resources
```

Or close the GUI window (cleanup happens automatically).

## Next Steps

### Phase 4 (Coming Soon)
- 4-track architecture
- Sample management system
- Track muting/soloing
- Independent effect chains per track

### Future Enhancements
- Preset saving/loading
- MIDI control mapping
- More filter types
- Envelope editor
- XY pad for parameter control

## Documentation

- **SOUND-TEST-GUIDE.md** - Detailed testing instructions
- **README.md** - Full project overview
- **tests/phase3-test.scd** - Automated test suite
- **tests/quick-sound-test.scd** - Quick sound verification

## Support

For issues or questions, see:
- Check the troubleshooting section above
- Review SOUND-TEST-GUIDE.md for detailed diagnostics
- Examine console output for error messages

## Enjoy!

You've built a powerful granular synthesis instrument. Experiment, explore, and create amazing textures!

**Remember**: Click "Load Test Sound" to hear it immediately!
