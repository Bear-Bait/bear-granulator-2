/*
Quick test - Fill buffer with sound and start granulating
Run this after main.scd boots
*/

(
// Fill the buffer with a rich harmonic sound
fork {
	"Generating test waveform...".postln;
	
	// Create a temporary buffer with a rich tone
	var tempBuf = Buffer.alloc(s, s.sampleRate * 4, 1);
	
	// Fill with multiple harmonics for interesting granulation
	tempBuf.sine1(
		[1.0, 0.5, 0.3, 0.2, 0.15, 0.1, 0.08, 0.05], // harmonics
		true,  // normalize
		true,  // wavetable
		true   // clear first
	);
	
	0.2.wait;
	
	// Copy to the recorder's buffer
	tempBuf.copyData(~recorder.buffer);
	
	0.2.wait;
	tempBuf.free;
	
	"✓ Test waveform loaded! You should hear grains now.".postln;
	"Try adjusting the GUI controls:".postln;
	"  - Grain Size: changes grain duration".postln;
	"  - Density: how many grains per second".postln;
	"  - Position: scrub through the buffer".postln;
	"  - Pitch: pitch shift the grains".postln;
	"  - Enable Filter and try the resonator!".postln;
};
)
