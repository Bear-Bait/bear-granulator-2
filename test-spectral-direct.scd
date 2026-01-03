/*
DIRECT SPECTRAL ENGINE TEST
Tests the spectral engine in isolation
*/

(
// Kill any existing test synth
if(~testSpectral.notNil, { ~testSpectral.free });

"=== DIRECT SPECTRAL TEST ===".postln;

// Get buffer from track 0
~testBuf = ~trackManager.getTrack(0).recorder.buffer;

"Using buffer: %".format(~testBuf.bufnum).postln;
"Buffer frames: %".format(~testBuf.numFrames).postln;
"".postln;

// Create spectral synth directly to hardware output
~testSpectral = Synth(\s4SpectralEngine, [
	\bufnum, ~testBuf.bufnum,
	\spectralMix, 1.0,          // 100% wet
	\position, 0.5,
	\rate, 1.0,                 // Normal speed
	\windowSize, 0.2,
	\overlaps, 4,
	\pitch, 0,
	\freeze, 0,
	\smear, 0,
	\amp, 0.5,
	\out, 0                     // Direct to hardware output
], addAction: \addToTail);

"".postln;
"✓ Test spectral synth created (node ID: %)".format(~testSpectral.nodeID).postln;
"  Output: Direct to speakers (bus 0)".postln;
"  SpectralMix: 1.0 (100% wet)".postln;
"  Amp: 0.5".postln;
"".postln;
"You should hear spectral playback NOW.".postln;
"".postln;
"To stop: ~testSpectral.free".postln;
)




// 1. Reload the spectral engine
(~config.corePath +/+ "spectral-engine.scd").load;

// 2. Run the test again
(
~testSpectral.free;
~testSpectral = Synth(\s4SpectralEngine, [
	\bufnum, ~testBuf.bufnum,
	\spectralMix, 1.0,
	\rate, 1.0,
	\windowSize, 0.2,
	\overlaps, 4,
	\amp, 0.8,
	\out, 0
], addAction: \addToTail);
"Test running - listen now!".postln;
)

