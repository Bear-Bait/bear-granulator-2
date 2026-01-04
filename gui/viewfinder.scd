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
			var playheadPos = 0;  // Phase 8: Real-time playhead position (0-1)
			var oscListener;  // Phase 8: OSC responder for playhead updates
			var spectrogramData, spectrogramOSC;  // Phase 11: FFT spectrogram data
			var spectrogramEnabled = true;  // Phase 11: Toggle spectrogram display
			var grainPulses = List.new;  // Phase 11: Grain trigger pulse animations
			var grainPulseEnabled = true;  // Phase 11: Toggle grain pulse display

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

				// Create both widgets first (without actions)
				slider = Slider(parent, Rect(x + 125, y, 150, 18))
					.value_(spec.unmap(default));

				numBox = NumberBox(parent, Rect(x + 280, y, 60, 18))
					.value_(default)
					.decimals_(3)
					.font_(Font("DejaVu Sans Mono", 9))
					.normalColor_(colors.cyan)
					.background_(Color.gray(0.2))
					.scroll_(true)
					.scroll_step_(spec.range / 100)
					.clipLo_(spec.minval)
					.clipHi_(spec.maxval);

				// Now assign actions (both widgets exist now)
				slider.action_({ arg sl;
					var val = spec.map(sl.value);
					numBox.value_(val);
					trackManager.setParam(trackNum, param, val);
				});

				numBox.action_({ arg nb;
					trackManager.setParam(trackNum, param, nb.value);
					slider.value_(spec.unmap(nb.value));
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
				.gridResolution_(0.1) // Grid every 100ms
				.setSelectionColor(0, Color.yellow.alpha_(0.3))  // Selection color
				.setEditableSelectionStart(0, true)   // Enable native zoom
				.setEditableSelectionSize(0, true);   // SHIFT+right-click to zoom

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
				.acceptsMouse_(false)      // Don't intercept any mouse events
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

					if(currentBuffer.notNil and: { currentBuffer.sampleRate.notNil }, {
						bufferDuration = currentBuffer.numFrames / currentBuffer.sampleRate;

						// === LAYER 0: FFT SPECTROGRAM (Phase 11) ===
						if(spectrogramEnabled and: { spectrogramData.notNil }, {
							var sliceWidth = viewWidth / 60;  // 60 time slices
							var bandHeight = viewHeight / 10;  // 10 frequency bands

							spectrogramData.do({ arg timeSlice, timeIdx;
								timeSlice.do({ arg magnitude, freqIdx;
									// Map magnitude (0-1) to color (dark blue → bright cyan)
									var alpha = magnitude.clip(0, 1);
									var hue = 0.55;  // Cyan hue
									var brightness = alpha.linlin(0, 1, 0.1, 1.0);

									Pen.fillColor = Color.hsv(hue, 0.8, brightness, alpha * 0.5);
									Pen.fillRect(Rect(
										timeIdx * sliceWidth,
										viewHeight - ((freqIdx + 1) * bandHeight),  // Flip Y (low freqs at bottom)
										sliceWidth + 1,  // +1 to avoid gaps
										bandHeight + 1
									));
								});
							});
						});

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

						// Main playhead line (position parameter - static or slow-moving)
						Pen.color = Color.red.alpha_(0.8);
						Pen.width = 3;
						Pen.line(Point(positionPixels, 0), Point(positionPixels, viewHeight));
						Pen.stroke;

						// === LAYER 4: Real-time Playhead (Phase 8 - sample-accurate @ 60Hz) ===
						// This is the ACTUAL playhead from the grain engine's Phasor
						// Shows true position when scanSpeed > 0 or when position is modulated
						if(playheadPos.notNil and: { currentBuffer.notNil }, {
							var realPlayheadPixels = playheadPos * viewWidth;

							// Bright cyan line (distinct from position parameter)
							Pen.color = colors.cyan.alpha_(0.9);
							Pen.width = 2;
							Pen.line(Point(realPlayheadPixels, 0), Point(realPlayheadPixels, viewHeight));
							Pen.stroke;

							// Small label to distinguish from position parameter
							Pen.stringAtPoint(
								"Live",
								Point(realPlayheadPixels + 5, viewHeight - 20),
								Font("DejaVu Sans Mono", 9),
								colors.cyan
							);
						});

						// === LAYER 5: GRAIN PULSE ANIMATION (Phase 11) ===
						// Draw expanding/fading pulse rings at playhead position
						if(grainPulseEnabled and: { playheadPos.notNil }, {
							var pulseX = playheadPos * viewWidth;
							var pulseY = viewHeight / 2;
							var overlap = track.params[\overlap] ? 4;

							// Create subtle pulse effect based on grain density
							// Higher overlap = more frequent pulses (visual feedback for grain density)
							var pulsePhase = (Date.getDate.rawSeconds * overlap * 2).mod(1.0);
							var pulseRadius = pulsePhase.linlin(0, 1, 5, 25);
							var pulseAlpha = (1 - pulsePhase) * 0.4;

							// Draw expanding ring
							Pen.strokeColor = colors.yellow.alpha_(pulseAlpha);
							Pen.width = 2;
							Pen.strokeOval(Rect(
								pulseX - pulseRadius,
								pulseY - pulseRadius,
								pulseRadius * 2,
								pulseRadius * 2
							));
						});
					});
				});

			// Start 30fps update routine for overlay
			updateRoutine = Routine({
				loop {
					{ overlayView.refresh }.defer;
					(1/30).wait;  // 30 FPS
				}
			}).play(AppClock);

			// Phase 8: OSC listener for sample-accurate playhead @ 60Hz
			// Receives normalized position (0-1) from grain engine's SendReply
			oscListener = OSCFunc({ arg msg, time, addr, recvPort;
				var nodeID = msg[1];  // Synth node ID
				var replyID = msg[2];  // '/playhead'
				var position = msg[3]; // Normalized position 0-1

				// Update playhead position (this will be drawn in overlay)
				playheadPos = position;
			}, '/playhead');

			// Phase 11: Initialize spectrogram data (10 frequency bands × 60 time slices)
			spectrogramData = Array.fill(60, { Array.fill(10, { 0.0 }) });

			// Phase 11: OSC listener for FFT spectrogram data @ 30Hz
			spectrogramOSC = OSCFunc({ arg msg, time, addr, recvPort;
				var nodeID = msg[1];
				var replyID = msg[2];
				var bands = msg[3..12];  // 10 frequency bands

				// Scroll spectrogram: remove oldest, add newest
				spectrogramData = spectrogramData.drop(1).add(bands);

				// Trigger overlay redraw
				{ overlayView.refresh }.defer;
			}, '/s4_fft');

			// Stop update routine and OSC listener when window closes
			win.onClose = {
				updateRoutine.stop;
				oscListener.free;  // Phase 8: Free OSC responder
				spectrogramOSC.free;  // Phase 11: Free spectrogram OSC responder
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
			// Play button
			Button(win, Rect(winWidth - 340, 290, 100, 30))
				.states_([["▶ PLAY", Color.white, Color.green(0.6)]])
				.font_(Font("Monaco", 12, true))
				.action_({
					trackManager.playTrack(trackNum);
					"Track % PLAYING".format(trackNum + 1).postln;
				});

			// Stop button
			Button(win, Rect(winWidth - 230, 290, 100, 30))
				.states_([["■ STOP", Color.white, Color.red(0.6)]])
				.font_(Font("Monaco", 12, true))
				.action_({
					trackManager.stopTrack(trackNum);
					"Track % STOPPED".format(trackNum + 1).postln;
				});

			// Refresh button
			Button(win, Rect(winWidth - 110, 290, 100, 30))
				.states_([["Refresh", Color.white, Color.gray(0.5)]])
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

			// === SPECTRAL ENGINE CONTROLS ===
			yPos = yPos + 50;
			StaticText(win, Rect(450, yPos, 200, 20))
				.string_("SPECTRAL ENGINE")
				.font_(Font("DejaVu Sans Mono", 10, true))
				.stringColor_(colors.yellow);

			yPos = yPos + 25;
			makeSlider.value(win, 450, yPos, "Spectral Mix", ControlSpec(0, 1, \lin), \spectralMix, track.params[\spectralMix] ? 0.0);
			yPos = yPos + 22;
			makeSlider.value(win, 450, yPos, "Spectral Amp", ControlSpec(0, 1, \lin), \spectralAmp, track.params[\spectralAmp] ? 0.5);
			yPos = yPos + 22;
			makeSlider.value(win, 450, yPos, "Window Size", ControlSpec(0.05, 1.0, \exp), \spectralWindowSize, track.params[\spectralWindowSize] ? 0.2);
			yPos = yPos + 22;
			makeSlider.value(win, 450, yPos, "Overlaps", ControlSpec(1, 8, \lin, 1), \spectralOverlaps, track.params[\spectralOverlaps] ? 4);
			yPos = yPos + 22;
			makeSlider.value(win, 450, yPos, "Rate", ControlSpec(-2, 2, \lin), \spectralRate, track.params[\spectralRate] ? 1.0);
			yPos = yPos + 22;
			makeSlider.value(win, 450, yPos, "Pitch", ControlSpec(-24, 24, \lin), \spectralPitch, track.params[\spectralPitch] ? 0);
			yPos = yPos + 22;
			makeSlider.value(win, 450, yPos, "Smear", ControlSpec(0, 1, \lin), \spectralSmear, track.params[\spectralSmear] ? 0);
			yPos = yPos + 22;
			// Freeze button
			Button(win, Rect(450, yPos, 150, 20))
				.states_([
					["Freeze: OFF", colors.fg, Color.gray(0.3)],
					["Freeze: ON", colors.black, colors.yellow]
				])
				.font_(Font("DejaVu Sans Mono", 9))
				.action_({ arg btn;
					trackManager.setParam(trackNum, \spectralFreeze, btn.value);
				});

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
