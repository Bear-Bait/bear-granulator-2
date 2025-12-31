/*
S-4 Rival: Buffer Recording System
Phase 1 - 4-second rolling buffer management

Features:
- 4-second mono buffer @ 48kHz
- Live input recording
- Rolling/looping buffer
- Overdub capability
- Clear/reset function

Usage:
- Creates and manages recording buffer
- Records from audio input continuously
- Can be used as grain source
*/

(
~s4BufferRecorder = {
	arg server;
	var bufferSize, recordBus, recordSynth;
	var publicAPI;

	// Buffer configuration
	bufferSize = server.sampleRate * 4; // 4 seconds at current sample rate

	publicAPI = (
		// Storage
		buffer: nil,
		isRecording: false,

		/*
		Function: init
		Purpose: Initialize buffer and prepare for recording
		*/
		init: {
			arg self;

			// Allocate buffer
			self.buffer = Buffer.alloc(server, bufferSize, 1); // mono

			"Buffer allocated: % frames (% seconds)".format(
				bufferSize,
				bufferSize / server.sampleRate
			).postln;

			self;
		},

		/*
		Function: startRecording
		Purpose: Start recording from audio input
		Args:
		  inputChannel: Audio input channel (default 0)
		  overdub: If true, mix with existing buffer content (default false)
		*/
		startRecording: {
			arg self, inputChannel = 0, overdub = false;

			if(self.buffer.isNil, {
				"Error: Buffer not initialized. Call init first.".postln;
			}, {
				if(self.isRecording, {
					"Already recording. Stop first.".postln;
				}, {
					// Create recording synth
					recordSynth = {
						arg in = 0, buf = 0, recLevel = 1.0, preLevel = 0.0;
						var input, output;

						// Get input signal
						input = SoundIn.ar(in);

						// Record to buffer (looping)
						RecordBuf.ar(
							inputArray: input,
							bufnum: buf,
							offset: 0,
							recLevel: recLevel,    // new audio level
							preLevel: preLevel,    // existing buffer level (0=replace, 1=overdub)
							loop: 1,               // loop recording
							trigger: 1,            // always recording
							doneAction: 0          // don't free synth when done
						);

						// Pass through for monitoring (optional)
						// Silent - use Out.ar if you want monitoring
						Silent.ar;
					}.play(
						server,
						args: [
							\in, inputChannel,
							\buf, self.buffer,
							\recLevel, 1.0,
							\preLevel, if(overdub, 1.0, 0.0)
						],
						addAction: \addToHead
					);

					self.isRecording = true;
					"Recording started (input: %, overdub: %)".format(
						inputChannel,
						overdub
					).postln;
				});
			});

			self;
		},

		/*
		Function: stopRecording
		Purpose: Stop recording
		*/
		stopRecording: {
			arg self;

			if(recordSynth.notNil, {
				recordSynth.free;
				recordSynth = nil;
				self.isRecording = false;
				"Recording stopped.".postln;
			});

			self;
		},

		/*
		Function: clear
		Purpose: Clear buffer contents (fill with silence)
		*/
		clear: {
			arg self;

			if(self.buffer.notNil, {
				self.buffer.zero;
				"Buffer cleared.".postln;
			});

			self;
		},

		/*
		Function: loadFile
		Purpose: Load an audio file into the buffer
		Args:
		  path: File path to audio file
		*/
		loadFile: {
			arg self, path;

			if(self.buffer.notNil, {
				self.buffer.readChannel(
					path,
					0, // start at beginning of file
					-1, // read entire file (or up to buffer size)
					0, // start at beginning of buffer
					channels: [0] // read first channel only
				);
				"File loaded: %".format(path).postln;
			});

			self;
		},

		/*
		Function: free
		Purpose: Free buffer and cleanup
		*/
		free: {
			arg self;

			self.stopRecording;

			if(self.buffer.notNil, {
				self.buffer.free;
				self.buffer = nil;
				"Buffer freed.".postln;
			});

			self;
		},

		/*
		Function: getBufferNum
		Purpose: Get buffer number for use in synths
		Returns: Buffer number (integer)
		*/
		getBufferNum: {
			arg self;
			if(self.buffer.notNil, {
				self.buffer.bufnum;
			}, {
				nil;
			});
		}
	);

	publicAPI;
};
)

/*
Usage example:
(
// Create buffer recorder
~recorder = ~s4BufferRecorder.value(s);
~recorder.init;

// Start recording from input 0
~recorder.startRecording(0, overdub: false);

// Wait a bit...
fork {
	4.wait;
	~recorder.stopRecording;
	"Recording complete!".postln;
};
)

// Use recorded buffer with grain engine
(
~grainSynth = Synth(\s4GrainEngine, [
	\bufnum, ~recorder.getBufferNum,
	\grainSize, 0.1,
	\density, 30,
	\position, 0.5
]);
)

// Cleanup
~recorder.free;
*/
