/*
BEARULATOR: Modulation Tab GUI
Phase 5 - Modulation Control Interface

Per-track modulation control:
- 4 modulators per track
- Type selector (LFO, EnvFollow, Random, Envelope)
- Rate/frequency control
- Depth control
- Shape/waveform selector
- Target parameter routing
- Min/max range controls
*/

~s4ModulationTab = { arg trackManager, server, trackNum;
	var makeModulatorSection;

	// === HELPER: Create modulator controls ===
	makeModulatorSection = { arg parent, x, y, modNum;
		var yPos = y;
		var typeMenu, rateSlider, rateNum, depthSlider, depthNum;
		var shapeMenu, targetMenu, minNum, maxNum;
		var enableButton;

		// Section label
		StaticText(parent, Rect(x, yPos, 150, 20))
			.string_("MODULATOR " ++ (modNum + 1))
			.font_(Font("Monaco", 10, true))
			.stringColor_(Color.cyan(0.7));
		yPos = yPos + 25;

		// Enable/Disable button
		enableButton = Button(parent, Rect(x, yPos, 60, 25))
			.states_([
				["OFF", Color.white, Color.gray(0.3)],
				["ON", Color.black, Color.green(0.7)]
			])
			.action_({ arg btn;
				if(btn.value == 1, {
					var type = typeMenu.value;
					var rate = rateNum.value;
					var depth = depthNum.value;
					var shape = shapeMenu.value;

					trackManager.createModulator(trackNum, modNum, type, rate, depth, shape);
				}, {
					trackManager.freeModulator(trackNum, modNum);
				});
			});

		// Type selector
		StaticText(parent, Rect(x + 70, yPos, 40, 20))
			.string_("Type")
			.font_(Font("Monaco", 9));
		typeMenu = PopUpMenu(parent, Rect(x + 115, yPos, 100, 20))
			.items_(["LFO", "Env Follow", "Random", "Envelope"])
			.value_(0);
		yPos = yPos + 25;

		// Rate control
		StaticText(parent, Rect(x, yPos, 80, 18))
			.string_("Rate (Hz)")
			.font_(Font("Monaco", 9));
		rateSlider = Slider(parent, Rect(x + 85, yPos, 80, 18))
			.value_(0.2)
			.action_({ arg sl;
				var val = ControlSpec(0.01, 20, \exp).map(sl.value);
				rateNum.value_(val);
				trackManager.setModParam(trackNum, modNum, \freq, val);
			});
		rateNum = NumberBox(parent, Rect(x + 170, yPos, 50, 18))
			.value_(1.0)
			.decimals_(3)
			.font_(Font("Monaco", 9))
			.action_({ arg nb;
				rateSlider.value_(ControlSpec(0.01, 20, \exp).unmap(nb.value));
				trackManager.setModParam(trackNum, modNum, \freq, nb.value);
			});
		yPos = yPos + 22;

		// Depth control
		StaticText(parent, Rect(x, yPos, 80, 18))
			.string_("Depth")
			.font_(Font("Monaco", 9));
		depthSlider = Slider(parent, Rect(x + 85, yPos, 80, 18))
			.value_(1.0)
			.action_({ arg sl;
				depthNum.value_(sl.value);
				trackManager.setModParam(trackNum, modNum, \amp, sl.value);
			});
		depthNum = NumberBox(parent, Rect(x + 170, yPos, 50, 18))
			.value_(1.0)
			.decimals_(3)
			.font_(Font("Monaco", 9))
			.action_({ arg nb;
				depthSlider.value_(nb.value);
				trackManager.setModParam(trackNum, modNum, \amp, nb.value);
			});
		yPos = yPos + 22;

		// Shape/Waveform selector
		StaticText(parent, Rect(x, yPos, 80, 18))
			.string_("Shape")
			.font_(Font("Monaco", 9));
		shapeMenu = PopUpMenu(parent, Rect(x + 85, yPos, 135, 18))
			.items_(["Sine", "Triangle", "Saw", "Square", "Smooth Rnd", "Step Rnd"])
			.value_(0)
			.action_({ arg menu;
				trackManager.setModParam(trackNum, modNum, \waveform, menu.value);
			});
		yPos = yPos + 22;

		// Target parameter selector
		StaticText(parent, Rect(x, yPos, 80, 18))
			.string_("Target")
			.font_(Font("Monaco", 9));
		targetMenu = PopUpMenu(parent, Rect(x + 85, yPos, 135, 18))
			.items_([
				"None",
				"Grain Size",
				"Density",
				"Position",
				"Pitch",
				"Pos Jitter",
				"Pitch Jitter",
				"Stereo Spread",
				"Filter Freq",
				"Filter Morph",
				"Reverb Mix",
				"Delay Mix"
			])
			.value_(0);
		yPos = yPos + 22;

		// Min/Max range
		StaticText(parent, Rect(x, yPos, 30, 18))
			.string_("Min")
			.font_(Font("Monaco", 9));
		minNum = NumberBox(parent, Rect(x + 35, yPos, 50, 18))
			.value_(0.0)
			.decimals_(3)
			.font_(Font("Monaco", 9));

		StaticText(parent, Rect(x + 95, yPos, 30, 18))
			.string_("Max")
			.font_(Font("Monaco", 9));
		maxNum = NumberBox(parent, Rect(x + 130, yPos, 50, 18))
			.value_(1.0)
			.decimals_(3)
			.font_(Font("Monaco", 9));

		Button(parent, Rect(x + 190, yPos, 30, 18))
			.states_([["Set", Color.black, Color.cyan(0.6)]])
			.action_({
				var paramMap = [
					nil,
					\grainSize,
					\density,
					\position,
					\pitch,
					\posJitter,
					\pitchJitter,
					\stereoSpread,
					\filterFreq,
					\filterMorph,
					\reverbMix,
					\delayMix
				];
				var targetIdx = targetMenu.value;
				if(targetIdx > 0, {
					var param = paramMap[targetIdx];
					var min = minNum.value;
					var max = maxNum.value;
					trackManager.routeModulator(trackNum, modNum, param, min, max);
				});
			});

		yPos;
	};

	// === PUBLIC API ===
	(
		create: { arg self, parent;
			var yPos = 10;
			var col1X = 10;
			var col2X = 370;
			var col3X = 730;
			var col4X = 1090;

			StaticText(parent, Rect(10, yPos, 500, 25))
				.string_("MODULATION - TRACK " ++ (trackNum + 1))
				.font_(Font("Monaco", 14, true))
				.stringColor_(Color.cyan);
			yPos = yPos + 35;

			// Create 4 modulator sections (2 columns × 2 rows)
			makeModulatorSection.value(parent, col1X, yPos, 0);
			makeModulatorSection.value(parent, col2X, yPos, 1);
			makeModulatorSection.value(parent, col1X, yPos + 200, 2);
			makeModulatorSection.value(parent, col2X, yPos + 200, 3);

			// Instructions
			StaticText(parent, Rect(10, 450, 700, 100))
				.string_("MODULATION INSTRUCTIONS:\n" ++
					"1. Click ON to enable modulator\n" ++
					"2. Select Type (LFO, Env Follow, Random, Envelope)\n" ++
					"3. Adjust Rate and Depth\n" ++
					"4. Choose Shape/Waveform\n" ++
					"5. Select Target parameter\n" ++
					"6. Set Min/Max range and click 'Set' to route")
				.font_(Font("Monaco", 10))
				.stringColor_(Color.gray(0.7));
		}
	);
};

"✓ Modulation tab module loaded".postln;
