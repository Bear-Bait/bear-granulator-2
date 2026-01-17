/*
═══════════════════════════════════════════════════════════════════
BEARULATOR GRANULAR WORKSTATION - START HERE
═══════════════════════════════════════════════════════════════════

QUICK START:
1. Boot server (if not booted): s.boot;
2. Run ONLY THE FIRST CODE BLOCK below (lines 14-73)
3. Wait for "READY TO PLAY!" message
4. Click cyan "Load Test Sound" button in GUI
5. YOU SHOULD HEAR SOUND! 🔊

Additional code blocks below are for manual testing - run them
separately AFTER the system is loaded.

═══════════════════════════════════════════════════════════════════
*/

(
"".postln;
"═══════════════════════════════════════════════════════".postln;
"  BEARULATOR v0.3.001 - Granular Synthesis Workstation".postln;
"═══════════════════════════════════════════════════════".postln;
"".postln;

// Check server
if(s.serverRunning.not, {
	"⚠ Server not running! Please boot server first:".postln;
	"  s.boot;".postln;
	"".postln;
}, {
	"✓ Server is running".postln;

	// Load main system
	"Loading system...".postln;
	(thisProcess.nowExecutingPath.dirname +/+ "main.scd").load;

	// Wait for system to initialize, then load test sound
	fork {
		3.wait;  // Give system time to fully initialize

		"".postln;
		"═══════════════════════════════════════════════════════".postln;
		"  READY TO PLAY!".postln;
		"═══════════════════════════════════════════════════════".postln;
		"".postln;
		"NEXT STEPS:".postln;
		"1. Click the cyan 'Load Test Sound' button (top-left)".postln;
		"2. OR run the 'Manual Sound Test' code block below".postln;
		"".postln;
		"TROUBLESHOOTING:".postln;
		"- No sound? Check amplitude slider > 0".postln;
		"- Still nothing? Run: ~grainSynth.set(\\amp, 0.7);".postln;
		"- Check buffer: ~recorder.buffer.plot;".postln;
		"".postln;
		"MANUAL TEST (run separately):".postln;
		"  ~grainSynth.set(\\density, 60, \\grainSize, 0.1, \\amp, 0.6);".postln;
		"".postln;
		"DOCUMENTATION:".postln;
		"- README.md - Project overview".postln;
		"- SOUND-TEST-GUIDE.md - Detailed testing instructions".postln;
		"- QUICK-REFERENCE.md - Parameter reference".postln;
		"".postln;
	};
});
)

/*
═══════════════════════════════════════════════════════════════════
MANUAL SOUND TEST (if button doesn't work)
Run this code block separately AFTER the main system is loaded
═══════════════════════════════════════════════════════════════════
*/
(
fork {
	var tempBuf = Buffer.alloc(s, s.sampleRate * 4, 1);
	tempBuf.sine1([1.0, 0.5, 0.3, 0.2, 0.15, 0.1], true, true, true);
	0.3.wait;
	tempBuf.copyData(~recorder.buffer);
	0.2.wait;
	tempBuf.free;
	"✓ Test sound loaded! YOU SHOULD HEAR SOUND NOW!".postln;
	"If not, check your audio interface volume.".postln;
};
)

/*
═══════════════════════════════════════════════════════════════════
QUICK PARAMETER TESTS
Run these commands individually to test different parameters
═══════════════════════════════════════════════════════════════════

Test 1: Basic grain parameters
*/
~grainSynth.set(\density, 60, \grainSize, 0.08, \amp, 0.6);

// Test 2: Pitch shifting
~grainSynth.set(\pitch, 12);   // Up an octave
~grainSynth.set(\pitch, -12);  // Down an octave
~grainSynth.set(\pitch, 0);    // Back to normal

// Test 3: Grain texture (randomness)
~grainSynth.set(\posJitter, 0.4, \pitchJitter, 3);

// Test 4: Scan through buffer
~grainSynth.set(\position, 0.0);  // Start
~grainSynth.set(\position, 0.5);  // Middle
~grainSynth.set(\position, 1.0);  // End

// Test 5: Grain size extremes
~grainSynth.set(\grainSize, 0.01);  // Tiny grains (crisp)
~grainSynth.set(\grainSize, 0.3);   // Large grains (smooth)

// Test 6: Enable 48-band filter
~grainSynth.set(\filterOn, 1, \filterFreq, 300, \filterMorph, 0.5, \filterRes, 0.7);

// Test 7: Enable reverb
~grainSynth.set(\spaceOn, 1, \reverbMix, 0.5, \reverbSize, 0.8);

// Test 8: Enable distortion
~grainSynth.set(\colorOn, 1, \distMix, 0.6, \distLoDrive, 3);

// Turn off all effects
~grainSynth.set(\filterOn, 0, \colorOn, 0, \spaceOn, 0);

/*
═══════════════════════════════════════════════════════════════════
LIVE RECORDING TEST (MOTU Mk5)
Run these commands to test live recording from your audio interface
═══════════════════════════════════════════════════════════════════

Select your input (0-7 for inputs 1-8)
*/
~selectedInput = 2;  // Input 3 (your default)

// Start recording
~recorder.startRecording(~selectedInput, overdub: false);

// ... make sound into your input ...

// Stop recording
~recorder.stopRecording;

// Now the grain engine plays your recorded audio!
// Adjust Position slider to scan through what you recorded

/*
═══════════════════════════════════════════════════════════════════
COMPREHENSIVE EFFECTS TEST
═══════════════════════════════════════════════════════════════════

Run the full Phase 3 test suite (runs all effects automatically):
*/
(thisProcess.nowExecutingPath.dirname +/+ "tests/phase3-test.scd").load;
