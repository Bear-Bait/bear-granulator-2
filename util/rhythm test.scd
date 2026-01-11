///Attempting make the my grain samples into beats.


//1. The "Modular" Approach (Signal-Rate Triggering)
//Instead of telling the synth to play a note from the language, you build the rhythm generator inside the SynthDef. This is how modular /synths work and produces the tightest, glitchiest timing.

//How it works: You replace a steady Impulse.ar (which makes a buzz or tone) with a dynamic trigger system.

//The Glitch Factor: Use Dust.ar (random impulses) or mix Impulse.ar with LFNoise0 to randomly change the speed of the grains.

//Key UGens: Impulse.kr, Dust.kr, Stepper.kr, Select.kr.

//Vibe: Unpredictable, organic, fizzing, Geiger-counter textures.

// 1. The Synth (One-shot grain cloud)
SynthDef(\grainHit, { |out=0, buf, pos=0, dur=0.1, pitch=1|
    var env = EnvGen.kr(Env.perc(0.01, dur), doneAction: 2); // Percussive envelope
    var grains = GrainBuf.ar(2, Impulse.ar(50), 0.1, buf, pitch, pos);
    Out.ar(out, grains * env);
}).add;

// 2. The Sequence (Pbind)
Pbind(
    \instrument, \grainHit,
    \dur, 0.25,  // 16th notes
    \pos, Pseq([0.1, 0.2, 0.1, 0.5], inf), // Change sample position per beat
    \pitch, Pseq([0.5, 1, 0.5, 2], inf)    // Pitch shift per beat
).play;


// (`-')  _                                _     _(`-')    (`-')  _(`-')  _
//( OO).-/     .->    _           <-.    (_)   ( (OO ).-> ( OO).-/(OO ).-/
//(,------.,--.(,--.   \-,-----. ,--. )   ,-(`-')\    .'_ (,------./ ,---.
// |  .---'|  | |(`-')  |  .--./ |  (`-') | ( OO)'`'-..__) |  .---'| \ /`.\
//(|  '--. |  | |(OO ) /_) (`-') |  |OO ) |  |  )|  |  ' |(|  '--. '-'|_.' |
// |  .--' |  | | |  \ ||  |OO )(|  '__ |(|  |_/ |  |  / : |  .--'(|  .-.  |
// |  `---.\  '-'(_ .'(_'  '--'\ |     |' |  |'->|  '-'  / |  `---.|  | |  |
// `------' `-----'      `-----' `-----'  `--'   `------'  `------'`--' `--'

(
~euclidean = { |hits, steps|
	var res = 0 ! steps;
	var current = 0;
	// The Bjorklund/Bresenham algorithm
	hits.do {
		res[current.floor] = 1;
		current = current + (steps / hits);
	};
	res
};
)

(
// 1. Generate the pattern (e.g., 3 hits in 8 steps = "Tresillo" / Reggaeton)
var pattern = ~euclidean.value(3, 8); // Try changing to (5, 16) or (7, 12)

"Rhythm Array: %".format(pattern).postln;

// 2. Play it against Track 1
Pdef(\euclid, Pbind(
	\type, \set,
	\id, ~trackManager.getTrack(0).grainSynth.nodeID, // Target Track 1
	\dur, 0.125, // Speed (16th notes)

	// The Gate: 1 = Loud, 0 = Silent
	// We use 'amp' so it works even without the 'prob' code
	\amp, Pseq(pattern, inf) * 0.5
)).play;
)


