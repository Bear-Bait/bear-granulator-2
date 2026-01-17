/*
BEARULATOR: Modulation Window
Phase 5 - Per-Track Modulation Control

Opens a dedicated window for modulation control of a single track
- 4 modulators with full controls
- Parameter routing matrix
- Real-time visualization (future)
*/

~bearulatorModulationWindow = { arg trackManager, server, trackNum;
	var window, makeModulatorSection;

	// === HELPER: Create modulator controls ===
	makeModulatorSection = { arg parent, x, y, modNum;
		var yPos = y;
		var typeMenu, rateSlider, rateNum, depthSlider, depthNum, scopeView, scopeUpdater;
		var shapeMenu, targetMenu, minNum, maxNum;
		var enableButton, statusText;

		// Section box
		CompositeView(parent, Rect(x, y, 340, 260))
			.background_(Color.gray(0.2));

		// Section label
		StaticText(parent, Rect(x + 10, yPos + 5, 150, 20))
			.string_("MODULATOR " ++ (modNum + 1))
			.font_(Font("Monaco", 11, true))
			.stringColor_(Color.cyan(0.8));

		// Enable/Disable button
		enableButton = Button(parent, Rect(x + 260, yPos + 5, 70, 25))
			.states_([
				["OFF", Color.white, Color.gray(0.4)],
				["ON", Color.black, Color.green(0.7)]
			])
			.action_({ arg btn;
				if(btn.value == 1, {
					var type = typeMenu.value;
					var rate = rateNum.value;
					var depth = depthNum.value;
					var shape = shapeMenu.value;

					trackManager.createModulator(trackNum, modNum, type, rate, depth, shape);
					statusText.string_("Status: Active").stringColor_(Color.green);
				}, {
					trackManager.freeModulator(trackNum, modNum);
					statusText.string_("Status: Inactive").stringColor_(Color.red);
				});
			});

		yPos = yPos + 35;

		// Type selector
		StaticText(parent, Rect(x + 10, yPos, 40, 20))
			.string_("Type:")
			.font_(Font("Monaco", 9));
		typeMenu = PopUpMenu(parent, Rect(x + 55, yPos, 120, 20))
			.items_(["LFO", "Env Follow", "Random", "Envelope"])
			.value_(0)
			.font_(Font("Monaco", 9));

		yPos = yPos + 25;

		// Phase 16: MOSAIC MODE - Source track selector for Envelope Follower
		StaticText(parent, Rect(x + 10, yPos, 55, 20))
			.string_("Listen:")
			.font_(Font("Monaco", 9))
			.stringColor_(Color.new255(0, 170, 170)); // Cyan for special feature

		PopUpMenu(parent, Rect(x + 70, yPos, 95, 20))
			.items_(["Track 1", "Track 2", "Track 3", "Track 4"])
			.value_(trackNum)  // Default to self
			.font_(Font("Monaco", 9))
			.action_({ arg menu;
				trackManager.setModSourceTrack(trackNum, modNum, menu.value);
			})
			.toolTip_("Which track's audio to follow (Mosaic Mode)");

		yPos = yPos + 25;

		// Shape/Waveform selector
		StaticText(parent, Rect(x + 10, yPos, 45, 20))
			.string_("Shape:")
			.font_(Font("Monaco", 9));
		shapeMenu = PopUpMenu(parent, Rect(x + 235, yPos, 95, 20))
			.items_(["Sine", "Tri", "Saw", "Sqr", "SRnd", "Rnd"])
			.value_(0)
			.font_(Font("Monaco", 9))
			.action_({ arg menu;
				trackManager.setModParam(trackNum, modNum, \waveform, menu.value);
			});

		yPos = yPos + 25;

		// Rate control
		StaticText(parent, Rect(x + 10, yPos, 70, 18))
			.string_("Rate (Hz):")
			.font_(Font("Monaco", 9));

		rateSlider = Slider(parent, Rect(x + 140, yPos, 190, 18))
			.value_(ControlSpec(0.01, 20, \exp).unmap(1.0))
			.action_({ arg sl;
				var val = ControlSpec(0.01, 20, \exp).map(sl.value);
				rateNum.value_(val);
				trackManager.setModParam(trackNum, modNum, \freq, val);
			});

		rateNum = NumberBox(parent, Rect(x + 85, yPos, 50, 18))
			.value_(1.0)
			.decimals_(2)
			.font_(Font("Monaco", 9))
			.action_({ arg nb;
				rateSlider.value_(ControlSpec(0.01, 20, \exp).unmap(nb.value));
				trackManager.setModParam(trackNum, modNum, \freq, nb.value);
			});

		yPos = yPos + 22;

		// Phase 15.5: Tempo Sync controls
		StaticText(parent, Rect(x + 10, yPos, 70, 18))
			.string_("Tempo Sync:")
			.font_(Font("Monaco", 9));

		Button(parent, Rect(x + 85, yPos, 50, 18))
			.states_([
				["OFF", Color.gray(0.3), Color.gray(0.7)],
				["ON", Color.black, Color.cyan]
			])
			.font_(Font("Monaco", 8, true))
			.value_(0)
			.action_({ arg btn;
				trackManager.setModParam(trackNum, modNum, \tempoSync, btn.value);
				if(btn.value == 1, {
					"✓ Mod%: Tempo sync ON".format(modNum + 1).postln;
				}, {
					"✓ Mod%: Tempo sync OFF (free-running)".format(modNum + 1).postln;
				});
			});

		StaticText(parent, Rect(x + 140, yPos, 40, 18))
			.string_("Mode:")
			.font_(Font("Monaco", 9));

		PopUpMenu(parent, Rect(x + 185, yPos, 60, 18))
			.items_(["1/4", "1/8", "1/16", "1/8t", "1/16t"])
			.value_(1)  // Default to 1/8 note
			.font_(Font("Monaco", 8))
			.action_({ arg menu;
				trackManager.setModParam(trackNum, modNum, \syncMode, menu.value);
				"✓ Mod%: Sync mode = %".format(modNum + 1, menu.items[menu.value]).postln;
			});

		yPos = yPos + 22;

		// Depth control
		StaticText(parent, Rect(x + 10, yPos, 70, 18))
			.string_("Depth:")
			.font_(Font("Monaco", 9));

		depthSlider = Slider(parent, Rect(x + 140, yPos, 190, 18))
			.value_(1.0)
			.action_({ arg sl;
				depthNum.value_(sl.value);
				trackManager.setModParam(trackNum, modNum, \amp, sl.value);
			});

		depthNum = NumberBox(parent, Rect(x + 85, yPos, 50, 18))
			.value_(1.0)
			.decimals_(2)
			.font_(Font("Monaco", 9))
			.action_({ arg nb;
				depthSlider.value_(nb.value);
				trackManager.setModParam(trackNum, modNum, \amp, nb.value);
			});

		yPos = yPos + 30;

		// Routing section
		StaticText(parent, Rect(x + 10, yPos, 80, 18))
			.string_("ROUTING")
			.font_(Font("Monaco", 9, true))
			.stringColor_(Color.yellow(0.8));

		yPos = yPos + 20;

		// Target parameter selector
		StaticText(parent, Rect(x + 10, yPos, 50, 18))
			.string_("Target:")
			.font_(Font("Monaco", 9));
		targetMenu = PopUpMenu(parent, Rect(x + 65, yPos, 125, 18))
			.items_([
				"None",
				"Grain Size",
				"Density",
				"Position",
				"Pitch",
				"Pos Jitter",
				"Pitch Jitter",
				"Spread",
				"Filt Freq",      // Per-track filter
				"Filt Morph",     // Per-track filter
				"Filt Res",       // Per-track filter
				"Filt Decay",     // Per-track filter (drive)
				"Filt Mix",       // Per-track filter dry/wet
				"Rev Mix",
				"Del Mix",
				"Shimmer Mix",
				"Quad X",         // Phase 13: Spatial modulation
				"Quad Y",         // Phase 13: Spatial modulation
				"─────",          // Separator
				"M: Filter Freq",    // Phase 15: Master filter
				"M: Filter Morph",   // Phase 15: Master filter
				"M: Filter Res",     // Phase 15: Master filter
				"M: Filter Decay",   // Phase 15: Master filter
				"M: Filter Animate", // Phase 15: Master filter
				"M: Filter Mix"      // Phase 15: Master filter
			])
			.value_(0)
			.font_(Font("Monaco", 8));

		yPos = yPos + 22;

		// Min/Max range
		StaticText(parent, Rect(x + 10, yPos, 30, 18))
			.string_("Min:")
			.font_(Font("Monaco", 9));
		minNum = NumberBox(parent, Rect(x + 45, yPos, 55, 18))
			.value_(0.0)
			.decimals_(3)
			.font_(Font("Monaco", 9));

		StaticText(parent, Rect(x + 110, yPos, 30, 18))
			.string_("Max:")
			.font_(Font("Monaco", 9));
		maxNum = NumberBox(parent, Rect(x + 145, yPos, 55, 18))
			.value_(1.0)
			.decimals_(3)
			.font_(Font("Monaco", 9));

		Button(parent, Rect(x + 210, yPos, 50, 18))
			.states_([["ROUTE", Color.black, Color.green(0.7)]])
			.font_(Font("Monaco", 8, true))
			.action_({
				var paramMap = [
					nil, \grainSize, \density, \position, \pitch,
					\posJitter, \pitchJitter, \stereoSpread,
					\filterFreq, \filterMorph, \filterRes, \filterDecay, \filterMix,  // Per-track filter (5 params)
					\reverbMix, \delayMix, \shimmerMix,
					\quadX, \quadY,  // Phase 13: Spatial modulation targets
					nil,  // Separator
					\masterFilterFreq, \masterFilterMorph, \masterFilterRes,    // Phase 15: Master filter
					\masterFilterDecay, \masterFilterAnimate, \masterFilterMix  // Phase 15: Master filter
				];
				var targetIdx = targetMenu.value;
				if(targetIdx > 0 and: { targetIdx != 18 }, {  // Skip separator (index 18 now)
					var param = paramMap[targetIdx];
					var min = minNum.value;
					var max = maxNum.value;

					// Phase 15: Route to master bus if master parameter (index 19+)
					if(targetIdx >= 19, {
						trackManager.routeModulatorToMaster(trackNum, modNum, param, min, max);
					}, {
						trackManager.routeModulator(trackNum, modNum, param, min, max);
					});

					statusText.string_("Status: Routed to " ++ targetMenu.items[targetIdx])
						.stringColor_(Color.cyan);
				});
			});


		// Phase 15: Mini-scope waveform visualizer (80x40px)
		scopeView = UserView(parent, Rect(x + 245, yPos - 40, 80, 40))
			.background_(Color.black)
			.drawFunc_({ arg view;
				var w = view.bounds.width;
				var h = view.bounds.height;
				var midY = h / 2;
				var numPoints = 60;  // 60 points for waveform
				var rate = rateNum.value ? 1.0;
				var shape = shapeMenu.value ? 0;  // 0=Sine, 1=Tri, 2=Saw, 3=Sqr
				var time = Main.elapsedTime;
				
				// Draw grid lines
				Pen.strokeColor = Color.gray(0.3);
				Pen.width = 1;
				Pen.line(Point(0, midY), Point(w, midY));  // Center line
				Pen.stroke;
				
				// Draw waveform based on shape
				Pen.strokeColor = Color.cyan.alpha_(0.8);
				Pen.width = 1.5;
				
				numPoints.do({ arg i;
					var x1 = (i / numPoints) * w;
					var x2 = ((i + 1) / numPoints) * w;
					var phase1 = (i / numPoints) + (time * rate * 0.5);  // Animate based on rate
					var phase2 = ((i + 1) / numPoints) + (time * rate * 0.5);
					var val1, val2, y1, y2;
					
					// Calculate waveform value based on shape
					val1 = case
						{ shape == 0 } { (phase1 * 2pi).sin }  // Sine
						{ shape == 1 } { ((phase1 % 1) * 4 - 2).abs - 1 }  // Triangle
						{ shape == 2 } { ((phase1 % 1) * 2) - 1 }  // Sawtooth
						{ shape == 3 } { if((phase1 % 1) < 0.5, 1, -1) }  // Square
						{ 0 };  // Default
					
					val2 = case
						{ shape == 0 } { (phase2 * 2pi).sin }
						{ shape == 1 } { ((phase2 % 1) * 4 - 2).abs - 1 }
						{ shape == 2 } { ((phase2 % 1) * 2) - 1 }
						{ shape == 3 } { if((phase2 % 1) < 0.5, 1, -1) }
						{ 0 };

					y1 = midY - (val1 * midY * 0.8);
					y2 = midY - (val2 * midY * 0.8);
					
					Pen.line(Point(x1, y1), Point(x2, y2));
				});
				Pen.stroke;
			});
		
		// Animate scope at 15fps
		scopeUpdater = Routine({
			loop {
				{ scopeView.refresh }.defer;
				(1/15).wait;  // 15fps refresh
			};
		}).play(AppClock);

		yPos = yPos + 25;

		// Status display
		statusText = StaticText(parent, Rect(x + 10, yPos, 320, 18))
			.string_("Status: Inactive")
			.font_(Font("Monaco", 8))
			.stringColor_(Color.red);
	};

	// === PUBLIC API ===
	(
		create: {
			window = Window("Track " ++ (trackNum + 1) ++ " Modulation", Rect(100, 100, 700, 580))
				.background_(Color.gray(0.1))
				.onClose_({ "Modulation window closed".postln; });

			// Title
			StaticText(window, Rect(10, 10, 680, 30))
				.string_("TRACK " ++ (trackNum + 1) ++ " - MODULATION SYSTEM")
				.font_(Font("Monaco", 14, true))
				.stringColor_(Color.cyan)
				.align_(\center);

			// Create 4 modulator sections (2×2 grid)
			makeModulatorSection.value(window, 10, 50, 0);
			makeModulatorSection.value(window, 360, 50, 1);
			makeModulatorSection.value(window, 10, 320, 2);
			makeModulatorSection.value(window, 360, 320, 3);

			window.front;
		},

		close: {
			if(window.notNil, {
				window.close;
				window = nil;
			});
		}
	);
};

"✓ Modulation window module loaded".postln;
