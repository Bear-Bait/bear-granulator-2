/*
DIAGNOSTIC: Test File Loading
Debug why Load Audio File button isn't working
*/

(
var testBuffer;

"=== STEP 1: Test basic file loading ===".postln;

// Try loading one of SC's built-in files
testBuffer = Buffer.read(s, Platform.resourceDir +/+ "sounds/a11wlk01.wav");

fork {
	1.0.wait;

	"Buffer info:".postln;
	"  Buffer number: %".format(testBuffer.bufnum).postln;
	"  Num frames: %".format(testBuffer.numFrames).postln;
	"  Duration: % seconds".format(testBuffer.duration).postln;
	"  Num channels: %".format(testBuffer.numChannels).postln;
	"".postln;

	"=== STEP 2: Test if buffer has audio data ===".postln;
	testBuffer.loadToFloatArray(action: { arg array;
		"Array size: %".format(array.size).postln;
		"First 10 samples: %".format(array[0..9]).postln;
		"Max amplitude: %".format(array.maxItem).postln;
		"".postln;

		"=== STEP 3: Test playback ===".postln;
		"Playing with PlayBuf...".postln;
		{
			var sig = PlayBuf.ar(1, testBuffer, loop: 1);
			sig ! 2 * 0.5;
		}.play;
	});

	3.0.wait;

	"=== STEP 4: Test with GrainBuf ===".postln;
	"Playing with GrainBuf...".postln;
	{
		GrainBuf.ar(
			numChannels: 2,
			trigger: Impulse.ar(40),
			dur: 0.1,
			sndbuf: testBuffer,
			rate: 1,
			pos: 0.5,
			pan: 0
		) * 0.3;
	}.play;
};
)

// To stop all sound:
// s.freeAll;

/*
EXPECTED OUTPUT:
- Buffer info with valid frame count
- Array with audio samples (not all zeros)
- Should hear audio from both PlayBuf and GrainBuf

IF YOU SEE:
- Num frames: 0 → File didn't load
- Array all zeros → Buffer is empty
- No sound from PlayBuf → Audio routing issue
- No sound from GrainBuf → Grain engine issue
*/
