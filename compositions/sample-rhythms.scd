// SAMPLE RHYTHMS - Trigger actual audio files instead of granular modulation
// Created for BEARULATOR Bearulator
// Uses Dirt-Samples and Tone.js instruments

// ============================================================================
// SAMPLE LOADER - Run this first to load samples into buffers
// ============================================================================

(
~samples = ();  // Dictionary to store all sample buffers

// Helper function to load all samples from a directory
~loadSampleFolder = { |path, name|
	var files = (path +/+ "*.wav").pathMatch ++ (path +/+ "*.WAV").pathMatch;
	if(files.size > 0, {
		~samples[name] = files.collect({ |file|
			Buffer.read(s, file);
		});
		"Loaded % samples: %".format(files.size, name).postln;
	}, {
		"No samples found in: %".format(path).postln;
	});
};

// Wait for server and load samples
fork {
	s.sync;

	// Load 808 drums
	~loadSampleFolder.value(
		"/Users/forrestmuelrath/Documents/supercollider/granular/samples/Dirt-Samples/808bd",
		\kick
	);
	~loadSampleFolder.value(
		"/Users/forrestmuelrath/Documents/supercollider/granular/samples/Dirt-Samples/808sd",
		\snare
	);
	~loadSampleFolder.value(
		"/Users/forrestmuelrath/Documents/supercollider/granular/samples/Dirt-Samples/808hc",
		\hat
	);
	~loadSampleFolder.value(
		"/Users/forrestmuelrath/Documents/supercollider/granular/samples/Dirt-Samples/808oh",
		\openhat
	);
	~loadSampleFolder.value(
		"/Users/forrestmuelrath/Documents/supercollider/granular/samples/Dirt-Samples/808cy",
		\cymbal
	);
	~loadSampleFolder.value(
		"/Users/forrestmuelrath/Documents/supercollider/granular/samples/Dirt-Samples/amencutup",
		\amen
	);

	// Load melodic samples (first note of each instrument)
	~loadSampleFolder.value(
		"/Users/forrestmuelrath/Documents/supercollider/granular/samples/tonejs-instruments/samples/piano",
		\piano
	);
	~loadSampleFolder.value(
		"/Users/forrestmuelrath/Documents/supercollider/granular/samples/tonejs-instruments/samples/xylophone",
		\xylophone
	);

	s.sync;
	"Sample loading complete!".postln;
	"Available kits: %".format(~samples.keys.asArray.sort).postln;
};
)

// ============================================================================
// SAMPLE PLAYER SYNTHDEF - One-shot playback with pitch/filter/envelope
// ============================================================================

(
SynthDef(\samplePlayer, { |out=0, buf=0, amp=0.5, pan=0, rate=1,
	                       attack=0.001, release=0.2,
	                       filterFreq=18000, resonance=0.1|
	var sig, env, filt;

	// Playback with pitch control
	sig = PlayBuf.ar(1, buf, rate * BufRateScale.kr(buf), doneAction: 2);

	// Filter (optional)
	filt = MoogFF.ar(sig, filterFreq.clip(20, 18000), resonance);
	sig = SelectX.ar(K2A.ar((filterFreq < 18000).asInteger), [sig, filt]);

	// Envelope
	env = EnvGen.kr(Env.perc(attack, release), doneAction: 2);

	Out.ar(out, Pan2.ar(sig * env * amp, pan));
}).add;

"SynthDef \\samplePlayer loaded.".postln;
)

// ============================================================================
// RHYTHM GENERATORS (reuse from wild-rhythms)
// ============================================================================

(
~euclidean = { |hits, steps|
	var res = 0 ! steps;
	var current = 0;
	hits.do {
		res[current.floor] = 1;
		current = current + (steps / hits);
	};
	res
};

~glitchPattern = { |length, density=0.5|
	Array.fill(length, { |i|
		if(density.coin, { [1, 0.7, 0.3, 0].choose }, { 0 })
	})
};

"Rhythm generators loaded.".postln;
)

// ============================================================================
// STYLE 1: APHEX TWIN - 808 Drums with Glitch Rhythms
// ============================================================================

