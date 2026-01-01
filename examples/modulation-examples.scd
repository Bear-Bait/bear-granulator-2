/*
S-4 RIVAL - MODULATION SYSTEM EXAMPLES
Phase 5 - Practical Modulation Demonstrations

Prerequisites:
1. Run BOOT-SERVER.scd
2. Run main.scd
3. Load an audio file on Track 1

These examples show how to use the modulation system via code.
You can also use the GUI by clicking the "MOD" button on any track.
*/

// ============================================
// EXAMPLE 1: LFO Modulating Grain Size
// ============================================
(
// Create an LFO on Track 1, Modulator 1
~trackManager.createModulator(
	trackNum: 0,      // Track 1
	modNum: 0,        // Modulator 1
	type: 0,          // LFO
	rate: 0.5,        // 0.5 Hz (slow)
	depth: 1.0,       // Full depth
	shape: 0          // Sine wave
);

// Route it to grain size (0.05 - 0.5 seconds)
~trackManager.routeModulator(
	trackNum: 0,
	modNum: 0,
	targetParam: \grainSize,
	minVal: 0.05,
	maxVal: 0.5
);

"Example 1: LFO slowly modulating grain size".postln;
)

// ============================================
// EXAMPLE 2: Fast Random Modulating Position
// ============================================
(
// Create random modulator on Track 1, Modulator 2
~trackManager.createModulator(
	trackNum: 0,
	modNum: 1,
	type: 2,          // Random
	rate: 8,          // 8 Hz (fast)
	depth: 1.0,
	shape: 0          // Stepped random
);

// Route to playback position (0 - 1 across buffer)
~trackManager.routeModulator(
	trackNum: 0,
	modNum: 1,
	targetParam: \position,
	minVal: 0.0,
	maxVal: 1.0
);

"Example 2: Fast random position jumping".postln;
)

// ============================================
// EXAMPLE 3: LFO Modulating Pitch
// ============================================
(
// Create triangle LFO on Track 1, Modulator 3
~trackManager.createModulator(
	trackNum: 0,
	modNum: 2,
	type: 0,          // LFO
	rate: 0.25,       // 0.25 Hz (very slow)
	depth: 1.0,
	shape: 1          // Triangle wave
);

// Route to pitch (-12 to +12 semitones)
~trackManager.routeModulator(
	trackNum: 0,
	modNum: 2,
	targetParam: \pitch,
	minVal: -12,
	maxVal: 12
);

"Example 3: Slow triangle LFO pitch sweep".postln;
)

// ============================================
// EXAMPLE 4: Envelope Follower on Density
// ============================================
(
// Create envelope follower on Track 1, Modulator 4
~trackManager.createModulator(
	trackNum: 0,
	modNum: 3,
	type: 1,          // Envelope Follower
	rate: 1.0,        // Response time
	depth: 1.0,
	shape: 0
);

// Route to density (10 - 100 grains/sec)
~trackManager.routeModulator(
	trackNum: 0,
	modNum: 3,
	targetParam: \density,
	minVal: 10,
	maxVal: 100
);

"Example 4: Input amplitude controls grain density".postln;
"(Record or play audio for this to work)".postln;
)

// ============================================
// STOP ALL MODULATORS
// ============================================
(
4.do({ arg modNum;
	~trackManager.freeModulator(0, modNum);
});
"All Track 1 modulators freed".postln;
)

// ============================================
// CREATIVE COMBINATIONS
// ============================================

// Slow evolving texture
(
// LFO 1: Slow grain size sweep
~trackManager.createModulator(0, 0, 0, 0.1, 1.0, 0);
~trackManager.routeModulator(0, 0, \grainSize, 0.05, 0.3);

// LFO 2: Medium stereo spread modulation
~trackManager.createModulator(0, 1, 0, 0.3, 1.0, 1);
~trackManager.routeModulator(0, 1, \stereoSpread, 0.1, 0.9);

// Random 3: Position jitter amount
~trackManager.createModulator(0, 2, 2, 2, 1.0, 1);
~trackManager.routeModulator(0, 2, \posJitter, 0.0, 0.5);

"Creative Combo: Slow evolving granular texture".postln;
)

// Rhythmic granular pattern
(
// Square wave LFO on density
~trackManager.createModulator(0, 0, 0, 2, 1.0, 3);  // 2 Hz square
~trackManager.routeModulator(0, 0, \density, 5, 80);

// Fast sine on pitch
~trackManager.createModulator(0, 1, 0, 4, 0.5, 0);  // 4 Hz sine
~trackManager.routeModulator(0, 1, \pitch, -5, 5);

"Creative Combo: Rhythmic granular pattern".postln;
)

// ============================================
// MODULATION PARAMETER REFERENCE
// ============================================
/*
Modulator Types:
  0 = LFO
  1 = Envelope Follower
  2 = Random
  3 = Envelope (triggered)

LFO Shapes:
  0 = Sine
  1 = Triangle
  2 = Sawtooth
  3 = Square
  4 = Smooth Random (LFNoise1)
  5 = Stepped Random (LFNoise0)

Random Shapes:
  0 = Stepped
  1 = Smooth

Common Target Parameters:
  \grainSize      (0.001 - 60 seconds)
  \density        (1 - 200 grains/sec)
  \position       (0 - 1 normalized)
  \pitch          (-24 to +24 semitones)
  \posJitter      (0 - 1)
  \pitchJitter    (0 - 12 semitones)
  \stereoSpread   (0 - 1)
  \filterFreq     (20 - 2000 Hz)
  \filterMorph    (0 - 1, LP→BP→HP)
  \reverbMix      (0 - 1)
  \delayMix       (0 - 1)

Rate Ranges:
  LFO: 0.01 - 20 Hz
  Envelope Follower: smoothing time
  Random: 0.01 - 20 Hz update rate
*/
