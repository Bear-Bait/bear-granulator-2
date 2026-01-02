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
	var window, updateTasks, levelMeters, levelResponders;
	var cpuMeterAvg, cpuMeterPeak, cpuTextAvg, cpuTextPeak, cpuUpdateTask;
	var publicAPI;
	var makeSlider, makeButton, makeMasterSlider, makeMasterButton;
	var makeTrackTab, makeMasterTab;
	var colors;  // Doom Material color palette

	// Doom Material Color Palette
	colors = (
		bg: Color.fromHexString("#262938"),
		fg: Color.fromHexString("#EEFFFF"),
		black: Color.fromHexString("#171F24"),
		red: Color.fromHexString("#ff5370"),
		green: Color.fromHexString("#c3e88d"),
		yellow: Color.fromHexString("#ffcb6b"),
		blue: Color.fromHexString("#82aaff"),
		magenta: Color.fromHexString("#c792ea"),
		cyan: Color.fromHexString("#89DDFF"),
		white: Color.fromHexString("#EEFFFF"),
		brightBlack: Color.fromHexString("#37474F"),
		orange: Color.fromHexString("#f78c6c"),
		selection: Color.fromHexString("#cc7000")
	);

	// Track update tasks for waveform displays
	updateTasks = Array.newClear(4);

	// Level meters and responders
	levelMeters = Array.newClear(4);
	levelResponders = Array.newClear(4);

	// ========================================
	// HELPER: Create labeled slider
	// ========================================
	makeSlider = { arg parent, x, y, label, spec, param, trackNum, default;
		var slider, numBox;

		StaticText(parent, Rect(x, y, 120, 18))
			.string_(label)
			.font_(Font("Monaco", 10));

		numBox = NumberBox(parent, Rect(x + 280, y, 60, 18))
			.value_(default)
			.decimals_(3)
			.font_(Font("Monaco", 9))
			.action_({ arg nb;
				trackManager.setParam(trackNum, param, nb.value);
				slider.value_(spec.unmap(nb.value));
			});

		slider = Slider(parent, Rect(x + 125, y, 150, 18))
			.value_(spec.unmap(default))
			.action_({ arg sl;
				var val = spec.map(sl.value);
				numBox.value_(val);
				trackManager.setParam(trackNum, param, val);
			});
	};

	// ========================================
	// HELPER: Create toggle button
	// ========================================
	makeButton = { arg parent, x, y, w, label, param, trackNum;
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
	makeMasterSlider = { arg parent, x, y, label, spec, param, default;
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
	makeMasterButton = { arg parent, x, y, w, label, param;
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
	makeTrackTab = { arg parent, trackNum;
		var track = trackManager.getTrack(trackNum);
		var waveView, positionView;
		var col1X = 10, col2X = 370, col3X = 730;
		var yPos;

		// === TOP: TRACK CONTROLS ===
		StaticText(parent, Rect(10, 10, 200, 25))
			.string_("TRACK " ++ (trackNum + 1))
			.font_(Font("Monaco", 14, true))
			.stringColor_(colors.cyan);

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
				["MUTE", colors.fg, colors.brightBlack],
				["MUTE", colors.black, colors.red]
			])
			.action_({ arg btn;
				trackManager.setMute(trackNum, btn.value.asBoolean);
			});

		// Solo
		Button(parent, Rect(545, 10, 60, 40))
			.states_([
				["SOLO", colors.fg, colors.brightBlack],
				["SOLO", colors.black, colors.yellow]
			])
			.action_({ arg btn;
				trackManager.setSolo(trackNum, btn.value.asBoolean);
			});

		// Modulation window button (Phase 5)
		Button(parent, Rect(610, 10, 60, 40))
			.states_([["MOD", colors.black, colors.cyan]])
			.action_({
				~s4ModulationWindow.value(trackManager, server, trackNum).create;
			});

		// Viewfinder button (Phase 7)
		Button(parent, Rect(675, 10, 70, 40))
			.states_([["LOOP\nVIEW", colors.fg, colors.blue]])
			.font_(Font("Monaco", 9, true))
			.action_({
				if(~viewfinder.notNil, {
					~viewfinder.createWindow(trackNum);
				}, {
					"Viewfinder not initialized. Run main.scd first.".warn;
				});
			});

		// === COLUMN 1: RECORDING + GRAIN ===
		yPos = 60;
		StaticText(parent, Rect(col1X, yPos, 350, 20))
			.string_("RECORDING + GRAIN")
			.font_(Font("Monaco", 12, true));

		yPos = yPos + 25;

		// Load Audio File button
		Button(parent, Rect(col1X, yPos, 150, 30))
			.states_([["Load Audio File", colors.black, colors.cyan]])
			.action_({
				"Opening file dialog...".postln;
				FileDialog({ |path|
					"FileDialog callback fired".postln;
					"Path received: %".format(path).postln;
					"Path type: %".format(path.class).postln;

					if(path.notNil and: { path.size > 0 }, {
						var soundFile = SoundFile.new;
						var filePath;

						// FileDialog with stripResult:true returns String, not Array
						filePath = if(path.isString, { path }, { path[0] });

						"Attempting to open: %".format(filePath).postln;

						if(soundFile.openRead(filePath), {
							var numFrames = soundFile.numFrames;
							var duration = numFrames / server.sampleRate;
							var numChannels = soundFile.numChannels;

							"File opened successfully!".postln;
							"  Frames: %".format(numFrames).postln;
							"  Channels: %".format(numChannels).postln;
							"  Duration: % sec".format(duration.round(0.01)).postln;

							soundFile.close;

							// Free old buffer and allocate new one matching file size
							"Freeing old buffer...".postln;
							track.recorder.buffer.free;

							"Loading new buffer from file...".postln;
							track.recorder.buffer = Buffer.readChannel(server, filePath, channels: [0]);

							// Store file path for viewfinder
							track.filePath = filePath;

							// CRITICAL: Update grain synth to point to new buffer!
							fork {
								0.3.wait; // Wait for buffer to load on server
								"New buffer number: %".format(track.recorder.buffer.bufnum).postln;

								if(track.grainSynth.notNil, {
									// Stop synth first
									track.grainSynth.run(false);
									// Update buffer
									track.grainSynth.set(\bufnum, track.recorder.buffer.bufnum);
									"Track %: Grain synth updated to buffer % (STOPPED - press PLAY to start)".format(
										trackNum + 1,
										track.recorder.buffer.bufnum
									).postln;
								}, {
									"WARNING: Grain synth is nil!".postln;
								});

								// Load waveform into main GUI display
								{
									var sf = SoundFile.new;
									if(sf.openRead(filePath), {
										waveView.soundfile = sf;
										waveView.read(0, sf.numFrames);
										sf.close;
										waveView.refresh;
										"Waveform loaded into main view".postln;
									});
								}.defer;

								"✓ Loaded: % (% seconds, % frames)".format(
									PathName(filePath).fileName,
									duration.round(0.01),
									numFrames
								).postln;
							};
						}, {
							"❌ Failed to open audio file: %".format(filePath).postln;
						});
					}, {
						"File dialog cancelled or no file selected".postln;
					});
				}, fileMode: 1, acceptMode: 0, stripResult: true);
			});

		yPos = yPos + 35;

		// Play/Stop buttons for grain engine
		Button(parent, Rect(col1X, yPos, 70, 25))
			.states_([
				["PLAY", colors.black, colors.green],
				["STOP", colors.fg, colors.red]
			])
			.action_({ arg btn;
				if(btn.value == 1, {
					// PLAY - Start grain synth
					if(track.grainSynth.notNil, {
						track.grainSynth.run(true);
						"Track % grain engine PLAYING".format(trackNum + 1).postln;
					}, {
						"ERROR: Grain synth is nil!".error;
					});
				}, {
					// STOP - Pause grain synth
					if(track.grainSynth.notNil, {
						track.grainSynth.run(false);
						"Track % grain engine STOPPED".format(trackNum + 1).postln;
					});
				});
			});

		yPos = yPos + 30;

		// Input selector
		StaticText(parent, Rect(col1X, yPos, 50, 20))
			.string_("Input")
			.font_(Font("Monaco", 9));
		PopUpMenu(parent, Rect(col1X + 55, yPos, 70, 20))
			.items_(["In 1", "In 2", "In 3", "In 4", "In 5", "In 6", "In 7", "In 8"])
			.value_(2)
			.action_({ arg menu;
				("Track " ++ (trackNum + 1) ++ " input: " ++ menu.value).postln;
			});

		// Record button
		Button(parent, Rect(col1X + 130, yPos, 70, 25))
			.states_([
				["REC", colors.black, colors.green],
				["STOP", colors.fg, colors.red]
			])
			.action_({ arg btn;
				if(btn.value == 1, {
					track.recorder.startRecording(2, overdub: false);
				}, {
					track.recorder.stopRecording;
					fork {
						0.2.wait;
						track.recorder.buffer.loadToFloatArray(action: { arg array;
							{
								waveView.setData(array);
								waveView.refresh;
							}.defer;
						});
					};
				});
			});

		yPos = yPos + 40;

		// Grain controls
		makeSlider.value(parent, col1X, yPos, "Grain Size", ControlSpec(0.001, 60.0, \exp), \grainSize, trackNum, 0.1);
		yPos = yPos + 22;
		makeSlider.value(parent, col1X, yPos, "Overlap", ControlSpec(1, 128, \lin), \overlap, trackNum, 1);
		yPos = yPos + 22;
		StaticText(parent, Rect(col1X, yPos, 350, 18))
			.string_("(Overlap = simultaneous grains, auto-adjusts for grain size)")
			.font_(Font("Monaco", 8))
			.stringColor_(Color.gray(0.6));
		yPos = yPos + 22;
		makeSlider.value(parent, col1X, yPos, "Position", ControlSpec(0, 1, \lin), \position, trackNum, 0.0);
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

		// Phase 6: Material Mode selector
		yPos = yPos + 30;
		StaticText(parent, Rect(col1X, yPos, 120, 20))
			.string_("Material Mode")
			.font_(Font("Monaco", 10, true))
			.stringColor_(Color.new(0.3, 0.8, 1.0));  // Cyan highlight
		PopUpMenu(parent, Rect(col1X + 125, yPos, 150, 20))
			.items_(["TAPE (Loop)", "POLY (Sample)", "LIVE (Input)"])
			.value_(0)  // Default to TAPE
			.action_({ arg menu;
				trackManager.setMode(trackNum, menu.value);
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

		// === INTEGRATED WAVEFORM VIEWFINDER ===
		yPos = 540;

		StaticText(parent, Rect(10, yPos, 600, 20))
			.string_("LOOP WINDOW (Drag to select • Arrows: Up/Down=Zoom, Left/Right=Pan • Mouse wheel zooms)")
			.font_(Font("Monaco", 10, true))
			.stringColor_(colors.cyan);

		waveView = SoundFileView(parent, Rect(10, yPos + 25, 1420, 150))
			.background_(colors.black)
			.waveColors_([colors.cyan.alpha_(0.8)])
			.gridOn_(true)
			.gridColor_(colors.brightBlack)
			.timeCursorOn_(true)
			.timeCursorColor_(colors.yellow.alpha_(0.6))
			.drawsWaveForm_(true)
			.elasticMode_(1)
			.gridResolution_(0.1)
			.resize_(5);

		waveView.setSelectionColor(0, colors.selection.alpha_(0.5));

		// Load waveform when buffer is ready
		fork {
			0.3.wait;
			if(track.filePath.notNil, {
				var sf = SoundFile.new;
				if(sf.openRead(track.filePath), {
					{
						waveView.soundfile = sf;
						waveView.read(0, sf.numFrames);
						sf.close;
						waveView.refresh;
					}.defer;
				});
			});
		};

		// Real-time update while dragging (like popup viewfinder)
		waveView.mouseMoveAction = { arg view;
			var sel = view.selection(0);
			var currentBuffer = track.recorder.buffer;
			if(sel.notNil and: { sel[1] > 0 } and: { currentBuffer.notNil }, {
				var startFrame = sel[0];
				var duration = sel[1];
				var endFrame = startFrame + duration;
				var numFrames = currentBuffer.numFrames;
				var sampleRate = currentBuffer.sampleRate;
				var loopStart = (startFrame / numFrames).clip(0.0, 1.0);
				var loopEnd = (endFrame / numFrames).clip(0.0, 1.0);

				// Ensure minimum window size (1% of buffer)
				if((loopEnd - loopStart) < 0.01, {
					loopEnd = (loopStart + 0.01).min(1.0);
				});

				// Update engine in real-time
				trackManager.setParam(trackNum, \loopStart, loopStart);
				trackManager.setParam(trackNum, \loopEnd, loopEnd);
			});
		};

		// Finalize on mouse up
		waveView.mouseUpAction = { arg view;
			var sel = view.selection(0);
			var currentBuffer = track.recorder.buffer;
			if(sel.notNil and: { sel[1] > 0 } and: { currentBuffer.notNil }, {
				var startFrame = sel[0];
				var duration = sel[1];
				var endFrame = startFrame + duration;
				var numFrames = currentBuffer.numFrames;
				var loopStart = (startFrame / numFrames).clip(0.0, 1.0);
				var loopEnd = (endFrame / numFrames).clip(0.0, 1.0);

				// Ensure minimum window size
				if((loopEnd - loopStart) < 0.01, {
					"Loop window too small (minimum 1% of buffer)".warn;
					^this;
				});

				trackManager.setParam(trackNum, \loopStart, loopStart);
				trackManager.setParam(trackNum, \loopEnd, loopEnd);

				"Track %: Loop % - % (% sec)".format(
					trackNum + 1,
					(loopStart * 100).round(0.1),
					(loopEnd * 100).round(0.1),
					((loopEnd - loopStart) * numFrames / currentBuffer.sampleRate).round(0.01)
				).postln;
			});
		};

		// === ZOOM & NAVIGATION ===
		// Arrow key controls on waveView
		waveView.keyDownAction = { arg view, char, modifiers, unicode, keycode;
			var currentBuffer = track.recorder.buffer;
			if(currentBuffer.notNil, {
				var numFrames = currentBuffer.numFrames;
				var zoomFactor = 1.5;
				var panAmount = 0.1;

				// UP - Zoom In
				if(keycode == 63232, {
					var viewStart = waveView.scrollPos;
					var viewSize = waveView.viewFrames;
					var newSize = (viewSize / zoomFactor).max(100);
					var center = viewStart + (viewSize / 2);
					var newStart = (center - (newSize / 2)).clip(0, numFrames - newSize);
					{ waveView.scroll(newStart); waveView.zoom(newSize); waveView.refresh; }.defer;
				});

				// DOWN - Zoom Out
				if(keycode == 63233, {
					var viewStart = waveView.scrollPos;
					var viewSize = waveView.viewFrames;
					var newSize = (viewSize * zoomFactor).min(numFrames);
					var center = viewStart + (viewSize / 2);
					var newStart = (center - (newSize / 2)).clip(0, numFrames - newSize);
					{ waveView.scroll(newStart); waveView.zoom(newSize); waveView.refresh; }.defer;
				});

				// LEFT - Pan Left
				if(keycode == 63234, {
					var viewStart = waveView.scrollPos;
					var viewSize = waveView.viewFrames;
					var newStart = (viewStart - (viewSize * panAmount)).max(0);
					{ waveView.scroll(newStart); waveView.refresh; }.defer;
				});

				// RIGHT - Pan Right
				if(keycode == 63235, {
					var viewStart = waveView.scrollPos;
					var viewSize = waveView.viewFrames;
					var newStart = (viewStart + (viewSize * panAmount)).min(numFrames - viewSize);
					{ waveView.scroll(newStart); waveView.refresh; }.defer;
				});
			});
		};

		// Mouse wheel zoom
		waveView.mouseWheelAction = { arg view, x, y, modifiers, xDelta, yDelta;
			var currentBuffer = track.recorder.buffer;
			if(currentBuffer.notNil, {
				var numFrames = currentBuffer.numFrames;
				var zoomFactor = if(yDelta > 0, { 1.2 }, { 0.83 });
				var viewStart = waveView.scrollPos;
				var viewSize = waveView.viewFrames;
				var mousePos = x / 1420;
				var mouseFrame = viewStart + (viewSize * mousePos);
				var newSize = (viewSize * zoomFactor).clip(100, numFrames);
				var newStart = (mouseFrame - (newSize * mousePos)).clip(0, numFrames - newSize);
				{ waveView.scroll(newStart); waveView.zoom(newSize); waveView.refresh; }.defer;
			});
		};

		// Position cursor overlay
		positionView = UserView(parent, Rect(10, yPos + 25, 1420, 150))
			.background_(Color.clear)
			.drawFunc_({
				var pos = track.params[\position] ? 0.0;
				var x = pos * 1420;
				Pen.color = colors.red.alpha_(0.7);
				Pen.width = 2;
				Pen.line(Point(x, 0), Point(x, 150));
				Pen.stroke;
			})
			.resize_(5);

		// Update position cursor
		updateTasks[trackNum] = Routine({
			loop {
				{ positionView.refresh }.defer;
				0.1.wait;
			}
		}).play(AppClock);
	};

	// ========================================
	// CREATE MASTER TAB
	// ========================================
	makeMasterTab = { arg parent;
		var yPos = 10;

		StaticText(parent, Rect(10, yPos, 400, 30))
			.string_("MASTER CONTROLS")
			.font_(Font("Monaco", 16, true))
			.stringColor_(colors.cyan);

		yPos = yPos + 40;

		// === GLOBAL TRANSPORT ===
		StaticText(parent, Rect(10, yPos, 400, 25))
			.string_("TRANSPORT")
			.font_(Font("Monaco", 12, true));

		yPos = yPos + 30;

		// Play All button
		Button(parent, Rect(10, yPos, 100, 40))
			.states_([
				["PLAY ALL", colors.black, colors.green]
			])
			.action_({
				4.do({ arg i;
					var track = trackManager.getTrack(i);
					if(track.grainSynth.notNil, {
						track.grainSynth.run(true);
					});
				});
				"All tracks PLAYING".postln;
			});

		// Stop All button
		Button(parent, Rect(115, yPos, 100, 40))
			.states_([
				["STOP ALL", colors.fg, colors.red]
			])
			.action_({
				4.do({ arg i;
					var track = trackManager.getTrack(i);
					if(track.grainSynth.notNil, {
						track.grainSynth.run(false);
					});
				});
				"All tracks STOPPED".postln;
			});

		yPos = yPos + 50;

		// Global Speed Control
		StaticText(parent, Rect(10, yPos, 200, 20))
			.string_("GLOBAL SPEED (Pitch)")
			.font_(Font("Monaco", 11, true));

		yPos = yPos + 25;

		StaticText(parent, Rect(10, yPos, 120, 18))
			.string_("Speed")
			.font_(Font("Monaco", 10));

		Slider(parent, Rect(135, yPos, 200, 18))
			.value_(0.5)  // Center = 0 semitones
			.action_({ arg sl;
				var pitch = sl.value.linlin(0, 1, -24, 24);  // -2 octaves to +2 octaves
				4.do({ arg i;
					trackManager.setParam(i, \pitch, pitch);
				});
			});

		NumberBox(parent, Rect(340, yPos, 60, 18))
			.value_(0)
			.decimals_(1)
			.font_(Font("Monaco", 9))
			.action_({ arg nb;
				var pitch = nb.value;
				4.do({ arg i;
					trackManager.setParam(i, \pitch, pitch);
				});
			});

		StaticText(parent, Rect(405, yPos, 200, 18))
			.string_("(-24 to +24 semitones)")
			.font_(Font("Monaco", 8))
			.stringColor_(Color.gray(0.6));

		yPos = yPos + 30;

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

			// VU Meter
			levelMeters[i] = LevelIndicator(parent, Rect(10, trackY + 20, 80, 12))
				.warning_(0.7)
				.critical_(0.9)
				.style_(\led)
				.numSteps_(12)
				.numTicks_(0)
				.numMajorTicks_(0);

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

			// Viewfinder button (Phase 7)
			Button(parent, Rect(615, trackY, 50, 35))
				.states_([["VIEW", colors.fg, colors.blue]])
				.font_(Font("Monaco", 8, true))
				.action_({
					if(~viewfinder.notNil, {
						~viewfinder.createWindow(i);
					}, {
						"Viewfinder not initialized".warn;
					});
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

		// === CPU MONITOR ===
		StaticText(parent, Rect(10, yPos, 200, 20))
			.string_("CPU USAGE")
			.font_(Font("Monaco", 12, true));

		yPos = yPos + 25;

		// Average CPU
		StaticText(parent, Rect(10, yPos, 80, 18))
			.string_("Average")
			.font_(Font("Monaco", 9));

		cpuMeterAvg = LevelIndicator(parent, Rect(95, yPos, 200, 18))
			.warning_(0.5)
			.critical_(0.8)
			.style_(\led)
			.numSteps_(20);

		cpuTextAvg = StaticText(parent, Rect(300, yPos, 60, 18))
			.string_("0%")
			.font_(Font("Monaco", 9))
			.align_(\right);

		yPos = yPos + 22;

		// Peak CPU
		StaticText(parent, Rect(10, yPos, 80, 18))
			.string_("Peak")
			.font_(Font("Monaco", 9));

		cpuMeterPeak = LevelIndicator(parent, Rect(95, yPos, 200, 18))
			.warning_(0.7)
			.critical_(0.9)
			.style_(\led)
			.numSteps_(20);

		cpuTextPeak = StaticText(parent, Rect(300, yPos, 60, 18))
			.string_("0%")
			.font_(Font("Monaco", 9))
			.align_(\right);

		yPos = yPos + 25;

		StaticText(parent, Rect(10, yPos, 400, 40))
			.string_("Target: <50% average, <80% peak\nHigh CPU may cause audio dropouts")
			.font_(Font("Monaco", 9))
			.stringColor_(colors.brightBlack);
	};

	// ========================================
	// PUBLIC API
	// ========================================
	publicAPI = (
		window: nil,

		create: {
			var tabButtons, tabViews, currentTab = 0;
			var buttonY = 10, buttonH = 30, contentY = 50;

			window = Window("S-4 Rival v0.4 - 4-Track Workstation", Rect(50, 50, 1450, 800))
				.onClose_({
					updateTasks.do({ arg task;
						if(task.notNil, { task.stop; });
					});
					levelResponders.do({ arg resp;
						if(resp.notNil, { resp.free; });
					});
					if(cpuUpdateTask.notNil, { cpuUpdateTask.stop; });
					"Four-track GUI closed.".postln;
				});

			// Create tab buttons and views
			tabButtons = Array.newClear(5);
			tabViews = Array.newClear(5);

			// Create buttons for each tab
			5.do({ arg i;
				var label = if(i < 4, { "TRACK " ++ (i + 1) }, { "MASTER" });
				var buttonX = 10 + (i * 150);

				tabButtons[i] = Button(window, Rect(buttonX, buttonY, 140, buttonH))
					.states_([
						[label, colors.fg, colors.brightBlack],
						[label, colors.black, colors.cyan]
					])
					.value_(if(i == 0, 1, 0))
					.action_({ arg btn;
						// Update all buttons
						tabButtons.do({ arg b, idx;
							b.value_(if(idx == i, 1, 0));
						});
						// Show/hide views
						tabViews.do({ arg v, idx;
							v.visible_(idx == i);
						});
						currentTab = i;
					});
			});

			// Create composite views for each tab
			5.do({ arg i;
				tabViews[i] = CompositeView(window, Rect(0, contentY, 1450, 740))
					.background_(colors.bg)
					.visible_(i == 0); // Only first tab visible initially

				if(i < 4, {
					// Track tabs
					makeTrackTab.value(tabViews[i], i);
				}, {
					// Master tab
					makeMasterTab.value(tabViews[i]);
				});
			});

			// Create level monitoring synths for each track
			4.do({ arg i;
				var track = trackManager.getTrack(i);
				var busIndex = track.audioBus.index;

				// Create SendPeakRMS synth to monitor levels
				{
					var sig = In.ar(busIndex, 2);
					SendPeakRMS.kr(sig, 20, 3, "/levels" ++ i);
					0; // Silent output
				}.play(server, addAction: \addToTail);

				// Create OSC responder to update meter
				levelResponders[i] = OSCFunc({ arg msg;
					var peak = msg[3].max(msg[5]); // Max of left/right peaks
					{
						if(levelMeters[i].notNil, {
							levelMeters[i].value_(peak.ampdb.linlin(-80, 0, 0, 1));
							levelMeters[i].peakLevel_(peak.ampdb.linlin(-80, 0, 0, 1));
						});
					}.defer;
				}, "/levels" ++ i);
			});

			// Create CPU monitoring task
			cpuUpdateTask = Routine({
				loop {
					{
						var avg = server.avgCPU / 100;  // Convert to 0-1
						var peak = server.peakCPU / 100;

						if(cpuMeterAvg.notNil, {
							cpuMeterAvg.value_(avg);
							cpuTextAvg.string_((avg * 100).round(0.1).asString ++ "%");
						});

						if(cpuMeterPeak.notNil, {
							cpuMeterPeak.value_(peak);
							cpuMeterPeak.peakLevel_(peak);
							cpuTextPeak.string_((peak * 100).round(0.1).asString ++ "%");
						});
					}.defer;
					0.5.wait;  // Update every 500ms
				}
			}).play(AppClock);

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