(
"APHEX TWIN SAMPLE MODE - Launching glitch beats...".postln;

// Track 1: Kick with irregular timing
Pdef(\aphexKick, Pbind(
	\instrument, \samplePlayer,
	\buf, Prand(~samples[\kick], inf),  // Random sample variation
	\dur, Pseq([0.25, 0.125, 0.375, 0.25, 0.125], inf),
	\amp, Pwhite(0.7, 1.0) * Prand([1, 1, 1, 0, 1, 0.5], inf),
	\rate, Pwhite(0.9, 1.1),  // Slight pitch variation
	\pan, Pwhite(-0.3, 0.3),
	\release, Pwhite(0.1, 0.3),
	\out, 0  // Stereo out (not routed through tracks)
)).play;

// Track 2: Snare with Euclidean gate
Pdef(\aphexSnare, Pbind(
	\instrument, \samplePlayer,
	\buf, Prand(~samples[\snare], inf),
	\dur, 0.25,
	\amp, Pseq(~euclidean.value(5, 13), inf) * Pwhite(0.5, 0.8),
	\rate, Pdup(8, Prand([0.8, 1, 1.2, 1.5], inf)),
	\filterFreq, Pseg(Pseq([500, 8000, 2000], inf), 4, \exp),
	\release, 0.15,
	\out, 0
)).play;

// Track 3: Hi-hat rapid fire
Pdef(\aphexHat, Pbind(
	\instrument, \samplePlayer,
	\buf, Prand(~samples[\hat], inf),
	\dur, 0.0625,
	\amp, Pseq(~glitchPattern.value(32, 0.5), inf) * 0.4,
	\rate, Pwhite(1.5, 3.0),
	\release, 0.05,
	\pan, Pwhite(-0.8, 0.8),
	\out, 0
)).play;

// Track 4: Cymbal swells
Pdef(\aphexCymbal, Pbind(
	\instrument, \samplePlayer,
	\buf, Prand(~samples[\cymbal], inf),
	\dur, Pwhite(0.5, 2.0),
	\amp, Pwhite(0.3, 0.6),
	\rate, Pwhite(0.5, 1.5),
	\attack, 0.01,
	\release, Pwhite(0.5, 1.5),
	\filterFreq, Pseg(Pseq([2000, 12000], inf), 2),
	\pan, Pwhite(-1, 1),
	\out, 0
)).play;
)

// Stop Aphex
Pdef(\aphexKick).stop; Pdef(\aphexSnare).stop; Pdef(\aphexHat).stop; Pdef(\aphexCymbal).stop;


// ============================================================================
// STYLE 2: AFRICAN DRUMS - Polyrhythmic 808s
// ============================================================================

(
"AFRICAN DRUMS SAMPLE MODE - Polyrhythmic bells...".postln;

// Timeline (12-beat cycle)
Pdef(\africanTimeline, Pbind(
	\instrument, \samplePlayer,
	\buf, ~samples[\cymbal][0],  // Use specific sample
	\dur, 0.25,
	\amp, Pseq([1, 0, 0, 0.7, 0, 0, 1, 0, 0, 0.7, 0, 0], inf) * 0.5,
	\rate, 2.0,
	\release, 0.1,
	\out, 0
)).play;

// Bell (7 against 12)
Pdef(\africanBell, Pbind(
	\instrument, \samplePlayer,
	\buf, ~samples[\cymbal][1],
	\dur, 0.25,
	\amp, Pseq(~euclidean.value(7, 12), inf) * 0.6,
	\rate, 2.5,
	\release, 0.08,
	\pan, 0.5,
	\out, 0
)).play;

// Talking drum (5 against 16)
Pdef(\africanDrum, Pbind(
	\instrument, \samplePlayer,
	\buf, Prand(~samples[\snare], inf),
	\dur, 0.1875,
	\amp, Pseq(~euclidean.value(5, 16), inf) * Prand([0.5, 0.7, 0.9], inf),
	\rate, Pseq([0.8, 1.0, 1.2], inf),
	\release, 0.12,
	\pan, -0.3,
	\out, 0
)).play;

// Bass drum (tresillo 3/8)
Pdef(\africanBass, Pbind(
	\instrument, \samplePlayer,
	\buf, ~samples[\kick][0],
	\dur, 0.375,
	\amp, Pseq(~euclidean.value(3, 8), inf) * 0.8,
	\rate, 0.8,
	\release, 0.3,
	\out, 0
)).play;
)

