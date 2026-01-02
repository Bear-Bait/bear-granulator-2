/*
PHASE 7 VIEWFINDER TEST
=======================

Test the waveform viewfinder and loop window selection.

Prerequisites:
1. Run main.scd first to initialize the system
2. Load an audio file on Track 1

Test Procedure:
1. Open viewfinder window
2. Drag to select different loop regions
3. Verify loop updates engine in real-time
4. Test with different material modes
*/

(
fork {
	var track;

	"=== PHASE 7 VIEWFINDER TEST ===".postln;
	"".postln;

	// Check prerequisites
	if(~viewfinder.isNil, {
		"ERROR: Viewfinder not initialized. Run main.scd first.".error;
		nil;
	}, {
		if(~trackManager.isNil, {
			"ERROR: Track manager not initialized. Run main.scd first.".error;
			nil;
		}, {
			track = ~trackManager.getTrack(0);

			if(track.recorder.buffer.isNil, {
				"WARNING: No audio loaded on Track 1.".warn;
				"Loading test audio file...".postln;

				// Load Houston audio file
				{
					var path = "/Users/forrestmuelrath/Documents/supercollider/sounds/a11wlk01-44_1.aiff";
					var sf = SoundFile.new;

					if(sf.openRead(path), {
						track.recorder.buffer.allocRead(path);
						s.sync;
						"✓ Test audio loaded".postln;
						sf.close;

						1.wait;

						// Open viewfinder
						"Opening viewfinder for Track 1...".postln;
						{ ~viewfinder.createWindow(0); }.defer;

						2.wait;

						"".postln;
						"=== INSTRUCTIONS ===".postln;
						"1. You should see a waveform window labeled 'Track 1 Viewfinder'".postln;
						"2. DRAG across the waveform to select a loop region".postln;
						"3. Release mouse - you should see feedback in post window".postln;
						"4. The grain engine loop boundaries update in REAL-TIME!".postln;
						"".postln;
						"5. Try selecting different regions:".postln;
						"   - Small region (10% of buffer)".postln;
						"   - Large region (80% of buffer)".postln;
						"   - Beginning of buffer only".postln;
						"   - End of buffer only".postln;
						"".postln;
						"6. Test with different Material Modes:".postln;
						"   - TAPE mode: Grains loop within window".postln;
						"   - POLY mode: Grains trigger from window start".postln;
						"   - LIVE mode: Grains read backward from window end".postln;
						"".postln;

						"Current Track 1 settings:".postln;
						"  Grain Size: % s".format(track.grainSynth.get(\grainSize, {|v| v})).postln;
						"  Overlap: %".format(track.grainSynth.get(\overlap, {|v| v})).postln;
						"  Material Mode: % (0=TAPE, 1=POLY, 2=LIVE)".format(track.grainSynth.get(\mode, {|v| v})).postln;
						"".postln;

						"=== TEST SUGGESTIONS ===".postln;
						"".postln;
						"Test 1: Full Loop (TAPE mode)".postln;
						"  - Set Material Mode to TAPE (0)".postln;
						"  - Select entire waveform".postln;
						"  - Should hear full 'columbia this houston over'".postln;
						"".postln;
						"Test 2: Small Loop (TAPE mode)".postln;
						"  - Keep TAPE mode".postln;
						"  - Select just 'houston' (middle section)".postln;
						"  - Should hear only that word looping".postln;
						"".postln;
						"Test 3: Sample Trigger (POLY mode)".postln;
						"  - Switch to POLY mode (1)".postln;
						"  - Select 'columbia' (start of buffer)".postln;
						"  - Grains should trigger from 'co' sound".postln;
						"".postln;
						"Test 4: Live Lookback (LIVE mode)".postln;
						"  - Switch to LIVE mode (2)".postln;
						"  - Select last 30% of buffer".postln;
						"  - Position slider becomes 'time ago'".postln;
						"".postln;

						"Quick commands:".postln;
						"  ~trackManager.setMode(0, 0)  // TAPE mode".postln;
						"  ~trackManager.setMode(0, 1)  // POLY mode".postln;
						"  ~trackManager.setMode(0, 2)  // LIVE mode".postln;
						"".postln;

						"To close viewfinder:".postln;
						"  Close the window manually, or:".postln;
						"  ~viewfinder.closeAll".postln;
						"".postln;

						"=== TEST READY ===".postln;

					}, {
						"ERROR: Could not open test audio file.".error;
						"Please load an audio file manually on Track 1.".postln;
					});
				}.fork;
			}, {
				// Buffer already loaded
				"✓ Audio already loaded on Track 1".postln;
				"Opening viewfinder...".postln;
				{ ~viewfinder.createWindow(0); }.defer;

				1.wait;

				"".postln;
				"=== VIEWFINDER OPENED ===".postln;
				"Drag on the waveform to select loop regions!".postln;
				"Changes update the engine in real-time.".postln;
			});
		});
	});
}
)
