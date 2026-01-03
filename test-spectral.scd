/*
SPECTRAL ENGINE DIAGNOSTIC TEST
Run this AFTER running main.scd to verify spectral engine is working
*/

(
"=== SPECTRAL ENGINE DIAGNOSTIC ===".postln;
"".postln;

// Check if SynthDef exists
if(SynthDescLib.global.at(\s4SpectralEngine).notNil, {
	"✓ SynthDef \\s4SpectralEngine is loaded".postln;
}, {
	"✗ ERROR: SynthDef \\s4SpectralEngine NOT FOUND".postln;
	"  Run main.scd first!".postln;
});

"".postln;

// Check track 0 spectral synth
if(~trackManager.notNil, {
	var track = ~trackManager.getTrack(0);

	"Track 0 status:".postln;
	"  Grain synth: %".format(if(track.grainSynth.notNil, "exists", "NIL")).postln;
	"  Spectral synth: %".format(if(track.spectralSynth.notNil, "exists", "NIL")).postln;

	if(track.spectralSynth.notNil, {
		"  Spectral synth node ID: %".format(track.spectralSynth.nodeID).postln;
		"  Spectral synth running: %".format(track.spectralSynth.isRunning).postln;
	});

	"".postln;
	"Track 0 spectral parameters:".postln;
	"  spectralMix: %".format(track.params[\spectralMix]).postln;
	"  spectralPosition: %".format(track.params[\spectralPosition]).postln;
	"  spectralRate: %".format(track.params[\spectralRate]).postln;
	"  spectralWindowSize: %".format(track.params[\spectralWindowSize]).postln;
	"  spectralOverlaps: %".format(track.params[\spectralOverlaps]).postln;

	"".postln;

	if(track.params[\spectralMix] == 0, {
		"⚠ WARNING: spectralMix is 0 (silent)".postln;
		"  Solution: Move 'Spectral Mix' slider in GUI to hear spectral layer".postln;
	});
}, {
	"✗ ERROR: ~trackManager is NIL".postln;
	"  Run main.scd first!".postln;
});

"".postln;
"=== END DIAGNOSTIC ===".postln;
)
