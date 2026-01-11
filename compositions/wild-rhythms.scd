// WILD RHYTHMS - 5 Styles Across 4 Tracks
// Created for S-4 RIVAL Bearulator
// Usage: Select a section and run it (Cmd+Enter)

// ============================================================================
// SETUP - Run this first if needed
// ============================================================================

(
// Ensure we have the euclidean function
~euclidean = { |hits, steps|
	var res = 0 ! steps;
	var current = 0;
	hits.do {
		res[current.floor] = 1;
		current = current + (steps / hits);
	};
	res
};

// Advanced rhythm generators
~glitchPattern = { |length, density=0.5|
	Array.fill(length, { |i|
		if(i.coin, { [1, 0.7, 0.3, 0].choose }, { 0 })
	})
};

~polyrhythm = { |pattern1, pattern2|
	var lcm = pattern1.size.lcm(pattern2.size);
	Array.fill(lcm, { |i|
		(pattern1.wrapAt(i) + pattern2.wrapAt(i)).min(1)
	})
};

~phasePattern = { |hits, steps, offset=0|
	var base = ~euclidean.value(hits, steps);
	base.rotate(offset)
};

"Rhythm generators loaded.".postln;
)

// ============================================================================
// STYLE 1: APHEX TWIN - Chaotic IDM with Metric Modulation
// ============================================================================
// Unpredictable time signatures, probability gates, random position jumps
// Tracks weave in/out of phase with each other

(
"APHEX TWIN MODE - Launching glitch rhythms...".postln;

// Track 1: Chaotic main beat with random position jumps
Pdef(\aphex1, Pbind(
	\type, \set,
	\id, ~trackManager.getTrack(0).grainSynth.nodeID,
	\dur, Pseq([0.125, 0.0625, 0.1875, 0.125, 0.0625], inf), // Irregular timing
	\amp, Pwhite(0.3, 0.9) * Prand([1, 1, 1, 0, 1, 0.5], inf), // Random gates
	\position, Pwhite(0.1, 0.9), // Jump around sample
	\grainSize, Pwhite(0.02, 0.15), // Varying grain sizes
	\prob, Pwhite(0.5, 1.0) // Probability gate
)).play;

// Track 2: Slow evolving drone with Euclidean gate (5/13)
Pdef(\aphex2, Pbind(
	\type, \set,
	\id, ~trackManager.getTrack(1).grainSynth.nodeID,
	\dur, 0.25,
	\amp, Pseq(~euclidean.value(5, 13), inf) * Pwhite(0.2, 0.6),
	\position, Pseg(Pseq([0.2, 0.8, 0.3], inf), 4, \exp), // Slow sweep
	\pitch, Pstutter(8, Prand([0.5, 0.707, 1, 1.414], inf)), // Occasional pitch shift
	\overlap, Pstep(Pseq([32, 64, 16], inf), 2)
)).play;

// Track 3: Rapid-fire micro-grains (Autechre style)
Pdef(\aphex3, Pbind(
	\type, \set,
	\id, ~trackManager.getTrack(2).grainSynth.nodeID,
	\dur, 0.0625, // 32nd notes
	\amp, Pseq(~glitchPattern.value(32, 0.4), inf) * 0.5,
	\grainSize, Pwhite(0.005, 0.03), // Tiny grains
	\position, Pbrown(0, 1, 0.05, inf), // Brownian motion through sample
	\pitch, Prand([1, 2, 4, 0.5], inf)
)).play;

// Track 4: Breakbeat stutter (7/16 against everything else)
Pdef(\aphex4, Pbind(
	\type, \set,
	\id, ~trackManager.getTrack(3).grainSynth.nodeID,
	\dur, 0.1875, // 3/16 timing
	\amp, Pseq(~euclidean.value(7, 16), inf) * Pwhite(0.4, 0.8),
	\position, Pstutter(4, Pwhite(0, 0.5)), // Stutter on positions
	\grainSize, Prand([0.05, 0.1, 0.2], inf)
)).play;
)

// Stop Aphex
Pdef(\aphex1).stop; Pdef(\aphex2).stop; Pdef(\aphex3).stop; Pdef(\aphex4).stop;


// ============================================================================
// STYLE 2: AFRICAN DRUMS - Polyrhythmic Bell Patterns
// ============================================================================
// Traditional West African bell patterns with interlocking rhythms
// 12/8 feel with triplet subdivisions

