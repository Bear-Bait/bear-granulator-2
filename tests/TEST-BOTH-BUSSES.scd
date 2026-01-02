/*
TEST BOTH CONTROL BUSSES
Monitor both the modulator bus AND the scaled mapper bus
*/

(
fork {
	var track = ~trackManager.getTrack(0);
	var modBus = track.modBusses[0];      // Modulator output (0-1)
	var mapperBus = track.modMappers[0];  // Scaled output (should be 0-5)

	"=== MONITORING BOTH BUSSES ===".postln;
	"Modulator bus: % (should oscillate 0-1)".format(modBus.index).postln;
	"Mapper bus: % (should oscillate 0-5)".format(mapperBus).postln;
	"".postln;

	10.do({ arg i;
		modBus.get({ arg modValue;
			if(mapperBus.notNil and: { mapperBus.class == Bus }, {
				mapperBus.get({ arg scaledValue;
					"Mod: %  |  Scaled: %".format(
						modValue.round(0.01),
						scaledValue.round(0.01)
					).postln;
				});
			}, {
				"Mod: %  |  Mapper is not a bus: %".format(
					modValue.round(0.01),
					mapperBus
				).postln;
			});
		});
		0.5.wait;
	});

	"=== Done ===".postln;
}
)