// Stop African
Pdef(\africanTimeline).stop; Pdef(\africanBell).stop; Pdef(\africanDrum).stop; Pdef(\africanBass).stop;


// ============================================================================
// STYLE 3: MINIMAL HOUSE - Classic 4/4
// ============================================================================

(
"MINIMAL HOUSE SAMPLE MODE - Deep groove...".postln;

// Kick (4/4)
Pdef(\houseKick, Pbind(
	\instrument, \samplePlayer,
	\buf, ~samples[\kick][0],
	\dur, 1.0,
	\amp, Pseq([0.9, 0.85, 0.88, 0.92], inf),
	\rate, 0.95,
	\release, 0.2,
	\out, 0
)).play;

// Hi-hat (off-beats)
Pdef(\houseHat, Pbind(
	\instrument, \samplePlayer,
	\buf, Prand(~samples[\hat], inf),
	\dur, 0.25,
	\amp, Pseq([
		0, 0.4, 0, 0.5, 0, 0.6, 0, 0.4,
		0, 0.5, 0, 0.7, 0, 0.5, 0, 0.6
	], inf) * Pseg(Pseq([0.6, 0.9, 0.6], inf), 8),
	\rate, Pdup(16, Prand([2, 2.5, 3], inf)),
	\release, 0.04,
	\filterFreq, Pseg(Pseq([8000, 15000], inf), 16),
	\pan, Pwhite(-0.5, 0.5),
	\out, 0
)).play;

// Open hat (Euclidean 11/16)
Pdef(\houseOpen, Pbind(
	\instrument, \samplePlayer,
	\buf, Prand(~samples[\openhat], inf),
	\dur, 0.25,
	\amp, Pseq(~euclidean.value(11, 16), inf) * 0.3,
	\rate, 1.5,
	\release, 0.2,
	\pan, Pwhite(-0.8, 0.8),
	\out, 0
)).play;

// Snare (2 and 4 with ghosts)
Pdef(\houseSnare, Pbind(
	\instrument, \samplePlayer,
	\buf, ~samples[\snare][0],
	\dur, 0.5,
	\amp, Pseq([0, 0.85, Prand([0, 0.2], 1), 0.9], inf),
	\rate, 1.0,
	\release, 0.15,
	\out, 0
)).play;
)

// Stop House
Pdef(\houseKick).stop; Pdef(\houseHat).stop; Pdef(\houseOpen).stop; Pdef(\houseSnare).stop;


// ============================================================================
// STYLE 4: FREE JAZZ - Controlled Chaos
// ============================================================================

(
"FREE JAZZ SAMPLE MODE - Controlled chaos...".postln;

// Cymbal swirl
Pdef(\jazzCymbal, Pbind(
	\instrument, \samplePlayer,
	\buf, Prand(~samples[\cymbal], inf),
	\dur, Pwhite(0.05, 0.15),
	\amp, Pwhite(0.2, 0.6) * Pseg(Pseq([0.4, 1.0, 0.6, 0.9], inf), 2),
	\rate, Pwhite(0.8, 2.0),
	\attack, 0.001,
	\release, Pwhite(0.3, 1.0),
	\pan, Pwhite(-1, 1),
	\out, 0
)).play;

// Snare rolls and hits
Pdef(\jazzSnare, Pbind(
	\instrument, \samplePlayer,
	\buf, Prand(~samples[\snare], inf),
	\dur, Prand([
		Pseq([0.0625] ! 8),  // Fast roll
		Pseq([0.25, 0.25, 0.5]),  // Hits
		Pseq([0.125] ! 4),  // Medium roll
		1.0  // Rest
	], inf),
	\amp, Pwhite(0.5, 0.95) * Prand([1, 1, 1, 0.3], inf),
	\rate, Pwhite(0.9, 1.5),
	\release, Pwhite(0.08, 0.2),
	\pan, Pwhite(-0.5, 0.5),
	\out, 0
)).play;

// Kick punctuation (sparse)
Pdef(\jazzKick, Pbind(
	\instrument, \samplePlayer,
	\buf, Prand(~samples[\kick], inf),
	\dur, Pwhite(0.5, 2.5),
	\amp, Prand([0, 0, 0, 0.9, 0, 0.8], inf),
	\rate, Pwhite(0.7, 1.0),
	\release, 0.3,
	\out, 0
)).play;
)

