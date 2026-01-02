/*
DEBUG VIEWFINDER LOADING
Check why waveform isn't appearing
*/

(
var track = ~trackManager.getTrack(0);

"=== VIEWFINDER DEBUG ===".postln;
"".postln;

"Track object:".postln;
track.postln;
"".postln;

"File path:".postln;
track.filePath.postln;
"".postln;

"Buffer:".postln;
track.recorder.buffer.postln;
"".postln;

if(track.filePath.notNil, {
	var sf = SoundFile.new;
	"Trying to open file...".postln;
	if(sf.openRead(track.filePath), {
		"✓ File opened successfully!".postln;
		"  Path: %".format(track.filePath).postln;
		"  Frames: %".format(sf.numFrames).postln;
		"  Channels: %".format(sf.numChannels).postln;
		"  Sample Rate: %".format(sf.sampleRate).postln;
		sf.close;
	}, {
		"✗ Could not open file!".error;
	});
}, {
	"✗ No file path stored!".error;
	"".postln;
	"This means the file was loaded before the filePath storage code was added.".postln;
	"Solution: Load the audio file again using the 'Load Audio File' button.".postln;
});
)
