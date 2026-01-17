/*
BEARULATOR: RECORDING VIEWFINDER (Phase 12)
===========================================

Live audio recording window with real-time waveform visualization.
Select regions and send them to any of the 4 granulator tracks.

Features:
- Live audio input monitoring
- Real-time waveform display (SoundFileView)
- Region selection with visual markers
- Send selected regions to granulator tracks
- Transport controls (Record/Stop/Play)
- Input source selection (8 channels, MOTU Mk5 support)
- Scrubbing/playback of recorded audio

Usage:
  ~recordingViewfinder = ~s4RecordingViewfinder.value(server, trackManager);
  ~recordingViewfinder.createWindow();
  ~recordingViewfinder.free;
*/

~s4RecordingViewfinder = { arg server, trackManager;
	var window, sfv, publicAPI;
	var recordBuffer, recordSynth;
	var isRecording = false, isPlaying = false;
	var recordingDuration = 0;
	var selectedRegion = nil;  // [start, end] in seconds
	var colors;

	// Doom Material color palette
	colors = (
		bg: Color.fromHexString("#262938"),
		fg: Color.fromHexString("#EEFFFF"),
		cyan: Color.fromHexString("#89DDFF"),
		yellow: Color.fromHexString("#ffcb6b"),
		green: Color.fromHexString("#c3e88d"),
		red: Color.fromHexString("#ff5370"),
		orange: Color.fromHexString("#f78c6c")
	);

	publicAPI = (
		// Create recording viewfinder window
		createWindow: { arg self;
			var winWidth = 900, winHeight = 500;
			var recordBtn, stopBtn, playBtn, sendBtn;
			var inputSelector, targetTrackSelector;
			var statusText, regionText;
			var currentInputChannel = 0;
			var targetTrack = 0;

			// Close existing window if open
			if(window.notNil, { window.close });

			// Create recording buffer (10 seconds default, expandable)
			recordBuffer = Buffer.alloc(server, server.sampleRate * 10, 1);

			// Create window
			window = Window("BEARULATOR: Recording Viewfinder", Rect(200, 200, winWidth, winHeight))
				.background_(colors.bg)
				.front;

			// Title
			StaticText(window, Rect(10, 10, 400, 30))
				.string_("RECORDING VIEWFINDER")
				.font_(Font("DejaVu Sans Mono", 16, true))
				.stringColor_(colors.cyan);

			// === WAVEFORM DISPLAY ===
			sfv = SoundFileView(window, Rect(10, 60, winWidth - 20, 200))
				.background_(colors.bg)
				.waveColors_([colors.cyan])
				.gridOn_(false)
				.timeCursorOn_(true)
				.timeCursorColor_(colors.yellow)
				.timeCursorPosition_(0)
				.elasticMode_(1);  // Elastic selection

			// Set selection color
			sfv.setSelectionColor(0, colors.orange.alpha_(0.5));

			// Mouse selection action
			sfv.mouseUpAction = { arg view;
				var sel = view.selection(0);
				if(sel.notNil and: { sel[1] > 0 }, {
					var startFrame = sel[0];
					var duration = sel[1];
					var endFrame = startFrame + duration;
					var sampleRate = server.sampleRate;

					selectedRegion = [
						startFrame / sampleRate,  // start in seconds
						endFrame / sampleRate      // end in seconds
					];

					// Update region text
					{
						regionText.string = "Selected: %.2f - %.2f sec (%.2f sec)".format(
							selectedRegion[0],
							selectedRegion[1],
							selectedRegion[1] - selectedRegion[0]
						);
					}.defer;

					"Region selected: % - % sec".format(
						selectedRegion[0].round(0.01),
						selectedRegion[1].round(0.01)
					).postln;
				});
			};

			// === TRANSPORT CONTROLS ===
			var yPos = 275;

			// Record button
			recordBtn = Button(window, Rect(10, yPos, 100, 40))
				.states_([
					["● REC", colors.fg, Color.gray(0.3)],
					["● REC", colors.bg, colors.red]
				])
				.font_(Font("Monaco", 14, true))
				.action_({ arg btn;
					if(btn.value == 1, {
						self.startRecording(currentInputChannel);
					}, {
						self.stopRecording;
					});
				});

			// Stop button
			stopBtn = Button(window, Rect(115, yPos, 100, 40))
				.states_([["■ STOP", colors.fg, Color.gray(0.3)]])
				.font_(Font("Monaco", 14, true))
				.action_({
					self.stopRecording;
					self.stopPlayback;
					recordBtn.value = 0;
				});

			// Play button
			playBtn = Button(window, Rect(220, yPos, 100, 40))
				.states_([
					["▶ PLAY", colors.fg, Color.gray(0.3)],
					["▶ PLAY", colors.bg, colors.green]
				])
				.font_(Font("Monaco", 14, true))
				.action_({ arg btn;
					if(btn.value == 1, {
						self.startPlayback;
					}, {
						self.stopPlayback;
					});
				});

			// Send to Track button
			sendBtn = Button(window, Rect(325, yPos, 150, 40))
				.states_([["→ Send to Track", colors.bg, colors.cyan]])
				.font_(Font("Monaco", 12, true))
				.action_({
					if(selectedRegion.notNil, {
						self.sendRegionToTrack(selectedRegion, targetTrack);
					}, {
						"No region selected. Drag to select a region first.".warn;
					});
				});

			// === INPUT/OUTPUT SELECTORS ===
			yPos = yPos + 50;

			// Input channel selector
			StaticText(window, Rect(10, yPos, 100, 20))
				.string_("Input Channel:")
				.font_(Font("DejaVu Sans Mono", 10))
				.stringColor_(colors.fg);

			inputSelector = PopUpMenu(window, Rect(120, yPos, 100, 25))
				.items_(["In 1", "In 2", "In 3", "In 4", "In 5", "In 6", "In 7", "In 8"])
				.value_(0)
				.action_({ arg menu;
					currentInputChannel = menu.value;
					"Input channel: In %".format(currentInputChannel + 1).postln;
				});

			// Target track selector
			StaticText(window, Rect(240, yPos, 100, 20))
				.string_("Target Track:")
				.font_(Font("DejaVu Sans Mono", 10))
				.stringColor_(colors.fg);

			targetTrackSelector = PopUpMenu(window, Rect(350, yPos, 100, 25))
				.items_(["Track 1", "Track 2", "Track 3", "Track 4"])
				.value_(0)
				.action_({ arg menu;
					targetTrack = menu.value;
					"Target track: Track %".format(targetTrack + 1).postln;
				});

			// === STATUS DISPLAY ===
			yPos = yPos + 40;

			statusText = StaticText(window, Rect(10, yPos, winWidth - 20, 25))
				.string_("Ready to record. Select input channel and press REC.")
				.font_(Font("Monaco", 11))
				.stringColor_(colors.cyan);

			self.statusText = statusText;  // Store reference

			yPos = yPos + 30;

			regionText = StaticText(window, Rect(10, yPos, winWidth - 20, 25))
				.string_("No region selected. Drag on waveform to select.")
				.font_(Font("Monaco", 10))
				.stringColor_(Color.gray(0.7));

			// === INSTRUCTIONS ===
			yPos = yPos + 40;

			StaticText(window, Rect(10, yPos, winWidth - 20, 60))
				.string_(
					"WORKFLOW:\n" ++
					"1. Select input channel (In 1-8) | 2. Press REC to start recording | 3. Press STOP to finish\n" ++
					"4. Drag on waveform to select region | 5. Choose target track | 6. Press 'Send to Track'"
				)
				.font_(Font("DejaVu Sans Mono", 9))
				.stringColor_(Color.gray(0.6));

			// Store SoundFileView reference
			self.sfv = sfv;
			self.window = window;

			// Window close action
			window.onClose = {
				self.cleanup;
				"Recording viewfinder closed.".postln;
			};

			"Recording Viewfinder created.".postln;
		},

		// Start recording from input channel
		startRecording: { arg self, inputChannel = 0;
			if(isRecording.not, {
				"Recording from input %...".format(inputChannel + 1).postln;

				// Free old recording buffer and create new one
				recordBuffer.free;
				recordBuffer = Buffer.alloc(server, server.sampleRate * 10, 1);

				// Create recording synth
				recordSynth = {
					var sig = SoundIn.ar(inputChannel) * 3.0;  // 3x input gain boost
					RecordBuf.ar(sig, recordBuffer, loop: 0, doneAction: 2);
					Silent.ar;
				}.play(server);

				isRecording = true;
				recordingDuration = 0;

				// Update status
				{
					self.statusText.string = "● RECORDING from In %...".format(inputChannel + 1);
					self.statusText.stringColor = colors.red;
				}.defer;

				// Start duration counter
				{
					while({ isRecording }, {
						recordingDuration = recordingDuration + 0.1;
						{
							self.statusText.string = "● RECORDING: %.1f sec".format(recordingDuration);
						}.defer;
						0.1.wait;
					});
				}.fork(AppClock);
			});
		},

		// Stop recording
		stopRecording: { arg self;
			if(isRecording, {
				"Recording stopped. Duration: % sec".format(recordingDuration.round(0.1)).postln;

				// Free recording synth
				if(recordSynth.notNil, {
					recordSynth.free;
					recordSynth = nil;
				});

				isRecording = false;

				// Update waveform display
				{
					0.2.wait;  // Wait for buffer to finalize
					{
						self.sfv.soundfile = recordBuffer;
						self.sfv.read(0, recordBuffer.numFrames);
						self.sfv.refresh;
						self.statusText.string = "Recording complete: %.1f sec. Drag to select region.".format(recordingDuration);
						self.statusText.stringColor = colors.green;
					}.defer;
				}.fork(AppClock);
			});
		},

		// Start playback of recorded buffer
		startPlayback: { arg self;
			if(isPlaying.not and: { recordBuffer.notNil }, {
				"Playing recorded audio...".postln;

				// Play recorded buffer
				recordSynth = {
					var sig = PlayBuf.ar(1, recordBuffer, BufRateScale.kr(recordBuffer), doneAction: 2);
					Out.ar(0, sig ! 2);  // Mono to stereo
				}.play(server);

				isPlaying = true;

				// Update status
				{
					self.statusText.string = "▶ PLAYING recorded audio...";
					self.statusText.stringColor = colors.green;
				}.defer;

				// Auto-stop when done
				{
					(recordBuffer.numFrames / server.sampleRate).wait;
					isPlaying = false;
					{
						self.statusText.string = "Playback complete.";
						self.statusText.stringColor = colors.cyan;
					}.defer;
				}.fork(AppClock);
			});
		},

		// Stop playback
		stopPlayback: { arg self;
			if(isPlaying, {
				if(recordSynth.notNil, {
					recordSynth.free;
					recordSynth = nil;
				});
				isPlaying = false;
				{
					self.statusText.string = "Playback stopped.";
					self.statusText.stringColor = colors.cyan;
				}.defer;
			});
		},

		// Send selected region to granulator track
		sendRegionToTrack: { arg self, region, trackNum;
			var startSec = region[0];
			var endSec = region[1];
			var startFrame = (startSec * server.sampleRate).asInteger;
			var endFrame = (endSec * server.sampleRate).asInteger;
			var numFrames = endFrame - startFrame;
			var track = trackManager.getTrack(trackNum);
			var newBuffer;

			"Sending region %.2f-%.2f sec to Track %...".format(startSec, endSec, trackNum + 1).postln;

			// Create new buffer for the selected region
			newBuffer = Buffer.alloc(server, numFrames, 1);

			// Copy selected region to new buffer
			{
				server.sync;  // Wait for buffer allocation

				// Use Buffer.copyData to transfer audio
				recordBuffer.copyData(newBuffer, dstStartAt: 0, srcStartAt: startFrame, numSamples: numFrames);

				server.sync;  // Wait for copy to complete

				// Replace track buffer
				if(track.recorder.buffer.notNil, {
					track.recorder.buffer.free;  // Free old buffer
				});

				track.recorder.buffer = newBuffer;

				// Update track parameters
				trackManager.setParam(trackNum, \loopStart, 0.0);
				trackManager.setParam(trackNum, \loopEnd, 1.0);

				// Update viewfinder if open
				if(~viewfinder.notNil, {
					~viewfinder.updateWaveform(trackNum);
				});

				"Region sent to Track %. Duration: %.2f sec".format(
					trackNum + 1,
					numFrames / server.sampleRate
				).postln;

				// Update status
				{
					self.statusText.string = "✓ Region sent to Track % (%.2f sec)".format(
						trackNum + 1,
						numFrames / server.sampleRate
					);
					self.statusText.stringColor = colors.green;
				}.defer;
			}.fork;
		},

		// Cleanup resources
		cleanup: { arg self;
			self.stopRecording;
			self.stopPlayback;

			if(recordBuffer.notNil, {
				recordBuffer.free;
				recordBuffer = nil;
			});

			"Recording viewfinder cleanup complete.".postln;
		},

		// Free resources
		free: { arg self;
			if(window.notNil, { window.close });
			self.cleanup;
		}
	);

	publicAPI;
};

/*
USAGE EXAMPLES:

// Create recording viewfinder module (do this in main.scd)
~recordingViewfinder = ~s4RecordingViewfinder.value(s, ~trackManager);

// Open recording viewfinder
~recordingViewfinder.createWindow();

// Cleanup
~recordingViewfinder.free;
*/
