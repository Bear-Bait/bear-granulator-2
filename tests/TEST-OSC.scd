/*
TEST OSC MESSAGES
Check if modulation OSC messages are being received
*/

(
// Listen to ALL OSC messages for 5 seconds
OSCFunc.trace(true);

fork {
	"=== Listening to OSC for 5 seconds ===".postln;
	"Turn ON a modulator and ROUTE it now...".postln;
	5.wait;
	OSCFunc.trace(false);
	"=== OSC trace stopped ===".postln;
}
)