(
"AFRICAN DRUMS MODE - Polyrhythmic cycles...".postln;

// Track 1: Timeline (12-beat master pattern)
Pdef(\african1, Pbind(
	\type, \set,
	\id, ~trackManager.getTrack(0).grainSynth.nodeID,
	\dur, 0.25, // 16th feel
	\amp, Pseq([1, 0, 0, 0.7, 0, 0, 1, 0, 0, 0.7, 0, 0], inf) * 0.7,
	\position, Pseq([0.1, 0.15, 0.12], inf), // Subtle position variation
	\grainSize, 0.08,
	\pitch, 1.5 // Higher pitch
)).play;

// Track 2: Gankogui bell (7 against 12)
Pdef(\african2, Pbind(
	\type, \set,
	\id, ~trackManager.getTrack(1).grainSynth.nodeID,
	\dur, 0.25,
	\amp, Pseq(~euclidean.value(7, 12), inf) * 0.8,
	\position, 0.3,
	\grainSize, 0.05,
	\pitch, 2.0 // Bell-like
)).play;

// Track 3: Talking drum (5 against 16 with syncopation)
Pdef(\african3, Pbind(
	\type, \set,
	\id, ~trackManager.getTrack(2).grainSynth.nodeID,
	\dur, 0.1875,
	\amp, Pseq(~euclidean.value(5, 16), inf) * Prand([0.5, 0.7, 0.9], inf),
	\position, Pwhite(0.4, 0.6), // Mid-range
	\grainSize, Prand([0.06, 0.12], inf), // Two voices
	\pitch, Pseq([0.8, 1.0, 1.2], inf) // Pitch bending
)).play;

// Track 4: Bass drum (3 against 8 - tresillo)
Pdef(\african4, Pbind(
	\type, \set,
	\id, ~trackManager.getTrack(3).grainSynth.nodeID,
	\dur, 0.375, // Slower
	\amp, Pseq(~euclidean.value(3, 8), inf) * 0.9,
	\position, 0.05, // Low bass region
	\grainSize, 0.2, // Long grains
	\pitch, 0.5 // Octave down
)).play;
)

// Stop African
Pdef(\african1).stop; Pdef(\african2).stop; Pdef(\african3).stop; Pdef(\african4).stop;




// ============================================================================
// STYLE 3: CLASSICAL INDIAN - Tabla Tihai & Raga Cycles
// ============================================================================
// Based on 16-beat Teen Taal with tihai patterns (phrase × 3)
// Tabla bols: Dha Dhin Dhin Dha / Ta Tin Tin Ta

(
"CLASSICAL INDIAN MODE - Teen Taal with tihai...".postln;

var tihai = [1, 0, 1, 0, 1, 0]; // Simple 3-note tihai pattern
var teenTaal = [1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0]; // 16-beat cycle

// Track 1: Tabla baya (bass drum) - Teen Taal structure
Pdef(\indian1, Pbind(
	\type, \set,
	\id, ~trackManager.getTrack(0).grainSynth.nodeID,
	\dur, 0.25,
	\amp, Pseq(teenTaal, inf) * Pseq([0.9, 0.5, 0.5, 0.4], inf),
	\position, 0.1,
	\grainSize, 0.15,
	\pitch, 0.7
)).play;

// Track 2: Tabla dayan (treble) - Complex ornamentation
Pdef(\indian2, Pbind(
	\type, \set,
	\id, ~trackManager.getTrack(1).grainSynth.nodeID,
	\dur, Pseq([0.125, 0.125, 0.25] ++ (0.125 ! 8), inf), // Varied subdivisions
	\amp, Pseq([1, 0.6, 0.8, 0, 1, 0.5, 0, 0.7, 1, 0, 0.5, 0, 1, 0.6, 0, 0.5], inf) * 0.7,
	\position, Pwhite(0.3, 0.5),
	\grainSize, Prand([0.04, 0.06, 0.08], inf), // Finger strikes
	\pitch, Prand([1, 1.2, 1.5], inf) // Pitch variation for bols
)).play;

// Track 3: Tihai pattern (repeating 3 times with gaps)
Pdef(\indian3, Pbind(
	\type, \set,
	\id, ~trackManager.getTrack(2).grainSynth.nodeID,
	\dur, 0.125,
	\amp, Pseq(tihai ++ tihai ++ tihai ++ (0 ! 10), inf) * 0.8, // Phrase × 3 then rest
	\position, 0.6,
	\grainSize, 0.07,
	\pitch, 1.3
)).play;

// Track 4: Drone (tanpura-like) with slow tabla punctuation
Pdef(\indian4, Pbind(
	\type, \set,
	\id, ~trackManager.getTrack(3).grainSynth.nodeID,
	\dur, 1.0, // Whole beats
	\amp, Pseq([0.4, 0, 0, 0, 0.35, 0, 0, 0, 0.4, 0, 0, 0, 0.45, 0, 0, 0], inf),
	\position, 0.2,
	\grainSize, 0.3,
	\pitch, 0.5,
	\overlap, 64 // Dense drone
)).play;
)

