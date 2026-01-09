# KeyStep Pro MIDI Quick Start

## Connection

1. **Connect KeyStep Pro via USB**
2. **Boot SuperCollider server**: `s.boot;`
3. **Run main script**: Load `main.scd`
4. **MIDI auto-initializes** - look for this message:

```
═══════════════════════════════════════════
  KeyStep Pro MIDI System
═══════════════════════════════════════════
MIDI Sources:
  [0] KeyStep Pro
  ...
✅ KeyStep Pro MIDI initialized
```

## Default Mappings (Track 1)

### Knobs

| Knob | CC | Parameter | Range | Warp |
|:-----|:---|:----------|:------|:-----|
| **Knob 1** | 74 | Position | 0.0 - 1.0 | Linear |
| **Knob 2** | 75 | Pitch | -24 to +24 semitones | Linear |
| **Knob 3** | 76 | Grain Size | 0.001 - 1.5 seconds | Exponential |
| **Knob 4** | 77 | Overlap | 0.5 - 16 grains | Linear |
| **Knob 5** | 78 | Amplitude | 0.0 - 1.0 | Linear |

### Mod Strip

| Control | CC | Parameter | Range |
|:--------|:---|:----------|:------|
| **Mod Strip** | 1 | Position Jitter | 0.0 - 1.0 |

### Keyboard

| Key Range | Function |
|:----------|:---------|
| **Notes 48-83** | Polyphonic pitch control |
| **Root: C3 (60)** | 0 semitones (original pitch) |
| **Note 84 (High C)** | **PANIC/RESET** - Resets all tracks |

**Pitch Behavior:**
- Each key triggers real-time pitch shift
- C3 (Note 60) = no pitch shift
- C4 (Note 72) = +12 semitones (1 octave up)
- C2 (Note 48) = -12 semitones (1 octave down)

## Smart Remapping

Change any knob assignment **on-the-fly** without stopping audio:

```supercollider
~mapKnob.(CC_NUMBER, \PARAMETER, MIN, MAX, WARP);
```

### Examples

```supercollider
// Remap Knob 1 to Spectral Mix
~mapKnob.(74, \spectralMix, 0, 1);

// Remap Knob 3 to Filter Cutoff (exponential feel)
~mapKnob.(76, \filterFreq, 0, 1, \exp);

// Remap Knob 4 to Reverb Mix
~mapKnob.(77, \reverbMix, 0, 1);

// Remap Knob 5 to Stereo Spread
~mapKnob.(78, \stereoSpread, 0, 1);
```

### Multi-Track Control

Control different tracks by adding track number (0-3):

```supercollider
// Knob 1 → Track 2 Position
~mapKnob.(74, \position, 0, 1, \lin, 1);

// Knob 2 → Track 3 Pitch
~mapKnob.(75, \pitch, -24, 24, \lin, 2);

// Knob 3 → Track 4 Grain Size
~mapKnob.(76, \grainSize, 0.001, 1.5, \exp, 3);
```

## Available Parameters

Here are all the parameters you can map:

### Grain Engine
- `\position` - Playback position in buffer (0-1)
- `\pitch` - Pitch shift in semitones (-24 to +24)
- `\grainSize` - Grain length (0.001 - 2.0 seconds)
- `\overlap` - Grain density (1-128)
- `\density` - Grains per second (1-1000)
- `\posJitter` - Position randomization (0-1)
- `\pitchJitter` - Pitch randomization (0-1)
- `\stereoSpread` - Stereo width (0-1)
- `\amp` - Track volume (0-1)
- `\pan` - Stereo pan (-1 to +1)

### Spectral Engine
- `\spectralMix` - Grain/Spectral crossfade (0-1)
- `\spectralPitch` - Spectral pitch shift (-24 to +24)
- `\spectralWindowSize` - FFT window size (0.05-0.5)
- `\spectralFreeze` - Freeze spectrum (0-1)

### Effects
- `\filterFreq` - Filter cutoff (0-1, exponential 20Hz-18kHz)
- `\filterRes` - Filter resonance (0-1)
- `\colorMix` - Color FX mix (0-1)
- `\spaceMix` - Space FX mix (0-1)
- `\reverbMix` - Reverb amount (0-1)
- `\delayMix` - Delay amount (0-1)

## Visual Feedback

When MIDI controls parameters:
- **Cyan overlays** appear in viewfinder for CC changes
- **Green pulses** appear for note triggers
- Parameter names and values are displayed briefly

## Testing

Run the test script to verify everything works:

```supercollider
"~/Documents/supercollider/granular/tests/keystep-pro-test.scd".standardizePath.load;
```

This will:
1. Verify MIDI connection
2. Monitor MIDI input for 30 seconds
3. Test smart remapping
4. Display troubleshooting info

## Panic/Reset

Press **Note 84 (High C)** on your keyboard to:
- Reset all 4 tracks to factory defaults
- Clear any stuck parameters
- Return to clean state

Console output:
```
🚨 PANIC/RESET TRIGGERED (Note 84)
✅ All tracks reset to factory defaults
```

## Troubleshooting

### No MIDI messages appearing?
```supercollider
// Check if MIDI is initialized
~keyStepProMapping.enabled.postln;  // Should print: true

// Manually reinitialize if needed
~keyStepProMapping.free;
~keyStepProMapping.init(~trackManager);
```

### Knobs control wrong parameters?
```supercollider
// Restore default mappings
~keyStepProMapping.loadDefaultMappings;
```

### Notes not triggering?
- Check MIDI channel (keyboard should be on any channel, it's omni)
- Verify KeyStep Pro is in keyboard mode (not sequencer mode)
- Try different octaves

### Visual feedback not appearing?
```supercollider
// Open viewfinder for Track 1
~viewfinder.createWindow(0);
```

## Advanced: Custom Mapping Profiles

Save your favorite mappings as a profile:

```supercollider
// Save as "myProfile.scd" in the project root
(
// My Custom KeyStep Pro Profile
~mapKnob.(74, \spectralMix, 0, 1);
~mapKnob.(75, \filterFreq, 0, 1, \exp);
~mapKnob.(76, \reverbMix, 0, 1);
~mapKnob.(77, \delayMix, 0, 1);
~mapKnob.(78, \amp, 0, 1);
~mapKnob.(1, \stereoSpread, 0, 1);

"Custom profile loaded!".postln;
)
```

Load it anytime:
```supercollider
"~/Documents/supercollider/granular/myProfile.scd".standardizePath.load;
```

## Tips

1. **Exponential warp** feels better for time-based parameters (grain size, filter frequency)
2. **Linear warp** is better for mix amounts and pitch
3. **Panic button** is your friend - don't hesitate to use it
4. **Remap during performance** - the smart mapper is designed for live remapping
5. **Open viewfinder** to see visual feedback of your MIDI control

## See Also

- `core/keystep-pro-mapping.scd` - Smart mapper implementation
- `tests/keystep-pro-test.scd` - MIDI testing script
- `FEATURES.md` - Complete feature list
- `CLAUDE.md` - Developer documentation
