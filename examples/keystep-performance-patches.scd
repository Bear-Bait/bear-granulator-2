/*
KeyStep Pro Performance Patches
Example MIDI mapping configurations for different performance styles

Load any patch by running its code block.
Remap on-the-fly during performance without stopping audio!

Author: S-4 Rival Team
*/

// ═══════════════════════════════════════════════════════════════════════════
// PATCH 1: "GRANULAR SCULPTOR" (Default)
// ═══════════════════════════════════════════════════════════════════════════
// Best for: Detailed grain manipulation, classic granular synthesis
// Track: 1
(
"Loading GRANULAR SCULPTOR patch...".postln;

~mapKnob.(74, \position, 0.0, 1.0);        // Knob 1: Scrub position
~mapKnob.(75, \pitch, -24, 24);            // Knob 2: Pitch shift
~mapKnob.(76, \grainSize, 0.001, 1.5, \exp); // Knob 3: Grain size (exp)
~mapKnob.(77, \overlap, 0.5, 16);          // Knob 4: Grain density
~mapKnob.(78, \amp, 0.0, 1.0);             // Knob 5: Volume
~mapKnob.(1, \posJitter, 0.0, 1.0);        // Mod: Position chaos

"✅ GRANULAR SCULPTOR loaded".postln;
"Knobs: Position | Pitch | Grain Size | Density | Volume".postln;
)

// ═══════════════════════════════════════════════════════════════════════════
// PATCH 2: "SPECTRAL MORPH"
// ═══════════════════════════════════════════════════════════════════════════
// Best for: Smooth spectral time-stretching, ambient textures
// Track: 1
(
"Loading SPECTRAL MORPH patch...".postln;

~mapKnob.(74, \spectralMix, 0.0, 1.0);         // Knob 1: Grain/Spectral blend
~mapKnob.(75, \pitch, -24, 24);                // Knob 2: Unified pitch
~mapKnob.(76, \spectralWindowSize, 0.05, 0.5); // Knob 3: FFT window size
~mapKnob.(77, \spectralFreeze, 0.0, 1.0);      // Knob 4: Spectral freeze
~mapKnob.(78, \amp, 0.0, 1.0);                 // Knob 5: Volume
~mapKnob.(1, \spectralSmear, 0.0, 1.0);        // Mod: Spectral blur

"✅ SPECTRAL MORPH loaded".postln;
"Knobs: Spectral Mix | Pitch | Window | Freeze | Volume".postln;
)

// ═══════════════════════════════════════════════════════════════════════════
// PATCH 3: "FILTER SWEEP"
// ═══════════════════════════════════════════════════════════════════════════
// Best for: Resonant filter sculpting, Moog-style sounds
// Track: 1
(
"Loading FILTER SWEEP patch...".postln;

~mapKnob.(74, \filterFreq, 0.0, 1.0, \exp);  // Knob 1: Cutoff (exponential)
~mapKnob.(75, \filterRes, 0.0, 0.95);        // Knob 2: Resonance
~mapKnob.(76, \filterDrive, 0.0, 5.0);       // Knob 3: Drive/saturation
~mapKnob.(77, \filterMorph, 0.0, 1.0);       // Knob 4: LP/BP/HP morph
~mapKnob.(78, \amp, 0.0, 1.0);               // Knob 5: Volume
~mapKnob.(1, \posJitter, 0.0, 1.0);          // Mod: Grain chaos

// Enable filter
~trackManager.setParam(0, \filterOn, 1);

"✅ FILTER SWEEP loaded".postln;
"Knobs: Cutoff | Resonance | Drive | Morph | Volume".postln;
)

// ═══════════════════════════════════════════════════════════════════════════
// PATCH 4: "SPACE DESIGNER"
// ═══════════════════════════════════════════════════════════════════════════
// Best for: Reverb/delay manipulation, ambient soundscapes
// Track: 1
(
"Loading SPACE DESIGNER patch...".postln;

~mapKnob.(74, \reverbMix, 0.0, 1.0);      // Knob 1: Reverb amount
~mapKnob.(75, \reverbSize, 0.5, 3.0);     // Knob 2: Room size
~mapKnob.(76, \delayMix, 0.0, 1.0);       // Knob 3: Delay amount
~mapKnob.(77, \delayTime, 0.05, 2.0);     // Knob 4: Delay time
~mapKnob.(78, \amp, 0.0, 1.0);            // Knob 5: Volume
~mapKnob.(1, \shimmerMix, 0.0, 1.0);      // Mod: Shimmer (pitch-shift delay)

// Enable space effects
~trackManager.setParam(0, \spaceOn, 1);

"✅ SPACE DESIGNER loaded".postln;
"Knobs: Reverb | Size | Delay | Time | Volume".postln;
)

