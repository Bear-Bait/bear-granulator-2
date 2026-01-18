/*
BEARULATOR: Spectral Capture SynthDef
Phase 17 - Spectral Photobooth

Records spectral engine output to a buffer for later use.
One-shot recording (stops automatically when buffer fills).
*/

SynthDef(\spectralCapture, { arg inBus, captureBuffer;
	var sig;

	// Read from track's audio bus (where spectral engine outputs)
	sig = In.ar(inBus, 2);  // Stereo

	// Record to capture buffer (one-shot, stop when full)
	RecordBuf.ar(sig, captureBuffer, loop: 0, doneAction: 2);

	// Send completion message when done
	SendReply.kr(Done.kr(RecordBuf.ar(sig, captureBuffer, loop: 0)), '/spectralCaptureDone');
}).add;

"✓ Spectral capture SynthDef loaded".postln;
