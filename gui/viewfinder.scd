/*
S-4 RIVAL: WAVEFORM VIEWFINDER (Phase 7)
==========================================

Real-time non-destructive loop window selection using SoundFileView.
Maps visual selection to grain engine loopStart/loopEnd parameters.

Inspired by:
- Torso Electronics S-4 Rival
- Monome Norns "Crone" engine

Usage:
  ~viewfinder = ~s4Viewfinder.value(server, trackManager);
  ~viewfinder.createWindow(trackNum);
  ~viewfinder.updateWaveform(trackNum);
  ~viewfinder.free;
*/

~s4Viewfinder = { arg server, trackManager;
	var windows, soundFileViews, publicAPI;

	// Store windows and views for each track
	windows = Array.fill(4, { nil });
	soundFileViews = Array.fill(4, { nil });

	publicAPI = (
		// Create viewfinder window for a specific track
		createWindow: { arg self, trackNum = 0;
			var win, sfv, track, buffer;
			var winWidth = 900, winHeight = 650;  // Phase 7c: Expanded for Pitch Jitter slider
			var trackName, statusText, colors;
			var makeSlider;  // Phase 7: Slider helper function
			var yPos;  // Phase 7: Y position for slider layout
			var overlayView, updateRoutine;  // Phase 7: Grain visualization overlay

			// Doom Material colors
			colors = (
				bg: Color.fromHexString("#262938"),
				fg: Color.fromHexString("#EEFFFF"),
				cyan: Color.fromHexString("#89DDFF"),
				yellow: Color.fromHexString("#ffcb6b"),
				green: Color.fromHexString("#c3e88d")
			);

			// Validate track number
			if(trackNum < 0 or: { trackNum > 3 }, {
				"Viewfinder: Invalid track number %".format(trackNum).error;
				^nil;
			});

			// Get track and buffer
			track = trackManager.getTrack(trackNum);
			if(track.isNil, {
				"Viewfinder: Track % not initialized".format(trackNum + 1).error;
				^nil;
			});

			buffer = track.recorder.buffer;
			if(buffer.isNil, {
				"Viewfinder: Track % has no buffer loaded".format(trackNum + 1).warn;
				^nil;
			});

			// Close existing window if open
			if(windows[trackNum].notNil, {
				windows[trackNum].close;
			});

			trackName = "Track % Grain Control".format(trackNum + 1);

			// Phase 7: Slider helper function
			makeSlider = { arg parent, x, y, label, spec, param, default;
				var slider, numBox;

				StaticText(parent, Rect(x, y, 120, 18))
					.string_(label)
					.font_(Font("DejaVu Sans Mono", 10))
					.stringColor_(colors.fg);

				numBox = NumberBox(parent, Rect(x + 280, y, 60, 18))
					.value_(default)
					.decimals_(3)
					.font_(Font("DejaVu Sans Mono", 9))
					.normalColor_(colors.fg)
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

			// Create window
			win = Window(trackName, Rect(100 + (trackNum * 50), 100 + (trackNum * 50), winWidth, winHeight))
				.background_(colors.bg)
				.front;

			// Create title label
			StaticText(win, Rect(10, 10, winWidth - 20, 30))
				.string_(trackName ++ " - Grain Visualization & Control")
				.font_(Font("DejaVu Sans Mono", 14, true))
				.stringColor_(colors.cyan)
				.align_(\center);

			// Info text
			StaticText(win, Rect(10, 45, winWidth - 20, 20))
				.string_("Drag to select loop • Arrows/wheel to zoom • Grain controls below")
				.font_(Font("DejaVu Sans Mono", 10))
				.stringColor_(Color.gray(0.7))
				.align_(\center);

			// Create SoundFileView
			sfv = SoundFileView(win, Rect(10, 75, winWidth - 20, 200))
				.background_(Color.black)
				.waveColors_([Color.cyan.alpha_(0.8)])
				.gridOn_(true)
				.gridColor_(Color.gray(0.3))
				.timeCursorOn_(true)
				.timeCursorColor_(Color.yellow.alpha_(0.6))
				.drawsWaveForm_(true)
				.elasticMode_(1) // Elastic resize
				.gridResolution_(0.1); // Grid every 100ms

			// Selection is enabled by default in SoundFileView

			// Load waveform (DEFER for Qt thread safety)
			{
				var soundFile;
				server.sync;

				// Check if track has a file path stored
				if(track.filePath.notNil, {
					soundFile = SoundFile.new;
					if(soundFile.openRead(track.filePath), {
						// MUST defer all SoundFileView operations
						{
							sfv.soundfile = soundFile;
							sfv.read(0, soundFile.numFrames);
							soundFile.close;
							sfv.refresh;
						}.defer;
					}, {
						"Viewfinder: Could not open audio file".warn;
					});
				}, {
					"Viewfinder: No file path found for this track".warn;
					"Try loading a file first, or this may be a recorded buffer.".postln;
				});

				// Set initial selection to current loop window
				fork {
					0.1.wait; // Wait for waveform to load
					{
						var currentStart = track.grainSynth.get(\loopStart, { arg val; val });
						var currentEnd = track.grainSynth.get(\loopEnd, { arg val; val });

						// This is async, so we use a callback pattern
						track.grainSynth.get(\loopStart, { arg startVal;
							track.grainSynth.get(\loopEnd, { arg endVal;
								{
									var startFrame = (startVal * buffer.numFrames).asInteger;
									var endFrame = (endVal * buffer.numFrames).asInteger;
									var duration = endFrame - startFrame;

									sfv.setSelection(0, [startFrame, duration]);
									sfv.refresh;
								}.defer;
							});
						});
					}.value;
				};
			}.fork;

			// === PHASE 7: GRAIN VISUALIZATION OVERLAY ===
			overlayView = UserView(win, Rect(10, 75, winWidth - 20, 200))
				.background_(Color.clear)
				.acceptsMouseOver_(false)  // Let mouse events pass through
				.canFocus_(false)          // Don't steal focus
				.drawFunc_({
					var pos = track.params[\position] ? 0.0;
					var grainSize = track.params[\grainSize] ? 0.1;
					var posJitter = track.params[\posJitter] ? 0.0;
					var loopStart = track.params[\loopStart] ? 0.0;
					var loopEnd = track.params[\loopEnd] ? 1.0;
					var currentBuffer = track.recorder.buffer;
					var bufferDuration, grainSizePixels, positionPixels, jitterPixels;
					var viewWidth = winWidth - 20, viewHeight = 200;
					var loopStartPixels, loopEndPixels, fadeWidth;

					if(currentBuffer.notNil, {
						bufferDuration = currentBuffer.numFrames / currentBuffer.sampleRate;

						// === LAYER 1: Loop Boundaries (green start, red end) ===
						loopStartPixels = loopStart * viewWidth;
						loopEndPixels = loopEnd * viewWidth;
						fadeWidth = 20;

						// Start boundary (green fade)
						Pen.fillColor = colors.green.alpha_(0.15);
						Pen.fillRect(Rect(loopStartPixels, 0, fadeWidth, viewHeight));
						Pen.color = colors.green.alpha_(0.6);
						Pen.width = 2;
						Pen.line(Point(loopStartPixels, 0), Point(loopStartPixels, viewHeight));
						Pen.stroke;

						// End boundary (red fade)
						Pen.fillColor = Color.red.alpha_(0.15);
						Pen.fillRect(Rect(loopEndPixels - fadeWidth, 0, fadeWidth, viewHeight));
						Pen.color = Color.red.alpha_(0.6);
						Pen.width = 2;
						Pen.line(Point(loopEndPixels, 0), Point(loopEndPixels, viewHeight));
						Pen.stroke;

						// === LAYER 2: Grain Size Overlay (yellow box) ===
						grainSizePixels = (grainSize / bufferDuration) * viewWidth;
						positionPixels = pos * viewWidth;

						// Semi-transparent rectangle showing grain window
						Pen.fillColor = colors.yellow.alpha_(0.2);
						Pen.fillRect(Rect(
							positionPixels,
							0,
							grainSizePixels.min(viewWidth - positionPixels),
							viewHeight
						));

						// Grain boundary markers
						Pen.color = colors.yellow.alpha_(0.6);
						Pen.width = 1;
						Pen.line(Point(positionPixels, 0), Point(positionPixels, viewHeight));
						Pen.line(
							Point((positionPixels + grainSizePixels).min(viewWidth), 0),
							Point((positionPixels + grainSizePixels).min(viewWidth), viewHeight)
						);
						Pen.stroke;

						// Grain size label
						Pen.stringAtPoint(
							"Grain: %ms".format((grainSize * 1000).round(0.1)),
							Point(positionPixels + 5, 5),
							Font("DejaVu Sans Mono", 10),
							colors.yellow
						);

						// === LAYER 3: Animated Position Playhead (red line with jitter) ===
						if(posJitter > 0.01, {
							jitterPixels = posJitter * viewWidth;
							Pen.fillColor = Color.red.alpha_(0.15);
							Pen.fillRect(Rect(
								(positionPixels - (jitterPixels / 2)).max(0),
								0,
								jitterPixels,
								viewHeight
							));
						});

						// Main playhead line
						Pen.color = Color.red.alpha_(0.8);
						Pen.width = 3;
						Pen.line(Point(positionPixels, 0), Point(positionPixels, viewHeight));
						Pen.stroke;
					});
				});

			// Start 30fps update routine for overlay
			updateRoutine = Routine({
				loop {
					{ overlayView.refresh }.defer;
					(1/30).wait;  // 30 FPS
				}
			}).play(AppClock);

			// Stop update routine when window closes
			win.onClose = {
				updateRoutine.stop;
				windows[trackNum] = nil;
				soundFileViews[trackNum] = nil;
				"Viewfinder % closed".format(trackNum + 1).postln;
			};

			// === THE BRIDGE: Real-time update on mouse drag ===
			sfv.mouseMoveAction = { arg view;
				var sel = view.selection(0);
				var currentBuffer = track.recorder.buffer;  // Get buffer from track
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

					// Update engine
					trackManager.setParam(trackNum, \loopStart, loopStart);
					trackManager.setParam(trackNum, \loopEnd, loopEnd);

					// Update status text
					{
						var startTime = (loopStart * numFrames / sampleRate).round(0.01);
						var endTime = (loopEnd * numFrames / sampleRate).round(0.01);
						var loopDur = (endTime - startTime).round(0.01);
						var pctStart = (loopStart * 100).round(0.1);
						var pctEnd = (loopEnd * 100).round(0.1);

						statusText.string = "Loop: %s - %s (%s) | %% - %%".format(
							startTime, endTime, loopDur, pctStart, pctEnd
						);
					}.defer;
				});
			};

			// === Finalize on mouse up ===
			sfv.mouseUpAction = { arg view;
				var sel = view.selection(0);
				var currentBuffer = track.recorder.buffer;  // Get buffer from track
				if(sel.notNil and: { sel[1] > 0 } and: { currentBuffer.notNil }, {
					var startFrame = sel[0];
					var duration = sel[1];
					var endFrame = startFrame + duration;
					var numFrames = currentBuffer.numFrames;
					var loopStart, loopEnd, startTime, endTime, loopDur;

					loopStart = (startFrame / numFrames).clip(0.0, 1.0);
					loopEnd = (endFrame / numFrames).clip(0.0, 1.0);

					// Ensure minimum window size
					if((loopEnd - loopStart) < 0.01, {
						"Loop window too small (minimum 1% of buffer)".warn;
						^this;
					});

					// Update engine
					trackManager.setParam(trackNum, \loopStart, loopStart);
					trackManager.setParam(trackNum, \loopEnd, loopEnd);

					// Post feedback
					startTime = (loopStart * currentBuffer.numFrames / currentBuffer.sampleRate).round(0.001);
					endTime = (loopEnd * currentBuffer.numFrames / currentBuffer.sampleRate).round(0.001);
					loopDur = (endTime - startTime).round(0.001);

					postf("Track %: Loop Window Set\n", trackNum + 1);
					postf("  Start: %s (%.1f%%)\n", startTime, loopStart * 100);
					postf("  End: %s (%.1f%%)\n", endTime, loopEnd * 100);
					postf("  Duration: %s\n", loopDur);
				});
			};

			// === ZOOM FUNCTIONALITY ===
			// Arrow key navigation: Up/Down = Zoom, Left/Right = Pan
			win.view.keyDownAction = { arg view, char, modifiers, unicode, keycode;
				var currentBuffer = track.recorder.buffer;
				if(currentBuffer.notNil, {
					var numFrames = currentBuffer.numFrames;
					var zoomFactor = 1.5;
					var panAmount = 0.1;

					// UP ARROW (keycode 63232) - Zoom In
					if(keycode == 63232, {
						var viewStart = sfv.scrollPos;
						var viewSize = sfv.viewFrames;
						var newSize = (viewSize / zoomFactor).max(100); // Minimum 100 frames visible
						var center = viewStart + (viewSize / 2);
						var newStart = (center - (newSize / 2)).clip(0, numFrames - newSize);

						{
							sfv.scroll(newStart);
							sfv.zoom(newSize);
							sfv.refresh;
						}.defer;
					});

					// DOWN ARROW (keycode 63233) - Zoom Out
					if(keycode == 63233, {
						var viewStart = sfv.scrollPos;
						var viewSize = sfv.viewFrames;
						var newSize = (viewSize * zoomFactor).min(numFrames); // Max = full buffer
						var center = viewStart + (viewSize / 2);
						var newStart = (center - (newSize / 2)).clip(0, numFrames - newSize);

						{
							sfv.scroll(newStart);
							sfv.zoom(newSize);
							sfv.refresh;
						}.defer;
					});

					// LEFT ARROW (keycode 63234) - Pan Left
					if(keycode == 63234, {
						var viewStart = sfv.scrollPos;
						var viewSize = sfv.viewFrames;
						var newStart = (viewStart - (viewSize * panAmount)).max(0);

						{
							sfv.scroll(newStart);
							sfv.refresh;
						}.defer;
					});

					// RIGHT ARROW (keycode 63235) - Pan Right
					if(keycode == 63235, {
						var viewStart = sfv.scrollPos;
						var viewSize = sfv.viewFrames;
						var newStart = (viewStart + (viewSize * panAmount)).min(numFrames - viewSize);

						{
							sfv.scroll(newStart);
							sfv.refresh;
						}.defer;
					});
				});
			};

			// Mouse wheel zoom
			sfv.mouseWheelAction = { arg view, x, y, modifiers, xDelta, yDelta;
				var currentBuffer = track.recorder.buffer;
				if(currentBuffer.notNil, {
					var numFrames = currentBuffer.numFrames;
					var zoomFactor = if(yDelta > 0, { 1.2 }, { 0.83 }); // Zoom in/out
					var viewStart = sfv.scrollPos;
					var viewSize = sfv.viewFrames;
					var mousePos = x / (winWidth - 20); // Normalized mouse position
					var mouseFrame = viewStart + (viewSize * mousePos);
					var newSize = (viewSize * zoomFactor).clip(100, numFrames);
					var newStart = (mouseFrame - (newSize * mousePos)).clip(0, numFrames - newSize);

					{
						sfv.scroll(newStart);
						sfv.zoom(newSize);
						sfv.refresh;
					}.defer;
				});
			};

			// Status display at bottom (will be updated dynamically)
			statusText = StaticText(win, Rect(10, 285, winWidth - 350, 40))
				.string_("Loop: Select a region to begin")
				.font_(Font("Monaco", 11))
				.stringColor_(Color.gray(0.8))
				.align_(\left);

			// Control buttons (bottom right)
			Button(win, Rect(winWidth - 340, 290, 100, 30))
				.states_([["Reset Loop", Color.white, Color.gray(0.4)]])
				.font_(Font("Monaco", 10))
				.action_({
					// Reset to full buffer
					var currentBuffer = track.recorder.buffer;
					trackManager.setParam(trackNum, \loopStart, 0.0);
					trackManager.setParam(trackNum, \loopEnd, 1.0);
					{
						if(currentBuffer.notNil, {
							sfv.setSelection(0, [0, currentBuffer.numFrames]);
							sfv.refresh;
						});
					}.defer;
					"Track %: Loop window reset to full buffer".format(trackNum + 1).postln;
				});

			Button(win, Rect(winWidth - 230, 290, 110, 30))
				.states_([["Select All", Color.white, Color.new(0.2, 0.6, 0.8)]])
				.font_(Font("Monaco", 10))
				.action_({
					var currentBuffer = track.recorder.buffer;
					{
						if(currentBuffer.notNil, {
							sfv.setSelection(0, [0, currentBuffer.numFrames]);
							sfv.refresh;
						});
					}.defer;
				});

			Button(win, Rect(winWidth - 110, 290, 100, 30))
				.states_([["Refresh", Color.white, Color.green(0.5)]])
				.font_(Font("Monaco", 10))
				.action_({
					self.updateWaveform(trackNum);
				});

			// === PHASE 7: GRAIN CONTROL SLIDERS ===
			StaticText(win, Rect(10, 335, 880, 20))
				.string_("GRAIN CONTROLS")
				.font_(Font("DejaVu Sans Mono", 12, true))
				.stringColor_(colors.cyan);

			// Column 1: Position & Pitch
			yPos = 360;
			makeSlider.value(win, 10, yPos, "Position", ControlSpec(0, 1, \lin), \position, track.params[\position] ? 0.0);
			yPos = yPos + 22;
			makeSlider.value(win, 10, yPos, "Scan Speed", ControlSpec(-4, 4, \lin), \scanSpeed, track.params[\scanSpeed] ? 0);
			yPos = yPos + 22;
			makeSlider.value(win, 10, yPos, "Pos Jitter", ControlSpec(0, 1, \lin), \posJitter, track.params[\posJitter] ? 0.1);
			yPos = yPos + 22;
			makeSlider.value(win, 10, yPos, "Pitch Shift", ControlSpec(-24, 24, \lin), \pitchShift, track.params[\pitchShift] ? 0);
			yPos = yPos + 22;
			makeSlider.value(win, 10, yPos, "Pitch Jitter", ControlSpec(0, 12, \lin), \pitchJitter, track.params[\pitchJitter] ? 0);
			yPos = yPos + 22;
			makeSlider.value(win, 10, yPos, "Grain Size", ControlSpec(0.001, 60.0, \exp), \grainSize, track.params[\grainSize] ? 0.1);
			yPos = yPos + 22;
			makeSlider.value(win, 10, yPos, "Overlap", ControlSpec(1, 128, \lin), \overlap, track.params[\overlap] ? 1);
			yPos = yPos + 22;
			makeSlider.value(win, 10, yPos, "Amplitude", ControlSpec(0, 1, \lin), \amp, track.params[\amp] ? 0.5);
			yPos = yPos + 22;
			makeSlider.value(win, 10, yPos, "Stereo Spread", ControlSpec(0, 1, \lin), \stereoSpread, track.params[\stereoSpread] ? 0.5);

			// Column 2: Loop boundaries (read-only display)
			yPos = 360;
			StaticText(win, Rect(450, yPos, 120, 18))
				.string_("Loop Start")
				.font_(Font("DejaVu Sans Mono", 10))
				.stringColor_(colors.green);
			NumberBox(win, Rect(575, yPos, 80, 18))
				.value_(track.params[\loopStart] ? 0.0)
				.decimals_(3)
				.font_(Font("DejaVu Sans Mono", 9))
				.normalColor_(colors.green)
				.enabled_(false);  // Read-only

			yPos = yPos + 22;
			StaticText(win, Rect(450, yPos, 120, 18))
				.string_("Loop End")
				.font_(Font("DejaVu Sans Mono", 10))
				.stringColor_(colors.green);
			NumberBox(win, Rect(575, yPos, 80, 18))
				.value_(track.params[\loopEnd] ? 1.0)
				.decimals_(3)
				.font_(Font("DejaVu Sans Mono", 9))
				.normalColor_(colors.green)
				.enabled_(false);  // Read-only

			yPos = yPos + 30;
			StaticText(win, Rect(450, yPos, 200, 40))
				.string_("Loop boundaries set by\nwaveform selection above")
				.font_(Font("DejaVu Sans Mono", 9))
				.stringColor_(Color.gray(0.6))
				.align_(\left);

			// Store references
			windows[trackNum] = win;
			soundFileViews[trackNum] = sfv;

			"Viewfinder created for Track % with grain visualization".format(trackNum + 1).postln;
		},

		// Update waveform display (call after loading new buffer)
		updateWaveform: { arg self, trackNum = 0;
			var sfv, track, buffer, soundFile;

			sfv = soundFileViews[trackNum];
			if(sfv.isNil, {
				"Viewfinder: No window open for track %".format(trackNum + 1).warn;
				^nil;
			});

			track = trackManager.getTrack(trackNum);
			buffer = track.recorder.buffer;

			if(buffer.notNil and: { track.filePath.notNil }, {
				soundFile = SoundFile.new;
				if(soundFile.openRead(track.filePath), {
					{
						sfv.soundfile = soundFile;
						sfv.read(0, soundFile.numFrames);
						soundFile.close;
						sfv.setSelection(0, [0, buffer.numFrames]); // Select all by default
						sfv.refresh;
						"Waveform updated for Track %".format(trackNum + 1).postln;
					}.defer;
				}, {
					"Viewfinder: Could not open audio file for refresh".warn;
				});
			}, {
				"Viewfinder: Track % has no buffer or file path".format(trackNum + 1).warn;
			});
		},

		// Open viewfinders for all tracks
		createAll: { arg self;
			4.do({ arg i;
				self.createWindow(i);
			});
		},

		// Close all viewfinder windows
		closeAll: { arg self;
			windows.do({ arg win;
				if(win.notNil, { win.close });
			});
		},

		// Free resources
		free: { arg self;
			self.closeAll;
		}
	);

	publicAPI;
};

/*
USAGE EXAMPLES:

// Create viewfinder module (do this in main.scd)
~viewfinder = ~s4Viewfinder.value(s, ~trackManager);

// Open viewfinder for Track 1
~viewfinder.createWindow(0);

// Open viewfinder for Track 2
~viewfinder.createWindow(1);

// Open all viewfinders
~viewfinder.createAll;

// Update waveform after loading new file
~viewfinder.updateWaveform(0);

// Close all viewfinders
~viewfinder.closeAll;

// Cleanup
~viewfinder.free;
*/