(
// =====================================================================
// 1. THE BRAIN: EUCLIDEAN CALCULATOR
// =====================================================================
~euclidean = { |hits, steps|
	var res = 0 ! steps;
	var current = 0;
	// The Bjorklund Algorithm: Distributes hits as evenly as possible
	hits.do {
		res[current.floor] = 1;
		current = current + (steps / hits);
	};
	res
};

// =====================================================================
// 2. THE CHEATSHEET (Copy numbers from here into the code below)
// =====================================================================
// (4, 16) -> Techno / Motorik (Straight 4/4)
// (3, 8)  -> Tresillo (Reggaeton / Dancehall)
// (5, 16) -> Bossa Nova (Classic House Clave)
// (2, 5)  -> Take Five (Dave Brubeck style 5/4)
// (5, 8)  -> Cinquillo (Cuban / Dense syncopation)
// (7, 12) -> West African Bell (Complex 12/8 polyrhythm)
// (9, 16) -> Jeff Mills (Driving Techno off-beats)
// =====================================================================

"Starting 4-Track Polyrhythm Engine...".postln;

// =====================================================================
// TRACK 1: THE FOUNDATION (Techno Kick)
// Pattern: 4 hits in 16 steps (Steady Pulse)
// =====================================================================
Pdef(\rhythmTrack1, Pbind(
	\type, \set,
	\id, ~trackManager.getTrack(0).grainSynth.nodeID, // Target Track 1
	\dur, 0.125, // 16th notes

	// The Logic: Generates [1, 0, 0, 0, 1, 0, 0, 0...]
	\amp, Pseq(~euclidean.value(4, 16), inf) * 0.8
)).play;


// =====================================================================
// TRACK 2: THE SYNCOPATION (Tresillo)
// Pattern: 3 hits in 8 steps (Reggaeton feel)
// This pattern is shorter (8 steps) so it loops twice as often
// =====================================================================
Pdef(\rhythmTrack2, Pbind(
	\type, \set,
	\id, ~trackManager.getTrack(1).grainSynth.nodeID, // Target Track 2
	\dur, 0.125,

	// ROTATION TRICK: .rotate(1) shifts the start so it doesn't clash with the kick
	\amp, Pseq(~euclidean.value(3, 8).rotate(1), inf) * 0.6
)).play;


// =====================================================================
// TRACK 3: THE POLYRHYTHM (African Bell)
// Pattern: 7 hits in 12 steps (3 over 4 feel)
// This length (12) will drift against the 16-step patterns
// =====================================================================
Pdef(\rhythmTrack3, Pbind(
	\type, \set,
	\id, ~trackManager.getTrack(2).grainSynth.nodeID, // Target Track 3
	\dur, 0.125,

	\amp, Pseq(~euclidean.value(7, 12), inf) * 0.5
)).play;


// =====================================================================
// TRACK 4: THE HYPER-GLITCH (Fast & Sparse)
// Pattern: 5 hits in 16 steps (Bossa) running at DOUBLE SPEED
// =====================================================================
Pdef(\rhythmTrack4, Pbind(
	\type, \set,
	\id, ~trackManager.getTrack(3).grainSynth.nodeID, // Target Track 4

	// DOUBLE TIME: 0.0625 = 32nd notes (Fast ratchets)
	\dur, 0.0625,

	\amp, Pseq(~euclidean.value(5, 16), inf) * 0.4
)).play;
)


(
// 1. Same Pattern (Tresillo)
var pattern = ~euclidean.value(3, 8);

"Rhythm Array: %".format(pattern).postln;

// 2. Play it FAST
Pdef(\euclid, Pbind(
	\type, \set,
	\id, ~trackManager.getTrack(1).grainSynth.nodeID,

	// DOUBLE TIME LOGIC:
	// Normal 16th notes = 0.25
	// Double time (32nd notes) = 0.125
	// Hyper speed = 0.0625
	\dur, 0.0625,

	\amp, Pseq(pattern, inf) * 0.5
)).play;
)


(
// 1. Generate the Euclidean Pattern (e.g., 5 hits in 16 steps = Bossa Nova)
var pattern = ~euclidean.value(5, 16);

"Rhythm Array: %".format(pattern).postln;

// 2. Play it controlling PROBABILITY
Pdef(\euclidProb, Pbind(
    \type, \set,
    \id, ~trackManager.getTrack(0).grainSynth.nodeID, // Target Track 1
    \dur, 0.125, // Speed (16th notes)

    // THE SWAP: Control 'prob' instead of 'amp'
    // 1 = Full Density (Solid beat)
    // 0 = Zero Probability (Silence/Rest)
    // We multiply by 1.0 to ensure it sends float values
    \prob, Pseq(pattern, inf) * 1.0
)).play;
)

(
// 1. SAFETY: Wake up all tracks first (Set volume to 0.5)
// This fixes the "Stuck Switch" issue where other tracks stayed silent
4.do({ |i| ~trackManager.setVolume(i, 0.5); });

"✓ Tracks Woken Up. Starting Rhythm on Track 3...".postln;

// 2. THE RHYTHM (Track 3 - African Bell Pattern)
Pdef(\rhythmTrack3, Pbind(
    \type, \set,
    \id, ~trackManager.getTrack(2).grainSynth.nodeID, // Target Track 3
    \dur, 0.125, // Speed

    // Pattern: 7 hits in 12 steps (Classic 12/8 Polyrhythm)
    // Uses \amp (Volume gating)
    \amp, Pseq(~euclidean.value(7, 12), inf) * 0.5
)).play;
)

Pdef(\rhythmTrack).stop; // Stops only Track 4's rhythm
Pdef(\rhythmTrack1).stop; // Stops Track 1
Pdef.removeAll; //alll

