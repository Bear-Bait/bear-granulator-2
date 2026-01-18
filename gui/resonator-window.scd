// ============================================
// BEARULATOR - RESONATOR WINDOW
// Popup GUI for 48-Band Morphing Resonator
// Works for Master Bus or Per-Track
// ============================================

(
~resonatorWindow = (
	windows: Dictionary.new,
	numBands: 48,

	// Open a resonator window for given target
	open: { |self, targetId, targetName = "Resonator"|
		var window, multiSlider;
		var freqKnob, morphKnob, dampKnob, decayKnob, feedbackKnob, mixKnob;
		var btnQuantize, btnSplit, btnFeedback, btnOn;
		var state, updateVisualizer;
		var knobWidth = 60, knobHeight = 80;
		var margin = 10;
		var colors, makeToggle;  // Declare here at top

		// Color scheme (must be defined before use, but declared at top)
		colors = (
			bg: Color.gray(0.12),
			fg: Color.white,
			accent: Color(0.2, 0.7, 1.0),
			bars: Color(0.3, 0.85, 0.6),
			btnOff: Color.gray(0.25),
			btnOn: Color(0.0, 0.8, 0.9),
			btnTextOff: Color.white,
			btnTextOn: Color.black
		);

		// Flat button factory
		makeToggle = { |parent, rect, label, initVal, action|
			Button(parent, rect)
				.states_([
					[label, colors.btnTextOff, colors.btnOff],
					[label, colors.btnTextOn, colors.btnOn]
				])
				.value_(initVal)
				.font_(Font("Helvetica Bold", 10))
				.action_(action);
		};

		// Check if window already open
		if(self.windows[targetId].notNil and: { self.windows[targetId].isClosed.not }, {
			self.windows[targetId].front;
			^self.windows[targetId];
		});

		// Get resonator state
		state = ~resonatorManager.getState(targetId);
		if(state.isNil, {
			("No resonator instance for '" ++ targetId ++ "'").warn;
			^nil;
		});

		// Update visualizer
		updateVisualizer = {
			{
				if(multiSlider.notNil and: { window.notNil and: { window.isClosed.not }}, {
					var displayAmps;
					state = ~resonatorManager.getState(targetId);
					if(state.notNil, {
						displayAmps = (state[\ampsL] + state[\ampsR]);
						displayAmps = displayAmps / displayAmps.maxItem.max(0.001);
						multiSlider.value_(displayAmps);
					});
				});
			}.defer;
		};

		// Create window
		window = Window(targetName ++ " - 48-Band Resonator", Rect(150, 150, 420, 380))
			.background_(colors.bg);

		// Title
		StaticText(window, Rect(margin, 8, 400, 22))
			.string_(targetName.asString.toUpper ++ " RESONATOR")
			.font_(Font("Helvetica Bold", 14))
			.stringColor_(colors.fg)
			.align_(\center);

		// MultiSlider Visualizer
		multiSlider = MultiSliderView(window, Rect(margin, 35, 400, 100))
			.size_(self.numBands)
			.elasticMode_(1)
			.indexThumbSize_(400 / self.numBands)
			.valueThumbSize_(2)
			.background_(Color.gray(0.18))
			.strokeColor_(colors.bars)
			.fillColor_(colors.bars.alpha_(0.6))
			.enabled_(false);

		// === TOGGLE BUTTONS ROW ===
		StaticText(window, Rect(margin, 145, 60, 18))
			.string_("MODE")
			.font_(Font("Helvetica", 10))
			.stringColor_(colors.fg.alpha_(0.6));

		btnOn = makeToggle.(window, Rect(margin + 50, 145, 50, 22), "ON",
			state[\on], { |b|
				~resonatorManager.setParam(targetId, \on, b.value);
			});

		btnQuantize = makeToggle.(window, Rect(margin + 105, 145, 80, 22), "Quantize",
			state[\quantize].asInteger, { |b|
				~resonatorManager.setParam(targetId, \quantize, b.value.asBoolean);
				updateVisualizer.();
			});

		btnSplit = makeToggle.(window, Rect(margin + 190, 145, 80, 22), "Split L/R",
			state[\split].asInteger, { |b|
				~resonatorManager.setParam(targetId, \split, b.value.asBoolean);
				updateVisualizer.();
			});

		btnFeedback = makeToggle.(window, Rect(margin + 275, 145, 80, 22), "Feedback",
			if(state[\feedback] > 0.05, 1, 0), { |b|
				var fbVal = if(b.value == 1, { 0.4 }, { 0.0 });
				~resonatorManager.setParam(targetId, \feedback, fbVal);
				feedbackKnob.value_(fbVal);
			});

		// === KNOB ROW ===
		StaticText(window, Rect(margin, 175, 400, 18))
			.string_("MACRO CONTROLS")
			.font_(Font("Helvetica", 10))
			.stringColor_(colors.fg.alpha_(0.6));

		// FREQ Knob
		freqKnob = EZKnob(window, Rect(margin, 195, knobWidth, knobHeight),
			"Freq",
			ControlSpec(20, 1000, \exp, 1, 100, " Hz"),
			{ |ez|
				~resonatorManager.setParam(targetId, \freq, ez.value);
				updateVisualizer.();
			},
			state[\freq], layout: \vert2
		);
		freqKnob.knobView.color_([colors.accent, colors.fg, colors.fg.alpha_(0.5), colors.accent]);

		// MORPH Knob
		morphKnob = EZKnob(window, Rect(margin + 65, 195, knobWidth, knobHeight),
			"Morph",
			ControlSpec(0.5, 2.5, \lin, 0.01, 1.0),
			{ |ez|
				~resonatorManager.setParam(targetId, \morph, ez.value);
				updateVisualizer.();
			},
			state[\morph], layout: \vert2
		);
		morphKnob.knobView.color_([colors.accent, colors.fg, colors.fg.alpha_(0.5), colors.accent]);

		// DAMP Knob
		dampKnob = EZKnob(window, Rect(margin + 130, 195, knobWidth, knobHeight),
			"Damp",
			ControlSpec(0.0, 2.0, \lin, 0.01, 1.0),
			{ |ez|
				~resonatorManager.setParam(targetId, \damp, ez.value);
				updateVisualizer.();
			},
			state[\damp], layout: \vert2
		);
		dampKnob.knobView.color_([colors.accent, colors.fg, colors.fg.alpha_(0.5), colors.accent]);

		// DECAY Knob
		decayKnob = EZKnob(window, Rect(margin + 195, 195, knobWidth, knobHeight),
			"Decay",
			ControlSpec(0.1, 4.0, \exp, 0.01, 1.0, " s"),
			{ |ez|
				~resonatorManager.setParam(targetId, \decay, ez.value);
				updateVisualizer.();
			},
			state[\decay], layout: \vert2
		);
		decayKnob.knobView.color_([colors.accent, colors.fg, colors.fg.alpha_(0.5), colors.accent]);

		// FEEDBACK Knob
		feedbackKnob = EZKnob(window, Rect(margin + 260, 195, knobWidth, knobHeight),
			"FB Amt",
			ControlSpec(0, 0.95, \lin, 0.01, 0),
			{ |ez|
				~resonatorManager.setParam(targetId, \feedback, ez.value);
				btnFeedback.value_(if(ez.value > 0.05, 1, 0));
			},
			state[\feedback], layout: \vert2
		);
		feedbackKnob.knobView.color_([colors.accent, colors.fg, colors.fg.alpha_(0.5), colors.accent]);

		// MIX Knob
		mixKnob = EZKnob(window, Rect(margin + 325, 195, knobWidth, knobHeight),
			"Mix",
			ControlSpec(0, 1, \lin, 0.01, 0.5),
			{ |ez|
				~resonatorManager.setParam(targetId, \mix, ez.value);
			},
			state[\mix], layout: \vert2
		);
		mixKnob.knobView.color_([colors.accent, colors.fg, colors.fg.alpha_(0.5), colors.accent]);

		// Info text
		StaticText(window, Rect(margin, 290, 400, 40))
			.string_("Morph: 0.5=cluster | 1.0=harmonic | 2.5=metallic\nDamp: 0=bass | 1=flat | 2=treble")
			.font_(Font("Helvetica", 9))
			.stringColor_(colors.fg.alpha_(0.4))
			.align_(\center);

		// Modulation targets info
		StaticText(window, Rect(margin, 330, 400, 40))
			.string_("Modulation Targets: resFreq, resMorph, resDamp, resDecay, resFeedback, resMix")
			.font_(Font("Helvetica", 9))
			.stringColor_(colors.accent.alpha_(0.6))
			.align_(\center);

		// Initial visualizer update
		updateVisualizer.();

		// Store and show
		self.windows[targetId] = window;
		window.onClose_({
			self.windows.removeAt(targetId);
		});
		window.front;

		window;
	},

	// Close a specific window
	close: { |self, targetId|
		if(self.windows[targetId].notNil, {
			self.windows[targetId].close;
			self.windows.removeAt(targetId);
		});
	},

	// Close all windows
	closeAll: { |self|
		self.windows.do(_.close);
		self.windows.clear;
	}
);

"✓ Resonator Window module loaded".postln;
"  Open: ~resonatorWindow.open(\\master, \"Master\")".postln;
"  Open: ~resonatorWindow.open(\\track1, \"Track 1\")".postln;
)
