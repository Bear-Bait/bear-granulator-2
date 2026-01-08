/*
═══════════════════════════════════════════════════════════════════
v2.1 64-STEP SEQUENCER EXAMPLES
═══════════════════════════════════════════════════════════════════

The v2.1 engine introduces 64-step sequencer arrays for position and
pitch modulation. This replaces random LFNoise with repeatable, musical
patterns that sync with hardware (KeyStep Pro, Digitone).

**New Parameters:**
- posSeq: 64-step array (-1 to 1, position offsets)
- pitchSeq: 64-step array (semitones)
- posJitter: Amplitude of position sequence (0-1)
- pitchJitter: Amplitude of pitch sequence (0-12)

**Usage:**
posJitter/pitchJitter act as "volume knobs" for the sequences.
Set to 0 to disable, 1 to use full sequence range.

═══════════════════════════════════════════════════════════════════
*/

// Assumes you have a track playing (e.g., from main.scd)
// Access via: ~trackManager.setParam(trackNum, \posSeq, array)

// ═══════════════════════════════════════════════════════════
// EXAMPLE 1: PENTATONIC ARPEGGIO
// ═══════════════════════════════════════════════════════════
(
// Major pentatonic scale (C, D, E, G, A)
var pentatonic = [0, 2, 4, 7, 9];
var pitchPattern = Array.fill(64, { pentatonic.choose });

~trackManager.setParam(0, \pitchSeq, pitchPattern);
~trackManager.setParam(0, \pitchJitter, 1);  // Full amplitude

"✓ Pentatonic arpeggio loaded (Track 1)".postln;
"  Adjust pitchJitter (0-1) to control intensity".postln;
)

// ═══════════════════════════════════════════════════════════
// EXAMPLE 2: RHYTHMIC POSITION STUTTER
// ═══════════════════════════════════════════════════════════
(
// Creates rhythmic "rewind" effect on 16th notes
var posPattern = Array.fill(64, 0);
posPattern[3] = -0.1;   // Jump back on beat 4
posPattern[7] = -0.1;   // Jump back on beat 8
posPattern[11] = -0.2;  // Bigger jump on beat 12
posPattern[15] = -0.3;  // Even bigger on beat 16

~trackManager.setParam(0, \posSeq, posPattern);
~trackManager.setParam(0, \posJitter, 1);  // Full amplitude

"✓ Rhythmic stutter loaded (Track 1)".postln;
"  Creates tape-rewind effect on beat divisions".postln;
)

// ═══════════════════════════════════════════════════════════
// EXAMPLE 3: GLITCH DRUMS (RANDOM SCATTER)
// ═══════════════════════════════════════════════════════════
(
// Scattered position jumps for percussive samples
var posPattern = Array.fill(64, { 0.3.rand2 });  // Random -0.3 to +0.3

~trackManager.setParam(0, \posSeq, posPattern);
~trackManager.setParam(0, \posJitter, 0.5);  // Medium amplitude

"✓ Glitch scatter loaded (Track 1)".postln;
"  Creates IDM-style micro-edits".postln;
)

// ═══════════════════════════════════════════════════════════
// EXAMPLE 4: HARMONIC CLOUD (OCTAVES + FIFTHS)
// ═══════════════════════════════════════════════════════════
(
// Mix of octaves (12, 24) and fifths (7, 19)
var harmonic = [0, 7, 12, 19, 24];
var pitchPattern = Array.fill(64, { harmonic.choose });

~trackManager.setParam(0, \pitchSeq, pitchPattern);
~trackManager.setParam(0, \pitchJitter, 1);

"✓ Harmonic cloud loaded (Track 1)".postln;
"  Creates shimmering, harmonically-rich texture".postln;
)

// ═══════════════════════════════════════════════════════════
// EXAMPLE 5: CHROMATIC WALK (SLOW DRIFT)
// ═══════════════════════════════════════════════════════════
(
// Slow chromatic ascent over 64 steps
var pitchPattern = Array.series(64, 0, 0.25);  // 0, 0.25, 0.5, 0.75...

~trackManager.setParam(0, \pitchSeq, pitchPattern);
~trackManager.setParam(0, \pitchJitter, 1);

"✓ Chromatic walk loaded (Track 1)".postln;
"  Slowly rises in pitch over 64 grains".postln;
)

// ═══════════════════════════════════════════════════════════
// EXAMPLE 6: EUCLIDEAN RHYTHM (POSITION HITS)
// ═══════════════════════════════════════════════════════════
(
// 7 hits distributed over 64 steps (Euclidean rhythm)
var posPattern = Array.fill(64, 0);
var stepSize = 64 / 7;
7.do({ |i|
	var index = (i * stepSize).round.asInteger;
	posPattern[index] = 0.5;  // Jump forward on hit
});

~trackManager.setParam(0, \posSeq, posPattern);
~trackManager.setParam(0, \posJitter, 1);

"✓ Euclidean rhythm loaded (Track 1)".postln;
"  7 evenly-spaced position jumps".postln;
)

// ═══════════════════════════════════════════════════════════
// EXAMPLE 7: MINOR SCALE (SAD/DARK)
// ═══════════════════════════════════════════════════════════
(
// Natural minor scale
var minor = [0, 2, 3, 5, 7, 8, 10];
var pitchPattern = Array.fill(64, { minor.choose });

~trackManager.setParam(0, \pitchSeq, pitchPattern);
~trackManager.setParam(0, \pitchJitter, 1);

"✓ Minor scale loaded (Track 1)".postln;
"  Creates darker, melancholic textures".postln;
)