// Stop Indian
Pdef(\indian1).stop; Pdef(\indian2).stop; Pdef(\indian3).stop; Pdef(\indian4).stop;


// ============================================================================
// STYLE 4: MINIMAL HOUSE - Hypnotic 4/4 with Micro-variations
// ============================================================================
// Basic 4/4 kick, but with probability gates and evolving hi-hats
// Track variation through subtle parameter changes over time

(
"MINIMAL HOUSE MODE - Deep groove...".postln;

// Track 1: Kick drum (4/4 with occasional double hits)
Pdef(\house1, Pbind(
	\type, \set,
	\id, ~trackManager.getTrack(0).grainSynth.nodeID,
	\dur, Pseq([1, 1, 1, Prand([1, 0.5], 1)], inf), // Mostly steady with occasional double
	\amp, Pseq([0.9, 0.85, 0.88, 0.92], inf), // Subtle swing
	\position, Pwhite(0.05, 0.15), // Slight position variation
	\grainSize, 0.15,
	\pitch, 0.6,
	\prob, 0.95 // Very occasional drop
)).play;

// Track 2: Hi-hat evolving pattern (off-beat focus)
Pdef(\house2, Pbind(
	\type, \set,
	\id, ~trackManager.getTrack(1).grainSynth.nodeID,
	\dur, 0.25,
	\amp, Pseq([
		0, 0.4, 0, 0.5, 0, 0.6, 0, 0.4,  // Pattern A
		0, 0.5, 0, 0.7, 0, 0.5, 0, 0.6   // Pattern B
	], inf) * Pseg(Pseq([0.6, 0.9, 0.6], inf), 8), // Slow volume evolution
	\position, Pseg(Pseq([0.7, 0.9], inf), 16), // Sweep through hi-hat zone
	\grainSize, Pwhite(0.02, 0.05),
	\pitch, Pstutter(16, Prand([2, 2.5, 3], inf)), // Change timbre every 4 bars
	\prob, Pstutter(32, Pwhite(0.7, 1.0)) // Slowly varying probability
)).play;

// Track 3: Shaker/percussion (Euclidean 11/16 for complexity)
Pdef(\house3, Pbind(
	\type, \set,
	\id, ~trackManager.getTrack(2).grainSynth.nodeID,
	\dur, 0.25,
	\amp, Pseq(~euclidean.value(11, 16), inf) * 0.3,
	\position, Pwhite(0.5, 0.7),
	\grainSize, 0.03,
	\pitch, 3.0
)).play;

// Track 4: Clap/snare (2 and 4 with ghost notes)
Pdef(\house4, Pbind(
	\type, \set,
	\id, ~trackManager.getTrack(3).grainSynth.nodeID,
	\dur, 0.5,
	\amp, Pseq([0, 0.85, Prand([0, 0.2], 1), 0.9], inf), // Ghost notes
	\position, 0.4,
	\grainSize, 0.1,
	\pitch, 1.2
)).play;
)

// Stop House
Pdef(\house1).stop; Pdef(\house2).stop; Pdef(\house3).stop; Pdef(\house4).stop;


// ============================================================================
// STYLE 5: FREE JAZZ - Controlled Chaos with Structured Randomness
// ============================================================================
// Tony Oxley/Sunny Murray style - swirling, dense, but with intentional peaks

