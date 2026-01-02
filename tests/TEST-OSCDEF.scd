/*
TEST OSCDEF RECEPTION
Check if the mapper's OSCdef is receiving messages
*/

(
// Create a test OSCdef that listens for /modUpdate messages
OSCdef(\testModUpdate, { arg msg;
	"OSC received: %".format(msg).postln;
}, '/modUpdate');

"=== Listening for /modUpdate messages for 5 seconds ===".postln;
"The mapper should be sending these at 30 Hz...".postln;

fork {
	5.wait;
	OSCdef(\testModUpdate).free;
	"=== Test complete ===".postln;
}
)