// ═══════════════════════════════════════════════════════════════════════════
// PATCH 5: "QUAD SPATIAL"
// ═══════════════════════════════════════════════════════════════════════════
// Best for: 4-speaker spatial positioning, immersive audio
// Track: 1
(
"Loading QUAD SPATIAL patch...".postln;

~mapKnob.(74, \quadX, -1.0, 1.0);          // Knob 1: X position (L/R)
~mapKnob.(75, \quadY, -1.0, 1.0);          // Knob 2: Y position (F/B)
~mapKnob.(76, \grainSize, 0.001, 1.5, \exp); // Knob 3: Grain size
~mapKnob.(77, \overlap, 0.5, 16);          // Knob 4: Density
~mapKnob.(78, \amp, 0.0, 1.0);             // Knob 5: Volume
~mapKnob.(1, \stereoSpread, 0.0, 1.0);     // Mod: Stereo width

"✅ QUAD SPATIAL loaded".postln;
"Knobs: X Position | Y Position | Grain Size | Density | Volume".postln;
"Requires quad speaker setup (4 outputs)".postln;
)

// ═══════════════════════════════════════════════════════════════════════════
// PATCH 6: "DESTROYER"
// ═══════════════════════════════════════════════════════════════════════════
// Best for: Aggressive distortion, lo-fi bit crushing
// Track: 1
(
"Loading DESTROYER patch...".postln;

~mapKnob.(74, \saturationDrive, 0.5, 10.0); // Knob 1: Distortion drive
~mapKnob.(75, \crusherBits, 1, 16);        // Knob 2: Bit depth
~mapKnob.(76, \crusherRate, 0.05, 1.0);    // Knob 3: Sample rate reduction
~mapKnob.(77, \compressorRatio, 1, 20);    // Knob 4: Compression ratio
~mapKnob.(78, \amp, 0.0, 1.0);             // Knob 5: Volume
~mapKnob.(1, \colorMix, 0.0, 1.0);         // Mod: Color FX amount

// Enable color effects
~trackManager.setParam(0, \colorOn, 1);

"✅ DESTROYER loaded".postln;
"Knobs: Drive | Bits | Crush | Compress | Volume".postln;
"WARNING: Can get LOUD! Start with knobs low.".postln;
)

// ═══════════════════════════════════════════════════════════════════════════
// PATCH 7: "HYBRID ENGINE"
// ═══════════════════════════════════════════════════════════════════════════
// Best for: Blending all 3 playback engines (Grain/Spectral/Direct)
// Track: 1
(
"Loading HYBRID ENGINE patch...".postln;

~mapKnob.(74, \engineMix, 0.0, 1.0);       // Knob 1: Grain→Direct morph
~mapKnob.(75, \spectralMix, 0.0, 1.0);     // Knob 2: Add spectral layer
~mapKnob.(76, \grainSize, 0.001, 1.5, \exp); // Knob 3: Grain texture
~mapKnob.(77, \timeStretch, 0.25, 4.0);    // Knob 4: Time stretch
~mapKnob.(78, \amp, 0.0, 1.0);             // Knob 5: Volume
~mapKnob.(1, \pitch, -12, 12);             // Mod: Pitch shift

"✅ HYBRID ENGINE loaded".postln;
"Knobs: Engine Mix | Spectral | Grain Size | Time | Volume".postln;
)

// ═══════════════════════════════════════════════════════════════════════════
// PATCH 8: "4-TRACK CONTROL" (Multi-track)
// ═══════════════════════════════════════════════════════════════════════════
// Best for: Controlling multiple tracks from one keyboard
// Knobs split across 4 tracks
(
"Loading 4-TRACK CONTROL patch...".postln;

// Track 1: Position
~mapKnob.(74, \position, 0.0, 1.0, \lin, 0);

// Track 2: Position
~mapKnob.(75, \position, 0.0, 1.0, \lin, 1);

// Track 3: Position
~mapKnob.(76, \position, 0.0, 1.0, \lin, 2);

// Track 4: Position
~mapKnob.(77, \position, 0.0, 1.0, \lin, 3);

// Master volume on Knob 5
~mapKnob.(78, \amp, 0.0, 1.0, \lin, 0);

// Mod strip controls all tracks' jitter
~mapKnob.(1, \posJitter, 0.0, 1.0, \lin, 0);
~mapKnob.(1, \posJitter, 0.0, 1.0, \lin, 1);
~mapKnob.(1, \posJitter, 0.0, 1.0, \lin, 2);
~mapKnob.(1, \posJitter, 0.0, 1.0, \lin, 3);

"✅ 4-TRACK CONTROL loaded".postln;
"Knobs: T1 Pos | T2 Pos | T3 Pos | T4 Pos | Volume".postln;
)

