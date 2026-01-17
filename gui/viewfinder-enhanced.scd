/*
BEARULATOR: ENHANCED GRANULAR VIEWFINDER
========================================

Advanced waveform visualization with grain-level feedback:
- Grain size overlay (semi-transparent window)
- Animated position playhead (real-time cursor)
- Loop boundary highlighting
- Grain-level zoom capabilities
- Mouse gesture controls

Inspired by Pure Data, Max/MSP, and NIME 2025 per-grain UI research

Usage:
  ~viewfinderEnhanced = ~bearulatorViewfinderEnhanced.value(server, trackManager);
  ~viewfinderEnhanced.createWindow(trackNum);
  ~viewfinderEnhanced.free;
*/

~bearulatorViewfinderEnhanced = { arg server, trackManager;
	var windows, soundFileViews, overlayViews, updateRoutines, publicAPI;
	var grainOverlays, playheadOverlays, boundaryOverlays;

	// Storage for each track (4 tracks)
	windows = Array.fill(4, { nil });
	soundFileViews = Array.fill(4, { nil });
	overlayViews = Array.fill(4, { nil });  // Main overlay UserView
	updateRoutines = Array.fill(4, { nil });

	// Individual overlay layers
	grainOverlays = Array.fill(4, { nil });
	playheadOverlays = Array.fill(4, { nil });
	boundaryOverlays = Array.fill(4, { nil });

	publicAPI = (
		// Feature toggles (can be disabled for debugging)
		showGrainOverlay: true,
		showPlayhead: true,
		showBoundaries: false,  // Off by default, toggle with 'L'

		/*
		==================================================
		CREATE ENHANCED VIEWFINDER WINDOW
		==================================================
		*/
		createWindow: { arg self, trackNum = 0;
			var win, sfv, overlayView, track, buffer;
			var winWidth = 900, winHeight = 400;
			var trackName, statusText;
			var colors;

			// Doom Material color palette
			colors = (
				bg: Color.fromHexString("#262938"),
				fg: Color.fromHexString("#EEFFFF"),
				cyan: Color.fromHexString("#89DDFF"),
				red: Color.fromHexString("#ff5370"),
				yellow: Color.fromHexString("#ffcb6b"),
				orange: Color.fromHexString("#f78c6c"),
				green: Color.fromHexString("#c3e88d"),
				selection: Color.fromHexString("#cc7000")
			);

			// Validate track number
			if(trackNum < 0 or: { trackNum > 3 }, {
				"Enhanced Viewfinder: Invalid track number %".format(trackNum).error;
				^nil;
			});

			// Get track and buffer
			track = trackManager.getTrack(trackNum);
			if(track.isNil, {
				"Enhanced Viewfinder: Track % not initialized".format(trackNum + 1).error;
				^nil;
			});

			buffer = track.recorder.buffer;
			if(buffer.isNil, {
				"Enhanced Viewfinder: Track % has no buffer loaded".format(trackNum + 1).warn;
				^nil;
			});

			// Close existing window if open
			if(windows[trackNum].notNil, {
				if(updateRoutines[trackNum].notNil, {
					updateRoutines[trackNum].stop;
				});
				windows[trackNum].close;
			});

			trackName = "Track % Enhanced Viewfinder".format(trackNum + 1);

			// ========================================
			// CREATE WINDOW
			// ========================================
			win = Window(trackName, Rect(100 + (trackNum * 50), 100 + (trackNum * 50), winWidth, winHeight))
				.background_(colors.bg)
				.front;

			// Title
			StaticText(win, Rect(10, 10, winWidth - 20, 30))
				.string_(trackName ++ " - Grain-Level Visualization")
				.font_(Font("DejaVu Sans Mono", 14, true))
				.stringColor_(colors.cyan)
				.align_(\center);

			// Info text
			StaticText(win, Rect(10, 45, winWidth - 20, 20))
				.string_("G: Zoom to grain • L: Toggle boundaries • Space: Freeze • Double-click: Auto-zoom")
				.font_(Font("DejaVu Sans Mono", 9))
				.stringColor_(Color.gray(0.7))
				.align_(\center);

			// ========================================
			// LAYER 1: WAVEFORM (SoundFileView base)
			// ========================================
			sfv = SoundFileView(win, Rect(10, 75, winWidth - 20, 250))
				.background_(Color.black)
				.waveColors_([colors.cyan.alpha_(0.8)])
				.gridOn_(true)
				.gridColor_(Color.gray(0.3))
				.timeCursorOn_(false)  // We'll draw our own
				.drawsWaveForm_(true)
				.elasticMode_(1)
				.gridResolution_(0.1);

			sfv.setSelectionColor(0, colors.selection.alpha_(0.5));

			// ========================================
			// LAYER 2-5: OVERLAY SYSTEM (UserView)
			// ========================================
			overlayView = UserView(win, Rect(10, 75, winWidth - 20, 250))
				.background_(Color.clear)
				.acceptsMouse_(false)      // Don't intercept any mouse events
				.acceptsMouseOver_(false)  // Let mouse events pass through
				.canFocus_(false)          // Don't steal focus
				.drawFunc_({
					var numFrames, sampleRate, viewWidth, viewHeight;
					var grainSize, position, posJitter, loopStart, loopEnd;
					var grainSizePixels, positionPixels, loopStartPixels, loopEndPixels;

					// Get current buffer info
					if(buffer.notNil and: { buffer.sampleRate.notNil }, {
						numFrames = buffer.numFrames;
						sampleRate = buffer.sampleRate;
						viewWidth = winWidth - 20;
						viewHeight = 250;

						// Get current parameters from track
						grainSize = track.params[\grainSize] ? 0.1;
						position = track.params[\position] ? 0.0;
						posJitter = track.params[\posJitter] ? 0.0;
						loopStart = track.params[\loopStart] ? 0.0;
						loopEnd = track.params[\loopEnd] ? 1.0;

						// ========================================
						// LAYER 3: LOOP BOUNDARY HIGHLIGHTING
						// ========================================
						if(self.showBoundaries, {
							var fadeWidth = ((loopEnd - loopStart) * 0.05).max(0.01);  // 5% fade zones
							var startX, endX, fadePixels;

							startX = loopStart * viewWidth;
							endX = loopEnd * viewWidth;
							fadePixels = fadeWidth * viewWidth;

							// Entry zone (green fade)
							Pen.fillColor = colors.green.alpha_(0.15);
							Pen.fillRect(Rect(startX, 0, fadePixels, viewHeight));

							// Exit zone (red fade)
							Pen.fillColor = colors.red.alpha_(0.15);
							Pen.fillRect(Rect(endX - fadePixels, 0, fadePixels, viewHeight));
						});

						// ========================================
						// LAYER 4: POSITION PLAYHEAD (animated)
						// ========================================
						if(self.showPlayhead, {
							var jitterWidth;

							positionPixels = position * viewWidth;

							// If jitter > 0, show fuzzy region
							if(posJitter > 0.01, {
								jitterWidth = posJitter * viewWidth;
								Pen.fillColor = colors.red.alpha_(0.2);
								Pen.fillRect(Rect(
									(positionPixels - (jitterWidth / 2)).max(0),
									0,
									jitterWidth,
									viewHeight
								));
							});

							// Main playhead line
							Pen.color = colors.red.alpha_(0.8);
							Pen.width = 3;
							Pen.line(Point(positionPixels, 0), Point(positionPixels, viewHeight));
							Pen.stroke;
						});

						// ========================================
						// LAYER 5: GRAIN SIZE OVERLAY
						// ========================================
						if(self.showGrainOverlay, {
							var bufferDuration = numFrames / sampleRate;

							grainSizePixels = (grainSize / bufferDuration) * viewWidth;
							positionPixels = position * viewWidth;

							// Semi-transparent rectangle showing grain window
							Pen.fillColor = colors.yellow.alpha_(0.25);
							Pen.fillRect(Rect(
								positionPixels,
								0,
								grainSizePixels.min(viewWidth - positionPixels),
								viewHeight
							));

							// Grain boundary markers (vertical lines)
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
						});
					});
				});

			// ========================================
			// LOAD WAVEFORM
			// ========================================
			{
				var soundFile;
				server.sync;

				if(track.filePath.notNil, {
					soundFile = SoundFile.new;
					if(soundFile.openRead(track.filePath), {
						{
							sfv.soundfile = soundFile;
							sfv.read(0, soundFile.numFrames);
							soundFile.close;
							sfv.refresh;
						}.defer;
					}, {
						"Enhanced Viewfinder: Could not open audio file".warn;
					});
				}, {
					"Enhanced Viewfinder: No file path found for this track".warn;
				});

				// Set initial selection to current loop window
				fork {
					0.1.wait;
					{
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

			// ========================================
			// MOUSE INTERACTIONS
			// ========================================

			// Selection updates loop window
			sfv.mouseMoveAction = { arg view;
				var sel = view.selection(0);
				var currentBuffer = track.recorder.buffer;
				if(sel.notNil and: { sel[1] > 0 } and: { currentBuffer.notNil }, {
					var startFrame = sel[0];
					var duration = sel[1];
					var endFrame = startFrame + duration;
					var numFrames = currentBuffer.numFrames;
					var loopStart = (startFrame / numFrames).clip(0.0, 1.0);
					var loopEnd = (endFrame / numFrames).clip(0.0, 1.0);

					if((loopEnd - loopStart) < 0.01, {
						loopEnd = (loopStart + 0.01).min(1.0);
					});

					trackManager.setParam(trackNum, \loopStart, loopStart);
					trackManager.setParam(trackNum, \loopEnd, loopEnd);

					overlayView.refresh;  // Refresh overlay when selection changes
				});
			};

			sfv.mouseUpAction = { arg view;
				var sel = view.selection(0);
				var currentBuffer = track.recorder.buffer;
				if(sel.notNil and: { sel[1] > 0 } and: { currentBuffer.notNil }, {
					var startFrame = sel[0];
					var duration = sel[1];
					var endFrame = startFrame + duration;
					var numFrames = currentBuffer.numFrames;
					var loopStart = (startFrame / numFrames).clip(0.0, 1.0);
					var loopEnd = (endFrame / numFrames).clip(0.0, 1.0);

					if((loopEnd - loopStart) < 0.01, {
						"Loop window too small (minimum 1% of buffer)".warn;
						^this;
					});

					trackManager.setParam(trackNum, \loopStart, loopStart);
					trackManager.setParam(trackNum, \loopEnd, loopEnd);

					postf("Track %: Loop Window Set\n", trackNum + 1);
					postf("  Start: %.2f%% | End: %.2f%%\n", loopStart * 100, loopEnd * 100);
				});
			};

			// ========================================
			// ZOOM & NAVIGATION
			// ========================================
			win.view.keyDownAction = { arg view, char, modifiers, unicode, keycode;
				var currentBuffer = track.recorder.buffer;
				if(currentBuffer.notNil, {
					var numFrames = currentBuffer.numFrames;
					var zoomFactor = 1.5;
					var panAmount = 0.1;

					// UP ARROW - Zoom In
					if(keycode == 63232, {
						var viewStart = sfv.scrollPos;
						var viewSize = sfv.viewFrames;
						var newSize = (viewSize / zoomFactor).max(100);
						var center = viewStart + (viewSize / 2);
						var newStart = (center - (newSize / 2)).clip(0, numFrames - newSize);

						{
							sfv.scroll(newStart);
							sfv.zoom(newSize);
							sfv.refresh;
							overlayView.refresh;
						}.defer;
					});

					// DOWN ARROW - Zoom Out
					if(keycode == 63233, {
						var viewStart = sfv.scrollPos;
						var viewSize = sfv.viewFrames;
						var newSize = (viewSize * zoomFactor).min(numFrames);
						var center = viewStart + (viewSize / 2);
						var newStart = (center - (newSize / 2)).clip(0, numFrames - newSize);

						{
							sfv.scroll(newStart);
							sfv.zoom(newSize);
							sfv.refresh;
							overlayView.refresh;
						}.defer;
					});

					// LEFT ARROW - Pan Left
					if(keycode == 63234, {
						var viewStart = sfv.scrollPos;
						var viewSize = sfv.viewFrames;
						var newStart = (viewStart - (viewSize * panAmount)).max(0);

						{
							sfv.scroll(newStart);
							sfv.refresh;
							overlayView.refresh;
						}.defer;
					});

					// RIGHT ARROW - Pan Right
					if(keycode == 63235, {
						var viewStart = sfv.scrollPos;
						var viewSize = sfv.viewFrames;
						var newStart = (viewStart + (viewSize * panAmount)).min(numFrames - viewSize);

						{
							sfv.scroll(newStart);
							sfv.refresh;
							overlayView.refresh;
						}.defer;
					});

					// G - Zoom to grain size
					if(char == $g, {
						var grainSize = track.params[\grainSize] ? 0.1;
						var sampleRate = currentBuffer.sampleRate;
						var grainFrames = (grainSize * sampleRate).asInteger;
						var targetViewSize = (grainFrames * 3).clip(100, numFrames);  // Show 3 grains worth
						var position = track.params[\position] ? 0.5;
						var centerFrame = (position * numFrames).asInteger;
						var newStart = (centerFrame - (targetViewSize / 2)).clip(0, numFrames - targetViewSize);

						{
							sfv.scroll(newStart);
							sfv.zoom(targetViewSize);
							sfv.refresh;
							overlayView.refresh;
							"Zoomed to grain level (%.1fms visible)".format((targetViewSize / sampleRate) * 1000).postln;
						}.defer;
					});

					// L - Toggle loop boundaries
					if(char == $l, {
						self.showBoundaries = self.showBoundaries.not;
						overlayView.refresh;
						"Loop boundaries: %".format(if(self.showBoundaries, "ON", "OFF")).postln;
					});
				});
			};

			// Mouse wheel zoom
			sfv.mouseWheelAction = { arg view, x, y, modifiers, xDelta, yDelta;
				var currentBuffer = track.recorder.buffer;
				if(currentBuffer.notNil, {
					var numFrames = currentBuffer.numFrames;
					var zoomFactor = if(yDelta > 0, { 1.2 }, { 0.83 });
					var viewStart = sfv.scrollPos;
					var viewSize = sfv.viewFrames;
					var mousePos = x / (winWidth - 20);
					var mouseFrame = viewStart + (viewSize * mousePos);
					var newSize = (viewSize * zoomFactor).clip(100, numFrames);
					var newStart = (mouseFrame - (newSize * mousePos)).clip(0, numFrames - newSize);

					{
						sfv.scroll(newStart);
						sfv.zoom(newSize);
						sfv.refresh;
						overlayView.refresh;
					}.defer;
				});
			};

			// ========================================
			// STATUS DISPLAY & CONTROLS
			// ========================================
			statusText = StaticText(win, Rect(10, 335, winWidth - 350, 40))
				.string_("Grain overlay: ON | Playhead: ON | Boundaries: OFF")
				.font_(Font("DejaVu Sans Mono", 10))
				.stringColor_(Color.gray(0.8))
				.align_(\left);

			// Reset Loop button
			Button(win, Rect(winWidth - 340, 340, 100, 30))
				.states_([["Reset Loop", Color.white, Color.gray(0.4)]])
				.font_(Font("DejaVu Sans Mono", 10))
				.action_({
					trackManager.setParam(trackNum, \loopStart, 0.0);
					trackManager.setParam(trackNum, \loopEnd, 1.0);
					{
						if(buffer.notNil, {
							sfv.setSelection(0, [0, buffer.numFrames]);
							sfv.refresh;
							overlayView.refresh;
						});
					}.defer;
					"Track %: Loop window reset to full buffer".format(trackNum + 1).postln;
				});

			// Refresh button
			Button(win, Rect(winWidth - 230, 340, 100, 30))
				.states_([["Refresh", Color.white, Color.green(0.5)]])
				.font_(Font("DejaVu Sans Mono", 10))
				.action_({
					{
						sfv.refresh;
						overlayView.refresh;
					}.defer;
				});

			// Toggle Overlays button
			Button(win, Rect(winWidth - 120, 340, 110, 30))
				.states_([
					["Overlays: ON", Color.white, colors.cyan],
					["Overlays: OFF", Color.white, Color.gray(0.5)]
				])
				.font_(Font("DejaVu Sans Mono", 9))
				.action_({ arg btn;
					if(btn.value == 0, {
						self.showGrainOverlay = true;
						self.showPlayhead = true;
					}, {
						self.showGrainOverlay = false;
						self.showPlayhead = false;
					});
					overlayView.refresh;
				});

			// ========================================
			// PHASE 3: ANIMATED UPDATE ROUTINE (30 FPS)
			// ========================================
			updateRoutines[trackNum] = Routine({
				loop {
					{
						overlayView.refresh;

						// Update status text
						statusText.string = "Grain: %ms | Pos: %.1f%% | Jitter: %.1f%% | %".format(
							((track.params[\grainSize] ? 0.1) * 1000).round(0.1),
							((track.params[\position] ? 0.0) * 100).round(1),
							((track.params[\posJitter] ? 0.0) * 100).round(1),
							if(self.showBoundaries, "Boundaries: ON", "Boundaries: OFF")
						);
					}.defer;
					(1/30).wait;  // 30 FPS
				}
			}).play(AppClock);

			// ========================================
			// STORE REFERENCES
			// ========================================
			windows[trackNum] = win;
			soundFileViews[trackNum] = sfv;
			overlayViews[trackNum] = overlayView;

			// Cleanup on window close
			win.onClose = {
				if(updateRoutines[trackNum].notNil, {
					updateRoutines[trackNum].stop;
					updateRoutines[trackNum] = nil;
				});
				windows[trackNum] = nil;
				soundFileViews[trackNum] = nil;
				overlayViews[trackNum] = nil;
			};

			"Enhanced Viewfinder created for Track % (30fps updates)".format(trackNum + 1).postln;
		},

		/*
		==================================================
		UTILITY FUNCTIONS
		==================================================
		*/

		// Close all viewfinder windows
		closeAll: { arg self;
			windows.do({ arg win, i;
				if(win.notNil, {
					if(updateRoutines[i].notNil, {
						updateRoutines[i].stop;
					});
					win.close;
				});
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

// Create enhanced viewfinder module (do this in main.scd)
~viewfinderEnhanced = ~bearulatorViewfinderEnhanced.value(s, ~trackManager);

// Open enhanced viewfinder for Track 1
~viewfinderEnhanced.createWindow(0);

// Toggle features
~viewfinderEnhanced.showGrainOverlay = false;  // Hide grain overlay
~viewfinderEnhanced.showPlayhead = false;       // Hide playhead
~viewfinderEnhanced.showBoundaries = true;      // Show loop boundaries

// Cleanup
~viewfinderEnhanced.free;
*/
