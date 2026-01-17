/*
TEST LONG GRAIN PLAYBACK
Diagnose the feedback/looping issue when grain size matches buffer length

The problem: When grain size = buffer length, we should hear the full audio
loop cleanly, but instead we get tiny fragments and feedback.

Hypothesis: Too many overlapping grains causing buildup
*/

(
fork {
	var testBuf, testSynth;

	"=== TESTING LONG GRAIN PLAYBACK ===".postln;

	// Load your test file
	testBuf = Buffer.read(s, "/Users/forrestmuelrath/Documents/supercollider/sounds/a11wlk01-44_1.aiff");

	s.sync; // Wait for buffer to load

	("Buffer loaded: " ++ testBuf.numFrames ++ " frames = " ++
	 (testBuf.numFrames / s.sampleRate).round(0.01) ++ " seconds").postln;

	1.wait;

	// === TEST 1: Long grains with HIGH density (current behavior - BAD) ===
	"".postln;
	"[TEST 1] Grain size = 2.7s, Density = 20 (CURRENT SETTINGS - SHOULD FAIL)".postln;
	"Expected: Feedback/artifacts from too many overlapping grains".postln;

	testSynth = Synth(\bearulatorGrainEngine, [
		\bufnum, testBuf,
		\mode, 0,  // TAPE mode
		\grainSize, 2.7,  // Match your buffer length
		\density, 20,     // Default density
		\position, 0.5,
		\amp, 0.3,  // Lower volume to prevent clipping
		\stereoSpread, 0
	]);

	5.wait;
	testSynth.free;

	// === TEST 2: Long grains with LOW density (should work better) ===
	"".postln;
	"[TEST 2] Grain size = 2.7s, Density = 1 (LOW DENSITY - SHOULD WORK)".postln;
	"Expected: Clean playback of full audio file".postln;

	testSynth = Synth(\bearulatorGrainEngine, [
		\bufnum, testBuf,
		\mode, 0,
		\grainSize, 2.7,
		\density, 1,      // Only 1 grain per second
		\position, 0.5,
		\amp, 0.3,
		\stereoSpread, 0
	]);

	5.wait;
	testSynth.free;

	// === TEST 3: Calculate safe density for grain size ===
	"".postln;
	"[TEST 3] Auto-calculated density for 2.7s grains".postln;

	// Rule: For clean playback, density should not exceed (1 / grainSize)
	// For 2.7s grains: max density = 1/2.7 = 0.37 grains/sec
	var safeGrainSize = 2.7;
	var safeDensity = (1.0 / safeGrainSize).min(10); // Cap at 10

	("Safe density for %.2fs grains = %.2f grains/sec".format(safeGrainSize, safeDensity)).postln;

	testSynth = Synth(\bearulatorGrainEngine, [
		\bufnum, testBuf,
		\mode, 0,
		\grainSize, safeGrainSize,
		\density, safeDensity,
		\position, 0.5,
		\amp, 0.3,
		\stereoSpread, 0
	]);

	5.wait;
	testSynth.free;

	// Cleanup
	testBuf.free;

	"".postln;
	"=== TEST COMPLETE ===".postln;
	"Did TEST 2 or 3 sound better than TEST 1?".postln;
	"If yes, the issue is density being too high for long grains.".postln;
}
)
