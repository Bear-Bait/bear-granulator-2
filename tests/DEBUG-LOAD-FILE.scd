/*
DEBUG SCRIPT: Check if Load Audio File is working
Run this AFTER clicking "Load Audio File" to see what happened
*/

(
var track = ~trackManager.getTrack(0); // Track 1

"=== TRACK 1 DEBUG INFO ===".postln;
"".postln;

"BUFFER:".postln;
"  Buffer number: %".format(track.recorder.buffer.bufnum).postln;
"  Num frames: %".format(track.recorder.buffer.numFrames).postln;
"  Duration: % seconds".format(track.recorder.buffer.duration).postln;
"  Sample rate: %".format(track.recorder.buffer.sampleRate).postln;
"".postln;

"GRAIN SYNTH:".postln;
"  Synth exists: %".format(track.grainSynth.notNil).postln;
if(track.grainSynth.notNil, {
	"  Node ID: %".format(track.grainSynth.nodeID).postln;
	"  Is playing: %".format(track.grainSynth.isPlaying).postln;
});
"".postln;

"CHECKING BUFFER CONTENTS:".postln;
track.recorder.buffer.loadToFloatArray(action: { arg array;
	"  Array size: %".format(array.size).postln;
	"  First 5 samples: %".format(array[0..4]).postln;
	"  Max amplitude: %".format(array.maxItem.abs).postln;
	"  All zeros? %".format(array.maxItem.abs < 0.0001).postln;
	"".postln;

	if(array.maxItem.abs < 0.0001, {
		"❌ BUFFER IS EMPTY (all zeros)".postln;
		"   → File didn't load correctly".postln;
	}, {
		"✅ BUFFER HAS AUDIO DATA".postln;
		"   → File loaded successfully".postln;
	});
});
)

/*
WHAT TO LOOK FOR:

✅ GOOD:
  Buffer number: 5 (or any number)
  Num frames: > 0 (e.g., 731040)
  Duration: > 0 (e.g., 15.23 seconds)
  Array size: matches num frames
  Max amplitude: > 0.0001
  ✅ BUFFER HAS AUDIO DATA

❌ BAD:
  Num frames: 0
  Duration: 0
  All zeros? true
  ❌ BUFFER IS EMPTY
*/
