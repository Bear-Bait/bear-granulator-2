# KeyStep Pro Quick Reference Card (v2.4)

## Default Mappings

```
┌─────────────────────────────────────────────┐
│         ARTURIA KEYSTEP PRO                 │
│         MIDI Controller Setup               │
└─────────────────────────────────────────────┘

╔═══════════════════════════════════════════╗
║  KNOBS (Track 1)                          ║
╠═══════════════════════════════════════════╣
║  [1] CC 74  →  Position    (0.0 - 1.0)    ║
║  [2] CC 75  →  Pitch       (-24 to +24)   ║
║  [3] CC 76  →  Grain Size  (0.001 - 1.5)  ║
║  [4] CC 77  →  Overlap     (0.5 - 16)     ║
║  [5] CC 78  →  Amplitude   (0.0 - 1.0)    ║
║  [6] CC 79  →  LO-FI Switch (v2.4 NEW!)  ║
╚═══════════════════════════════════════════╝

╔═══════════════════════════════════════════╗
║  MOD STRIP                                ║
╠═══════════════════════════════════════════╣
║  CC 1  →  Entropy Gradient (v2.4 NEW!)   ║
╚═══════════════════════════════════════════╝

╔═══════════════════════════════════════════╗
║  KEYBOARD                                 ║
╠═══════════════════════════════════════════╣
║  Notes 48-83  →  Polyphonic Pitch         ║
║  Root: C3 (60)  =  0 semitones            ║
║  Note 84 (High C)  →  🚨 PANIC/RESET      ║
╚═══════════════════════════════════════════╝
```

## NEW v2.4 Features

### LO-FI Grain Switch (CC 79 / Knob 6)
6 density modes with colored arc indicator:
- **0:** HD (256) - Cyan
- **1:** Pro (128) - Yellow  
- **2:** Texture (64) - Orange
- **3:** Lo-Fi (28) - Red-orange
- **4:** Glitch (16) - Red
- **5:** Broken - Red with dropout

### Entropy Gradient (CC 1 / Mod Wheel)
Progressive disintegration for Tracks 1+2:
- **0:** Solid (pristine)
- **1:** Warm (slight degradation)
- **2:** Unstable (moderate chaos)
- **3:** Chaotic (heavy fragmentation)
- **4:** Atoms (complete disintegration)

### Modular MIDI Manager (NEW SYSTEM)
Dynamic CC patch bay replacing static mappings:

```supercollider
// Open GUI patcher
~midiManager.createPatcherWindow;

// Manual patching
~midiManager.patch(ccNum, target, param, min, max, warp);

// Examples
~midiManager.patch(74, 0, \grainSize, 0.001, 0.1);      // Track 1
~midiManager.patch(16, \multi, \overlap, 1, 128);        // Tracks 1+2
~midiManager.patch(18, \all, \filterFreq, 20, 20000, \exp); // All tracks
```

**Target Options:**
- `0, 1, 2, 3` - Single tracks
- `\multi` - Tracks 1+2 (stereo pair)
- `\all` - All 4 tracks

**GUI Features:**
- CC selector (0-127)
- Track/Target dropdown
- Parameter list with auto-ranging
- Warp selector (lin/exp)
- Live binding feedback

## MIDI Control Systems

### 1. Legacy Smart Remapping (Pre-v2.4)
```supercollider
~mapKnob.(CC, \PARAM, MIN, MAX, WARP, TRACK);
```

### 2. NEW Modular MIDI Manager (v2.4)
```supercollider
~midiManager.patch(CC, TARGET, PARAM, MIN, MAX, WARP);
~midiManager.createPatcherWindow; // GUI interface
```

**Migration Examples:**
```supercollider
// Old way (still works)
~mapKnob.(74, \spectralMix, 0, 1);

// New way (more powerful)
~midiManager.patch(74, 0, \spectralMix, 0, 1);
~midiManager.patch(74, \all, \spectralMix, 0, 1); // All tracks
```

## Common Parameters

| Category | Parameters |
|:---------|:-----------|
| **Grain** | `\position`, `\pitch`, `\grainSize`, `\overlap`, `\timeStretch` |
| **Spectral** | `\spectralMix`, `\spectralPitch`, `\spectralFreeze`, `\spectralWindowSize` |
| **Filter** | `\filterFreq`, `\filterRes`, `\filterDrive`, `\filterMorph` |
| **Space FX** | `\reverbMix`, `\delayMix`, `\shimmerMix`, `\reverbSize`, `\delayTime` |
| **Color FX** | `\saturationDrive`, `\crusherBits`, `\crusherRate`, `\compressorRatio` |
| **Mix** | `\amp`, `\pan`, `\stereoSpread` |
| **Quad** | `\quadX`, `\quadY` |

## Warp Types

- **`\lin`** - Linear scaling (best for mix amounts, pitch)
- **`\exp`** - Exponential scaling (best for frequency, time)

## Quick Actions

| Action | Command |
|:-------|:--------|
| **Open MIDI Patcher** | `~midiManager.createPatcherWindow;` |
| **Open Sync Manager** | `~syncManager.createSyncWindow;` |
| **Test MIDI** | `"tests/keystep-pro-test.scd".standardizePath.load;` |
| **Load Patch** | `"examples/keystep-performance-patches.scd".standardizePath.load;` |
| **Restore Defaults** | `~keyStepProMapping.loadDefaultMappings;` |
| **Reset All Tracks** | Press **Note 84** on keyboard |
| **Free MIDI** | `~keyStepProMapping.free;` |
| **Reinit MIDI** | `~keyStepProMapping.init(~trackManager);` |

## Sync Manager (v2.4 NEW)

### Tempo & Rhythm Control
```supercollider
~syncManager.setBPM(120);                    // Global tempo
~syncManager.setRhythmicDensity(0, \eighth); // Track 1 → 1/8 notes
~syncManager.playQuantized(0);               // Start on next bar
~syncManager.tapTempo;                       // Tap tempo
```

### Rhythmic Subdivisions
- `quarter`, `eighth`, `sixteenth`
- `eighthTriplet`, `sixteenthTriplet`
- `eighthDotted`, `sixteenthDotted`
- Custom values (e.g., `0.375` for 1/8T)

### Polyrhythm Presets
- **4:3:8:5** - Complex interlocking
- **16:12:8:6** - Standard orchestral
- **32:24:16:12** - High-resolution

## Performance Patches

Load pre-configured mappings from `examples/keystep-performance-patches.scd`:

1. **Granular Sculptor** - Classic grain control
2. **Spectral Morph** - FFT time-stretching
3. **Filter Sweep** - Resonant filter sculpting
4. **Space Designer** - Reverb/delay manipulation
5. **Quad Spatial** - 4-speaker positioning
6. **Destroyer** - Distortion/bit crushing
7. **Hybrid Engine** - 3-engine blending
8. **4-Track Control** - Multi-track from one keyboard
9. **Performance Mix** - Live mixing setup
10. **Custom Template** - Build your own!

## Troubleshooting

| Issue | Solution |
|:------|:---------|
| No MIDI messages | Check USB connection, verify `MIDIClient.sources` |
| Wrong parameters | `~keyStepProMapping.loadDefaultMappings;` |
| Notes not working | Check KeyStep is in keyboard mode, not sequencer |
| Visual feedback missing | Open viewfinder: `~viewfinder.createWindow(0);` |

## Emergency Reset

```supercollider
// Nuclear option: Free and reinitialize everything
~keyStepProMapping.free;
~keyStepProMapping.init(~trackManager);
```

---

**Full Documentation:** `KEYSTEP-PRO-QUICKSTART.md`
