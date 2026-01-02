/*
TEST DIRECT PARAMETER SETTING
Manually change grainSize to verify the synth responds
*/

(
fork {
	var grainSynth = ~trackManager.getTrack(0).grainSynth;

	"=== TESTING DIRECT SYNTH CONTROL ===".postln;
	"Grain synth: %".format(grainSynth).postln;

	"Setting grain size to 0.01 (tiny grains)...".postln;
	grainSynth.set(\grainSize, 0.01);
	2.wait;

	"Setting grain size to 1.0 (large grains)...".postln;
	grainSynth.set(\grainSize, 1.0);
	2.wait;

	"Setting grain size to 0.01 (tiny grains)...".postln;
	grainSynth.set(\grainSize, 0.01);
	2.wait;

	"Setting grain size to 1.0 (large grains)...".postln;
	grainSynth.set(\grainSize, 1.0);

	"Test complete. You should have heard the grain size changing.".postln;
}
)