// Stop Jazz
Pdef(\jazzCymbal).stop; Pdef(\jazzSnare).stop; Pdef(\jazzKick).stop;


// ============================================================================
// STYLE 5: AMEN BREAK - Jungle/DnB
// ============================================================================

(
"AMEN BREAK MODE - Jungle madness...".postln;

// Slice the amen break into pieces
Pdef(\amenSlices, Pbind(
	\instrument, \samplePlayer,
	\buf, Pseq(~samples[\amen], inf),  // Cycle through slices
	\dur, Prand([0.125, 0.0625, 0.25, 0.1875], inf),
	\amp, Pwhite(0.6, 1.0) * Prand([1, 1, 0, 1, 0.5, 1, 1], inf),
	\rate, Prand([1, 2, 0.5, -1, 1.5], inf),  // Reverse and pitch
	\release, Pwhite(0.05, 0.2),
	\filterFreq, Pdup(8, Pwhite(500, 15000)),
	\resonance, 0.3,
	\pan, Pwhite(-0.7, 0.7),
	\out, 0
)).play;

// Add kick reinforcement
Pdef(\amenKick, Pbind(
	\instrument, \samplePlayer,
	\buf, ~samples[\kick][0],
	\dur, Pseq([0.5, 0.25, 0.25, 0.5, 0.5], inf),
	\amp, 0.7,
	\rate, 0.9,
	\release, 0.15,
	\out, 0
)).play;
)

// Stop Amen
Pdef(\amenSlices).stop; Pdef(\amenKick).stop;


// ============================================================================
// MELODIC MODE - Use Tone.js Piano Samples
// ============================================================================

(
"MELODIC MODE - Piano patterns...".postln;

// Simple melodic pattern
Pdef(\melody, Pbind(
	\instrument, \samplePlayer,
	\buf, Prand(~samples[\piano], inf),
	\dur, Pseq([0.5, 0.25, 0.25, 0.5, 0.5], inf),
	\amp, Pwhite(0.3, 0.6),
	\rate, Pseq([
		1.0, 1.189, 1.335, 1.498,  // C D E F#
		1.682, 1.498, 1.335, 1.189  // G# F# E D
	], inf),
	\release, Pwhite(0.3, 0.8),
	\pan, Pwhite(-0.5, 0.5),
	\out, 0
)).play;
)

// Stop Melody
Pdef(\melody).stop;


// ============================================================================
// STYLE 6: BACH INVENTION - Two-Voice Counterpoint on Xylophone
// ============================================================================
// Inspired by Bach's Two-Part Inventions (BWV 772-786)
// Contrapuntal melody with flowing 16th notes and baroque intervals

