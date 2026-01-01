/*
S-4 Rival: Four-Track GUI
Phase 4 - Tabbed Interface

5 tabs:
- Track 1, Track 2, Track 3, Track 4 (full controls each)
- Master (48-band filter + track overview)

Each track tab contains:
- Recording controls + Load Test Sound
- Grain parameters
- Color effects
- Space effects
- Waveform display
*/

~s4FourTrackGUI = {
	arg trackManager, masterBus, server;
	var window, tabView, updateTasks;
	var publicAPI;

	// Track update tasks for waveform displays
	updateTasks = Array.newClear(4);

	// ========================================
	// HELPER: Create labeled slider
	// ========================================
	var makeSlider = { arg parent, x, y, label, spec, param, trackNum, default;
		StaticText(parent, Rect(x, y, 120, 18))
			.string_(label)
			.font_(Font("Monaco", 10));

		Slider(parent, Rect(x + 125, y, 150, 18))
			.value_(spec.unmap(default))
			.action_({ arg sl;
				var val = spec.map(sl.value);
				trackManager.setParam(trackNum, param, val);
			});

		NumberBox(parent, Rect(x + 280, y, 60, 18))
			.value_(default)
			.decimals_(3)
			.font_(Font("Monaco", 9))
			.action_({ arg nb;
				trackManager.setParam(trackNum, param, nb.value);
			});
	};

	// ========================================
	// HELPER: Create toggle button
	// ========================================
	var makeButton = { arg parent, x, y, w, label, param, trackNum;
		Button(parent, Rect(x, y, w, 25))
			.states_([
				[label ++ " OFF", Color.black, Color.gray(0.5)],
				[label ++ " ON", Color.white, Color.green(0.6)]
			])
			.action_({ arg btn;
				trackManager.setParam(trackNum, param, btn.value);
			});
	};

	// ========================================
	// HELPER: Create master bus slider
	// ========================================
	var makeMasterSlider = { arg parent, x, y, label, spec, param, default;
		StaticText(parent, Rect(x, y, 120, 18))
			.string_(label)
			.font_(Font("Monaco", 10));

		Slider(parent, Rect(x + 125, y, 150, 18))
			.value_(spec.unmap(default))
			.action_({ arg sl;
				var val = spec.map(sl.value);
				masterBus.set(param, val);
			});

		NumberBox(parent, Rect(x + 280, y, 60, 18))
			.value_(default)
			.decimals_(3)
			.font_(Font("Monaco", 9))
			.action_({ arg nb;
				masterBus.set(param, nb.value);
			});
	};

	// ========================================
	// HELPER: Create master bus button
	// ========================================
	var makeMasterButton = { arg parent, x, y, w, label, param;
		Button(parent, Rect(x, y, w, 25))
			.states_([
				[label ++ " OFF", Color.black, Color.gray(0.5)],
				[label ++ " ON", Color.white, Color.green(0.6)]
			])
			.action_({ arg btn;
				masterBus.set(param, btn.value);
			});
	};

	// ========================================
	// CREATE TRACK TAB (full controls)
	// ========================================
	var makeTrackTab = { arg parent, trackNum;
		var track = trackManager.getTrack(trackNum);
		var waveView, positionView;
		var col1X = 10, col2X = 370, col3X = 730;
		var yPos;

		// === TOP: TRACK CONTROLS ===
		StaticText(parent, Rect(10, 10, 200, 25))
			.string_("TRACK " ++ (trackNum + 1))
			.font_(Font("Monaco", 14, true))
			.stringColor_(Color.cyan);

		// Volume
		StaticText(parent, Rect(220, 10, 50, 20))
			.string_("Volume")
			.font_(Font("Monaco", 9));
		Slider(parent, Rect(220, 30, 120, 20))
			.value_(0.8)
			.action_({ arg sl;
				trackManager.setVolume(trackNum, sl.value);
			});

		// Pan
		StaticText(parent, Rect(350, 10, 50, 20))
			.string_("Pan")
			.font_(Font("Monaco", 9));
		Slider(parent, Rect(350, 30, 120, 20))
			.value_(0.5)
			.action_({ arg sl;
				trackManager.setPan(trackNum, sl.value.linlin(0, 1, -1, 1));
			});

		// Mute
		Button(parent, Rect(480, 10, 60, 40))
			.states_([
				["MUTE", Color.black, Color.gray(0.5)],
				["MUTE", Color.white, Color.red(0.7)]
			])
			.action_({ arg btn;
				trackManager.setMute(trackNum, btn.value.asBoolean);
			});

		// Solo
		Button(parent, Rect(545, 10, 60, 40))
			.states_([
				["SOLO", Color.black, Color.gray(0.5)],
				["SOLO", Color.white, Color.yellow(0.8)]
			])
			.action_({ arg btn;
				trackManager.setSolo(trackNum, btn.value.asBoolean);
			});

		// === COLUMN 1: RECORDING + GRAIN ===
		yPos = 60;
		StaticText(parent, Rect(col1X, yPos, 350, 20))
			.string_("RECORDING + GRAIN")
			.font_(Font("Monaco", 12, true));

		yPos = yPos + 25;

		// Load Test Sound button
		Button(parent, Rect(col1X, yPos, 150, 30))
			.states_([["Load Test Sound", Color.black, Color.cyan(0.6)]])
			.action_({
				track.recorder.loadTestSound;
				fork {
					0.1.wait;
					{
						waveView.soundfile_(track.recorder.buffer);
						waveView.read(0, track.recorder.buffer.numFrames);
						waveView.refresh;
					}.defer;
				};
			});

		// Input selector
		StaticText(parent, Rect(col1X + 160, yPos, 50, 20))
			.string_("Input")
			.font_(Font("Monaco", 9));
		PopUpMenu(parent, Rect(col1X + 210, yPos, 70, 20))
			.items_(["In 1", "In 2", "In 3", "In 4", "In 5", "In 6", "In 7", "In 8"])
			.value_(2)
			.action_({ arg menu;
				("Track " ++ (trackNum + 1) ++ " input: " ++ menu.value).postln;
			});

		// Record button
		Button(parent, Rect(col1X + 285, yPos, 70, 25))
			.states_([
				["REC", Color.black, Color.green(0.7)],
				["STOP", Color.white, Color.red(0.7)]
			])
			.action_({ arg btn;
				if(btn.value == 1, {
					track.recorder.startRecording(2, overdub: false);
				}, {
					track.recorder.stopRecording;
					fork {
						0.1.wait;
						{
							waveView.soundfile_(track.recorder.buffer);
							waveView.read(0, track.recorder.buffer.numFrames);
							waveView.refresh;
						}.defer;
					};
				});
			});

		yPos = yPos + 40;

		// Grain controls
		makeSlider.value(parent, col1X, yPos, "Grain Size", ControlSpec(0.01, 0.5, \lin), \grainSize, trackNum, 0.1);
		yPos = yPos + 22;
		makeSlider.value(parent, col1X, yPos, "Density", ControlSpec(1, 200, \lin), \density, trackNum, 30);
		yPos = yPos + 22;
		makeSlider.value(parent, col1X, yPos, "Position", ControlSpec(0, 1, \lin), \position, trackNum, 0.5);
		yPos = yPos + 22;
		makeSlider.value(parent, col1X, yPos, "Pitch", ControlSpec(-24, 24, \lin), \pitch, trackNum, 0);
		yPos = yPos + 22;
		makeSlider.value(parent, col1X, yPos, "Pos Jitter", ControlSpec(0, 1, \lin), \posJitter, trackNum, 0.1);
		yPos = yPos + 22;
		makeSlider.value(parent, col1X, yPos, "Pitch Jitter", ControlSpec(0, 12, \lin), \pitchJitter, trackNum, 0);
		yPos = yPos + 22;
		makeSlider.value(parent, col1X, yPos, "Stereo Spread", ControlSpec(0, 1, \lin), \stereoSpread, trackNum, 0.5);
		yPos = yPos + 22;
		makeSlider.value(parent, col1X, yPos, "Amplitude", ControlSpec(0, 1, \lin), \amp, trackNum, 0.5);

		yPos = yPos + 30;
		StaticText(parent, Rect(col1X, yPos, 120, 18))
			.string_("Envelope Type")
			.font_(Font("Monaco", 10));
		PopUpMenu(parent, Rect(col1X + 125, yPos, 150, 20))
			.items_(["Percussive", "Sine", "Triangle", "Welch"])
			.value_(1)
			.action_({ arg menu;
				trackManager.setParam(trackNum, \envType, menu.value);
			});

		// === COLUMN 2: COLOR EFFECTS ===
		yPos = 60;
		StaticText(parent, Rect(col2X, yPos, 350, 20))
			.string_("COLOR EFFECTS")
			.font_(Font("Monaco", 12, true));

		yPos = yPos + 25;
		makeButton.value(parent, col2X, yPos, 100, "Color FX", \colorOn, trackNum);

		yPos = yPos + 35;
		StaticText(parent, Rect(col2X, yPos, 350, 18))
			.string_("DISTORTION")
			.font_(Font("Monaco", 10, true));
		yPos = yPos + 22;
		makeSlider.value(parent, col2X, yPos, "Crossover", ControlSpec(100, 2000, \exp), \distCrossover, trackNum, 500);
		yPos = yPos + 22;
		makeSlider.value(parent, col2X, yPos, "Lo Drive", ControlSpec(1, 10, \exp), \distLoDrive, trackNum, 1);
		yPos = yPos + 22;
		makeSlider.value(parent, col2X, yPos, "Hi Drive", ControlSpec(1, 10, \exp), \distHiDrive, trackNum, 1);
		yPos = yPos + 22;
		makeSlider.value(parent, col2X, yPos, "Dist Mix", ControlSpec(0, 1, \lin), \distMix, trackNum, 0);

		yPos = yPos + 30;
		StaticText(parent, Rect(col2X, yPos, 350, 18))
			.string_("BIT CRUSHER")
			.font_(Font("Monaco", 10, true));
		yPos = yPos + 22;
		makeSlider.value(parent, col2X, yPos, "Sample Rate", ControlSpec(100, 48000, \exp), \crushRate, trackNum, 8000);
		yPos = yPos + 22;
		makeSlider.value(parent, col2X, yPos, "Bit Depth", ControlSpec(1, 16, \lin), \crushBits, trackNum, 8);
		yPos = yPos + 22;
		makeSlider.value(parent, col2X, yPos, "Crush Mix", ControlSpec(0, 1, \lin), \crushMix, trackNum, 0);

		yPos = yPos + 30;
		StaticText(parent, Rect(col2X, yPos, 350, 18))
			.string_("COMPRESSOR")
			.font_(Font("Monaco", 10, true));
		yPos = yPos + 22;
		makeSlider.value(parent, col2X, yPos, "Threshold", ControlSpec(0, 1, \lin), \compThresh, trackNum, 0.5);
		yPos = yPos + 22;
		makeSlider.value(parent, col2X, yPos, "Ratio", ControlSpec(1, 20, \lin), \compRatio, trackNum, 4);

		yPos = yPos + 30;
		StaticText(parent, Rect(col2X, yPos, 350, 18))
			.string_("NOISE")
			.font_(Font("Monaco", 10, true));
		yPos = yPos + 22;
		PopUpMenu(parent, Rect(col2X + 125, yPos, 150, 20))
			.items_(["White", "Pink", "Brown"])
			.value_(0)
			.action_({ arg menu;
				trackManager.setParam(trackNum, \noiseType, menu.value);
			});
		yPos = yPos + 22;
		makeSlider.value(parent, col2X, yPos, "Noise Amount", ControlSpec(0, 0.5, \lin), \noiseAmount, trackNum, 0);

		// === COLUMN 3: SPACE EFFECTS ===
		yPos = 60;
		StaticText(parent, Rect(col3X, yPos, 350, 20))
			.string_("SPACE EFFECTS")
			.font_(Font("Monaco", 12, true));

		yPos = yPos + 25;
		makeButton.value(parent, col3X, yPos, 100, "Space FX", \spaceOn, trackNum);

		yPos = yPos + 35;
		StaticText(parent, Rect(col3X, yPos, 350, 18))
			.string_("REVERB")
			.font_(Font("Monaco", 10, true));
		yPos = yPos + 22;
		makeSlider.value(parent, col3X, yPos, "Size", ControlSpec(0, 1, \lin), \reverbSize, trackNum, 0.5);
		yPos = yPos + 22;
		makeSlider.value(parent, col3X, yPos, "Damping", ControlSpec(0, 1, \lin), \reverbDamp, trackNum, 0.5);
		yPos = yPos + 22;
		makeSlider.value(parent, col3X, yPos, "Freeze", ControlSpec(0, 1, \lin), \reverbFreeze, trackNum, 0);
		yPos = yPos + 22;
		makeSlider.value(parent, col3X, yPos, "Reverb Mix", ControlSpec(0, 1, \lin), \reverbMix, trackNum, 0.3);

		yPos = yPos + 30;
		StaticText(parent, Rect(col3X, yPos, 350, 18))
			.string_("DELAY")
			.font_(Font("Monaco", 10, true));
		yPos = yPos + 22;
		makeSlider.value(parent, col3X, yPos, "Time", ControlSpec(0.01, 2.0, \exp), \delayTime, trackNum, 0.25);
		yPos = yPos + 22;
		makeSlider.value(parent, col3X, yPos, "Feedback", ControlSpec(0, 0.95, \lin), \delayFeedback, trackNum, 0.5);
		yPos = yPos + 22;
		makeSlider.value(parent, col3X, yPos, "Filter", ControlSpec(100, 10000, \exp), \delayFilter, trackNum, 5000);
		yPos = yPos + 22;
		makeSlider.value(parent, col3X, yPos, "Delay Mix", ControlSpec(0, 1, \lin), \delayMix, trackNum, 0.3);
		yPos = yPos + 22;
		Button(parent, Rect(col3X + 125, yPos, 150, 20))
			.states_([
				["Ping-Pong OFF", Color.black, Color.gray(0.5)],
				["Ping-Pong ON", Color.white, Color.green(0.6)]
			])
			.action_({ arg btn;
				trackManager.setParam(trackNum, \delayPingPong, btn.value);
			});

		yPos = yPos + 30;
		StaticText(parent, Rect(col3X, yPos, 350, 18))
			.string_("SHIMMER")
			.font_(Font("Monaco", 10, true));
		yPos = yPos + 22;
		makeSlider.value(parent, col3X, yPos, "Time", ControlSpec(0.1, 2.0, \exp), \shimmerTime, trackNum, 0.5);
		yPos = yPos + 22;
		makeSlider.value(parent, col3X, yPos, "Feedback", ControlSpec(0, 0.95, \lin), \shimmerFeedback, trackNum, 0.6);
		yPos = yPos + 22;
		makeSlider.value(parent, col3X, yPos, "Pitch", ControlSpec(-12, 24, \lin), \shimmerPitch, trackNum, 12);
		yPos = yPos + 22;
		makeSlider.value(parent, col3X, yPos, "Shimmer Mix", ControlSpec(0, 1, \lin), \shimmerMix, trackNum, 0);

		// === WAVEFORM DISPLAY ===
		StaticText(parent, Rect(10, 540, 200, 20))
			.string_("WAVEFORM")
			.font_(Font("Monaco", 10, true));

		waveView = SoundFileView(parent, Rect(10, 565, 1420, 150))
			.background_(Color.black)
			.waveColors_([Color.cyan(0.8)])
			.gridOn_(false)
			.resize_(5);

		// Position indicator
		positionView = UserView(parent, Rect(10, 565, 1420, 150))
			.background_(Color.clear)
			.drawFunc_({
				var pos = trackManager.getTrack(trackNum).params[\position] ? 0.5;
				var x = pos * 1420;
				Pen.color = Color.red(0.8);
				Pen.line(Point(x, 0), Point(x, 150));
				Pen.stroke;
			})
			.resize_(5);

		// Update position indicator
		updateTasks[trackNum] = Routine({
			loop {
				{ positionView.refresh }.defer;
				0.1.wait;
			}
		}).play(AppClock);

		// Load initial waveform
		fork {
			0.2.wait;
			{
				waveView.soundfile_(track.recorder.buffer);
				waveView.read(0, track.recorder.buffer.numFrames);
				waveView.refresh;
			}.defer;
		};
	};

	// ========================================
	// CREATE MASTER TAB
	// ========================================
	var makeMasterTab = { arg parent;
		var yPos = 10;

		StaticText(parent, Rect(10, yPos, 400, 30))
			.string_("MASTER CONTROLS")
			.font_(Font("Monaco", 16, true))
			.stringColor_(Color.cyan);

		yPos = yPos + 40;

		// === 48-BAND MORPHING RESONATOR ===
		StaticText(parent, Rect(10, yPos, 400, 25))
			.string_("48-BAND MORPHING RESONATOR (Shared)")
			.font_(Font("Monaco", 12, true));

		yPos = yPos + 30;
		makeMasterButton.value(parent, 10, yPos, 150, "Filter", \filterOn);

		yPos = yPos + 35;
		makeMasterSlider.value(parent, 10, yPos, "Frequency", ControlSpec(20, 2000, \exp), \filterFreq, 200);
		yPos = yPos + 22;
		makeMasterSlider.value(parent, 10, yPos, "Morph (LP→BP→HP)", ControlSpec(0, 1, \lin), \filterMorph, 0.5);
		yPos = yPos + 22;
		makeMasterSlider.value(parent, 10, yPos, "Resonance", ControlSpec(0, 1, \lin), \filterRes, 0.5);
		yPos = yPos + 22;
		makeMasterSlider.value(parent, 10, yPos, "Decay", ControlSpec(0, 1, \lin), \filterDecay, 0.5);
		yPos = yPos + 22;
		makeMasterSlider.value(parent, 10, yPos, "Animate", ControlSpec(0, 1, \lin), \filterAnimate, 0);
		yPos = yPos + 22;
		makeMasterSlider.value(parent, 10, yPos, "Anim Rate", ControlSpec(0.01, 10, \exp), \filterAnimRate, 0.5);
		yPos = yPos + 22;
		makeMasterSlider.value(parent, 10, yPos, "Filter Mix", ControlSpec(0, 1, \lin), \filterMix, 0.5);

		yPos = yPos + 40;

		// === TRACK OVERVIEW ===
		StaticText(parent, Rect(10, yPos, 400, 25))
			.string_("TRACK OVERVIEW")
			.font_(Font("Monaco", 12, true));

		yPos = yPos + 30;

		4.do({ arg i;
			var trackY = yPos + (i * 50);

			StaticText(parent, Rect(10, trackY, 80, 20))
				.string_("TRACK " ++ (i + 1))
				.font_(Font("Monaco", 11, true));

			// Mute
			Button(parent, Rect(100, trackY, 60, 35))
				.states_([
					["MUTE", Color.black, Color.gray(0.5)],
					["MUTE", Color.white, Color.red(0.7)]
				])
				.action_({ arg btn;
					trackManager.setMute(i, btn.value.asBoolean);
				});

			// Solo
			Button(parent, Rect(165, trackY, 60, 35))
				.states_([
					["SOLO", Color.black, Color.gray(0.5)],
					["SOLO", Color.white, Color.yellow(0.8)]
				])
				.action_({ arg btn;
					trackManager.setSolo(i, btn.value.asBoolean);
				});

			// Volume
			StaticText(parent, Rect(235, trackY, 50, 20))
				.string_("Vol")
				.font_(Font("Monaco", 9));
			Slider(parent, Rect(235, trackY + 18, 180, 18))
				.value_(0.8)
				.action_({ arg sl;
					trackManager.setVolume(i, sl.value);
				});

			// Pan
			StaticText(parent, Rect(425, trackY, 50, 20))
				.string_("Pan")
				.font_(Font("Monaco", 9));
			Slider(parent, Rect(425, trackY + 18, 180, 18))
				.value_(0.5)
				.action_({ arg sl;
					trackManager.setPan(i, sl.value.linlin(0, 1, -1, 1));
				});
		});

		yPos = yPos + 220;

		// === MASTER OUTPUT ===
		StaticText(parent, Rect(10, yPos, 400, 25))
			.string_("MASTER OUTPUT")
			.font_(Font("Monaco", 12, true));

		yPos = yPos + 30;
		makeMasterSlider.value(parent, 10, yPos, "Master Volume", ControlSpec(0, 1, \lin), \masterVol, 0.8);

		yPos = yPos + 40;
		StaticText(parent, Rect(10, yPos, 400, 60))
			.string_("CPU Monitor:\nUse s.avgCPU and s.peakCPU to check performance.\nTarget: <50% average, <80% peak")
			.font_(Font("Monaco", 10))
			.stringColor_(Color.gray(0.7));
	};

	// ========================================
	// PUBLIC API
	// ========================================
	publicAPI = (
		window: nil,

		create: {
			window = Window("S-4 Rival v0.4 - 4-Track Workstation", Rect(50, 50, 1450, 750))
				.onClose_({
					updateTasks.do({ arg task;
						if(task.notNil, { task.stop; });
					});
					"Four-track GUI closed.".postln;
				});

			// Create tabbed view
			tabView = TabbedView(window, Rect(0, 0, 1450, 750))
				.font_(Font("Monaco", 11));

			// Create 4 track tabs
			4.do({ arg i;
				var tab = tabView.add("TRACK " ++ (i + 1));
				makeTrackTab.value(tab.view, i);
			});

			// Create master tab
			var masterTab = tabView.add("MASTER");
			makeMasterTab.value(masterTab.view);

			window.front;
		},

		close: {
			if(window.notNil, {
				window.close;
			});
		}
	);

	publicAPI;
};
)