///this is the best patern I have.
(
// =====================================================================
// 0. SETUP: DEFINE MATH & WAKE UP TRACKS
// =====================================================================
~euclidean = { |hits, steps|
	var res = 0 ! steps;
	var current = 0;
	hits.do {
		res[current.floor] = 1;
		current = current + (steps / hits);
	};
	res
};

// SAFETY: Reset all volumes to 0.5 so tracks aren't "stuck" at silent
4.do({ |i| ~trackManager.setVolume(i, 0.5); });
"✓ Tracks initialized. Starting 4-Track Rhythm Engine...".postln;


// =====================================================================
// TRACK 1: YOUR CODE (Tresillo / Reggaeton)
// Pattern: 3 hits in 8 steps
// =====================================================================
Pdef(\euclid1, Pbind(
	\type, \set,
	\id, ~trackManager.getTrack(0).grainSynth.nodeID, // Target Track 1
	\dur, 0.125, // Speed (16th notes)

	// The Gate: 1 = Loud, 0 = Silent
	\amp, Pseq(~euclidean.value(3, 8), inf) * 0.5
)).play;


// =====================================================================
// TRACK 2: THE ANCHOR (Techno Kick)
// Pattern: 4 hits in 16 steps (Steady Pulse)
// =====================================================================
Pdef(\euclid2, Pbind(
	\type, \set,
	\id, ~trackManager.getTrack(1).grainSynth.nodeID, // Target Track 2
	\dur, 0.125,

	\amp, Pseq(~euclidean.value(4, 16), inf) * 0.5
)).play;


// =====================================================================
// TRACK 3: THE POLYRHYTHM (African Bell)
// Pattern: 7 hits in 12 steps (Drifts against the others)
// =====================================================================
Pdef(\euclid3, Pbind(
	\type, \set,
	\id, ~trackManager.getTrack(2).grainSynth.nodeID, // Target Track 3
	\dur, 0.125,

	\amp, Pseq(~euclidean.value(7, 12), inf) * 0.5
)).play;


// =====================================================================
// TRACK 4: THE GLITCH (Double Time)
// Pattern: 5 hits in 16 steps (Bossa) running FAST
// =====================================================================
Pdef(\euclid4, Pbind(
	\type, \set,
	\id, ~trackManager.getTrack(3).grainSynth.nodeID, // Target Track 4
	\dur, 0.0625, // 32nd notes (Double Speed)

	// Lower volume (0.3) for the background texture
	\amp, Pseq(~euclidean.value(5, 16), inf) * 0.3
)).play;
)

(
// 1. CREATE THE MASTER CLOCK
// 130 BPM (Beats Per Minute) / 60 seconds
t = TempoClock(130/60);

// 2. DEFINE THE MATH (Euclidean)
~euclidean = { |hits, steps|
	var res = 0 ! steps;
	var current = 0;
	hits.do {
		res[current.floor] = 1;
		current = current + (steps / hits);
	};
	res
};

// 3. WAKE UP TRACKS (Volume Safety)
4.do({ |i| ~trackManager.setVolume(i, 0.5); });

"✓ Master Clock Running at 130 BPM".postln;

// ============================================================
// TRACK 1: THE KICK (Techno) - Controls PROB (Texture) THIS IS NOT GOOD. TRYING TO LEARN HOW TO CLOCK The beats WOULD like to sequence with melodies from the patern libary.
// ============================================================
Pdef(\track1, Pbind(
	\type, \set,
	\id, ~trackManager.getTrack(0).grainSynth.nodeID,
	\dur, 0.25, // Quarter notes
	// 'quant' locks it to the next beat so they start together

	// RHYTHM: 4 hits in 16 steps (Kick on every beat)
	\prob, Pseq(~euclidean.value(4, 16), inf)
)).play(t, quant: 1); // <--- PLAY ON CLOCK 't'


// ============================================================
// TRACK 2: THE SNARE/CLAP (Tresillo) - Controls AMP (Volume)
// ============================================================
Pdef(\track2, Pbind(
	\type, \set,
	\id, ~trackManager.getTrack(1).grainSynth.nodeID,
	\dur, 0.25,

	// RHYTHM: 3 hits in 8 steps, rotated to be off-beat
	\amp, Pseq(~euclidean.value(3, 8).rotate(1), inf) * 0.5
)).play(t, quant: 1);


// ============================================================
// TRACK 3: THE HI-HATS (Fast) - Controls PROB
// ============================================================
Pdef(\track3, Pbind(
	\type, \set,
	\id, ~trackManager.getTrack(2).grainSynth.nodeID,
	\dur, 0.125, // 8th notes (Faster)

	// RHYTHM: Continuous stream with random dropouts
	\prob, Pseq([1, 1, 1, 0, 1, 1, 0, 1], inf)
)).play(t, quant: 1);

)

Pdef.removeAll;