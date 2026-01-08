/*
═══════════════════════════════════════════════════════════════════
SEQUENCER PATTERN CODING GUIDE
═══════════════════════════════════════════════════════════════════

Learn to code your own 64-step sequencer patterns based on terrestrial
and extraterrestrial musical systems.

This guide teaches you how to:
1. Create arrays and patterns in SuperCollider
2. Apply musical scales from around the world
3. Use mathematical functions for pattern generation
4. Explore microtonal and xenharmonic systems
5. Build custom pattern generators

═══════════════════════════════════════════════════════════════════
*/

/*
═══════════════════════════════════════════════════════════════════
PART 1: SUPERCOLLIDER ARRAY BASICS
═══════════════════════════════════════════════════════════════════
*/

// CREATING ARRAYS
// Method 1: Manual array
[0, 2, 4, 7, 9]

// Method 2: Fill with function
Array.fill(64, { |i| i });  // [0, 1, 2, 3, ... 63]

// Method 3: Series (arithmetic progression)
Array.series(64, 0, 0.5);  // [0, 0.5, 1, 1.5, 2, ...]

// Method 4: Fill with random values
Array.fill(64, { 12.rand });  // Random integers 0-11

// Method 5: Choose from array
var scale = [0, 2, 4, 7, 9];
Array.fill(64, { scale.choose });  // Random pentatonic notes

// MODIFYING ARRAYS
var pattern = Array.fill(64, 0);
pattern[0] = 5;      // Set index 0 to 5
pattern[10] = -3;    // Set index 10 to -3

// ITERATION
(1..63).do({ |i|
	pattern[i] = pattern[i-1] + 1;  // Ascending
});

// INDEXING WITH MODULO (wrapping)
Array.fill(64, { |i|
	scale[i % scale.size]  // Cycles through scale
});

/*
═══════════════════════════════════════════════════════════════════
PART 2: MATHEMATICAL PATTERN GENERATORS
═══════════════════════════════════════════════════════════════════
*/

// SINE WAVE (smooth melodic contour)
(
var pattern = Array.fill(64, { |i|
	((i / 64 * 2pi).sin * 12).round;  // ±12 semitones
});
~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);
)

// COSINE WAVE (phase-shifted sine)
(
var pattern = Array.fill(64, { |i|
	((i / 64 * 2pi).cos * 7).round;
});
~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);
)

// SAWTOOTH WAVE
(
var pattern = Array.fill(64, { |i|
	((i % 16) - 8);  // Repeating -8 to 7
});
~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);
)

// TRIANGLE WAVE
(
var pattern = Array.fill(64, { |i|
	var phase = i % 32;
	if(phase < 16, { phase - 8 }, { 24 - phase - 8 });
});
~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);
)

// EXPONENTIAL CURVE
(
var pattern = Array.fill(64, { |i|
	(i / 64).pow(2) * 24;  // 0 to 24, exponential
});
~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);
)

// LOGARITHMIC CURVE
(
var pattern = Array.fill(64, { |i|
	((i + 1).log2 * 3).round;  // Logarithmic ascent
});
~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);
)

/*
═══════════════════════════════════════════════════════════════════
PART 3: RHYTHMIC PATTERN GENERATORS
═══════════════════════════════════════════════════════════════════
*/

// EUCLIDEAN RHYTHM (evenly distributed hits)
(
var hits = 7;      // Number of hits
var steps = 64;    // Total steps
var pattern = Array.fill(steps, 0);
var stepSize = steps / hits;

hits.do({ |i|
	var index = (i * stepSize).round.asInteger;
	pattern[index] = 0.5;  // Position jump on hit
});

~trackManager.setParam(0, \posSeq, pattern);
~trackManager.setParam(0, \posJitter, 1);
)

// FIBONACCI RHYTHM
(
var fib = [1, 1, 2, 3, 5, 8, 13, 21, 34];  // Fibonacci sequence
var pattern = Array.fill(64, 0);
var pos = 0;

fib.do({ |interval|
	pos = (pos + interval) % 64;
	pattern[pos] = 0.3;
});

~trackManager.setParam(0, \posSeq, pattern);
~trackManager.setParam(0, \posJitter, 1);
)

// PRIME NUMBER RHYTHM
(
var primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61];
var pattern = Array.fill(64, 0);

primes.do({ |p|
	if(p < 64, { pattern[p] = 0.4 });
});

~trackManager.setParam(0, \posSeq, pattern);
~trackManager.setParam(0, \posJitter, 1);
)

