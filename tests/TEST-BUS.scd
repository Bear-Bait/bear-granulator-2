/*
TEST CONTROL BUS VALUES
Monitor the modulator's control bus to see if it's outputting values
*/

(
fork {
	var track = ~trackManager.getTrack(0);
	var bus = track.modBusses[0];  // Modulator 1's bus

	"=== MONITORING CONTROL BUS % ===".format(bus.index).postln;
	"This should show values changing between 0 and 1 if the LFO is working...".postln;
	"".postln;

	10.do({ arg i;
		bus.get({ arg value;
			"Bus value: %".format(value.round(0.001)).postln;
		});
		0.5.wait;
	});

	"=== Done ===".postln;
}
)
