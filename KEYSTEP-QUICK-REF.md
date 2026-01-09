# KeyStep Pro Quick Reference Card

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
╚═══════════════════════════════════════════╝

╔═══════════════════════════════════════════╗
║  MOD STRIP                                ║
╠═══════════════════════════════════════════╣
║  CC 1  →  Position Jitter  (0.0 - 1.0)    ║
╚═══════════════════════════════════════════╝

╔═══════════════════════════════════════════╗
║  KEYBOARD                                 ║
╠═══════════════════════════════════════════╣
║  Notes 48-83  →  Polyphonic Pitch         ║
║  Root: C3 (60)  =  0 semitones            ║
║  Note 84 (High C)  →  🚨 PANIC/RESET      ║
╚═══════════════════════════════════════════╝
```

## Smart Remapping

```supercollider
~mapKnob.(CC, \PARAM, MIN, MAX, WARP, TRACK);
```

**Examples:**
```supercollider
~mapKnob.(74, \spectralMix, 0, 1);         // Knob 1 → Spectral Mix
~mapKnob.(76, \filterFreq, 0, 1, \exp);    // Knob 3 → Filter (exponential)
~mapKnob.(77, \reverbMix, 0, 1, \lin, 1);  // Knob 4 → Track 2 Reverb
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
| **Test MIDI** | `"tests/keystep-pro-test.scd".standardizePath.load;` |
| **Load Patch** | `"examples/keystep-performance-patches.scd".standardizePath.load;` |
| **Restore Defaults** | `~keyStepProMapping.loadDefaultMappings;` |
| **Reset All Tracks** | Press **Note 84** on keyboard |
| **Free MIDI** | `~keyStepProMapping.free;` |
| **Reinit MIDI** | `~keyStepProMapping.init(~trackManager);` |

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
