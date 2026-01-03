/*
PLAYHEAD TRACKING TEST (Phase 8)
Tests the sample-accurate playhead visualization in the viewfinder

SETUP:
1. Reload main.scd: ~cleanup.value; then run main.scd
2. Load an audio file into Track 1
3. Press PLAY button
4. Open the viewfinder window

WHAT TO EXPECT:
- RED line: Position parameter (static or slow-moving)
- CYAN line labeled "Live": Real-time playhead @ 60Hz from Phasor
- When scanSpeed > 0, cyan line will move through buffer
- When scanSpeed = 0, both lines should be at same position
*/

(
"=== PLAYHEAD TRACKING TEST ===".postln;
"".postln;

// Open viewfinder if not already open
if(~viewfinder.isNil, {
	"ERROR: ~viewfinder is nil. Run main.scd first.".error;
}, {
	// Open viewfinder for Track 1
	~viewfinder.createWindow(0);
	1.0.wait;

	"".postln;
	"VISUAL TEST:".postln;
	"1. You should see TWO playhead lines:".postln;
	"   - RED line: Position parameter (static)".postln;
	"   - CYAN line labeled 'Live': Real-time playhead @ 60Hz".postln;
	"".postln;
	"2. When static (scanSpeed = 0):".postln;
	"   - Both lines should be at the SAME position".postln;
	"".postln;

	"Now testing scanSpeed (continuous scanning)...".postln;
	"".postln;

	// Test 1: Forward scan at normal speed
	"Test 1: Forward scan (scanSpeed = 1.0)".postln;
	~trackManager.setParam(0, \scanSpeed, 1.0);
	"   → CYAN line should move FORWARD through buffer".postln;
	"   → RED line stays at position parameter".postln;
	3.0.wait;

	// Test 2: Faster forward scan
	"Test 2: Fast forward (scanSpeed = 2.0)".postln;
	~trackManager.setParam(0, \scanSpeed, 2.0);
	"   → CYAN line moves FASTER".postln;
	3.0.wait;

	// Test 3: Reverse scan
	"Test 3: Reverse scan (scanSpeed = -1.0)".postln;
	~trackManager.setParam(0, \scanSpeed, -1.0);
	"   → CYAN line moves BACKWARD".postln;
	3.0.wait;

	// Test 4: Reset to static
	"Test 4: Reset to static (scanSpeed = 0)".postln;
	~trackManager.setParam(0, \scanSpeed, 0);
	"   → CYAN line should stop and match RED line".postln;
	"".postln;

	2.0.wait;

	"=== MANUAL TESTS ===".postln;
	"Now try these manual tests in the GUI:".postln;
	"".postln;
	"1. Move Position slider → RED line moves, CYAN follows".postln;
	"2. Move Scan Speed slider → CYAN line moves independently".postln;
	"3. Select loop region → Both lines stay within green/red boundaries".postln;
	"".postln;
	"✓ If you see smooth 60Hz playhead motion, tracking is working!".postln;
	"".postln;
});
)


// Quick test: Enable scan and watch playhead
(
~trackManager.setParam(0, \scanSpeed, 1.5);
"Scan speed set to 1.5 - watch the cyan 'Live' playhead move!".postln;
)

// Stop scan
(
~trackManager.setParam(0, \scanSpeed, 0);
"Scan stopped - playhead should be static".postln;
)
