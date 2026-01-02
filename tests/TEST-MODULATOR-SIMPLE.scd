/*
SIMPLE MODULATOR API TEST
Tests if ~s4Modulator works at all
*/

(
fork {
	var api, bus, synth;

	"=== TESTING MODULATOR API ===".postln;

	// Get the API
	api = ~s4Modulator.value(s);
	"API object: %".format(api).postln;

	0.2.wait;

	// Create a control bus
	bus = Bus.control(s, 1);
	"Created bus: %".format(bus).postln;

	0.2.wait;

	// Try to create a modulator
	synth = api.create(
		type: 0,      // LFO
		outBus: bus.index,
		rate: 2.0,    // 2 Hz
		depth: 1.0,
		shape: 0,     // Sine
		inputBus: nil
	);

	"Synth returned: %".format(synth).postln;

	0.5.wait;

	// Check node tree
	s.queryAllNodes;

	2.wait;

	// Cleanup
	if(synth.notNil, { synth.free });
	bus.free;
	"Test complete.".postln;
}
)