(
// ALL VAR DECLARATIONS FIRST (SuperCollider requirement)
var bachMelody, bachBass;

"BACH INVENTION MODE - Xylophone counterpoint...".postln;

// Map MIDI note numbers to sample rate multipliers (equal temperament)
~midiToRate = { |midi, baseMidi=60|
	2.pow((midi - baseMidi) / 12.0)
};

// Bach-like melodic sequence (C major scale, typical invention patterns)
// Based on ascending/descending sequences with passing tones
bachMelody = [
	60, 62, 64, 65, 67, 69, 71, 72,  // C D E F G A B C (ascending scale)
	72, 71, 69, 67, 65, 64, 62, 60,  // Descending
	60, 64, 67, 72, 67, 64, 60, 64,  // Arpeggios (C maj)
	62, 65, 69, 74, 69, 65, 62, 65,  // D min arpeggio
	60, 67, 64, 71, 67, 72, 69, 76,  // Sequence pattern
	72, 69, 65, 62, 64, 60, 62, 64,  // Resolution
	65, 62, 64, 65, 67, 64, 65, 67,  // Baroque turn
	69, 67, 65, 64, 62, 64, 65, 67   // Final cadence approach
];

// Counter-melody (lower voice, moves in contrary motion)
bachBass = [
	48, 50, 52, 53, 55, 53, 52, 50,  // Bass voice (octave lower)
	48, 50, 52, 48, 55, 53, 52, 50,  // Counter-motion
	48, 52, 55, 60, 55, 52, 48, 52,  // Bass arpeggios
	50, 53, 57, 62, 57, 53, 50, 53,  // D to A
	48, 55, 52, 59, 55, 60, 57, 64,  // Ascending bass
	60, 57, 53, 50, 52, 48, 50, 52,  // Descending
	53, 50, 52, 53, 55, 52, 53, 55,  // Mirror upper voice
	57, 55, 53, 52, 50, 52, 53, 48   // Cadence (land on C)
];

// Upper voice (right hand) - flowing 16th notes
Pdef(\bachUpper, Pbind(
	\instrument, \samplePlayer,
	\buf, ~samples[\xylophone][0],  // Use first xylophone sample (C5)
	\dur, 0.125,  // 16th notes at moderate tempo
	\midinote, Pseq(bachMelody, inf),
	\rate, Pfunc({ |ev| ~midiToRate.value(ev[\midinote], 60) }),
	\amp, Pseq([0.6, 0.4, 0.5, 0.45, 0.6, 0.4, 0.5, 0.45], inf), // Accent pattern
	\release, 0.15,
	\pan, 0.3,  // Slightly right
	\out, 0
)).play;

// Lower voice (left hand) - eighth notes, more sustained
Pdef(\bachLower, Pbind(
	\instrument, \samplePlayer,
	\buf, ~samples[\xylophone][0],
	\dur, 0.25,  // 8th notes (half speed of upper voice)
	\midinote, Pseq(bachBass, inf),
	\rate, Pfunc({ |ev| ~midiToRate.value(ev[\midinote], 60) }),
	\amp, 0.55,
	\release, 0.25,  // Slightly longer sustain
	\pan, -0.3,  // Slightly left
	\out, 0
)).play;

// Optional: Add ornamental grace notes (baroque trills)
Pdef(\bachOrnament, Pbind(
	\instrument, \samplePlayer,
	\buf, ~samples[\xylophone][0],
	\dur, Pseq([2, 0.0625, 0.0625, 1.75], inf),  // Quick grace notes
	\midinote, Pseq([
		\rest, 71, 72, \rest,  // Quick trill before strong beat
		\rest, 67, 69, \rest,
		\rest, 64, 65, \rest,
		\rest, 71, 72, \rest
	], inf),
	\rate, Pfunc({ |ev|
		if(ev[\midinote] == \rest, { 1.0 }, { ~midiToRate.value(ev[\midinote], 60) })
	}),
	\amp, 0.3,
	\release, 0.05,
	\pan, 0,
	\out, 0
)).play;
)

// Stop Bach
Pdef(\bachUpper).stop; Pdef(\bachLower).stop; Pdef(\bachOrnament).stop;


// ============================================================================
// MEGA STOP - Kill all patterns
// ============================================================================

(
Pdef.all.do(_.stop);
"All sample patterns stopped.".postln;
)


// ============================================================================
// LOAD MORE SAMPLE FOLDERS (Optional)
// ============================================================================

// Add more Dirt-Samples kits as needed:
(
fork {
	s.sync;

	~loadSampleFolder.value(
		"/Users/forrestmuelrath/Documents/supercollider/granular/samples/Dirt-Samples/808lt",
		\lowtom
	);
	~loadSampleFolder.value(
		"/Users/forrestmuelrath/Documents/supercollider/granular/samples/Dirt-Samples/808mt",
		\midtom
	);
	~loadSampleFolder.value(
		"/Users/forrestmuelrath/Documents/supercollider/granular/samples/Dirt-Samples/808ht",
		\hitom
	);

	s.sync;
	"Additional samples loaded.".postln;
};
)


// ============================================================================
// ROUTING TO BEARULATOR TRACKS (Advanced)
// ============================================================================

// Instead of going directly to output, route samples through Bearulator tracks
// This lets you use filters, effects, and spatial positioning

