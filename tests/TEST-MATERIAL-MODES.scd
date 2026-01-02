/*
PHASE 6 MATERIAL MODES TEST
Tests all three playback modes: TAPE, POLY, LIVE

Prerequisites:
1. Boot server with main.scd
2. Load an audio file on Track 1
3. Make sure grain parameters are set to hear changes

Test Procedure:
- Test each mode for 5 seconds
- Listen for distinct sonic characteristics
- Verify no crashes when switching modes
*/

(
fork {
	"=== PHASE 6 MATERIAL MODES TEST ===".postln;
	"".postln;

	// Check that track 1 is initialized
	if(~trackManager.isNil, {
		"ERROR: Track manager not initialized. Run main.scd first.".postln;
		nil;
	}, {
		var currentMode;

		"Testing Track 1 with three material modes...".postln;
		"Make sure you have loaded an audio file and started playback!".postln;
		"".postln;

		2.wait;

		// === TEST 1: TAPE MODE (default) ===
		"[1/3] Testing TAPE mode (looping buffer playback)...".postln;
		~trackManager.setMode(0, 0);  // Mode 0 = TAPE
		currentMode = ~trackManager.getMode(0);
		"  Current mode: %".format(currentMode).postln;
		"  Expected: Position loops through buffer between loopStart/loopEnd".postln;
		"  Listening for 5 seconds...".postln;
		5.wait;

		// === TEST 2: POLY MODE ===
		"".postln;
		"[2/3] Testing POLY mode (fixed position, like a sampler)...".postln;
		~trackManager.setMode(0, 1);  // Mode 1 = POLY
		currentMode = ~trackManager.getMode(0);
		"  Current mode: %".format(currentMode).postln;
		"  Expected: Grains always start from same position (no looping)".postln;
		"  Listening for 5 seconds...".postln;
		5.wait;

		// === TEST 3: LIVE MODE ===
		"".postln;
		"[3/3] Testing LIVE mode (lookback time)...".postln;
		~trackManager.setMode(0, 2);  // Mode 2 = LIVE
		currentMode = ~trackManager.getMode(0);
		"  Current mode: %".format(currentMode).postln;
		"  Expected: Position = time ago (0=now, 1=buffer start)".postln;
		"  Listening for 5 seconds...".postln;
		5.wait;

		// === RETURN TO TAPE MODE ===
		"".postln;
		"Returning to TAPE mode (default)...".postln;
		~trackManager.setMode(0, 0);

		"".postln;
		"=== TEST COMPLETE ===".postln;
		"Did you hear distinct differences between the three modes?".postln;
		"  TAPE: Continuous looping through buffer".postln;
		"  POLY: Fixed attack point (like triggering a sample)".postln;
		"  LIVE: Lookback delay effect".postln;
	});
}
)
