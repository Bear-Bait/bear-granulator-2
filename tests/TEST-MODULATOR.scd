/*
QUICK MODULATOR TEST
Run this to verify modulators are working
*/

(
fork {
	var track = ~trackManager.getTrack(0);

	"=== CHECKING TRACK 1 MODULATORS ===".postln;

	4.do({ arg i;
		"Modulator %: %".format(i + 1, track.modulators[i]).postln;
		"Bus %: %".format(i + 1, track.modBusses[i]).postln;
		"Target %: %".format(i + 1, track.modTargets[i]).postln;
	});

	"".postln;
	"=== SERVER NODE TREE ===".postln;
	s.queryAllNodes;
}
)

/*
Expected output if Mod 2 is active:
- Modulator 2: Synth(...)
- Bus 2: Bus(control, X, 1)
- Should see node in server tree
*/
