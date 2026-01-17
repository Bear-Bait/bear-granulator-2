# BEARULATOR - Phase 1 Quick Start Guide

## What's Included in Phase 1

Phase 1 delivers the **Core Granular Engine** - the foundation of the BEARULATOR system.

### Features
- ✅ 128 grain granular synthesis engine
- ✅ 4-second rolling buffer (@ 48kHz)
- ✅ Live audio input recording
- ✅ Real-time grain parameter control
- ✅ 4 envelope shapes (Percussive, Sine, Triangle, Welch)
- ✅ Position and pitch jitter for organic textures
- ✅ Stereo spread control
- ✅ Simple GUI with essential controls

## Getting Started

### 1. Prerequisites
- SuperCollider 3.13 or higher installed
- Audio interface configured (recommended for low latency)
- Basic familiarity with SuperCollider

### 2. Boot SuperCollider Server

```supercollider
// In SuperCollider IDE, boot the server
s.boot;
```

Wait for the server to boot completely (you'll see "Server 'localhost' running" in the post window).

### 3. Run Main Script

```supercollider
// Open main.scd and execute the entire file
// Keyboard shortcut: Cmd+A (select all), then Cmd+Enter (execute)
```

Or use the File menu: `File > Open` → navigate to `main.scd` → select all code → execute.

### 4. What Happens

The system will:
1. Configure audio server settings (48kHz, proper buffer sizes)
2. Load all core modules (grain engine, buffer recorder, GUI)
3. Initialize a 4-second recording buffer
4. Create the grain synthesis engine
5. Open the control GUI

You should see output like:
```
============================================
BEARULATOR - GRANULAR SCULPTING SAMPLER
Phase 1: Core Granular Engine
============================================

Loading core modules...
  ✓ Grain engine loaded
  ✓ Buffer recorder loaded
  ✓ GUI module loaded

Initializing system...
  ✓ Buffer recorder initialized
  ✓ Grain synth created
  ✓ GUI created

SYSTEM READY!
```

## Using the Interface

### Recording Audio

1. **Connect Audio Source**: Plug a microphone, instrument, or audio source into your audio interface input 1
2. **Click "Start Recording"**: The green button will turn red and begin recording to the 4-second buffer
3. **Let it Record**: Record for a few seconds to fill the buffer with material
4. **Click "Stop Recording"**: The button returns to green

💡 **Tip**: The buffer loops continuously, so you can leave recording on for live processing.

### Controlling Grains

Once you have material in the buffer, adjust these parameters:

#### Grain Parameters
- **Grain Size** (10ms - 500ms): Duration of each grain. Smaller = glitchy, larger = smoother
- **Density** (1-200 grains/sec): How many grains trigger per second. Higher = denser texture
- **Position** (0-1): Where in the buffer to read grains. Scrub through your recording
- **Pitch** (-24 to +24 semitones): Transpose grains up or down

#### Randomization
- **Position Jitter** (0-1): Randomize grain position for less predictable textures
- **Pitch Jitter** (0-12 semitones): Randomize pitch per grain for shimmer effects

#### Spatial
- **Stereo Spread** (0-1): Width of the stereo field. 0 = mono, 1 = wide
- **Amplitude** (0-1): Output volume

#### Envelope Shape
Choose grain envelope shape from the dropdown:
- **Percussive**: Sharp attack, quick decay (good for rhythmic textures)
- **Sine**: Smooth and gentle (default, no clicks)
- **Triangle**: Linear envelope (bright, present)
- **Welch**: Parabolic curve (smooth, warm)

## Sound Design Tips

### Dense Clouds
```
Grain Size: 50-100ms
Density: 80-150 grains/sec
Position Jitter: 0.2-0.4
Envelope: Sine
```
Creates thick, ambient textures.

### Glitch Textures
```
Grain Size: 10-30ms
Density: 100-200 grains/sec
Pitch Jitter: 5-12 semitones
Envelope: Percussive
```
Glitchy, digital artifacts.

### Time Stretching
```
Grain Size: 80-150ms
Density: 20-40 grains/sec
Position: Slowly adjust 0→1
Position Jitter: 0
Envelope: Welch
```
Slow down audio without pitch change.

### Pitch Shifting
```
Grain Size: 100ms
Density: 40 grains/sec
Pitch: -12 or +12
Pitch Jitter: 0
```
Clean pitch transposition.

### Frozen Texture
```
Grain Size: 200-400ms
Density: 15-25 grains/sec
Position: Fixed at interesting point
Position Jitter: 0.05
Envelope: Sine
```
Hold and sustain a moment in time.

## Code Access

All system components are accessible via global variables:

```supercollider
// Access the grain synth directly
~grainSynth.set(\pitch, 7); // Set to perfect fifth

// Access the recorder
~recorder.clear; // Clear the buffer
~recorder.loadFile("path/to/audio.wav"); // Load a file

// Close the GUI
~gui.close;

// Get configuration
~config.basePath; // Project directory
```

## Cleanup

When you're done:

```supercollider
~cleanup.value; // Stops everything and frees resources
```

This will:
- Close the GUI
- Free the grain synth
- Free the recording buffer
- Clean up all resources

## Troubleshooting

### No Sound
- Check that the server is booted (`s.boot;`)
- Verify you've recorded audio into the buffer (or loaded a file)
- Check amplitude slider is not at 0
- Check your audio interface output settings

### Clicks or Pops
- Try the "Sine" envelope shape (smoothest)
- Reduce density if CPU is high
- Increase grain size for smoother results

### High CPU Usage
- Target is <15% CPU for Phase 1
- Check with `s.avgCPU;`
- Reduce density if needed
- Lower grain size creates more overhead

### Recording Not Working
- Verify audio interface input is connected
- Check SuperCollider audio device settings
- Make sure input channel is correct (default is input 0)

## Testing

Run the automated test suite:

```supercollider
// Load and run tests
"tests/grain-engine-test.scd".loadRelative;
```

This will verify:
- Server is running
- Buffers allocate correctly
- Grain engine boots
- Parameters respond
- CPU usage is acceptable
- All features work

## Next Steps (Phase 2)

Once you're comfortable with Phase 1, the next phase will add:
- 48-band morphing resonator filterbank
- LP/BP/HP filter type morphing
- Harmonic and inharmonic tuning
- Resonance and decay controls

## Files Reference

```
granular/
├── main.scd                      ← Start here
├── core/
│   ├── grain-engine.scd          ← Grain synthesis SynthDef
│   └── buffer-recorder.scd       ← Recording system
├── gui/
│   └── basic-controls.scd        ← GUI interface
└── tests/
    └── grain-engine-test.scd     ← Test suite
```

## Performance Targets (Phase 1)

- ✅ CPU usage: <15%
- ✅ Max grains: 128
- ✅ Buffer size: 4 seconds
- ✅ No audio dropouts
- ✅ Smooth parameter control

---

**Have fun exploring granular synthesis!** 🎛️🎵

For detailed technical documentation, see `README.md`.
