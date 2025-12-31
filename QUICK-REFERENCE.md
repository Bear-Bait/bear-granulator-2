# S-4 Rival Quick Reference Card
## Phase 1 + Phase 2: Granular Engine + Morphing Resonator

## 🚀 Start System

```supercollider
s.boot;                              // 1. Boot server
"main.scd".load;                     // 2. Load main script (or open and execute)
```

## 🎛️ Global Variables

```supercollider
~grainSynth    // The grain synthesis engine
~recorder      // Buffer recording system
~gui           // GUI controller
~config        // System configuration
~filterShapes  // Filter morphing functions (Phase 2)
~filterbank    // 48-band resonator functions (Phase 2)
~cleanup       // Cleanup function
```

## 🎚️ Direct Control (bypassing GUI)

```supercollider
// Grain parameters
~grainSynth.set(\grainSize, 0.05);      // 10ms-500ms
~grainSynth.set(\density, 80);          // 1-200 grains/sec
~grainSynth.set(\position, 0.75);       // 0-1
~grainSynth.set(\pitch, 12);            // -24 to +24 semitones

// Randomization
~grainSynth.set(\posJitter, 0.3);       // 0-1
~grainSynth.set(\pitchJitter, 5);       // 0-12 semitones

// Spatial
~grainSynth.set(\stereoSpread, 0.8);    // 0-1
~grainSynth.set(\amp, 0.6);             // 0-1
~grainSynth.set(\pan, 0.5);             // -1 to 1

// Envelope (0=Perc, 1=Sine, 2=Triangle, 3=Welch)
~grainSynth.set(\envType, 1);

// === PHASE 2: FILTER PARAMETERS ===
// Filter enable/disable
~grainSynth.set(\filterOn, 1);              // 0=off, 1=on

// Filter frequency & morphing
~grainSynth.set(\filterFreq, 200);          // 20-2000 Hz
~grainSynth.set(\filterMorph, 0.5);         // 0=LP, 0.5=BP, 1.0=HP

// Filter character
~grainSynth.set(\filterRes, 0.7);           // Resonance 0-1
~grainSynth.set(\filterDecay, 0.6);         // Decay 0-1
~grainSynth.set(\filterMix, 0.8);           // Dry/wet 0-1

// Animation
~grainSynth.set(\filterAnimate, 0.5);       // Amount 0-1
~grainSynth.set(\filterAnimRate, 0.5);      // Rate 0.01-10 Hz

// Tuning
~grainSynth.set(\filterTuning, 0);          // 0=harmonic, 1=inharmonic
~grainSynth.set(\filterSpread, 1.5);        // Inharmonic spread 1.0-2.0
```

## 📼 Recording

```supercollider
// Recording control
~recorder.startRecording(0, overdub: false);  // Start (input 0)
~recorder.stopRecording;                      // Stop
~recorder.clear;                              // Clear buffer

// Load audio file
~recorder.loadFile("~/Music/sample.wav");
```

## 🧪 Test Samples

```supercollider
"tests/create-test-samples.scd".loadRelative;

~createTestSamples.value.drone;       // Harmonic drone
~createTestSamples.value.melody;      // Melodic sequence
~createTestSamples.value.noise;       // Noise sweep
~createTestSamples.value.percussion;  // Percussive hits
~createTestSamples.value.complex;     // Complex texture
```

## 🔬 Testing

```supercollider
// Phase 1 tests
"tests/grain-engine-test.scd".loadRelative;   // Grain engine tests

// Phase 2 tests
"tests/filterbank-test.scd".loadRelative;     // Filterbank tests

// System monitoring
s.avgCPU;                                     // Check CPU usage
s.meter;                                      // Open meters
s.scope;                                      // Open scope
s.freqscope;                                  // Frequency scope (great for filters!)
```

## 🎨 Sound Design Presets

### Dense Cloud
```supercollider
~grainSynth.set(\grainSize, 0.08, \density, 100, \posJitter, 0.3, \envType, 1);
```

### Glitch
```supercollider
~grainSynth.set(\grainSize, 0.015, \density, 150, \pitchJitter, 8, \envType, 0);
```

### Time Stretch
```supercollider
~grainSynth.set(\grainSize, 0.12, \density, 35, \posJitter, 0.05, \envType, 3);
// Slowly move position slider 0→1
```

### Pitch Shift
```supercollider
~grainSynth.set(\grainSize, 0.1, \density, 40, \pitch, -12, \envType, 1);
```

### Freeze
```supercollider
~grainSynth.set(\grainSize, 0.3, \density, 20, \position, 0.5, \posJitter, 0.05);
```

### Shimmer
```supercollider
~grainSynth.set(\grainSize, 0.15, \density, 50, \pitchJitter, 7, \envType, 1);
```

## 🎨 Phase 2: Resonator Presets