(
// 1. MASTER CLOCK
t = TempoClock(120/60); // 120 BPM

// 2. GET DATA SOURCES
// A. Melody: Get the array from your Library
var melodyArray = ~patternLibrary.generate(\yoshimuraCreek);

// B. Rhythm: Get the array from Euclidean Math
var rhythmArray = ~euclidean.value(5, 16); // Bossa Nova

"Melody Length: % steps".format(melodyArray.size).postln;
"Rhythm Length: % steps".format(rhythmArray.size).postln;

// 3. THE SYNCED SEQUENCER
Pdef(\syncedTrack1, Pbind(
    \type, \set,
    \id, ~trackManager.getTrack(0).grainSynth.nodeID, // Target Track 1
    \dur, 0.25, // 16th notes (The "Grid")

    // --- THE SYNCHRONIZATION ---

    // 1. RHYTHM (Euclidean) -> Controls Probability
    // It loops through the 16-step rhythm array
    \prob, Pseq(rhythmArray, inf),

    // 2. MELODY (Yoshimura) -> Controls Pitch Shift
    // It loops through the 64-step melody array independently
    // but perfectly locked to the same grid step.
    \pitchShift, Pseq(melodyArray, inf),

    // Optional: Reset other jitter to clean up the sound
    \pitchJitter, 0,
    \posJitter, 0
)).play(t, quant: 1);
)

(
// Example: Route samples to Track 1's audio bus
Pdef(\toTrack1, Pbind(
	\instrument, \samplePlayer,
	\buf, Prand(~samples[\kick], inf),
	\dur, 1.0,
	\amp, 0.8,
	\out, ~trackManager.getTrack(0).audioBus.index  // Route to Track 1 bus
)).play;

// Then set Track 1 to DIRECT playback mode (not granular)
// And enable effects as desired
)


// ============================================================================
// PERFORMANCE NOTES
// ============================================================================

/*

SAMPLE MANAGEMENT:
- First time: Run the sample loader section (takes 2-5 seconds)
- Samples stay in memory until you restart SuperCollider
- Check available kits: ~samples.keys

TRIGGERING:
- Each Pdef triggers samples independently (like a drum machine)
- \buf parameter selects which sample buffer to play
- Prand(~samples[\kick], inf) = random sample variation per hit
- ~samples[\kick][0] = specific sample (first in folder)

PITCH/RATE:
- rate: 1.0 = original pitch
- rate: 2.0 = octave up
- rate: 0.5 = octave down
- rate: -1.0 = reversed playback

ENVELOPE:
- attack: fade in time (0.001 = instant)
- release: fade out time (0.05 = short, 1.0 = long)

FILTERING:
- filterFreq: 20-18000 Hz (18000 = bypassed)
- resonance: 0-4 (0.1 = subtle, 0.7 = squelchy)

ROUTING:
- out: 0 = direct to speakers (bypasses Bearulator tracks)
- out: ~trackManager.getTrack(0).audioBus.index = through Track 1 (use effects!)

ADDING YOUR OWN SAMPLES:
- Put WAV files in a folder
- Use ~loadSampleFolder.value("path/to/folder", \myKit)
- Trigger with \buf, ~samples[\myKit]

MIXING APPROACHES:
- Pure samples (this file) = traditional drum machine
- Samples + granular (wild-rhythms.scd) = hybrid approach
- Samples through Bearulator tracks = full effects processing

BACH INVENTION MODE:
- Two-voice counterpoint: upper voice (16th notes) + lower voice (8th notes)
- Ornament voice adds baroque trills on strong beats
- Based on C major scale with typical invention sequences
- Uses ~midiToRate helper to convert MIDI notes to pitch ratios
- Modify bachMelody/bachBass arrays for different melodies
- Try different time signatures: change \dur values (0.125 = 16ths, 0.25 = 8ths)
- Add more voices by duplicating Pdef patterns with different octaves

MELODIC COMPOSITION TIPS:
- Use MIDI note numbers (60 = C4, 72 = C5, etc.)
- Baroque intervals: perfect 5ths (7 semitones), 4ths (5), major 3rds (4)
- Contrary motion: when melody goes up, bass goes down
- Sequences: repeat a pattern at different pitches
- Cadence: end on root note (48 or 60 for C)

*/
