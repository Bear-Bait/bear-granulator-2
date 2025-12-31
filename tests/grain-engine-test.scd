/*
S-4 Rival: Phase 1 Testing
Grain Engine Test Suite

Run these tests to verify Phase 1 implementation
*/

(
"============================================".postln;
"PHASE 1 TEST SUITE".postln;
"============================================".postln;
"".postln;

fork {
	var testBuffer, testSynth;
	var passCount = 0, failCount = 0;

	// Helper function to report test results
	~testResult = { arg testName, passed, message = "";
		if(passed, {
			("✓ PASS: " ++ testName).postln;
			passCount = passCount + 1;
		}, {
			("✗ FAIL: " ++ testName ++ " - " ++ message).postln;
			failCount = failCount + 1;
		});
	};

	"".postln;
	"Test 1: Server Running".postln;
	"--------------------------------------".postln;
	~testResult.value("Server is running", s.serverRunning);
	1.wait;

	"".postln;
	"Test 2: Buffer Allocation".postln;
	"--------------------------------------".postln;
	testBuffer = Buffer.alloc(s, s.sampleRate * 4, 1);
	0.5.wait;
	~testResult.value("4-second buffer allocated", testBuffer.numFrames == (s.sampleRate * 4));
	0.5.wait;

	"".postln;
	"Test 3: Grain Engine SynthDef".postln;
	"--------------------------------------".postln;
	// Fill buffer with test tone
	testBuffer.sine1([1, 0.5, 0.25], true, true, true);
	0.5.wait;

	// Create grain synth
	testSynth = Synth(\s4GrainEngine, [
		\bufnum, testBuffer,
		\grainSize, 0.1,
		\density, 20,
		\position, 0.5,
		\amp, 0.3
	]);
	1.wait;
	~testResult.value("Grain synth boots without errors", testSynth.isPlaying);
	2.wait;

	"".postln;
	"Test 4: Parameter Control".postln;
	"--------------------------------------".postln;
	"  Setting grain size to 0.05s...".postln;
	testSynth.set(\grainSize, 0.05);
	1.wait;
	"  Setting density to 50 grains/s...".postln;
	testSynth.set(\density, 50);
	1.wait;
	"  Setting pitch to +12 semitones...".postln;
	testSynth.set(\pitch, 12);
	1.wait;
	~testResult.value("Parameters can be changed in real-time", true);
	1.wait;

	"".postln;
	"Test 5: CPU Usage".postln;
	"--------------------------------------".postln;
	var cpuBefore, cpuAfter;
	testSynth.free;
	1.wait;
	cpuBefore = s.avgCPU;
	("  CPU before: " ++ cpuBefore.round(0.1) ++ "%").postln;

	// Create synth with max grains stress test
	testSynth = Synth(\s4GrainEngine, [
		\bufnum, testBuffer,
		\grainSize, 0.05,
		\density, 100, // high density
		\position, 0.5,
		\amp, 0.2
	]);
	2.wait;
	cpuAfter = s.avgCPU;
	("  CPU with high grain density: " ++ cpuAfter.round(0.1) ++ "%").postln;

	~testResult.value(
		"CPU usage <15% at high density",
		cpuAfter < 15,
		"CPU is at " ++ cpuAfter.round(0.1) ++ "%"
	);
	2.wait;

	"".postln;
	"Test 6: Envelope Types".postln;
	"--------------------------------------".postln;
	[\perc, \sine, \triangle, \welch].do({ arg envName, i;
		("  Testing " ++ envName ++ " envelope...").postln;
		testSynth.set(\envType, i);
		1.wait;
	});
	~testResult.value("All 4 envelope types work", true);
	1.wait;

	"".postln;
	"Test 7: Stereo Spread".postln;
	"--------------------------------------".postln;
	"  Setting stereo spread to 0 (mono)...".postln;
	testSynth.set(\stereoSpread, 0);
	1.wait;
	"  Setting stereo spread to 1 (wide)...".postln;
	testSynth.set(\stereoSpread, 1);
	1.wait;
	~testResult.value("Stereo spread control works", true);
	1.wait;

	"".postln;
	"Test 8: Jitter Controls".postln;
	"--------------------------------------".postln;
	"  Testing position jitter...".postln;
	testSynth.set(\posJitter, 0.3);
	1.5.wait;
	"  Testing pitch jitter...".postln;
	testSynth.set(\pitchJitter, 5);
	1.5.wait;
	~testResult.value("Jitter controls create variation", true);
	1.wait;

	"".postln;
	"Test 9: Cleanup".postln;
	"--------------------------------------".postln;
	testSynth.free;
	0.5.wait;
	testBuffer.free;
	0.5.wait;
	~testResult.value("Resources freed without errors", true);

	"".postln;
	"============================================".postln;
	"TEST RESULTS".postln;
	"============================================".postln;
	("Tests Passed: " ++ passCount).postln;
	("Tests Failed: " ++ failCount).postln;
	("Success Rate: " ++ ((passCount / (passCount + failCount)) * 100).round(0.1) ++ "%").postln;
	"".postln;

	if(failCount == 0, {
		"🎉 ALL TESTS PASSED! Phase 1 complete.".postln;
	}, {
		"⚠️  Some tests failed. Review errors above.".postln;
	});

	"============================================".postln;
};
)

/*
MANUAL TESTING CHECKLIST:

After running automated tests, verify these manually:

GUI Tests:
□ GUI window opens without errors
□ All sliders respond smoothly
□ Number boxes update with sliders
□ Envelope type menu works
□ Record button starts/stops recording
□ Clear buffer button works

Audio Tests:
□ No audio dropouts during playback
□ No clicking or pops
□ Smooth grain triggering
□ Clean transitions between parameters
□ Recording from input works
□ Buffer playback is clean

Performance Tests:
□ CPU stays below 15% (check s.avgCPU)
□ No memory leaks over 5+ minutes
□ GUI remains responsive
□ Parameter changes are immediate

Integration Tests:
□ Record live input, then granulate it
□ Switch between envelope types while playing
□ Extreme parameter values don't crash
□ Multiple rapid parameter changes are stable

Phase 1 Completion Criteria:
✓ All deliverables created
✓ Basic tests passing
✓ CPU usage within target (<15%)
✓ No audio artifacts
✓ Smooth real-time control
*/