// GOLDEN RATIO RHYTHM (φ ≈ 1.618)
(
var phi = (1 + 5.sqrt) / 2;  // Golden ratio
var pattern = Array.fill(64, 0);
var pos = 0;

16.do({ |i|
	pos = (pos + (phi * 4)) % 64;
	pattern[pos.round.asInteger] = 0.3;
});

~trackManager.setParam(0, \posSeq, pattern);
~trackManager.setParam(0, \posJitter, 1);
)

/*
═══════════════════════════════════════════════════════════════════
PART 4: TERRESTRIAL MUSICAL SYSTEMS
═══════════════════════════════════════════════════════════════════
*/

// WESTERN MODES (Greek modes in 12-TET)

// Ionian (Major scale)
(
var ionian = [0, 2, 4, 5, 7, 9, 11];
var pattern = Array.fill(64, { ionian.choose });
~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);
"✓ Ionian mode (Major)".postln;
)

// Dorian
(
var dorian = [0, 2, 3, 5, 7, 9, 10];
var pattern = Array.fill(64, { dorian.choose });
~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);
"✓ Dorian mode (minor with raised 6th)".postln;
)

// Phrygian
(
var phrygian = [0, 1, 3, 5, 7, 8, 10];
var pattern = Array.fill(64, { phrygian.choose });
~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);
"✓ Phrygian mode (Spanish/flamenco feel)".postln;
)

// Lydian
(
var lydian = [0, 2, 4, 6, 7, 9, 11];
var pattern = Array.fill(64, { lydian.choose });
~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);
"✓ Lydian mode (dreamy, raised 4th)".postln;
)

// Mixolydian
(
var mixolydian = [0, 2, 4, 5, 7, 9, 10];
var pattern = Array.fill(64, { mixolydian.choose });
~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);
"✓ Mixolydian mode (blues/rock feel)".postln;
)

// Aeolian (Natural minor)
(
var aeolian = [0, 2, 3, 5, 7, 8, 10];
var pattern = Array.fill(64, { aeolian.choose });
~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);
"✓ Aeolian mode (Natural minor)".postln;
)

// Locrian
(
var locrian = [0, 1, 3, 5, 6, 8, 10];
var pattern = Array.fill(64, { locrian.choose });
~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);
"✓ Locrian mode (diminished, unstable)".postln;
)

// PENTATONIC SCALES

// Major Pentatonic (worldwide - China, Africa, blues)
(
var majorPenta = [0, 2, 4, 7, 9];
var pattern = Array.fill(64, { majorPenta.choose });
~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);
"✓ Major pentatonic (universal scale)".postln;
)

// Minor Pentatonic (blues, rock)
(
var minorPenta = [0, 3, 5, 7, 10];
var pattern = Array.fill(64, { minorPenta.choose });
~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);
"✓ Minor pentatonic (blues scale)".postln;
)

// Japanese Hirajoshi
(
var hirajoshi = [0, 2, 3, 7, 8];
var pattern = Array.fill(64, { hirajoshi.choose });
~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);
"✓ Hirajoshi (Japanese traditional)".postln;
)

// Japanese In-Sen
(
var insen = [0, 1, 5, 7, 10];
var pattern = Array.fill(64, { insen.choose });
~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);
"✓ In-Sen (Japanese traditional)".postln;
)

// MIDDLE EASTERN SCALES

// Maqam Hijaz (Middle Eastern)
(
var hijaz = [0, 1, 4, 5, 7, 8, 11];
var pattern = Array.fill(64, { hijaz.choose });
~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);
"✓ Maqam Hijaz (Middle Eastern)".postln;
)

// Maqam Rast
(
var rast = [0, 2, 3.5, 5, 7, 9, 10.5];  // Quarter-tones!
var pattern = Array.fill(64, { rast.choose });
~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);
"✓ Maqam Rast (with quarter-tones)".postln;
)

// INDIAN RAGAS (simplified to 12-TET)

// Raga Bhairav
(
var bhairav = [0, 1, 4, 5, 7, 8, 11];
var pattern = Array.fill(64, { bhairav.choose });
~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);
"✓ Raga Bhairav (Indian classical)".postln;
)

// Raga Yaman
(
var yaman = [0, 2, 4, 6, 7, 9, 11];
var pattern = Array.fill(64, { yaman.choose });
~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);
"✓ Raga Yaman (evening raga)".postln;
)

/*
═══════════════════════════════════════════════════════════════════
PART 5: MICROTONAL & XENHARMONIC SYSTEMS
═══════════════════════════════════════════════════════════════════
*/

