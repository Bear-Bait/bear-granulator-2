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
			var grainPlayheadPos = 0;  // Phase 15: Grain engine playhead position (0-1)
			var spectralPlayheadPos = 0;  // Phase 15: Spectral engine playhead position (0-1)
			var directPlayheadPos = 0;  // Phase 15: Direct playback playhead position (0-1)
			var recPlayheadPos = nil;  // Phase 15: Recording playhead position (0-1)
			var grainOSCListener;  // Phase 15: OSC responder for grain playhead
			var spectralOSCListener;  // Phase 15: OSC responder for spectral playhead
			var directOSCListener;  // Phase 15: OSC responder for direct playback playhead
			var recOSCListener;  // Phase 15: OSC responder for recording playhead
			var spectrogramData, spectrogramOSC;  // Phase 11: FFT spectrogram data
			var spectrogramEnabled = true;  // Phase 11: Toggle spectrogram display
			var grainPulses = List.new;  // Phase 11: Grain trigger pulse animations
			var grainPulseEnabled = true;  // Phase 11: Toggle grain pulse display
			var cropMode = false;  // Phase 15: Crop mode toggle
			var cropButton, applyCropButton;  // Phase 15: Crop UI elements
			var grainEngineButton, spectralEngineButton;  // Phase 15: Engine toggle buttons

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
					var isRecording = track.recorder.isRecording;
					var recPulse = (Main.elapsedTime * 2).sin.linlin(-1, 1, 0.3, 1.0);
				var yOffset, grainActive, spectralActive;  // Phase 15

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

						// === LAYER 4A: Grain Playhead (Phase 15 - sample-accurate @ 60Hz) ===
						// Shows actual grain engine playhead position
						if(grainPlayheadPos.notNil and: { currentBuffer.notNil }, {
							grainActive = if(grainEngineButton.notNil, { grainEngineButton.value == 1 }, { false });

							if(grainActive, {
								var grainPlayheadPixels = grainPlayheadPos * viewWidth;

								// Bright green line for grain engine
								Pen.color = colors.green.alpha_(0.85);
								Pen.width = 2;
								Pen.line(Point(grainPlayheadPixels, 0), Point(grainPlayheadPixels, viewHeight));
								Pen.stroke;

								// Small label
								Pen.stringAtPoint(
									"Grain",
									Point(grainPlayheadPixels + 5, viewHeight - 35),
									Font("DejaVu Sans Mono", 8),
									colors.green
								);
							});
						});

						// === LAYER 4B: Spectral Playhead (Phase 15 - sample-accurate @ 60Hz) ===
						// Shows actual spectral engine playhead position
						if(spectralPlayheadPos.notNil and: { currentBuffer.notNil }, {
							spectralActive = if(spectralEngineButton.notNil, { spectralEngineButton.value == 1 }, { false });

							if(spectralActive, {
								var spectralPlayheadPixels = spectralPlayheadPos * viewWidth;

								// Bright yellow line for spectral engine
								Pen.color = colors.yellow.alpha_(0.85);
								Pen.width = 2;
								Pen.line(Point(spectralPlayheadPixels, 0), Point(spectralPlayheadPixels, viewHeight));
								Pen.stroke;

								// Small label
								Pen.stringAtPoint(
									"Spectral",
									Point(spectralPlayheadPixels + 5, viewHeight - 20),
									Font("DejaVu Sans Mono", 8),
									colors.yellow
								);
							});
						});

						// === LAYER 4C: Direct Playback Playhead (Phase 15 - sample-accurate @ 60Hz) ===
						// Shows actual direct playback engine playhead position
						if(directPlayheadPos.notNil and: { currentBuffer.notNil }, {
							var directActive = track.params[\engineMode] == 1;  // Check if in DIRECT mode

							if(directActive, {
								var directPlayheadPixels = directPlayheadPos * viewWidth;

								// Bright white line for direct playback
								Pen.color = Color.white.alpha_(0.9);
								Pen.width = 3;
								Pen.line(Point(directPlayheadPixels, 0), Point(directPlayheadPixels, viewHeight));
								Pen.stroke;

								// Small label
								Pen.stringAtPoint(
									"DIRECT",
									Point(directPlayheadPixels + 5, viewHeight - 50),
									Font("DejaVu Sans Mono", 8, true),
									Color.white
								);
							});
						});

						// === LAYER 5: Recording Playhead (Phase 15 - @ 30Hz) ===
						// Red playhead showing current recording position
						if(recPlayheadPos.notNil and: { currentBuffer.notNil }, {
							var recPlayheadPixels = recPlayheadPos * viewWidth;
							var pulseAlpha = (Main.elapsedTime * 3).sin.abs;

							// Bright red line with glow
							Pen.color = Color.red.alpha_(0.95);
							Pen.width = 3;
							Pen.line(Point(recPlayheadPixels, 0), Point(recPlayheadPixels, viewHeight));
							Pen.stroke;

							// Pulsing "REC" label
							Pen.stringAtPoint(
								"REC",
								Point(recPlayheadPixels + 5, 10),
								Font("DejaVu Sans Mono", 10, true),
								Color.red
							);

							// Pulsing red dot indicator
							Pen.fillColor = Color.red.alpha_(pulseAlpha);
							Pen.fillOval(Rect(recPlayheadPixels - 5, 5, 10, 10));
						});

						// === LAYER 5: GRAIN PULSE ANIMATION (Phase 11/15) ===
						// Draw expanding/fading pulse rings at grain playhead position
						// Only shows when grain engine is active
						if(grainPulseEnabled and: { grainPlayheadPos.notNil }, {
							grainActive = if(grainEngineButton.notNil, { grainEngineButton.value == 1 }, { false });

							if(grainActive, {
								var pulseX = grainPlayheadPos * viewWidth;
								var pulseY = viewHeight / 2;
								var overlap = track.params[\overlap] ? 4;

								// Create subtle pulse effect based on grain density
								// Higher overlap = more frequent pulses (visual feedback for grain density)
								var pulsePhase = (Date.getDate.rawSeconds * overlap * 2).mod(1.0);
								var pulseRadius = pulsePhase.linlin(0, 1, 5, 25);
								var pulseAlpha = (1 - pulsePhase) * 0.3;

								// Draw expanding ring (green for grain engine)
								Pen.strokeColor = colors.green.alpha_(pulseAlpha);
								Pen.width = 2;
								Pen.strokeOval(Rect(
									pulseX - pulseRadius,
									pulseY - pulseRadius,
									pulseRadius * 2,
									pulseRadius * 2
								));
							});
						});

						// === LAYER 6: RECORDING INDICATOR (Phase 15) ===
						if(isRecording, {
							// Pulsing red border
							Pen.strokeColor = Color.red.alpha_(recPulse);
							Pen.width = 4;
							Pen.strokeRect(Rect(0, 0, viewWidth, viewHeight));

							// "RECORDING..." text with pulsing glow
							Pen.stringAtPoint(
								"RECORDING...",
								Point(10, 10),
								Font("DejaVu Sans Mono", 14, true),
								Color.red.alpha_(recPulse)
							);

							// Progress bar (4-second buffer)
							Pen.fillColor = Color.red.alpha_(0.3);
							Pen.fillRect(Rect(0, viewHeight - 10, (recPlayheadPos ? 0) * viewWidth, 10));

							// Pulsing red dot in corner
							Pen.fillColor = Color.red.alpha_(recPulse);
							Pen.fillOval(Rect(viewWidth - 20, 5, 15, 15));
						});

						// === LAYER 7: CROP MODE INDICATOR (Phase 15) ===
						if(cropMode, {
							var sel = sfv.selection(0);
							var cropPulse = (Main.elapsedTime * 1.5).sin.linlin(-1, 1, 0.5, 1.0);

							// Pulsing yellow border
							Pen.strokeColor = colors.yellow.alpha_(cropPulse);
							Pen.width = 3;
							Pen.strokeRect(Rect(0, 0, viewWidth, viewHeight));

							// "CROP MODE" text in top-right
							Pen.stringAtPoint(
								"CROP MODE - Select region to keep",
								Point(viewWidth - 280, 10),
								Font("DejaVu Sans Mono", 11, true),
								colors.yellow.alpha_(cropPulse)
							);

							// Highlight selected region with yellow overlay
							if(sel.notNil and: { sel[1] > 0 }, {
								var selStart = (sel[0] / currentBuffer.numFrames) * viewWidth;
								var selWidth = (sel[1] / currentBuffer.numFrames) * viewWidth;

								// Semi-transparent yellow fill
								Pen.fillColor = colors.yellow.alpha_(0.2);
								Pen.fillRect(Rect(selStart, 0, selWidth, viewHeight));

								// Bright yellow borders on selection
								Pen.strokeColor = colors.yellow.alpha_(0.9);
								Pen.width = 2;
								Pen.strokeRect(Rect(selStart, 0, selWidth, viewHeight));
							});
						});

						// === LAYER 8: ENGINE STATUS INDICATORS (Phase 15) ===
						// Show which engines are currently running
						yOffset = 40;  // Start below waveform instructions
						grainActive = if(grainEngineButton.notNil, { grainEngineButton.value == 1 }, { false });
						spectralActive = if(spectralEngineButton.notNil, { spectralEngineButton.value == 1 }, { false });

						// Grain engine indicator
						if(grainActive, {
							var pulse = (Main.elapsedTime * 2).sin.linlin(-1, 1, 0.7, 1.0);

							// Green dot
							Pen.fillColor = colors.green.alpha_(pulse);
							Pen.fillOval(Rect(10, yOffset, 12, 12));

							// "GRAIN" text
							Pen.stringAtPoint(
								"GRAIN",
								Point(25, yOffset - 2),
								Font("DejaVu Sans Mono", 10, true),
								colors.green.alpha_(0.9)
							);

							yOffset = yOffset + 18;
						});

						// Spectral engine indicator
						if(spectralActive, {
							var pulse = (Main.elapsedTime * 2).sin.linlin(-1, 1, 0.7, 1.0);

							// Yellow dot
							Pen.fillColor = colors.yellow.alpha_(pulse);
							Pen.fillOval(Rect(10, yOffset, 12, 12));

							// "SPECTRAL" text
							Pen.stringAtPoint(
								"SPECTRAL",
								Point(25, yOffset - 2),
								Font("DejaVu Sans Mono", 10, true),
								colors.yellow.alpha_(0.9)
							);
						});

						// Concurrent mode badge (both engines running)
						if(grainActive and: spectralActive, {
							var concurrentPulse = (Main.elapsedTime * 1.5).sin.linlin(-1, 1, 0.6, 1.0);

							// Bright cyan badge for concurrent mode
							Pen.fillColor = colors.cyan.alpha_(0.15 * concurrentPulse);
							Pen.fillRect(Rect(viewWidth - 140, 40, 130, 20));

							Pen.strokeColor = colors.cyan.alpha_(0.8 * concurrentPulse);
							Pen.width = 2;
							Pen.strokeRect(Rect(viewWidth - 140, 40, 130, 20));

							Pen.stringAtPoint(
								"CONCURRENT MODE",
								Point(viewWidth - 135, 43),
								Font("DejaVu Sans Mono", 9, true),
								colors.cyan.alpha_(concurrentPulse)
							);
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

			// Phase 15: OSC listener for grain engine playhead @ 60Hz
			grainOSCListener = OSCFunc({ arg msg, time, addr, recvPort;
				var nodeID = msg[1];
				var replyID = msg[2];  // '/grainPlayhead'
				var position = msg[3]; // Normalized position 0-1

				// Update grain playhead position
				grainPlayheadPos = position;
			}, '/grainPlayhead');

			// Phase 15: OSC listener for spectral engine playhead @ 60Hz
			spectralOSCListener = OSCFunc({ arg msg, time, addr, recvPort;
				var nodeID = msg[1];
				var replyID = msg[2];  // '/spectralPlayhead'
				var position = msg[3]; // Normalized position 0-1

				// Update spectral playhead position
				spectralPlayheadPos = position;
			}, '/spectralPlayhead');

			// Phase 15: OSC listener for direct playback playhead @ 60Hz
			directOSCListener = OSCFunc({ arg msg, time, addr, recvPort;
				var nodeID = msg[1];
				var replyID = msg[2];  // '/directPlayhead'
				var position = msg[3]; // Normalized position 0-1

				// Update direct playhead position
				directPlayheadPos = position;
			}, '/directPlayhead');

			// Phase 15: OSC listener for recording playhead @ 30Hz
			// Receives normalized position (0-1) from buffer recorder's SendReply
			recOSCListener = OSCFunc({ arg msg, time, addr, recvPort;
				var nodeID = msg[1];
				var replyID = msg[2];  // '/recPlayhead'
				var position = msg[3]; // Normalized position 0-1

				// Update recording playhead position (red line)
				recPlayheadPos = position;
			}, '/recPlayhead');

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

			// Stop update routine and OSC listeners when window closes
			win.onClose = {
				updateRoutine.stop;
				grainOSCListener.free;  // Phase 15: Free grain playhead OSC responder
				spectralOSCListener.free;  // Phase 15: Free spectral playhead OSC responder
				directOSCListener.free;  // Phase 15: Free direct playback OSC responder
				recOSCListener.free;  // Phase 15: Free recording OSC responder
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

					// Ensure minimum window size (SKIP in crop mode)
					if(cropMode.not and: { (loopEnd - loopStart) < 0.01 }, {
						"Loop window too small for playback (minimum 1%)".warn;
						^this;
					});

					// Update engine (only if not in crop mode)
					if(cropMode.not, {
						trackManager.setParam(trackNum, \loopStart, loopStart);
						trackManager.setParam(trackNum, \loopEnd, loopEnd);
					});

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
			// Phase 15: GRAIN ENGINE toggle
			grainEngineButton = Button(win, Rect(winWidth - 340, 290, 100, 30))
				.states_([
					["GRAIN: OFF", Color.white, Color.gray(0.4)],
					["GRAIN: ON", Color.black, colors.green]
				])
				.font_(Font("Monaco", 10, true))
				.value_(0)  // Start OFF
				.action_({ arg btn;
					if(btn.value == 1, {
						track.grainSynth.run(true);
						trackManager.setParam(trackNum, \amp, 0.5);
						"Track %: Grain engine RUNNING".format(trackNum + 1).postln;
					}, {
						track.grainSynth.run(false);
						"Track %: Grain engine STOPPED".format(trackNum + 1).postln;
					});
				});

			// Phase 15: SPECTRAL ENGINE toggle
			spectralEngineButton = Button(win, Rect(winWidth - 230, 290, 100, 30))
				.states_([
					["SPECTRAL: OFF", Color.white, Color.gray(0.4)],
					["SPECTRAL: ON", Color.black, colors.yellow]
				])
				.font_(Font("Monaco", 10, true))
				.value_(0)  // Start OFF
				.action_({ arg btn;
					if(btn.value == 1, {
						track.spectralSynth.run(true);
						trackManager.setParam(trackNum, \spectralMix, 0.5);
						trackManager.setParam(trackNum, \spectralAmp, 0.5);
						"Track %: Spectral engine RUNNING".format(trackNum + 1).postln;
					}, {
						track.spectralSynth.run(false);
						"Track %: Spectral engine STOPPED".format(trackNum + 1).postln;
					});
				});

			// Refresh button
			Button(win, Rect(winWidth - 110, 290, 100, 30))
				.states_([["Refresh", Color.white, Color.gray(0.5)]])
				.font_(Font("Monaco", 10))
				.action_({
					self.updateWaveform(trackNum);
				});

			// Phase 15: CROP MODE button (below play controls)
			cropButton = Button(win, Rect(winWidth - 340, 325, 100, 25))
				.states_([
					["CROP MODE", Color.white, Color.gray(0.4)],
					["EXIT CROP", Color.black, colors.yellow]
				])
				.font_(Font("Monaco", 10, true))
				.background_(Color.blue)  // DEBUG: Make button bright blue so it's visible
				.action_({ arg btn;
					"╔══════════════════════════════════════╗".postln;
					"║ DEBUG: CROP BUTTON CLICKED!         ║".postln;
					"║ Button value = %                    ║".format(btn.value).postln;
					"╚══════════════════════════════════════╝".postln;
					cropMode = btn.value.asBoolean;
					if(cropMode, {
						"✓ Crop mode enabled - Select region to keep".postln;
						// Show apply crop button
						{
							applyCropButton.visible_(true);
							"DEBUG: Apply crop button shown".postln;
						}.defer;
					}, {
						"✓ Crop mode disabled".postln;
						// Hide apply crop button
						{
							applyCropButton.visible_(false);
							"DEBUG: Apply crop button hidden".postln;
						}.defer;
					});
				});

			"DEBUG: Crop button created at position (%, %)".format(winWidth - 340, 325).postln;

			// Phase 15: APPLY CROP button (appears when crop mode active)
			applyCropButton = Button(win, Rect(winWidth - 230, 325, 120, 25))
				.states_([["✂ APPLY CROP", Color.white, Color.green(0.6)]])
				.font_(Font("Monaco", 10, true))
				.visible_(false)  // Hidden by default
				.action_({
					var sel = sfv.selection(0);
					var currentBuffer = track.recorder.buffer;

					if(sel.notNil and: { sel[1] > 0 } and: { currentBuffer.notNil }, {
						var startFrame = sel[0].asInteger;
						var numFrames = sel[1].asInteger;
						var newBuffer, tempPath;

						fork {
							"Cropping buffer: % frames starting at %...".format(numFrames, startFrame).postln;

							// Create new buffer for cropped audio
							newBuffer = Buffer.alloc(server, numFrames, 1);
							server.sync;

							// Copy selected region to new buffer
							currentBuffer.copyData(newBuffer, dstStartAt: 0, srcStartAt: startFrame, numSamples: numFrames);
							server.sync;

							// Free old buffer
							currentBuffer.free;
							server.sync;

							// Update track's buffer reference
							track.recorder.buffer = newBuffer;

							// Write to temp file for waveform display
							tempPath = PathName.tmp +/+ "s4_cropped_" ++ Date.getDate.stamp ++ ".wav";
							newBuffer.write(tempPath, "WAV", "int16");
							server.sync;

							// Update track file path
							track.filePath = tempPath;
							track.recorder.tempFilePath = tempPath;

							// Reset loop bounds to full buffer
							trackManager.setParam(trackNum, \loopStart, 0.0);
							trackManager.setParam(trackNum, \loopEnd, 1.0);

							// Update synth buffer references
							track.grainSynth.set(\bufnum, newBuffer.bufnum);
							track.spectralSynth.set(\bufnum, newBuffer.bufnum);

							// Refresh waveform display
							{
								var soundFile = SoundFile.new;
								if(soundFile.openRead(tempPath), {
									{
										sfv.soundfile = soundFile;
										sfv.read(0, soundFile.numFrames);
										soundFile.close;
										sfv.setSelection(0, [0, newBuffer.numFrames]);
										sfv.refresh;

										// Exit crop mode
										cropButton.value_(0);
										cropMode = false;
										applyCropButton.visible_(false);

										"✓ Crop complete! New buffer: % frames (% seconds)".format(
											newBuffer.numFrames,
											(newBuffer.numFrames / server.sampleRate).round(0.01)
										).postln;
									}.defer;
								});
							}.defer(0.1);
						};
					}, {
						"No region selected for cropping".warn;
					});
				});

			// === PHASE 7: GRAIN CONTROL SLIDERS ===
			StaticText(win, Rect(10, 335, 880, 20))
				.string_("GRAIN CONTROLS")
				.font_(Font("DejaVu Sans Mono", 12, true))
				.stringColor_(colors.cyan);

			// Column 1: Position & Pitch
			yPos = 360;

			// ENGINE MODE toggle (Direct Playback vs Granular)
			StaticText(win, Rect(10, yPos, 120, 20))
				.string_("ENGINE MODE:")
				.font_(Font("DejaVu Sans Mono", 10, true))
				.stringColor_(colors.fg);

			Button(win, Rect(135, yPos, 120, 20))
				.states_([
					["GRANULAR", Color.black, colors.cyan],
					["DIRECT", Color.white, Color.blue(0.5)]
				])
				.font_(Font("DejaVu Sans Mono", 9, true))
				.action_({ arg btn;
					var mode = btn.value;
					trackManager.setParam(trackNum, \engineMode, mode);
					case
						{ mode == 0 } { "✓ Track %: GRANULAR mode".format(trackNum + 1).postln }
						{ mode == 1 } { "✓ Track %: DIRECT mode".format(trackNum + 1).postln };
				});

			yPos = yPos + 30;  // Shift down for next control

			makeSlider.value(win, 10, yPos, "Position", ControlSpec(0, 1, \lin), \position, track.params[\position] ? 0.0);
			yPos = yPos + 22;
			makeSlider.value(win, 10, yPos, "Scan Speed", ControlSpec(-4, 4, \lin), \scanSpeed, track.params[\scanSpeed] ? 0);
			yPos = yPos + 22;
			makeSlider.value(win, 10, yPos, "Time Stretch", ControlSpec(0.25, 4, \exp), \timeStretch, track.params[\timeStretch] ? 1.0);
			yPos = yPos + 22;
			makeSlider.value(win, 10, yPos, "Rate (Speed)", ControlSpec(0.25, 4, \exp), \rate, track.params[\rate] ? 1.0);
			yPos = yPos + 22;
			makeSlider.value(win, 10, yPos, "Pos Jitter", ControlSpec(0, 1, \lin), \posJitter, track.params[\posJitter] ? 0.1);
			yPos = yPos + 22;

			// Master Pitch - controls BOTH engines simultaneously
			StaticText(win, Rect(10, yPos, 120, 18))
				.string_("MASTER Pitch")
				.font_(Font("DejaVu Sans Mono", 10, true))
				.stringColor_(colors.cyan);
			Slider(win, Rect(135, yPos, 150, 18))
				.value_(0.5)
				.action_({ arg sl;
					var val = sl.value.linlin(0, 1, -24, 24);
					trackManager.setParam(trackNum, \pitch, val);
					trackManager.setParam(trackNum, \spectralPitch, val);
				});
			NumberBox(win, Rect(290, yPos, 60, 18))
				.value_(0)
				.decimals_(1)
				.font_(Font("DejaVu Sans Mono", 9))
				.action_({ arg nb;
					trackManager.setParam(trackNum, \pitch, nb.value);
					trackManager.setParam(trackNum, \spectralPitch, nb.value);
				});

			// Pitch Quantize toggle (Phase 15)
			{
				var pitchQuantize = false;
				Button(win, Rect(355, yPos, 50, 18))
					.states_([
						["SMTH", Color.gray(0.3), Color.gray(0.7)],
						["QNTZ", Color.black, Color.green]
					])
					.font_(Font("DejaVu Sans Mono", 7, true))
					.value_(0)
					.action_({ arg btn;
						pitchQuantize = (btn.value == 1);
						if(pitchQuantize, {
							"✓ Pitch quantize: ON (semitones)".postln;
						}, {
							"✓ Pitch quantize: OFF (smooth)".postln;
						});
					});
			}.value;
			yPos = yPos + 22;

			makeSlider.value(win, 10, yPos, "Grain Pitch", ControlSpec(-24, 24, \lin), \pitch, track.params[\pitch] ? 0);
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
			makeSlider.value(win, 450, yPos, "Spectral Pitch", ControlSpec(-24, 24, \lin), \spectralPitch, track.params[\spectralPitch] ? 0);
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

		// Phase 12: MIDI visual feedback - CC parameter change (cyan overlay)
		showCCFeedback: { arg self, trackNum, param, value;
			// Display parameter name + value as cyan overlay
			// Fades out after 1 second
			{
				var win = windows[trackNum];
				var overlayText;

				if(win.notNil and: { win.isClosed.not }, {
					// Create temporary overlay text
					overlayText = StaticText(win, Rect(350, 50, 200, 30))
						.string_("% : %".format(param, value.round(0.01)))
						.font_(Font("DejaVu Sans Mono", 14, true))
						.stringColor_(Color.fromHexString("#89DDFF"))  // Doom cyan
						.background_(Color.fromHexString("#262938").alpha_(0.9));

					// Fade out and remove after 1 second
					{
						1.wait;
						{ overlayText.remove }.defer;
					}.fork(AppClock);
				});
			}.defer;
		},

		// Phase 12: MIDI visual feedback - Note trigger (green pulse)
		showNotePulse: { arg self, trackNum, velocity;
			// This triggers a visual pulse that the overlay will draw
			// Store pulse data for overlay to animate
			{
				var track = trackManager.getTrack(trackNum);
				if(track.notNil, {
					// Trigger pulse animation in overlay
					// The existing grain pulse animation will be enhanced to show this
					track.lastMIDIVelocity = velocity;
					track.lastMIDITime = Date.getDate.rawSeconds;
				});
			}.defer;
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