(
"FREE JAZZ MODE - Controlled chaos...".postln;

// Track 1: Ride cymbal swirl (high density brownian motion)
Pdef(\jazz1, Pbind(
	\type, \set,
	\id, ~trackManager.getTrack(0).grainSynth.nodeID,
	\dur, Pwhite(0.05, 0.15), // Irregular timing
	\amp, Pwhite(0.2, 0.7) * Pseg(Pseq([0.4, 1.0, 0.6, 0.9], inf), 2), // Swells
	\position, Pbrown(0.6, 1.0, 0.02, inf), // Wander through cymbal zone
	\grainSize, Pwhite(0.02, 0.08),
	\pitch, Pwhite(2.0, 4.0), // High shimmer
	\overlap, Pwhite(16, 48).round // Varying density
)).play;

// Track 2: Snare rolls and hits (clustered bursts)
Pdef(\jazz2, Pbind(
	\type, \set,
	\id, ~trackManager.getTrack(1).grainSynth.nodeID,
	\dur, Prand([
		Pseq([0.0625] ! 8), // Fast roll
		Pseq([0.25, 0.25, 0.5]), // Hits
		Pseq([0.125] ! 4), // Medium roll
		1.0 // Rest
	], inf),
	\amp, Pwhite(0.5, 0.95) * Prand([1, 1, 1, 0.3], inf), // Some soft hits
	\position, Pwhite(0.3, 0.6),
	\grainSize, Pwhite(0.06, 0.15),
	\pitch, Pwhite(0.9, 1.5)
)).play;

// Track 3: Tom hits (sparse but violent)
Pdef(\jazz3, Pbind(
	\type, \set,
	\id, ~trackManager.getTrack(3).grainSynth.nodeID,
	\dur, Prand([1, 2, 0.5, 3, 0.75], inf), // Unpredictable spacing
	\amp, Pwhite(0.7, 1.0),
	\position, Pwhite(0.1, 0.4), // Lower tom range
	\grainSize, Pwhite(0.1, 0.25),
	\pitch, Pwhite(0.5, 1.0),
	\prob, 0.7 // Sometimes drops out completely
)).play;

// Track 4: Kick punctuation (rare accents)
Pdef(\jazz4, Pbind(
	\type, \set,
	\id, ~trackManager.getTrack(3).grainSynth.nodeID,
	\dur, Pwhite(0.5, 2.5),
	\amp, Prand([0, 0, 0, 0.9, 0, 0.8], inf), // Sparse
	\position, 0.05,
	\grainSize, 0.2,
	\pitch, 0.5
)).play;
)

// Stop Jazz
Pdef(\jazz1).stop; Pdef(\jazz2).stop; Pdef(\jazz3).stop; Pdef(\jazz4).stop;


// ============================================================================
// MEGA STOP - Kill all patterns
// ============================================================================

(
[\aphex1, \aphex2, \aphex3, \aphex4,
 \african1, \african2, \african3, \african4,
 \indian1, \indian2, \indian3, \indian4,
 \house1, \house2, \house3, \house4,
 \jazz1, \jazz2, \jazz3, \jazz4].do { |name|
	Pdef(name).stop;
};
"All rhythm patterns stopped.".postln;
)



// ============================================================================
// PERFORMANCE TIPS
// ============================================================================

/*

LOADING SAMPLES:
- Load different samples into each track for best results
- Percussion samples work best (drums, cymbals, found sounds)
- Example: Track 1 = kick, Track 2 = snare, Track 3 = hi-hat, Track 4 = cymbal

MIXING:
- Adjust track amp parameters before starting patterns
- Use Track Manager to set base volume for each track
- Consider enabling filters for tonal shaping

EFFECTS:
- Minimal House: Add reverb to Track 2 (hi-hats) and Track 4 (claps)
- Aphex Twin: Distortion on Track 3, shimmer on Track 2
- African Drums: Keep mostly dry, slight reverb on Track 2 (bell)
- Indian Classical: Reverb on Track 4 (drone), dry tabla on 1-3
- Free Jazz: Heavy reverb on Track 1 (cymbal), compression on Track 2

TRANSITIONING:
- Stop one style, wait a beat, start another
- Or overlap them for chaotic polyrhythmic madness
- Use probability parameters to gradually introduce new patterns

MODULATION:
- Route LFO to 'position' for automatic sample scanning
- Route Envelope Follower from Track 1 to Track 2 'amp' for ducking
- Use Random modulator on 'pitch' for evolving timbre

LIVE TWEAKING:
- Change \dur values in running patterns for speed variation
- Adjust probability values for more/less density
- Swap Euclidean parameters: try (9,16), (13,16), (11,24)

CUSTOM PATTERNS:
- Use ~euclidean.value(hits, steps) to generate new patterns
- Try ~glitchPattern.value(length, density) for random variations
- Combine patterns with ~polyrhythm.value(pattern1, pattern2)

*/
