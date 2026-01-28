// ============================================
// BEARULATOR - 48-BAND MORPHING RESONATOR v2
// Torso S-4 Style Filter Bank + Advanced DSP
// ============================================
//
// MACRO KNOBS:
//   - Freq: Fundamental frequency (20-1000 Hz)
//   - Morph: Harmonic stretch (0.5=compressed, 1.0=harmonic, 2.5=metallic)
//   - Damp: Amplitude tilt (0=lowpass, 1=flat, 2=highpass)
//   - Decay: Ring time scaling (0.1-4.0 seconds)
//
// TOGGLES:
//   - Quantize: Snap frequencies to D Minor scale
//   - Split L/R: Odd bands left, even bands right (massive stereo)
//   - Feedback: Karplus-Strong style howling resonance
//
// Math:
//   Freq[i] = BaseFreq * ((i + 1) ** Morph)
//   Quantized: Snap to nearest Scale.minor degree

(
fork {
	var numBands = 48;
	var synth, window;
	var freqKnob, morphKnob, dampKnob, decayKnob, feedbackKnob;
	var multiSlider;
	var btnQuantize, btnSplit, btnFeedback;
	var currentFreqs, currentAmpsL, currentAmpsR, currentRings;
	var isQuantized = false, isSplit = false;
	var updateArrays, updateSynth, updateVisualizer;

	// D Minor scale frequencies for quantization
	var dMinorRatios = [1, 9/8, 6/5, 4/3, 3/2, 8/5, 9/5];  // D E F G A Bb C

	// ========================================
	// SYNTHDEF: 48-Band DynKlank with Feedback
	// ========================================
	SynthDef(\resonator48v2, { |out = 0, amp = 0.5, gate = 1, fbAmt = 0.0|
		var input, sigL, sigR, sig, env, feedback;
		var freqs = \freqs.kr(Array.fill(numBands, { |i| 100 * (i + 1) }));
		var ampsL = \ampsL.kr(Array.fill(numBands, { |i| 1 / (i + 1) }));
		var ampsR = \ampsR.kr(Array.fill(numBands, { |i| 1 / (i + 1) }));
		var rings = \rings.kr(Array.fill(numBands, { 1.0 }));

		// Feedback loop input (Karplus-Strong style)
		feedback = LocalIn.ar(2) * fbAmt;

		// Test input: Pink noise burst + feedback
		input = (PinkNoise.ar * Decay.ar(Impulse.ar(1), 0.1) * 0.3) + feedback[0];

		// Two DynKlank banks: Left (odd bands) and Right (even bands)
		sigL = DynKlank.ar(`[freqs, ampsL, rings], input);
		sigR = DynKlank.ar(`[freqs, ampsR, rings], input);

		// Feedback send (before limiting for natural decay)
		LocalOut.ar([sigL, sigR] * 0.3);

		// SAFETY: Hard limit output - feedback can explode!
		sigL = (sigL * 0.1).tanh * 2;
		sigR = (sigR * 0.1).tanh * 2;
		sig = [sigL, sigR];
		sig = Limiter.ar(sig, 0.9);

		env = EnvGen.kr(Env.asr(0.01, 1, 0.1), gate, doneAction: 2);
		Out.ar(out, sig * amp * env);
	}).add;

	s.sync;

	// ========================================
	// ARRAY CALCULATION WITH QUANTIZE + SPLIT
	// ========================================
	updateArrays = { |baseFreq = 100, morph = 1.0, decayTime = 1.0|
		var nyquist = s.sampleRate * 0.5;
		var baseAmps;

		// FREQUENCIES: Freq[i] = BaseFreq * ((i + 1) ** Morph)
		currentFreqs = Array.fill(numBands, { |i|
			var freq = baseFreq * ((i + 1) ** morph);

			// QUANTIZE: Snap to nearest D Minor pitch
			if(isQuantized, {
				var octave = (freq / baseFreq).log2.floor;
				var ratio = freq / (baseFreq * (2 ** octave));
				var nearestRatio = dMinorRatios.minItem({ |r| (r - ratio).abs });
				freq = baseFreq * (2 ** octave) * nearestRatio;
			});

			freq.clip(20, nyquist - 100);
		});

		// BASE AMPLITUDES: Get directly from the interactive MultiSliderView
		baseAmps = multiSlider.value;

		// Normalize
		baseAmps = baseAmps.normalizeSum * numBands * 0.5;

		// STEREO SPLIT: Odd bands left, even bands right
		if(isSplit, {
			currentAmpsL = Array.fill(numBands, { |i|
				if(i.odd, { baseAmps[i] }, { 0.0 });  // Odd indices to Left
			});
			currentAmpsR = Array.fill(numBands, { |i|
				if(i.even, { baseAmps[i] }, { 0.0 });  // Even indices to Right
			});
		}, {
			currentAmpsL = baseAmps;
			currentAmpsR = baseAmps;
		});

		// RING TIMES: Higher partials decay faster
		currentRings = Array.fill(numBands, { |i|
			var normalized = i / (numBands - 1);
			(decayTime * (1 - (normalized * 0.7))).clip(0.05, 10);
		});

		nil;
	};

	updateSynth = {
		if(synth.notNil, {
			synth.setn(\freqs, currentFreqs);
			synth.setn(\ampsL, currentAmpsL);
			synth.setn(\ampsR, currentAmpsR);
			synth.setn(\rings, currentRings);
		});
		nil;
	};

	// ========================================
	// GUI
	// ========================================
	{
		var knobWidth = 70, knobHeight = 90;
		var sliderHeight = 120;
		var margin = 10;
		var btnY, knobY;

		// Color scheme
		var colors = (
			bg: Color.gray(0.12),
			fg: Color.white,
			accent: Color(0.2, 0.7, 1.0),      // Cyan accent
			bars: Color(0.3, 0.85, 0.6),       // Green bars
			btnOff: Color.gray(0.25),
			btnOn: Color(0.0, 0.8, 0.9),       // Bright cyan
			btnTextOff: Color.white,
			btnTextOn: Color.black
		);

		// Flat button factory
		var makeToggle = { |parent, rect, label, action|
			Button(parent, rect)
				.states_([
					[label, colors.btnTextOff, colors.btnOff],
					[label, colors.btnTextOn, colors.btnOn]
				])
				.font_(Font("Helvetica Bold", 10))
				.action_(action);
		};

		window = Window("48-Band Resonator", Rect(100, 100, 380, 400))
			.background_(colors.bg);

		// Title
		StaticText(window, Rect(margin, 8, 360, 22))
			.string_("48-BAND MORPHING RESONATOR")
			.font_(Font("Helvetica Bold", 14))
			.stringColor_(colors.fg)
			.align_(\center);

		// MultiSlider Visualizer
		multiSlider = MultiSliderView(window, Rect(margin, 35, 360, sliderHeight))
			.size_(numBands)
			.elasticMode_(1)
			.indexThumbSize_(360 / numBands)
			.valueThumbSize_(2)
			.background_(Color.gray(0.18))
			.strokeColor_(colors.bars)
			.fillColor_(colors.bars.alpha_(0.6))
			.enabled_(true) // <-- ENABLED FOR GUI CONTROL
			.action_({
				updateArrays.value(freqKnob.value, morphKnob.value, decayKnob.value);
				updateSynth.value;
			});

		// === TOGGLE BUTTONS ROW ===
		btnY = 165;

		StaticText(window, Rect(margin, btnY, 60, 18))
			.string_("MODE")
			.font_(Font("Helvetica", 10))
			.stringColor_(colors.fg.alpha_(0.6));

		btnQuantize = makeToggle.(window, Rect(margin + 65, btnY, 80, 22), "Quantize", { |b|
			isQuantized = b.value.asBoolean;
			updateArrays.value(freqKnob.value, morphKnob.value, decayKnob.value);
			updateSynth.value;
		});

		btnSplit = makeToggle.(window, Rect(margin + 150, btnY, 80, 22), "Split L/R", { |b|
			isSplit = b.value.asBoolean;
			updateArrays.value(freqKnob.value, morphKnob.value, decayKnob.value);
			updateSynth.value;
		});

		btnFeedback = makeToggle.(window, Rect(margin + 235, btnY, 80, 22), "Feedback", { |b|
			// Use knob value when ON, 0 when OFF
			var fbVal = if(b.value == 1, { feedbackKnob.value }, { 0.0 });
			if(synth.notNil, { synth.set(\fbAmt, fbVal) });
		});

		// === KNOB ROW ===
		knobY = 200;

		StaticText(window, Rect(margin, knobY, 360, 18))
			.string_("MACRO CONTROLS")
			.font_(Font("Helvetica", 10))
			.stringColor_(colors.fg.alpha_(0.6));

		knobY = knobY + 22;

		// FREQ Knob
		freqKnob = EZKnob(window, Rect(margin, knobY, knobWidth, knobHeight),
			"Freq",
			ControlSpec(20, 1000, \exp, 1, 100, " Hz"),
			{ |ez|
				updateArrays.value(ez.value, morphKnob.value, decayKnob.value);
				updateSynth.value;
			},
			100, layout: \vert2
		);
		freqKnob.knobView.color_([colors.accent, colors.fg, colors.fg.alpha_(0.5), colors.accent]);

		// MORPH Knob
		morphKnob = EZKnob(window, Rect(margin + 75, knobY, knobWidth, knobHeight),
			"Morph",
			ControlSpec(0.5, 2.5, \lin, 0.01, 1.0),
			{ |ez|
				updateArrays.value(freqKnob.value, ez.value, decayKnob.value);
				updateSynth.value;
			},
			1.0, layout: \vert2
		);
		morphKnob.knobView.color_([colors.accent, colors.fg, colors.fg.alpha_(0.5), colors.accent]);

		// DECAY Knob
		decayKnob = EZKnob(window, Rect(margin + 150, knobY, knobWidth, knobHeight),
			"Decay",
			ControlSpec(0.1, 4.0, \exp, 0.01, 1.0, " s"),
			{ |ez|
				updateArrays.value(freqKnob.value, morphKnob.value, ez.value);
				updateSynth.value;
			},
			1.0, layout: \vert2
		);
		decayKnob.knobView.color_([colors.accent, colors.fg, colors.fg.alpha_(0.5), colors.accent]);

		// FEEDBACK Amount Knob (only active when button is ON)
		feedbackKnob = EZKnob(window, Rect(margin + 225, knobY, knobWidth, knobHeight),
			"FB Amt",
			ControlSpec(0, 0.95, \lin, 0.01, 0.4),
			{ |ez|
				// Only send to synth if feedback button is ON
				if(btnFeedback.value == 1, {
					if(synth.notNil, { synth.set(\fbAmt, ez.value) });
				});
			},
			0.4, layout: \vert2
		);
		feedbackKnob.knobView.color_([colors.accent, colors.fg, colors.fg.alpha_(0.5), colors.accent]);

		// Info text
		StaticText(window, Rect(margin, 370, 360, 20))
			.string_("Morph: 0.5=cluster | 1.0=harmonic | 2.5=metallic")
			.font_(Font("Helvetica", 9))
			.stringColor_(colors.fg.alpha_(0.4))
			.align_(\center);

		// Initialize
		// Set initial slider values to a flat state
		multiSlider.value_(Array.fill(numBands, 1.0));
		updateArrays.value(100, 1.0, 1.0);

		// Create synth
		synth = Synth(\resonator48v2);
		updateSynth.value;

		// Cleanup
		window.onClose_({
			if(synth.notNil, { synth.release });
			synth = nil;
			"Resonator closed.".postln;
		});

		window.front;

		"".postln;
		"═══════════════════════════════════════════".postln;
		"  48-BAND RESONATOR v2 LOADED".postln;
		"═══════════════════════════════════════════".postln;
		"  KNOBS: Freq, Morph, Damp, Decay, FB Amt".postln;
		"  TOGGLES: Quantize (D Minor), Split L/R, Feedback".postln;
		"═══════════════════════════════════════════".postln;

	}.defer;
};
)
