/*
Quick Sound Test - Get immediate audio output
Run this after booting the main system to verify sound is working
*/

(
"=== QUICK SOUND TEST ===".postln;
"".postln;

// Load test waveform into buffer
fork {
	var tempBuf = Buffer.alloc(s, s.sampleRate * 4, 1);
	tempBuf.sine1([1.0, 0.5, 0.3, 0.2, 0.15, 0.1], true, true, true);
	0.3.wait;

	// Copy to recorder buffer
	if(~recorder.notNil && ~recorder.buffer.notNil, {
		tempBuf.copyData(~recorder.buffer);
		0.2.wait;
		tempBuf.free;

		"✓ Test sound loaded into buffer!".postln;
		"".postln;
		"You should now hear granular synthesis!".postln;
		"If not, check:".postln;
		"  - Volume is up on your audio interface".postln;
		"  - Amplitude slider in GUI is above 0".postln;
		"  - ~grainSynth is running: ~grainSynth.postln;".postln;
		"".postln;
		"Try adjusting these sliders:".postln;
		"  - Grain Size (0.01 - 0.5)".postln;
		"  - Density (grains per second)".postln;
		"  - Position (playback position in buffer)".postln;
		"  - Pitch (-24 to +24 semitones)".postln;
	}, {
		"ERROR: ~recorder or buffer not initialized!".postln;
		"Make sure you ran main.scd first!".postln;
	});
};
)

/*
Manual control examples:
~grainSynth.set(\amp, 0.7);         // Increase volume
~grainSynth.set(\grainSize, 0.05);  // Smaller grains
~grainSynth.set(\density, 50);      // More grains
~grainSynth.set(\pitch, 12);        // Up an octave
~grainSynth.set(\posJitter, 0.3);   // More position randomness
*/
