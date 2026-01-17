/*
BEARULATOR: Quad Spatial Panner GUI
Phase 12 - Visual Quad Positioning

Interactive 2D panner for quad speaker setups.
Displays 4 tracks as colored dots on a 2D spatial field.
Click and drag to position tracks in quad space.

Speaker Layout:
  FL        FR
    [ X Y ]
  RL        RR

Features:
- Visual representation of speaker positions
- Drag-and-drop track positioning
- Real-time parameter updates
- Color-coded tracks (cyan, yellow, green, orange)
- Doom Material themed
*/

~bearulatorQuadPanner = { arg trackManager;
	var window, canvas;
	var canvasWidth = 400, canvasHeight = 400;
	var margin = 40;
	var fieldWidth, fieldHeight;
	var colors, trackColors;
	var trackPositions;  // Array of [x, y] positions (-1 to 1)
	var positionHistory;  // Phase 13: Trail history for each track
	var draggingTrack = nil;
	var updateTask;  // Phase 13: Task for real-time position updates
	var showTrails = true;  // Phase 13: Toggle for visual trails
	var publicAPI;

	// Doom Material colors
	colors = (
		bg: Color.fromHexString("#262938"),
		fg: Color.fromHexString("#EEFFFF"),
		cyan: Color.fromHexString("#89DDFF"),
		yellow: Color.fromHexString("#ffcb6b"),
		green: Color.fromHexString("#c3e88d"),
		orange: Color.fromHexString("#f78c6c"),
		red: Color.fromHexString("#ff5370"),
		gridLine: Color.gray(0.3)
	);

	// Track colors
	trackColors = [colors.cyan, colors.yellow, colors.green, colors.orange];

	// Field dimensions
	fieldWidth = canvasWidth - (margin * 2);
	fieldHeight = canvasHeight - (margin * 2);

	// Initialize track positions (default: corners)
	trackPositions = [
		[-0.5, -0.5],  // Track 1: Front-Left
		[ 0.5, -0.5],  // Track 2: Front-Right
		[-0.5,  0.5],  // Track 3: Rear-Left
		[ 0.5,  0.5]   // Track 4: Rear-Right
	];

	// Phase 13: Initialize position history for trails (30 points per track)
	positionHistory = 4.collect({ List.newClear(30) });

	publicAPI = (
		createWindow: { arg self;
			// Close existing window if open
			if(window.notNil, { window.close });

			// Create window (Phase 13: increased height for second row of buttons)
			window = Window("BEARULATOR: Quad Spatial Panner", Rect(100, 100, canvasWidth, canvasHeight + 125))
				.background_(colors.bg)
				.front;

			// Title
			StaticText(window, Rect(10, 10, canvasWidth - 20, 25))
				.string_("QUAD SPATIAL PANNER")
				.font_(Font("DejaVu Sans Mono", 14, true))
				.stringColor_(colors.cyan)
				.align_(\center);

			// Instructions
			StaticText(window, Rect(10, 35, canvasWidth - 20, 15))
				.string_("Drag colored dots to position tracks in quad space")
				.font_(Font("DejaVu Sans Mono", 9))
				.stringColor_(Color.gray(0.7))
				.align_(\center);

			// Canvas for quad field
			canvas = UserView(window, Rect(0, 60, canvasWidth, canvasHeight))
				.background_(Color.gray(0.15))
				.drawFunc_({
					var centerX = canvasWidth / 2;
					var centerY = canvasHeight / 2;

					// === DRAW SPEAKER POSITIONS ===
					// Draw speaker corners (small gray boxes)
					Pen.fillColor = colors.gridLine;
					Pen.fillRect(Rect(margin - 5, margin - 5, 10, 10));  // FL
					Pen.fillRect(Rect(canvasWidth - margin - 5, margin - 5, 10, 10));  // FR
					Pen.fillRect(Rect(margin - 5, canvasHeight - margin - 5, 10, 10));  // RL
					Pen.fillRect(Rect(canvasWidth - margin - 5, canvasHeight - margin - 5, 10, 10));  // RR

					// Speaker labels
					Pen.stringAtPoint("FL", Point(margin - 20, margin - 20), Font("Monaco", 9), colors.fg);
					Pen.stringAtPoint("FR", Point(canvasWidth - margin + 10, margin - 20), Font("Monaco", 9), colors.fg);
					Pen.stringAtPoint("RL", Point(margin - 20, canvasHeight - margin + 10), Font("Monaco", 9), colors.fg);
					Pen.stringAtPoint("RR", Point(canvasWidth - margin + 10, canvasHeight - margin + 10), Font("Monaco", 9), colors.fg);

					// === DRAW GRID ===
					Pen.strokeColor = colors.gridLine;
					Pen.width = 1;

					// Vertical centerline
					Pen.line(Point(centerX, margin), Point(centerX, canvasHeight - margin));
					Pen.stroke;

					// Horizontal centerline
					Pen.line(Point(margin, centerY), Point(canvasWidth - margin, centerY));
					Pen.stroke;

					// Outer boundary
					Pen.strokeColor = colors.fg.alpha_(0.3);
					Pen.width = 2;
					Pen.strokeRect(Rect(margin, margin, fieldWidth, fieldHeight));

					// === PHASE 13: DRAW POSITION TRAILS ===
					if(showTrails, {
						positionHistory.do({ arg history, i;
							var validPoints = history.select({ arg p; p.notNil });
							if(validPoints.size > 1, {
								Pen.strokeColor = trackColors[i].alpha_(0.3);
								Pen.width = 2;

								// Draw trail as connected line segments
								validPoints.do({ arg point, idx;
									if(idx > 0, {
										var prevPoint = validPoints[idx - 1];
										var x1 = ((prevPoint[0] + 1) * 0.5 * fieldWidth) + margin;
										var y1 = ((prevPoint[1] + 1) * 0.5 * fieldHeight) + margin;
										var x2 = ((point[0] + 1) * 0.5 * fieldWidth) + margin;
										var y2 = ((point[1] + 1) * 0.5 * fieldHeight) + margin;

										// Fade older trail points
										var alpha = (idx / validPoints.size) * 0.3;
										Pen.strokeColor = trackColors[i].alpha_(alpha);
										Pen.line(Point(x1, y1), Point(x2, y2));
										Pen.stroke;
									});
								});
							});
						});
					});

					// === DRAW TRACK POSITIONS ===
					trackPositions.do({ arg pos, i;
						var x = pos[0];  // -1 to 1
						var y = pos[1];  // -1 to 1
						var pixelX = ((x + 1) * 0.5 * fieldWidth) + margin;
						var pixelY = ((y + 1) * 0.5 * fieldHeight) + margin;
						var radius = 12;

						// Draw track dot (filled circle)
						Pen.fillColor = trackColors[i];
						Pen.fillOval(Rect(pixelX - radius, pixelY - radius, radius * 2, radius * 2));

						// Draw track number
						Pen.stringAtPoint(
							(i + 1).asString,
							Point(pixelX - 4, pixelY - 7),
							Font("Monaco", 12, true),
							colors.bg
						);

						// Draw position coordinates (below dot)
						Pen.stringAtPoint(
							"(%.2f, %.2f)".format(x, y),
							Point(pixelX - 30, pixelY + radius + 5),
							Font("Monaco", 8),
							trackColors[i].alpha_(0.8)
						);
					});
				})
				.mouseDownAction_({ arg view, x, y, modifiers, buttonNumber, clickCount;
					// Check if click is on any track dot
					trackPositions.do({ arg pos, i;
						var trackX = ((pos[0] + 1) * 0.5 * fieldWidth) + margin;
						var trackY = ((pos[1] + 1) * 0.5 * fieldHeight) + margin;
						var dist = ((x - trackX).squared + (y - trackY).squared).sqrt;

						if(dist < 12, {
							draggingTrack = i;
							"Dragging Track %".format(i + 1).postln;
						});
					});
				})
				.mouseMoveAction_({ arg view, x, y, modifiers;
					if(draggingTrack.notNil, {
						// Convert pixel coords to normalized space (-1 to 1)
						var normalizedX = ((x - margin) / fieldWidth * 2) - 1;
						var normalizedY = ((y - margin) / fieldHeight * 2) - 1;

						// Clamp to field boundaries
						normalizedX = normalizedX.clip(-1, 1);
						normalizedY = normalizedY.clip(-1, 1);

						// Update track position
						trackPositions[draggingTrack] = [normalizedX, normalizedY];

						// Update master bus parameters
						trackManager.setQuadPosition(draggingTrack, normalizedX, normalizedY);

						// Refresh canvas
						canvas.refresh;
					});
				})
				.mouseUpAction_({
					if(draggingTrack.notNil, {
						"Track % positioned at (%.2f, %.2f)".format(
							draggingTrack + 1,
							trackPositions[draggingTrack][0],
							trackPositions[draggingTrack][1]
						).postln;
						draggingTrack = nil;
					});
				});

			// Preset buttons
			Button(window, Rect(10, canvasHeight + 65, 90, 20))
				.states_([["Corners", colors.fg, Color.gray(0.3)]])
				.font_(Font("Monaco", 9))
				.action_({
					trackPositions = [
						[-0.7, -0.7], [0.7, -0.7],
						[-0.7,  0.7], [0.7,  0.7]
					];
					self.updateAllPositions;
					canvas.refresh;
				});

			Button(window, Rect(105, canvasHeight + 65, 90, 20))
				.states_([["Front Row", colors.fg, Color.gray(0.3)]])
				.font_(Font("Monaco", 9))
				.action_({
					trackPositions = [
						[-0.7, -0.5], [0.7, -0.5],
						[-0.3, -0.5], [0.3, -0.5]
					];
					self.updateAllPositions;
					canvas.refresh;
				});

			Button(window, Rect(200, canvasHeight + 65, 90, 20))
				.states_([["Circle", colors.fg, Color.gray(0.3)]])
				.font_(Font("Monaco", 9))
				.action_({
					trackPositions = [
						[0.0, -0.7],   // Front center
						[0.7, 0.0],    // Right center
						[0.0, 0.7],    // Rear center
						[-0.7, 0.0]    // Left center
					];
					self.updateAllPositions;
					canvas.refresh;
				});

			Button(window, Rect(295, canvasHeight + 65, 90, 20))
				.states_([["Center All", colors.fg, Color.gray(0.3)]])
				.font_(Font("Monaco", 9))
				.action_({
					trackPositions = [
						[0.0, 0.0], [0.0, 0.0],
						[0.0, 0.0], [0.0, 0.0]
					];
					self.updateAllPositions;
					canvas.refresh;
				});

			// Phase 13: Advanced controls (second row)
			Button(window, Rect(10, canvasHeight + 90, 90, 20))
				.states_([["Freeze", colors.fg, colors.red.alpha_(0.6)]])
				.font_(Font("Monaco", 9, true))
				.action_({
					self.freezePositions;
				});

			Button(window, Rect(105, canvasHeight + 90, 90, 20))
				.states_([["Randomize", colors.fg, colors.orange.alpha_(0.6)]])
				.font_(Font("Monaco", 9, true))
				.action_({
					self.randomizePositions;
				});

			Button(window, Rect(200, canvasHeight + 90, 90, 20))
				.states_([["Save Preset", colors.fg, colors.green.alpha_(0.6)]])
				.font_(Font("Monaco", 9))
				.action_({
					var name = "preset" ++ Date.getDate.stamp;
					self.savePreset(name);
					("Saved as: " ++ name).postln;
				});

			Button(window, Rect(295, canvasHeight + 90, 90, 20))
				.states_([["Load Last", colors.fg, colors.cyan.alpha_(0.6)]])
				.font_(Font("Monaco", 9))
				.action_({
					if(~quadPannerPresets.notNil and: { ~quadPannerPresets.size > 0 }, {
						var lastKey = ~quadPannerPresets.keys.asArray.last;
						self.loadPreset(lastKey);
					}, {
						"No presets saved yet.".warn;
					});
				});

			// Phase 13: Start real-time position update task
			updateTask = Task({
				loop {
					// Read current positions from track manager
					4.do({ arg i;
						var track = trackManager.getTracks[i];
						if(track.quadX.notNil, {
							var currentPos = [track.quadX, track.quadY];

							// Update position history (circular buffer)
							positionHistory[i].removeAt(0);
							positionHistory[i].add(currentPos);

							// Update displayed position
							trackPositions[i] = currentPos;
						});
					});

					// Refresh canvas
					{ canvas.refresh }.defer;

					// Update at 20Hz (smooth but not too CPU-intensive)
					0.05.wait;
				}
			}).play(AppClock);

			// Store window reference
			self.window = window;
			self.canvas = canvas;

			// Window close action
			window.onClose = {
				if(updateTask.notNil, { updateTask.stop });
				"Quad panner closed.".postln;
			};

			"Quad spatial panner created with real-time trails.".postln;
		},

		// Update all track positions in master bus
		updateAllPositions: {
			trackPositions.do({ arg pos, i;
				trackManager.setQuadPosition(i, pos[0], pos[1]);
			});
		},

		// Phase 13: Freeze current positions (stop all spatial modulation)
		freezePositions: { arg self;
			4.do({ arg i;
				var track = trackManager.getTracks[i];
				// Store current positions
				if(track.quadX.notNil, {
					trackPositions[i] = [track.quadX, track.quadY];
				});
			});
			canvas.refresh;
			"Spatial positions frozen.".postln;
		},

		// Phase 13: Randomize all track positions
		randomizePositions: { arg self;
			trackPositions = 4.collect({
				[rrand(-0.8, 0.8), rrand(-0.8, 0.8)]
			});
			self.updateAllPositions;
			canvas.refresh;
			"Spatial positions randomized.".postln;
		},

		// Phase 13: Save current preset
		savePreset: { arg self, name;
			var presetData = (
				name: name,
				positions: trackPositions.deepCopy
			);
			// Store in environment variable
			if(~quadPannerPresets.isNil, {
				~quadPannerPresets = IdentityDictionary.new;
			});
			~quadPannerPresets.put(name.asSymbol, presetData);
			("Preset '" ++ name ++ "' saved.").postln;
		},

		// Phase 13: Load preset by name
		loadPreset: { arg self, name;
			if(~quadPannerPresets.notNil, {
				var preset = ~quadPannerPresets.at(name.asSymbol);
				if(preset.notNil, {
					trackPositions = preset.positions.deepCopy;
					self.updateAllPositions;
					canvas.refresh;
					("Preset '" ++ name ++ "' loaded.").postln;
				}, {
					("Preset '" ++ name ++ "' not found.").warn;
				});
			}, {
				"No presets saved yet.".warn;
			});
		},

		// Free resources
		free: { arg self;
			if(window.notNil, { window.close });
		}
	);

	publicAPI;
};

/*
USAGE EXAMPLES:

// Create quad panner (requires trackManager)
~quadPanner = ~bearulatorQuadPanner.value(~trackManager);
~quadPanner.createWindow();

// Cleanup
~quadPanner.free;
*/
