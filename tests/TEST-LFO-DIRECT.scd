/*
TEST LFO DIRECTLY
Create an LFO synth and monitor its output
*/

(
fork {
	var testBus, testSynth;

	"=== TESTING DIRECT LFO CREATION ===".postln;

	// Create a test control bus
	testBus = Bus.control(s, 1);
	"Test bus allocated: index %".format(testBus.index).postln;

	0.2.wait;

	// Create a simple LFO synth
	testSynth = {
		arg out = 0, freq = 2.0;
		var sig = SinOsc.kr(freq).range(0, 1);
		Out.kr(out, sig);
	}.play(s, [\out, testBus.index], addAction: \addToTail);

	"LFO synth created: %".format(testSynth).postln;

	0.5.wait;

	// Monitor the bus for 5 seconds
	"Monitoring bus for 5 seconds...".postln;
	10.do({ arg i;
		testBus.get({ arg value;
			"Bus value: %".format(value.round(0.01)).postln;
		});
		0.5.wait;
	});

	// Cleanup
	testSynth.free;
	testBus.free;
	"=== Test complete ===".postln;
}
)
