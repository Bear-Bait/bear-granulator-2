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
// 1. Same Pattern (Tresillo)
var pattern = ~euclidean.value(3, 8);

"Rhythm Array: %".format(pattern).postln;

// 2. Play it FAST
Pdef(\euclid, Pbind(
	\type, \set,
	\id, ~trackManager.getTrack(0).grainSynth.nodeID,

	// DOUBLE TIME LOGIC:
	// Normal 16th notes = 0.25
	// Double time (32nd notes) = 0.125
	// Hyper speed = 0.0625
	\dur, 0.0625,

	\amp, Pseq(pattern, inf) * 0.5
)).play;
)