### Harmonic Cloud
```supercollider
~grainSynth.set(\filterOn, 1, \filterFreq, 150, \filterMorph, 0.5, \filterRes, 0.7,
    \filterTuning, 0, \filterAnimate, 0.4, \filterAnimRate, 0.3, \filterMix, 0.9);
```

### Metallic Texture
```supercollider
~grainSynth.set(\filterOn, 1, \filterFreq, 200, \filterMorph, 0.5, \filterRes, 0.8,
    \filterTuning, 1, \filterSpread, 1.7, \filterDecay, 0.8, \filterMix, 1.0);
```

### Resonant Lowpass
```supercollider
~grainSynth.set(\filterOn, 1, \filterFreq, 400, \filterMorph, 0.0, \filterRes, 0.5,
    \filterMix, 1.0);
```

### Spectral Sweep
```supercollider
~grainSynth.set(\filterOn, 1, \filterFreq, 100, \filterMorph, 0.5, \filterRes, 0.6,
    \filterAnimate, 0.9, \filterAnimRate, 0.5, \filterMix, 0.8);
```

### Formant-Like
```supercollider
~grainSynth.set(\filterOn, 1, \filterFreq, 300, \filterMorph, 0.5, \filterRes, 0.75,
    \filterDecay, 0.3, \filterAnimate, 0, \filterMix, 0.9);
```

## 🧹 Cleanup

```supercollider
~cleanup.value;              // Clean shutdown
// OR manually:
~gui.close;
~grainSynth.free;
~recorder.free;
```

## 🆘 Troubleshooting

```supercollider
// Panic! Stop all sound
s.freeAll;

// Restart system
~cleanup.value;
"main.scd".load;

// Check what's running
s.queryAllNodes;

// Check buffer status
~recorder.buffer.query;

// CPU too high?
s.avgCPU;  // Should be <15%
// If high: reduce density, increase grain size
```

## 📊 System Info

```supercollider
~config.postln;              // View configuration
s.options.postln;            // Server options
s.sampleRate;                // Check sample rate (should be 48000)
s.numOutputBusChannels;      // Output channels
s.numInputBusChannels;       // Input channels
```

## ⌨️ Useful SuperCollider Commands

```supercollider
s.boot;                      // Boot server
s.quit;                      // Quit server
s.reboot;                    // Reboot server
s.meter;                     // Level meters
s.scope;                     // Oscilloscope
s.freqscope;                 // Frequency scope
s.plotTree;                  // Node tree
s.dumpOSC(1);                // Show OSC messages
s.dumpOSC(0);                // Stop showing OSC
```

## 📁 File Locations

```
main.scd                              ← Start here
core/grain-engine.scd                 ← SynthDef
core/buffer-recorder.scd              ← Recording system
gui/basic-controls.scd                ← GUI
tests/grain-engine-test.scd           ← Tests
tests/create-test-samples.scd         ← Test samples
docs/phase1-quickstart.md             ← Full documentation
PHASE1-COMPLETE.md                    ← Phase 1 summary
```

## 🎯 Performance Targets

**Phase 1 (Grain Engine):**
- CPU: <15% (typically 8-12%)

**Phase 2 (+ Resonator):**
- CPU: <25% total (typically 13-20%)
- Filter CPU increase: ~5-8%

**General:**
- Max grains: 128
- Buffer: 4 seconds
- Sample rate: 48kHz
- Latency: <10ms
- Filter bands: 48

## 💡 Tips

**Phase 1 (Grains):**
1. **Start simple**: Begin with default settings, adjust one parameter at a time
2. **Envelope matters**: Sine = smooth, Percussive = punchy
3. **Jitter = organic**: Add small amounts for natural movement
4. **Position scrubbing**: Slowly move position for time-stretching effects
5. **Density vs Size**: Inverse relationship - small grains need high density
6. **CPU management**: Lower density or increase grain size if CPU spikes
7. **Stereo spread**: 0 = mono center, 1 = wide stereo field
8. **Recording tip**: Let buffer fill completely (4 seconds) before granulating

**Phase 2 (Filter):**
9. **Morph exploration**: 0.0=LP (bass), 0.5=BP (resonant), 1.0=HP (bright)
10. **Resonance sweet spot**: 0.5-0.8 for pronounced but stable resonance
11. **Animation adds life**: Even small amounts (0.2-0.4) create movement
12. **Harmonic = musical**: Use for melodic/tonal results
13. **Inharmonic = metallic**: Use for bells, gongs, unusual timbres
14. **Low frequencies work best**: Try fundamental 100-300 Hz
15. **Mix for subtlety**: Don't always go full wet - try 0.6-0.8
16. **Frequency scope**: Use s.freqscope to see what the filter is doing

---

**Need help?**
- Phase 1 guide: `docs/phase1-quickstart.md`
- Phase 2 summary: `PHASE2-COMPLETE.md`
- Quick reference: This file!

**Found a bug?**
- Run `tests/grain-engine-test.scd` for Phase 1
- Run `tests/filterbank-test.scd` for Phase 2
