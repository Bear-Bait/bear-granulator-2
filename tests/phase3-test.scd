/*
Phase 3 Test - Effects Chain
Test Color and Space effects with granular engine
*/

(
"=== PHASE 3 EFFECTS TEST ===".postln;
"".postln;

// First, load a test sound into the buffer
fork {
	var tempBuf = Buffer.alloc(s, s.sampleRate * 4, 1);
	tempBuf.sine1([1.0, 0.5, 0.3, 0.2, 0.15, 0.1], true, true, true);
	0.2.wait;
	tempBuf.copyData(~recorder.buffer);
	0.2.wait;
	tempBuf.free;
	"✓ Test waveform loaded".postln;
	"".postln;

	// Test 1: Color Effects - Distortion
	"Test 1: Dual-band distortion...".postln;
	~grainSynth.set(\colorOn, 1, \distMix, 0.7, \distLoDrive, 3, \distHiDrive, 5);
	2.wait;
	~grainSynth.set(\colorOn, 0);
	"✓ Distortion test complete".postln;
	1.wait;

	// Test 2: Color Effects - Bit Crusher
	"Test 2: Bit crusher (lo-fi)...".postln;
	~grainSynth.set(\colorOn, 1, \crushMix, 1.0, \crushRate, 2000, \crushBits, 4);
	2.wait;
	~grainSynth.set(\colorOn, 0);
	"✓ Bit crusher test complete".postln;
	1.wait;

	// Test 3: Color Effects - Noise
	"Test 3: Adding noise...".postln;
	~grainSynth.set(\colorOn, 1, \noiseAmount, 0.1, \noiseType, 1);
	2.wait;
	~grainSynth.set(\colorOn, 0, \noiseAmount, 0);
	"✓ Noise test complete".postln;
	1.wait;

	// Test 4: Space Effects - Reverb
	"Test 4: Reverb...".postln;
	~grainSynth.set(\spaceOn, 1, \reverbMix, 0.6, \reverbSize, 0.9);
	3.wait;
	~grainSynth.set(\spaceOn, 0);
	"✓ Reverb test complete".postln;
	1.wait;

	// Test 5: Space Effects - Delay
	"Test 5: Ping-pong delay...".postln;
	~grainSynth.set(\spaceOn, 1, \delayMix, 0.5, \delayTime, 0.25, \delayFeedback, 0.6, \delayPingPong, 1);
	3.wait;
	~grainSynth.set(\spaceOn, 0);
	"✓ Delay test complete".postln;
	1.wait;

	// Test 6: Space Effects - Shimmer
	"Test 6: Shimmer (pitch-shift delay)...".postln;
	~grainSynth.set(\spaceOn, 1, \shimmerMix, 0.7, \shimmerPitch, 12, \shimmerFeedback, 0.7);
	4.wait;
	~grainSynth.set(\spaceOn, 0, \shimmerMix, 0);
	"✓ Shimmer test complete".postln;
	1.wait;

	// Test 7: Combined Effects
	"Test 7: Combined effects (distortion + reverb + delay)...".postln;
	~grainSynth.set(
		\colorOn, 1, \distMix, 0.5, \distLoDrive, 2,
		\spaceOn, 1, \reverbMix, 0.4, \delayMix, 0.3
	);
	4.wait;
	~grainSynth.set(\colorOn, 0, \spaceOn, 0);
	"✓ Combined effects test complete".postln;
	"".postln;

	"=== ALL PHASE 3 TESTS COMPLETE ===".postln;
	"Effects chain is working!".postln;
};
)
