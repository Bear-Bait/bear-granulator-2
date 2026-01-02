/*
TEST MODULATOR SYNTH REPLICA
Exactly replicate the modulator synth code to find the bug
*/

(
fork {
	var testBus, testSynth;

	testBus = Bus.control(s, 1);
	"Test bus: %".format(testBus.index).postln;

	0.2.wait;

	// Exact replica of modulator synth LFO code
	testSynth = {
		arg modType = 0, out = 0, freq = 2.0, amp = 1.0, waveform = 0;
		var sig, lfoSig;

		// === LFO (Type 0) ===
		lfoSig = Select.kr(waveform, [
			SinOsc.kr(freq),                    // 0: Sine
			LFTri.kr(freq),                     // 1: Triangle
			LFSaw.kr(freq),                     // 2: Sawtooth
			LFPulse.kr(freq, width: 0.5),       // 3: Square
			LFNoise1.kr(freq),                  // 4: Smooth random
			LFNoise0.kr(freq)                   // 5: Stepped random
		]).range(0, 1);

		// Select modulator type
		sig = Select.kr(modType, [lfoSig, 0, 0, 0]);

		// Apply depth and output to control bus
		Out.kr(out, sig * amp);
	}.play(s, [
		\modType, 0,
		\out, testBus.index,
		\freq, 2.0,
		\amp, 1.0,
		\waveform, 0
	], addAction: \addToTail);

	"Synth created: %".format(testSynth).postln;

	0.5.wait;

	// Monitor for 5 seconds
	"Monitoring for 5 seconds...".postln;
	10.do({
		testBus.get({ |v| "Bus value: %".format(v.round(0.01)).postln });
		0.5.wait;
	});

	// Cleanup
	testSynth.free;
	testBus.free;
	"Test complete".postln;
}
)