// ═══════════════════════════════════════════════════════════
// EXAMPLE 8: WHOLE TONE SCALE (DREAMY)
// ═══════════════════════════════════════════════════════════
(
// Whole tone scale (Debussy/ambient)
var wholeTone = [0, 2, 4, 6, 8, 10];
var pitchPattern = Array.fill(64, { wholeTone.choose });

~trackManager.setParam(0, \pitchSeq, pitchPattern);
~trackManager.setParam(0, \pitchJitter, 1);

"✓ Whole tone scale loaded (Track 1)".postln;
"  Creates floating, dreamlike quality".postln;
)

// ═══════════════════════════════════════════════════════════
// EXAMPLE 9: MICROTONAL (24-TET)
// ═══════════════════════════════════════════════════════════
(
// Quarter-tone scale (24-tone equal temperament)
var microtonal = Array.series(24, 0, 0.5);  // 0, 0.5, 1, 1.5, 2...
var pitchPattern = Array.fill(64, { microtonal.choose });

~trackManager.setParam(0, \pitchSeq, pitchPattern);
~trackManager.setParam(0, \pitchJitter, 1);

"✓ Microtonal (24-TET) loaded (Track 1)".postln;
"  Creates intentional microtonal intervals".postln;
)

// ═══════════════════════════════════════════════════════════
// EXAMPLE 10: SILENT STEPS (SPARSE RHYTHM)
// ═══════════════════════════════════════════════════════════
(
// Most steps silent, occasional hits
var pitchPattern = Array.fill(64, { |i|
	if((i % 16) == 0, { [0, 7, 12].choose }, { 0 });
});

~trackManager.setParam(0, \pitchSeq, pitchPattern);
~trackManager.setParam(0, \pitchJitter, 1);

"✓ Sparse rhythm loaded (Track 1)".postln;
"  Pitch changes only on downbeats".postln;
)

// ═══════════════════════════════════════════════════════════
// EXAMPLE 11: COMBINED POSITION + PITCH SEQUENCE
// ═══════════════════════════════════════════════════════════
(
// Position: slow forward drift
var posPattern = Array.series(64, 0, 0.01);  // 0, 0.01, 0.02...

// Pitch: pentatonic melody
var pentatonic = [0, 2, 4, 7, 9];
var pitchPattern = Array.fill(64, { pentatonic.choose });

~trackManager.setParam(0, \posSeq, posPattern);
~trackManager.setParam(0, \posJitter, 0.5);

~trackManager.setParam(0, \pitchSeq, pitchPattern);
~trackManager.setParam(0, \pitchJitter, 1);

"✓ Combined sequence loaded (Track 1)".postln;
"  Position slowly scans forward while pitch arpeggiates".postln;
)

// ═══════════════════════════════════════════════════════════
// EXAMPLE 12: DISABLE SEQUENCES (BACK TO RANDOM)
// ═══════════════════════════════════════════════════════════
(
// Turn off jitter to return to static behavior
~trackManager.setParam(0, \posJitter, 0);
~trackManager.setParam(0, \pitchJitter, 0);

"✓ Sequences disabled (Track 1)".postln;
"  Back to static grain position and pitch".postln;
)

// ═══════════════════════════════════════════════════════════
// ADVANCED: PATTERN GENERATORS
// ═══════════════════════════════════════════════════════════

// Generate melodic contour (sine wave)
(
var sinePattern = Array.fill(64, { |i|
	((i / 64 * 2pi).sin * 12).round;  // Sine wave, ±12 semitones
});
~trackManager.setParam(0, \pitchSeq, sinePattern);
~trackManager.setParam(0, \pitchJitter, 1);
"✓ Sine wave melody".postln;
)

// Generate random walk
(
var walkPattern = Array.fill(64, { |i|
	if(i == 0, { 0 }, {
		walkPattern[i-1] + [0, 1, -1].choose;  // Random walk
	});
});
~trackManager.setParam(0, \pitchSeq, walkPattern);
~trackManager.setParam(0, \pitchJitter, 1);
"✓ Random walk".postln;
)

// Generate accelerando (increasing density)
(
var accelPattern = Array.fill(64, { |i|
	if((i.pow(1.5) % 8) < 1, { 0.2 }, { 0 });  // Accelerating hits
});
~trackManager.setParam(0, \posSeq, accelPattern);
~trackManager.setParam(0, \posJitter, 1);
"✓ Accelerando pattern".postln;
)

/*
═══════════════════════════════════════════════════════════════════
TIPS & TRICKS
═══════════════════════════════════════════════════════════════════

1. **Start with low jitter amounts:**
   Set posJitter/pitchJitter to 0.2-0.3 first, then increase.

2. **Combine with timeStretch:**
   Slow down time to hear sequences more clearly.
   ~trackManager.setParam(0, \timeStretch, 0.5);

3. **Layer multiple tracks:**
   Different sequences on each track for complex polyrhythms.

4. **Use with TAPE mode:**
   Position sequences work best with looping material.

5. **MIDI sync:**
   64 steps matches KeyStep Pro and Digitone for hardware integration.

6. **Live coding:**
   Update sequences in real-time during performance.

7. **Save with presets:**
   Sequences are saved in preset files for recall.

8. **Modulate jitter amount:**
   Use modulation window to route LFO to posJitter/pitchJitter.

═══════════════════════════════════════════════════════════════════
*/
