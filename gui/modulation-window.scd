/*
S-4 Rival: Modulation Window
Phase 5 - Per-Track Modulation Control

Opens a dedicated window for modulation control of a single track
- 4 modulators with full controls
- Parameter routing matrix
- Real-time visualization (future)
*/

~s4ModulationWindow = { arg trackManager, server, trackNum;
	var window, makeModulatorSection;

	// === HELPER: Create modulator controls ===
	makeModulatorSection = { arg parent, x, y, modNum;
		var yPos = y;
		var typeMenu, rateSlider, rateNum, depthSlider, depthNum;
		var shapeMenu, targetMenu, minNum, maxNum;
		var enableButton, statusText;

		// Section box
		CompositeView(parent, Rect(x, y, 340, 220))
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

		// Shape/Waveform selector
		StaticText(parent, Rect(x + 185, yPos, 45, 20))
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
				"Filt Freq",
				"Filt Morph",
				"Rev Mix",
				"Del Mix"
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
					\filterFreq, \filterMorph, \reverbMix, \delayMix
				];
				var targetIdx = targetMenu.value;
				if(targetIdx > 0, {
					var param = paramMap[targetIdx];
					var min = minNum.value;
					var max = maxNum.value;
					trackManager.routeModulator(trackNum, modNum, param, min, max);
					statusText.string_("Status: Routed to " ++ targetMenu.items[targetIdx])
						.stringColor_(Color.cyan);
				});
			});

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
			window = Window("Track " ++ (trackNum + 1) ++ " Modulation", Rect(100, 100, 700, 480))
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
			makeModulatorSection.value(window, 10, 280, 2);
			makeModulatorSection.value(window, 360, 280, 3);

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
