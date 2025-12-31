/*
S-4 Rival: Wide GUI Layout
All Phase 1, 2, 3 features in a wide horizontal layout
No ScrollView - just a wide window with columns
*/

(
~s4WideGUI = {
	arg grainSynth, recorder, server;
	var window, waveView, positionView, updateTask;
	var publicAPI;
	var makeSlider, makeButton;

	// Helper: Create labeled slider
	makeSlider = { arg parent, x, y, label, spec, param, default;
		StaticText(parent, Rect(x, y, 120, 18))
			.string_(label)
			.font_(Font("Monaco", 10));

		Slider(parent, Rect(x + 125, y, 150, 18))
			.value_(spec.unmap(default))
			.action_({ arg sl;
				var val = spec.map(sl.value);
				grainSynth.set(param, val);
			});

		NumberBox(parent, Rect(x + 280, y, 60, 18))
			.value_(default)
			.decimals_(3)
			.font_(Font("Monaco", 9))
			.action_({ arg nb;
				grainSynth.set(param, nb.value);
			});
	};

	// Helper: Create toggle button
	makeButton = { arg parent, x, y, w, label, param;
		Button(parent, Rect(x, y, w, 25))
			.states_([
				[label ++ " OFF", Color.black, Color.gray(0.5)],
				[label ++ " ON", Color.white, Color.green(0.6)]
			])
			.action_({ arg btn;
				grainSynth.set(param, btn.value);
			});
	};

	publicAPI = (
		window: nil,

		create: {
			arg self;
			var col1X = 10, col2X = 370, col3X = 730, col4X = 1090;
			var yPos;

			// Wide window: 1450px wide x 750px tall (extra space for waveform)
			window = Window("S-4 Rival v0.3.001 - Full Control", Rect(50, 50, 1450, 750))
				.front
				.onClose_({
					if(updateTask.notNil, { updateTask.stop; });
					"GUI closed.".postln;
				});

			// === COLUMN 1: RECORDING + GRAIN ===
			StaticText(window, Rect(col1X, 10, 350, 20))
				.string_("RECORDING + GRAIN")
				.font_(Font("Monaco", 12, true));

			// Input selector
			StaticText(window, Rect(col1X, 35, 80, 20))
				.string_("Input");
			PopUpMenu(window, Rect(col1X + 85, 35, 100, 20))
				.items_(["In 1", "In 2", "In 3", "In 4", "In 5", "In 6", "In 7", "In 8"])
				.value_(2)
				.action_({ arg menu; ~selectedInput = menu.value; });

			// Record buttons
			Button(window, Rect(col1X + 190, 35, 75, 25))
				.states_([
					["REC", Color.black, Color.green(0.7)],
					["STOP", Color.white, Color.red(0.7)]
				])
				.action_({ arg btn;
					if(btn.value == 1, {
						var inp = if(~selectedInput.notNil, ~selectedInput, 2);
						recorder.startRecording(inp, overdub: false);
					}, {
						recorder.stopRecording;
						// Refresh waveform after recording stops
						fork {
							0.1.wait;
							{
								waveView.soundfile_(recorder.buffer);
								waveView.read(0, recorder.buffer.numFrames);
								waveView.refresh;
							}.defer;
						};
					});
				});

			Button(window, Rect(col1X + 270, 35, 75, 25))
				.states_([["Clear", Color.black, Color.gray(0.7)]])
				.action_({ recorder.clear; });

			// Load test sound
			Button(window, Rect(col1X, 65, 170, 25))
				.states_([["Load Test Sound", Color.black, Color.cyan(0.7)]])
				.action_({
					var tempBuf = Buffer.alloc(server, server.sampleRate * 4, 1);
					tempBuf.sine1([1.0, 0.5, 0.3, 0.2, 0.15], true, true, true);
					fork {
						0.2.wait;
						tempBuf.copyData(recorder.buffer);
						0.2.wait;
						tempBuf.free;
						"✓ Test sound loaded!".postln;
						// Refresh waveform display
						{
							waveView.soundfile_(recorder.buffer);
							waveView.read(0, recorder.buffer.numFrames);
							waveView.refresh;
						}.defer;
					};
				});

			// Grain parameters
			yPos = 100;
			makeSlider.value(window, col1X, yPos, "Grain Size",
				ControlSpec(0.01, 0.5, \exp), \grainSize, 0.1);
			yPos = yPos + 25;
			makeSlider.value(window, col1X, yPos, "Density",
				ControlSpec(1, 200, \exp), \density, 30);
			yPos = yPos + 25;
			makeSlider.value(window, col1X, yPos, "Position",
				ControlSpec(0, 1), \position, 0.5);
			yPos = yPos + 25;
			makeSlider.value(window, col1X, yPos, "Pitch",
				ControlSpec(-24, 24), \pitch, 0);
			yPos = yPos + 25;
			makeSlider.value(window, col1X, yPos, "Pos Jitter",
				ControlSpec(0, 1), \posJitter, 0.1);
			yPos = yPos + 25;
			makeSlider.value(window, col1X, yPos, "Pitch Jitter",
				ControlSpec(0, 12), \pitchJitter, 0);
			yPos = yPos + 25;
			makeSlider.value(window, col1X, yPos, "Stereo Spread",
				ControlSpec(0, 1), \stereoSpread, 0.5);
			yPos = yPos + 25;
			makeSlider.value(window, col1X, yPos, "Amplitude",
				ControlSpec(0, 1), \amp, 0.5);

			// Envelope type
			yPos = yPos + 30;
			StaticText(window, Rect(col1X, yPos, 120, 18))
				.string_("Envelope");
			PopUpMenu(window, Rect(col1X + 125, yPos, 210, 20))
				.items_(["Percussive", "Sine", "Triangle", "Welch"])
				.value_(1)
				.action_({ arg menu;
					grainSynth.set(\envType, menu.value);
				});

			// === COLUMN 2: 48-BAND FILTER ===
			StaticText(window, Rect(col2X, 10, 350, 20))
				.string_("48-BAND MORPHING RESONATOR")
				.font_(Font("Monaco", 12, true));

			makeButton.value(window, col2X, 35, 170, "Filter", \filterOn);

			yPos = 70;
			makeSlider.value(window, col2X, yPos, "Frequency",
				ControlSpec(20, 2000, \exp), \filterFreq, 200);
			yPos = yPos + 25;
			makeSlider.value(window, col2X, yPos, "Morph (LP→BP→HP)",
				ControlSpec(0, 1), \filterMorph, 0.5);
			yPos = yPos + 25;
			makeSlider.value(window, col2X, yPos, "Resonance",
				ControlSpec(0, 1), \filterRes, 0.5);
			yPos = yPos + 25;
			makeSlider.value(window, col2X, yPos, "Decay",
				ControlSpec(0, 1), \filterDecay, 0.5);
			yPos = yPos + 25;
			makeSlider.value(window, col2X, yPos, "Mix (Dry/Wet)",
				ControlSpec(0, 1), \filterMix, 0.5);

			yPos = yPos + 30;
			StaticText(window, Rect(col2X, yPos, 350, 18))
				.string_("ANIMATION")
				.font_(Font("Monaco", 11, true));
			yPos = yPos + 25;
			makeSlider.value(window, col2X, yPos, "Animate Amount",
				ControlSpec(0, 1), \filterAnimate, 0);
			yPos = yPos + 25;
			makeSlider.value(window, col2X, yPos, "Animate Rate",
				ControlSpec(0.01, 10, \exp), \filterAnimRate, 0.5);

			yPos = yPos + 30;
			StaticText(window, Rect(col2X, yPos, 120, 18))
				.string_("Tuning");
			PopUpMenu(window, Rect(col2X + 125, yPos, 210, 20))
				.items_(["Harmonic", "Inharmonic"])
				.value_(0)
				.action_({ arg menu;
					grainSynth.set(\filterTuning, menu.value);
				});

			// === COLUMN 3: COLOR EFFECTS ===
			StaticText(window, Rect(col3X, 10, 350, 20))
				.string_("COLOR EFFECTS")
				.font_(Font("Monaco", 12, true));

			makeButton.value(window, col3X, 35, 170, "Color FX", \colorOn);

			yPos = 70;
			StaticText(window, Rect(col3X, yPos, 350, 18))
				.string_("DISTORTION")
				.font_(Font("Monaco", 11, true));
			yPos = yPos + 25;
			makeSlider.value(window, col3X, yPos, "Crossover Freq",
				ControlSpec(100, 2000, \exp), \distCrossover, 500);
			yPos = yPos + 25;
			makeSlider.value(window, col3X, yPos, "Low Drive",
				ControlSpec(1, 10, \exp), \distLoDrive, 1);
			yPos = yPos + 25;
			makeSlider.value(window, col3X, yPos, "High Drive",
				ControlSpec(1, 10, \exp), \distHiDrive, 1);
			yPos = yPos + 25;
			makeSlider.value(window, col3X, yPos, "Dist Mix",
				ControlSpec(0, 1), \distMix, 0);

			yPos = yPos + 30;
			StaticText(window, Rect(col3X, yPos, 350, 18))
				.string_("BIT CRUSHER")
				.font_(Font("Monaco", 11, true));
			yPos = yPos + 25;
			makeSlider.value(window, col3X, yPos, "Sample Rate",
				ControlSpec(100, 48000, \exp), \crushRate, 8000);
			yPos = yPos + 25;
			makeSlider.value(window, col3X, yPos, "Bit Depth",
				ControlSpec(1, 16), \crushBits, 8);
			yPos = yPos + 25;
			makeSlider.value(window, col3X, yPos, "Crush Mix",
				ControlSpec(0, 1), \crushMix, 0);

			yPos = yPos + 30;
			StaticText(window, Rect(col3X, yPos, 350, 18))
				.string_("COMPRESSOR + NOISE")
				.font_(Font("Monaco", 11, true));
			yPos = yPos + 25;
			makeSlider.value(window, col3X, yPos, "Comp Threshold",
				ControlSpec(0, 1), \compThresh, 0.5);
			yPos = yPos + 25;
			makeSlider.value(window, col3X, yPos, "Comp Ratio",
				ControlSpec(1, 20), \compRatio, 4);
			yPos = yPos + 25;
			makeSlider.value(window, col3X, yPos, "Noise Amount",
				ControlSpec(0, 1), \noiseAmount, 0);
			yPos = yPos + 25;
			StaticText(window, Rect(col3X, yPos, 120, 18))
				.string_("Noise Type");
			PopUpMenu(window, Rect(col3X + 125, yPos, 210, 20))
				.items_(["White", "Pink", "Brown"])
				.value_(0)
				.action_({ arg menu;
					grainSynth.set(\noiseType, menu.value);
				});

			// === COLUMN 4: SPACE EFFECTS ===
			StaticText(window, Rect(col4X, 10, 350, 20))
				.string_("SPACE EFFECTS")
				.font_(Font("Monaco", 12, true));

			makeButton.value(window, col4X, 35, 170, "Space FX", \spaceOn);

			yPos = 70;
			StaticText(window, Rect(col4X, yPos, 350, 18))
				.string_("REVERB")
				.font_(Font("Monaco", 11, true));
			yPos = yPos + 25;
			makeSlider.value(window, col4X, yPos, "Size",
				ControlSpec(0, 1), \reverbSize, 0.5);
			yPos = yPos + 25;
			makeSlider.value(window, col4X, yPos, "Damping",
				ControlSpec(0, 1), \reverbDamp, 0.5);
			yPos = yPos + 25;
			makeSlider.value(window, col4X, yPos, "Reverb Mix",
				ControlSpec(0, 1), \reverbMix, 0.3);
			yPos = yPos + 25;
			Button(window, Rect(col4X, yPos, 170, 25))
				.states_([
					["Freeze OFF", Color.black, Color.gray(0.5)],
					["Freeze ON", Color.white, Color.blue(0.8)]
				])
				.action_({ arg btn;
					grainSynth.set(\reverbFreeze, btn.value);
				});

			yPos = yPos + 35;
			StaticText(window, Rect(col4X, yPos, 350, 18))
				.string_("DELAY")
				.font_(Font("Monaco", 11, true));
			yPos = yPos + 25;
			makeSlider.value(window, col4X, yPos, "Time",
				ControlSpec(0.01, 2, \exp), \delayTime, 0.25);
			yPos = yPos + 25;
			makeSlider.value(window, col4X, yPos, "Feedback",
				ControlSpec(0, 0.95), \delayFeedback, 0.5);
			yPos = yPos + 25;
			makeSlider.value(window, col4X, yPos, "Filter Freq",
				ControlSpec(200, 10000, \exp), \delayFilter, 5000);
			yPos = yPos + 25;
			makeSlider.value(window, col4X, yPos, "Delay Mix",
				ControlSpec(0, 1), \delayMix, 0.3);
			yPos = yPos + 25;
			Button(window, Rect(col4X, yPos, 170, 25))
				.states_([
					["Ping-Pong OFF", Color.black, Color.gray(0.5)],
					["Ping-Pong ON", Color.white, Color.green(0.6)]
				])
				.action_({ arg btn;
					grainSynth.set(\delayPingPong, btn.value);
				});

			yPos = yPos + 35;
			StaticText(window, Rect(col4X, yPos, 350, 18))
				.string_("SHIMMER")
				.font_(Font("Monaco", 11, true));
			yPos = yPos + 25;
			makeSlider.value(window, col4X, yPos, "Shimmer Time",
				ControlSpec(0.1, 2, \exp), \shimmerTime, 0.5);
			yPos = yPos + 25;
			makeSlider.value(window, col4X, yPos, "Shimmer FB",
				ControlSpec(0, 0.9), \shimmerFeedback, 0.6);
			yPos = yPos + 25;
			makeSlider.value(window, col4X, yPos, "Pitch (semi)",
				ControlSpec(0, 24), \shimmerPitch, 12);
			yPos = yPos + 25;
			makeSlider.value(window, col4X, yPos, "Shimmer Mix",
				ControlSpec(0, 1), \shimmerMix, 0);

			// === WAVEFORM VIEW (Bottom) ===
			StaticText(window, Rect(10, 580, 1430, 18))
				.string_("WAVEFORM - 4 Second Buffer")
				.font_(Font("Monaco", 11, true))
				.align_(\center);

			// Waveform display
			waveView = SoundFileView(window, Rect(10, 605, 1430, 120))
				.gridOn_(true)
				.gridColor_(Color.gray(0.3))
				.waveColors_([Color.cyan(0.8)])
				.background_(Color.gray(0.1))
				.elasticMode_(1)
				.timeCursorOn_(true)
				.timeCursorColor_(Color.red)
				.timeCursorPosition_(0);

			// Load buffer into waveform view when available
			fork {
				0.5.wait;  // Wait for buffer to be ready
				if(recorder.buffer.notNil, {
					{
						waveView.soundfile_(recorder.buffer);
						waveView.read(0, recorder.buffer.numFrames);
						waveView.refresh;
					}.defer;
				});
			};

			// Update position cursor based on Position parameter
			// Note: Using get() is async - for real-time display we'd need OSC feedback
			// For now, just disable the cursor update to avoid threading errors
			// Users can see position via the slider value
			updateTask = nil;

			// Refresh waveform button
			Button(window, Rect(1290, 732, 150, 20))
				.states_([["Refresh Waveform", Color.white, Color.gray(0.3)]])
				.action_({
					if(recorder.buffer.notNil, {
						{
							waveView.soundfile_(recorder.buffer);
							waveView.read(0, recorder.buffer.numFrames);
							waveView.refresh;
						}.defer;
						"Waveform refreshed".postln;
					});
				});

			self.window = window;
			self;
		},

		close: {
			arg self;
			if(updateTask.notNil, { updateTask.stop; });
			if(window.notNil, { window.close; });
		}
	);

	publicAPI;
};
)