// 24-TET (Quarter-tone equal temperament)
(
var scale24 = Array.series(24, 0, 0.5);  // 0, 0.5, 1, 1.5, ...
var pattern = Array.fill(64, { scale24.choose });
~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);
"✓ 24-TET (quarter-tones)".postln;
)

// 31-TET (Approximates quarter-comma meantone)
(
var scale31 = Array.series(31, 0, 12/31);
var pattern = Array.fill(64, { scale31.choose });
~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);
"✓ 31-TET (meantone approximation)".postln;
)

// 19-TET (Approximates 1/3-comma meantone)
(
var scale19 = Array.series(19, 0, 12/19);
var pattern = Array.fill(64, { scale19.choose });
~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);
"✓ 19-TET".postln;
)

// 53-TET (Approximates Pythagorean and 5-limit JI)
(
var scale53 = Array.series(53, 0, 12/53);
var pattern = Array.fill(64, { scale53.choose });
~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);
"✓ 53-TET (high resolution)".postln;
)

// JUST INTONATION (pure ratios)
// Using semitone approximations

// 5-Limit Just Major Scale
(
var just5 = [
	0,              // 1/1   (C)
	2.04,           // 9/8   (D)
	3.86,           // 5/4   (E)
	4.98,           // 4/3   (F)
	7.02,           // 3/2   (G)
	8.84,           // 5/3   (A)
	10.88           // 15/8  (B)
];
var pattern = Array.fill(64, { just5.choose });
~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);
"✓ 5-Limit Just Intonation".postln;
)

// BOHLEN-PIERCE SCALE (13-step tritave, "extraterrestrial")
// Maps to 12-TET semitones for approximation
(
var bp = [
	0,              // 1/1
	1.87,           // 27/25
	3.37,           // 25/21
	4.98,           // 9/7
	6.38,           // 7/5
	7.82,           // 75/49
	9.24,           // 5/3
	10.67,          // 9/5
	11.95,          // 49/25
	13.36,          // 15/7
	14.68,          // 7/3
	16.04,          // 63/25
	17.28           // 25/9 (tritave)
];
var pattern = Array.fill(64, { bp.choose });
~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);
"✓ Bohlen-Pierce (13-step tritave)".postln;
)

// CARLOS ALPHA SCALE (78.0¢ steps)
(
var alpha = Array.series(16, 0, 0.65);  // Approx 78 cents = 0.65 semitones
var pattern = Array.fill(64, { alpha.choose });
~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);
"✓ Carlos Alpha (78¢ steps)".postln;
)

// CARLOS BETA SCALE (63.8¢ steps)
(
var beta = Array.series(19, 0, 0.532);  // Approx 63.8 cents
var pattern = Array.fill(64, { beta.choose });
~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);
"✓ Carlos Beta (63.8¢ steps)".postln;
)

// CARLOS GAMMA SCALE (35.1¢ steps)
(
var gamma = Array.series(34, 0, 0.293);  // Approx 35.1 cents
var pattern = Array.fill(64, { gamma.choose });
~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);
"✓ Carlos Gamma (35.1¢ steps)".postln;
)

/*
═══════════════════════════════════════════════════════════════════
PART 6: ADVANCED PATTERN TECHNIQUES
═══════════════════════════════════════════════════════════════════
*/

// MARKOV CHAIN (probabilistic transitions)
(
var scale = [0, 2, 4, 7, 9];
var transitions = Dictionary.new;
transitions[0] = [2, 4];      // From 0, go to 2 or 4
transitions[2] = [0, 4, 7];   // From 2, go to 0, 4, or 7
transitions[4] = [2, 7, 9];
transitions[7] = [4, 9, 0];
transitions[9] = [7, 0];

var pattern = Array.newClear(64);
var current = 0;
pattern[0] = current;

(1..63).do({ |i|
	current = transitions[current].choose;
	pattern[i] = current;
});

~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);
"✓ Markov chain melody".postln;
)

// CELLULAR AUTOMATON (Rule 30)
(
var rule = 30;
var cells = Array.fill(64, { [0, 1].choose });
var pattern = Array.newClear(64);

cells.do({ |cell, i|
	pattern[i] = if(cell == 1, { [0, 4, 7].choose }, { 0 });
});

~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);
"✓ Cellular automaton pattern".postln;
)

