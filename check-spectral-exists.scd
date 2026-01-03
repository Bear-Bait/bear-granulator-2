// Quick check: Does the spectral synth exist?
(
var track = ~trackManager.getTrack(0);

"=== SPECTRAL SYNTH CHECK ===".postln;
"".postln;

if(track.spectralSynth.notNil, {
	"✓ Spectral synth EXISTS".postln;
	"  Node ID: %".format(track.spectralSynth.nodeID).postln;
	"  Running: %".format(track.spectralSynth.isRunning).postln;
	"  Output bus: %".format(track.audioBus.index).postln;
	"".postln;

	"Spectral parameters:".postln;
	"  spectralMix: % (0=silent, 1=full)".format(track.params[\spectralMix]).postln;
	"  spectralRate: % (0=freeze, 1=normal)".format(track.params[\spectralRate]).postln;
	"  spectralWindowSize: %".format(track.params[\spectralWindowSize]).postln;
	"".postln;

	if(track.params[\spectralMix] == 0, {
		"⚠️  WARNING: spectralMix is 0 - you won't hear it!".postln;
		"   Move the 'Spectral Mix' slider in the GUI".postln;
	});

	if(track.spectralSynth.isRunning.not, {
		"⚠️  WARNING: Spectral synth is STOPPED".postln;
		"   Press the green PLAY button".postln;
	});
}, {
	"✗ ERROR: Spectral synth is NIL!".postln;
	"  This means it wasn't created. Check console for errors.".postln;
});

"".postln;
"=== END CHECK ===".postln;
)


(
// Start the spectral synth and set mix to 100%
~trackManager.getTrack(0).spectralSynth.run(true);
~trackManager.setParam(0, \spectralMix, 1.0);
"Spectral engine should be audible NOW".postln;
)