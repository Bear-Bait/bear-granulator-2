/*
DEBUG: Test if spectral parameters are being routed correctly
Run this AFTER loading a sample and pressing PLAY
*/

(
var track = ~trackManager.getTrack(0);

"=== SPECTRAL DEBUG ===".postln;
"".postln;

// Check if spectral synth exists and is running
if(track.spectralSynth.notNil, {
	"✓ Spectral synth exists".postln;
	"  Node ID: %".format(track.spectralSynth.nodeID).postln;
	"  Is running: %".format(track.spectralSynth.isRunning).postln;
}, {
	"✗ Spectral synth is NIL!".postln;
});

"".postln;

// Test parameter routing
"Testing parameter update...".postln;
~trackManager.setParam(0, \spectralMix, 0.8);
0.1.wait;

"After setting spectralMix to 0.8:".postln;
"  Stored param: %".format(track.params[\spectralMix]).postln;

"".postln;

// Try setting it directly on the synth
"Setting spectralMix directly on synth...".postln;
track.spectralSynth.set(\spectralMix, 0.9);

"".postln;
"=== END DEBUG ===".postln;
"".postln;
"If you hear spectral layer now, the problem is parameter routing.".postln;
"If you still don't hear it, the problem is in the SynthDef.".postln;
)