// FRACTAL (Dragon Curve)
(
var turns = [1, 1, -1, 1, 1, -1, -1, 1, 1, 1, -1, -1, 1, -1, -1, 1];  // Dragon curve sequence
var pattern = Array.newClear(64);
var pitch = 0;

64.do({ |i|
	pattern[i] = pitch;
	pitch = pitch + turns[i % turns.size];
});

~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);
"✓ Dragon curve fractal".postln;
)

// LINDENMAYER SYSTEM (L-System)
(
// Simple L-system: A → AB, B → A
// Generates Fibonacci-like pattern
var axiom = "A";
var rules = Dictionary[\A -> "AB", \B -> "A"];
var iterations = 6;

// Generate string
iterations.do({
	var next = "";
	axiom.do({ |char|
		next = next ++ rules[char.asSymbol];
	});
	axiom = next;
});

// Convert to pitch pattern (A=0, B=7)
var pattern = Array.fill(64, { |i|
	if(axiom[i % axiom.size].asSymbol == \A, { 0 }, { 7 });
});

~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);
"✓ L-System pattern".postln;
)

/*
═══════════════════════════════════════════════════════════════════
PART 7: COMBINING TECHNIQUES
═══════════════════════════════════════════════════════════════════
*/

// Example: Euclidean rhythm + Hijaz scale
(
var hijaz = [0, 1, 4, 5, 7, 8, 11];
var hits = 9;
var steps = 64;
var pattern = Array.fill(steps, { |i|
	if((i * hits % steps) < hits, {
		hijaz.choose  // Hit: choose from scale
	}, {
		0             // Rest: unison
	});
});

~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);
"✓ Euclidean Hijaz".postln;
)

// Example: Sine wave contour + 24-TET scale
(
var scale24 = Array.series(24, 0, 0.5);
var pattern = Array.fill(64, { |i|
	var contour = (i / 64 * 2pi).sin;  // -1 to 1
	var index = ((contour + 1) / 2 * (scale24.size - 1)).round.asInteger;
	scale24[index];
});

~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);
"✓ Sine wave + 24-TET".postln;
)

// Example: Random walk constrained to Raga Bhairav
(
var bhairav = [0, 1, 4, 5, 7, 8, 11];
var pattern = Array.newClear(64);
var currentIndex = 3;  // Start on scale degree 3
pattern[0] = bhairav[currentIndex];

(1..63).do({ |i|
	currentIndex = (currentIndex + [-1, 0, 1].choose).clip(0, bhairav.size - 1);
	pattern[i] = bhairav[currentIndex];
});

~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);
"✓ Constrained random walk (Bhairav)".postln;
)

/*
═══════════════════════════════════════════════════════════════════
PART 8: EXERCISES & EXPERIMENTS
═══════════════════════════════════════════════════════════════════

Try these challenges:

1. Create a pattern based on your birth date (MMDDYYYY)
2. Map the Mandelbrot set to pitch values
3. Sonify the digits of Pi or Phi
4. Create a scale based on planetary orbital ratios
5. Build a pattern using the atomic numbers of elements
6. Map DNA base pairs (A,T,G,C) to pitch classes
7. Create a rhythm based on Morse code
8. Translate text to pitch using ASCII values
9. Generate a melody from a bitmap image (pixel brightness)
10. Create a pattern based on the Fibonacci spiral

═══════════════════════════════════════════════════════════════════
*/

// Example: Sonify Pi digits
(
var piDigits = [3,1,4,1,5,9,2,6,5,3,5,8,9,7,9,3,2,3,8,4,6,2,6,4,3,3,8,3,2,7,9,5,
                0,2,8,8,4,1,9,7,1,6,9,3,9,9,3,7,5,1,0,5,8,2,0,9,7,4,9,4,4,5,9,2];
var pattern = piDigits - 5;  // Center around 0 (±5 semitones)

~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);
"✓ Digits of Pi".postln;
)

/*
═══════════════════════════════════════════════════════════════════
RESOURCES FOR FURTHER EXPLORATION
═══════════════════════════════════════════════════════════════════

Tuning Theory:
- xenharmonic.wikispaces.com
- huygens-fokker.org/microtonality
- kylegann.com/tuning.html

World Music Scales:
- "The Rāga Guide" by Nimbus Records
- "The Maqam Book" by Sami Abu Shumays
- "Music in Java" by Jaap Kunst

Algorithmic Composition:
- "The Computer Music Tutorial" by Curtis Roads
- "Algorithmic Composition" by David Cope
- "Formalized Music" by Iannis Xenakis

═══════════════════════════════════════════════════════════════════
*/
