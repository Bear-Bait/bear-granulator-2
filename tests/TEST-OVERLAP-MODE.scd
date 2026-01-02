/*
PHASE 6B OVERLAP MODE TEST
Test the new overlap parameter with full-length grain playback

Your audio file: "columbia this houston over" = 2.44 seconds
Goal: Hear the FULL audio file looping cleanly with grain size = 2.7s

HOW OVERLAP WORKS:
- Overlap = number of simultaneous grains (1-128)
- Density is calculated automatically: density = overlap / grainSize
- For 2.7s grains with overlap=1: density = 1/2.7 = 0.37 grains/sec
- This means grains DON'T pile up and cause feedback!

COMPARISON:
OLD WAY (density mode):
  - Grain size = 2.7s, Density = 20 grains/sec
  - Simultaneous grains = 2.7 × 20 = 54 grains overlapping
  - Result: FEEDBACK, artifacts, chaos

NEW WAY (overlap mode):
  - Grain size = 2.7s, Overlap = 1
  - Density auto-calculated = 1/2.7 = 0.37 grains/sec
  - Simultaneous grains = exactly 1 (clean!)
  - Result: CLEAN playback of full audio file
*/

(
fork {
	var testBuf, testSynth;

	"=== PHASE 6B OVERLAP MODE TEST ===".postln;
	"".postln;

	// Load your Houston audio file
	testBuf = Buffer.read(s, "/Users/forrestmuelrath/Documents/supercollider/sounds/a11wlk01-44_1.aiff");

	s.sync; // Wait for buffer to load

	("Buffer loaded: " ++ (testBuf.numFrames / s.sampleRate).round(0.01) ++ " seconds").postln;
	"".postln;

	1.wait;

	// === TEST 1: Overlap = 1 (single grain, full audio) ===
	"[TEST 1] Overlap = 1 (one grain at a time)".postln;
	"Grain Size: 2.7s (longer than buffer for smooth looping)".postln;
	"Expected: Clean playback of full \"columbia this houston over\"".postln;
	"".postln;

	testSynth = Synth(\s4GrainEngine, [
		\bufnum, testBuf,
		\mode, 0,          // TAPE mode
		\grainSize, 2.7,   // Longer than buffer
		\overlap, 1,       // ONE grain at a time
		\useOverlap, 1,    // Use overlap mode (not density)
		\position, 0.5,
		\amp, 0.4,
		\stereoSpread, 0,
		\posJitter, 0,     // No jitter for clean test
		\pitchJitter, 0
	]);

	8.wait;
	testSynth.free;
	1.wait;

	// === TEST 2: Overlap = 2 (two overlapping grains) ===
	"".postln;
	"[TEST 2] Overlap = 2 (two grains overlapping)".postln;
	"Expected: Slightly denser, smoother transitions".postln;
	"".postln;

	testSynth = Synth(\s4GrainEngine, [
		\bufnum, testBuf,
		\mode, 0,
		\grainSize, 2.7,
		\overlap, 2,       // TWO grains overlapping
		\useOverlap, 1,
		\position, 0.5,
		\amp, 0.4,
		\stereoSpread, 0,
		\posJitter, 0,
		\pitchJitter, 0
	]);

	8.wait;
	testSynth.free;
	1.wait;

	// === TEST 3: Overlap = 8 (denser, more granular) ===
	"".postln;
	"[TEST 3] Overlap = 8 (denser grain cloud)".postln;
	"Expected: Thicker texture, more \"granular\" sound".postln;
	"".postln;

	testSynth = Synth(\s4GrainEngine, [
		\bufnum, testBuf,
		\mode, 0,
		\grainSize, 2.7,
		\overlap, 8,       // EIGHT grains overlapping
		\useOverlap, 1,
		\position, 0.5,
		\amp, 0.3,         // Lower volume to prevent buildup
		\stereoSpread, 0.3,
		\posJitter, 0.05,  // Add slight jitter
		\pitchJitter, 0
	]);

	8.wait;
	testSynth.free;
	1.wait;

	// === TEST 4: Short grains with overlap (classic granular) ===
	"".postln;
	"[TEST 4] Short grains (50ms) with Overlap = 4".postln;
	"Expected: Classic granular texture".postln;
	"".postln;

	testSynth = Synth(\s4GrainEngine, [
		\bufnum, testBuf,
		\mode, 0,
		\grainSize, 0.05,  // 50ms grains
		\overlap, 4,       // 4 grains overlapping
		\useOverlap, 1,    // density = 4/0.05 = 80 grains/sec
		\position, 0.5,
		\amp, 0.4,
		\stereoSpread, 0.5,
		\posJitter, 0.1,
		\pitchJitter, 2
	]);

	8.wait;
	testSynth.free;

	// Cleanup
	testBuf.free;

	"".postln;
	"=== TEST COMPLETE ===".postln;
	"".postln;
	"Did you hear the full \"columbia this houston over\" phrase in TEST 1?".postln;
	"If YES, the overlap mode is working correctly!".postln;
	"".postln;
	"USAGE TIP:".postln;
	"- For full-length playback: Set grain size >= buffer length, overlap = 1-2".postln;
	"- For granular texture: Set grain size small (10-100ms), overlap = 2-8".postln;
	"- For dense clouds: Increase overlap to 16-64".postln;
}
)
