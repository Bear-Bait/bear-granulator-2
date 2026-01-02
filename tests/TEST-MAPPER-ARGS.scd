/*
TEST MAPPER SYNTH ARGUMENTS
Check what min/max the mapper synth actually has
*/

(
fork {
	var track = ~trackManager.getTrack(0);
	var mapper = track.modMappers[0];  // Modulator 1's mapper

	"=== CHECKING MAPPER SYNTH ===".postln;
	"Mapper synth: %".format(mapper).postln;

	if(mapper.notNil, {
		0.2.wait;
		"Querying synth arguments...".postln;
		s.sendMsg('/s_get', mapper.nodeID, 'min', 'max', 'inBus', 'replyID');

		// Listen for response
		OSCdef(\getReply, { arg msg;
			"Response: %".format(msg).postln;
			OSCdef(\getReply).free;
		}, '/n_set');

		2.wait;
		OSCdef(\getReply).free;
	}, {
		"Mapper doesn't exist!".postln;
	});
}
)
