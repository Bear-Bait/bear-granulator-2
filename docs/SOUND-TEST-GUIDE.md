# BEARULATOR: Sound Test Guide

## Getting Sound Working - Step by Step

### Step 1: Boot the Server
```supercollider
s.boot;
```
Wait for server to fully boot before proceeding.

### Step 2: Run Main Script
1. Open `main.scd`
2. Select all (Cmd+A)
3. Execute (Cmd+Enter)
4. Wait for "SYSTEM READY!" message

### Step 3: Load Test Sound (EASIEST WAY)
Click the cyan **"Load Test Sound"** button at the top-left of the GUI.

**You should immediately hear granular synthesis!**

If you don't hear sound, check:
- ✓ Volume is up on your audio interface
- ✓ Amplitude slider in GUI is > 0 (default is 0.5)
- ✓ Output routing is correct (default: outputs 0-1)

### Step 4: Adjust Grain Parameters
Try moving these sliders while sound is playing:
- **Grain Size**: 0.01-0.5 seconds (smaller = more textural)
- **Density**: 1-200 grains/sec (higher = denser sound)
- **Position**: 0-1 (where in buffer to read grains)
- **Pitch**: -24 to +24 semitones
- **Pos Jitter**: 0-1 (randomize grain positions)
- **Pitch Jitter**: 0-12 semitones (randomize grain pitches)
- **Stereo Spread**: 0-1 (stereo width)

## Alternative: Run Quick Test Script

If the GUI button doesn't work, run this:

```supercollider
// Load: tests/quick-sound-test.scd
(
"=== QUICK SOUND TEST ===".postln;

fork {
	var tempBuf = Buffer.alloc(s, s.sampleRate * 4, 1);
	tempBuf.sine1([1.0, 0.5, 0.3, 0.2, 0.15, 0.1], true, true, true);
	0.3.wait;
	tempBuf.copyData(~recorder.buffer);
	0.2.wait;
	tempBuf.free;
	"✓ Test sound loaded! You should hear granular synthesis now!".postln;
};
)
```

## Testing Live Recording (MOTU Mk5)

### Step 1: Select Input
1. Choose input channel from dropdown (In 1-8)
2. Default is **In 3** (your preferred input)

### Step 2: Start Recording
1. Click green **"REC"** button
2. Play sound into your selected input
3. Recording fills a 4-second rolling buffer
4. Click **"STOP"** when done

### Step 3: Listen
The grain engine continuously plays from the buffer, so you'll hear your recorded sound granulated in real-time!

## Testing Phase 2: 48-Band Resonator

1. Enable **"Filter ON"** button (turns green)
2. Adjust these parameters:
   - **Frequency**: 20-2000 Hz (fundamental frequency)
   - **Morph**: 0=Lowpass, 0.5=Bandpass, 1.0=Highpass
   - **Resonance**: 0-1 (filter sharpness)
   - **Decay**: 0-1 (high band rolloff)
   - **Mix**: 0=dry, 1=wet
3. Try animation:
   - **Animate Amount**: 0-1
   - **Animate Rate**: 0.01-10 Hz

## Testing Phase 3: Color Effects

1. Enable **"Color FX ON"** button
2. Try each effect:

### Distortion
- **Crossover Freq**: 100-2000 Hz
- **Low Drive**: 1-10
- **High Drive**: 1-10
- **Dist Mix**: 0-1

### Bit Crusher
- **Sample Rate**: 100-48000 Hz (lower = more lo-fi)
- **Bit Depth**: 1-16 bits (lower = more crunch)
- **Crush Mix**: 0-1

### Noise
- **Noise Amount**: 0-1
- **Noise Type**: White/Pink/Brown

## Testing Phase 3: Space Effects

1. Enable **"Space FX ON"** button
2. Try each effect:

### Reverb
- **Size**: 0-1 (room size)
- **Damping**: 0-1 (high frequency absorption)
- **Reverb Mix**: 0-1
- **Freeze**: Click to freeze reverb tail!

### Delay
- **Time**: 0.01-2 seconds
- **Feedback**: 0-0.95
- **Filter Freq**: 200-10000 Hz (feedback filtering)
- **Delay Mix**: 0-1
- **Ping-Pong**: ON = stereo bounce

### Shimmer (Pitch-Shifted Delay)
- **Shimmer Time**: 0.1-2 seconds
- **Shimmer FB**: 0-0.9
- **Pitch**: 0-24 semitones (try +7 or +12)
- **Shimmer Mix**: 0-1

## Advanced Testing: Run Phase 3 Test Suite

```supercollider
// Load: tests/phase3-test.scd
// This will automatically test all effects in sequence
```

## Troubleshooting

### No Sound?
1. Check server is running: `s.serverRunning; // should return true`
2. Check synth is running: `~grainSynth.isRunning; // should return true`
3. Check amplitude: `~grainSynth.set(\amp, 0.7);`
4. Check buffer: `~recorder.buffer.postln; // should not be nil`
5. Manually set parameters:
   ```supercollider
   ~grainSynth.set(\density, 50);
   ~grainSynth.set(\grainSize, 0.1);
   ~grainSynth.set(\position, 0.5);
   ```

### Qt Threading Errors (Waveform Display)?
These are **harmless** - the waveform display has threading issues but doesn't affect sound.
You can safely ignore messages like:
```
ERROR: Qt: You can not use this Qt functionality in the current thread...
```

### CPU Usage Too High?
Monitor in post window. Target: **<15% for single track**

If CPU > 15%:
- Reduce **Density** (fewer grains/sec)
- Increase **Grain Size** (longer grains)
- Disable effects when not in use
- Turn off filter animation

## Manual Sound Test (No Buffer)

If you want to test the synth directly without the recorder:

```supercollider
(
// Create a test buffer
b = Buffer.alloc(s, s.sampleRate * 4, 1);
b.sine1([1, 0.5, 0.25, 0.15], true, true, true);

// Create a grain synth
x = Synth(\s4GrainEngine, [
	\bufnum, b,
	\grainSize, 0.1,
	\density, 40,
	\amp, 0.6
]);
)

// Adjust parameters
x.set(\pitch, 7);
x.set(\density, 80);
x.set(\posJitter, 0.3);

// Enable filter
x.set(\filterOn, 1, \filterFreq, 300, \filterMorph, 0.5, \filterRes, 0.7);

// Enable reverb
x.set(\spaceOn, 1, \reverbMix, 0.5, \reverbSize, 0.8);

// Cleanup
x.free; b.free;
```

## Success Criteria

You know it's working when:
- ✓ You hear continuous granular synthesis after loading test sound
- ✓ Moving sliders changes the sound in real-time
- ✓ Filter creates resonant tones
- ✓ Effects add color and space
- ✓ CPU usage stays < 15%
- ✓ No audio dropouts or glitches

## Next Steps

Once sound is confirmed working:
- **Phase 4**: 4-track architecture with sample management
- Add preset saving/loading
- Add MIDI control mapping
- Performance optimizations