// ═══════════════════════════════════════════════════════════════════════════
// PATCH 9: "PERFORMANCE MIX"
// ═══════════════════════════════════════════════════════════════════════════
// Best for: Live mixing and blending
// Track: 1
(
"Loading PERFORMANCE MIX patch...".postln;

~mapKnob.(74, \position, 0.0, 1.0);        // Knob 1: Playback position
~mapKnob.(75, \filterFreq, 0.0, 1.0, \exp); // Knob 2: Filter sweep
~mapKnob.(76, \reverbMix, 0.0, 1.0);       // Knob 3: Reverb amount
~mapKnob.(77, \delayMix, 0.0, 1.0);        // Knob 4: Delay amount
~mapKnob.(78, \amp, 0.0, 1.0);             // Knob 5: Volume
~mapKnob.(1, \pan, -1.0, 1.0);             // Mod: Stereo pan

"✅ PERFORMANCE MIX loaded".postln;
"Knobs: Position | Filter | Reverb | Delay | Volume".postln;
)

// ═══════════════════════════════════════════════════════════════════════════
// PATCH 10: "CUSTOM TEMPLATE"
// ═══════════════════════════════════════════════════════════════════════════
// Blank template - customize to your needs!
(
"Loading CUSTOM TEMPLATE...".postln;

// Edit these to create your own patch!
~mapKnob.(74, \position, 0.0, 1.0);        // Knob 1: YOUR CHOICE
~mapKnob.(75, \pitch, -24, 24);            // Knob 2: YOUR CHOICE
~mapKnob.(76, \grainSize, 0.001, 1.5, \exp); // Knob 3: YOUR CHOICE
~mapKnob.(77, \overlap, 0.5, 16);          // Knob 4: YOUR CHOICE
~mapKnob.(78, \amp, 0.0, 1.0);             // Knob 5: YOUR CHOICE
~mapKnob.(1, \posJitter, 0.0, 1.0);        // Mod: YOUR CHOICE

"✅ CUSTOM TEMPLATE loaded".postln;
"Edit this patch to create your own mapping!".postln;
)

/*
═══════════════════════════════════════════════════════════════════════════
AVAILABLE PARAMETERS FOR MAPPING
═══════════════════════════════════════════════════════════════════════════

GRAIN ENGINE:
\position, \pitch, \grainSize, \overlap, \density, \posJitter, \pitchJitter,
\stereoSpread, \amp, \pan, \scanSpeed, \timeStretch, \useOverlap

SPECTRAL ENGINE:
\spectralMix, \spectralPitch, \spectralPosition, \spectralRate,
\spectralWindowSize, \spectralOverlaps, \spectralFreeze, \spectralSmear

FILTER:
\filterOn, \filterFreq, \filterRes, \filterDrive, \filterMorph, \filterDecay

COLOR FX:
\colorOn, \colorMix, \saturationDrive, \crusherBits, \crusherRate,
\compressorThresh, \compressorRatio, \noiseMix

SPACE FX:
\spaceOn, \spaceMix, \reverbMix, \reverbSize, \reverbDamp, \reverbFreeze,
\delayMix, \delayTime, \delayFeedback, \shimmerMix, \shimmerPitch

QUAD SPATIAL:
\quadX, \quadY

HYBRID:
\engineMix (Grain→Direct), \grainMode (TAPE/POLY/LIVE)

═══════════════════════════════════════════════════════════════════════════
TIPS FOR CREATING YOUR OWN PATCHES
═══════════════════════════════════════════════════════════════════════════

1. Use \exp warp for time-based parameters (grainSize, filterFreq)
2. Use \lin warp for mix amounts and pitch
3. Group related parameters (all reverb controls together)
4. Reserve Knob 5 for volume (muscle memory!)
5. Use mod strip for performance-critical parameters
6. Test your patch before performing!
7. Save custom patches to separate files for easy recall

Example custom patch file structure:
(
// My Custom Patch Name
~mapKnob.(74, \param1, min, max, warp);
~mapKnob.(75, \param2, min, max, warp);
// ... etc
"✅ My Patch loaded".postln;
)

═══════════════════════════════════════════════════════════════════════════
*/
