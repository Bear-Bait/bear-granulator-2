/*
S-4 Rival: Basic GUI Controls
Phase 1 - Simple control interface for grain engine
Phase 2 - Filter controls added

Features:
- Grain size, density, position controls
- Pitch and jitter controls
- Envelope type selector
- Stereo spread
- Record controls
- 48-band morphing resonator controls
- Filter enable/bypass
- Harmonic/inharmonic tuning
*/

(
~s4BasicGUI = {
	arg grainSynth, recorder, server;
	var window, controlLayout, scrollView;
	var grainSizeSlider, densitySlider, positionSlider, pitchSlider;
	var posJitterSlider, pitchJitterSlider, spreadSlider, ampSlider;
	var envTypeMenu, recordButton, clearButton, stopRecButton, recIndicator;
	var specs, publicAPI;

	// Control specifications
	specs = (
		grainSize: ControlSpec(0.01, 0.5, \exp, 0.001, 0.1, "s"),
		density: ControlSpec(1, 200, \exp, 0.1, 30, "grains/s"),
		position: ControlSpec(0, 1, \lin, 0.001, 0.5, ""),
		pitch: ControlSpec(-24, 24, \lin, 0.1, 0, "semi"),
		posJitter: ControlSpec(0, 1, \lin, 0.01, 0.1, ""),
		pitchJitter: ControlSpec(0, 12, \lin, 0.1, 0, "semi"),
		spread: ControlSpec(0, 1, \lin, 0.01, 0.5, ""),
		amp: ControlSpec(0, 1, \lin, 0.01, 0.5, ""),
		// Filter specs (Phase 2)
		filterFreq: ControlSpec(20, 2000, \exp, 1, 200, "Hz"),
		filterMorph: ControlSpec(0, 1, \lin, 0.01, 0.5, ""),
		filterRes: ControlSpec(0, 1, \lin, 0.01, 0.5, ""),
		filterDecay: ControlSpec(0, 1, \lin, 0.01, 0.5, ""),
		filterAnimate: ControlSpec(0, 1, \lin, 0.01, 0, ""),
		filterAnimRate: ControlSpec(0.01, 10, \exp, 0.01, 0.5, "Hz"),
		filterSpread: ControlSpec(1.0, 2.0, \lin, 0.01, 1.5, ""),
		filterMix: ControlSpec(0, 1, \lin, 0.01, 0.5, ""),
		// Color effects specs (Phase 3)
		distCrossover: ControlSpec(100, 2000, \exp, 1, 500, "Hz"),
		distLoDrive: ControlSpec(1, 20, \lin, 0.1, 1, ""),
		distHiDrive: ControlSpec(1, 20, \lin, 0.1, 1, ""),
		distMix: ControlSpec(0, 1, \lin, 0.01, 0, ""),
		crushRate: ControlSpec(100, 48000, \exp, 1, 48000, "Hz"),
		crushBits: ControlSpec(1, 16, \lin, 1, 16, "bits"),
		crushMix: ControlSpec(0, 1, \lin, 0.01, 0, ""),
		compThresh: ControlSpec(0.01, 1, \lin, 0.01, 0.5, ""),
		compRatio: ControlSpec(1, 20, \lin, 0.1, 4, ":1"),
		noiseAmount: ControlSpec(0, 0.5, \lin, 0.01, 0, ""),
		// Space effects specs (Phase 3)
		reverbSize: ControlSpec(0, 1, \lin, 0.01, 0.5, ""),
		reverbDamp: ControlSpec(0, 1, \lin, 0.01, 0.5, ""),
		reverbMix: ControlSpec(0, 1, \lin, 0.01, 0.3, ""),
		delayTime: ControlSpec(0.01, 2.0, \exp, 0.01, 0.25, "s"),
		delayFeedback: ControlSpec(0, 0.95, \lin, 0.01, 0.5, ""),
		delayFilter: ControlSpec(200, 10000, \exp, 1, 5000, "Hz"),
		delayMix: ControlSpec(0, 1, \lin, 0.01, 0.3, ""),
		shimmerTime: ControlSpec(0.1, 2.0, \exp, 0.01, 0.5, "s"),
		shimmerFeedback: ControlSpec(0, 0.9, \lin, 0.01, 0.6, ""),
		shimmerPitch: ControlSpec(0, 24, \lin, 1, 12, "semi"),
		shimmerMix: ControlSpec(0, 1, \lin, 0.01, 0, "")
	);

	publicAPI = (
		window: nil,
		synth: grainSynth,
		recorder: recorder,

		/*
		Function: create
		Purpose: Build and display GUI window
		*/
		create: {
			arg self;

			// Create main window (600px height to fit most screens)
			window = Window("S-4 Rival v0.3.001", Rect(100, 100, 520, 600))
				.front
				.onClose_({
					"GUI closed.".postln;
				})
				.alwaysOnTop_(true);

			// Scrollable view for all controls
			scrollView = ScrollView(window, Rect(0, 0, 520, 600))
				.hasBorder_(true)
				.hasVerticalScroller_(true)
				.hasHorizontalScroller_(false)
				.autohidesScrollers_(false)  // Always show scrollbar
				.background_(Color.gray(0.15))
				.canFocus_(true);

			// Content view - much taller than window to enable scrolling
			controlLayout = View(scrollView, Rect(0, 0, 480, 2000));
			scrollView.canvas_(controlLayout);
			controlLayout.decorator = FlowLayout(controlLayout.bounds, 10@10, 10@10);

			// Title
			StaticText(controlLayout, 460@30)
				.string_("S-4 RIVAL v0.3.001 - PHASE 3")
				.align_(\center)
				.font_(Font("Monaco", 14, true));

			controlLayout.decorator.nextLine;

			// === RECORDING SECTION ===
			StaticText(controlLayout, 460@20)
				.string_("RECORDING")
				.align_(\left)
				.font_(Font("Monaco", 12, true));

			controlLayout.decorator.nextLine;

			// Input channel selector
			StaticText(controlLayout, 120@20)
				.string_("Input Channel")
				.align_(\left);

			PopUpMenu(controlLayout, 180@25)
				.items_(["In 1 (L)", "In 2 (R)", "In 3", "In 4", "In 5", "In 6", "In 7", "In 8"])
				.value_(2) // default to input 3
				.action_({ arg menu;
					// Store selected input for next recording
					~selectedInput = menu.value;
					"Input channel set to: %".format(menu.value + 1).postln;
				});

			controlLayout.decorator.nextLine;

			// Record button
			recordButton = Button(controlLayout, 150@30)
				.states_([
					["Start Recording", Color.black, Color.green(0.7)],
					["Stop Recording", Color.white, Color.red(0.7)]
				])
				.action_({ arg btn;
					if(btn.value == 1, {
						var inputChan = if(~selectedInput.notNil, ~selectedInput, 2);
						recorder.startRecording(inputChan, overdub: false);
						// Light up recording indicator
						{ recIndicator.stringColor_(Color.red); }.defer;
					}, {
						recorder.stopRecording;
						// Dim recording indicator
						{ recIndicator.stringColor_(Color.gray(0.3)); }.defer;
					});
				});

			// Clear button
			clearButton = Button(controlLayout, 150@30)
				.states_([
					["Clear Buffer", Color.black, Color.gray(0.7)]
				])
				.action_({
					recorder.clear;
				});

			controlLayout.decorator.nextLine;

			// Load Test Sound button
			Button(controlLayout, 150@30)
				.states_([
					["Load Test Sound", Color.black, Color.cyan(0.7)]
				])
				.action_({
					fork {
						var tempBuf;
						"Generating test waveform...".postln;
						tempBuf = Buffer.alloc(server, server.sampleRate * 4, 1);
						tempBuf.sine1([1.0, 0.5, 0.3, 0.2, 0.15, 0.1, 0.08, 0.05], true, true, true);
						0.2.wait;
						tempBuf.copyData(recorder.buffer);
						0.2.wait;
						tempBuf.free;
						"✓ Test waveform loaded!".postln;
					};
				});

			// Recording indicator
			recIndicator = StaticText(controlLayout, 150@30)
				.string_("● REC")
				.align_(\center)
				.font_(Font("Monaco", 16, true))
				.stringColor_(Color.gray(0.3))
				.background_(Color.gray(0.1));

			controlLayout.decorator.nextLine;
			controlLayout.decorator.nextLine;

			// === GRAIN PARAMETERS ===
			StaticText(controlLayout, 460@20)
				.string_("GRAIN PARAMETERS")
				.align_(\left)
				.font_(Font("Monaco", 12, true));

			controlLayout.decorator.nextLine;

			// Helper function to create labeled slider
			~makeSlider = { arg parent, label, spec, param, default;
				var slider, numberBox, labelView;

				// Label
				labelView = StaticText(parent, 120@20)
					.string_(label)
					.align_(\left);

				// Slider
				slider = Slider(parent, 200@20)
					.value_(spec.unmap(default))
					.action_({ arg sl;
						var val = spec.map(sl.value);
						numberBox.value = val;
						if(grainSynth.notNil, {
							grainSynth.set(param, val);
						});
					});

				// Number box
				numberBox = NumberBox(parent, 120@20)
					.value_(default)
					.decimals_(3)
					.action_({ arg nb;
						var val = spec.constrain(nb.value);
						slider.value = spec.unmap(val);
						if(grainSynth.notNil, {
							grainSynth.set(param, val);
						});
					});

				parent.decorator.nextLine;

				(slider: slider, numberBox: numberBox);
			};

			// Grain Size
			grainSizeSlider = ~makeSlider.value(
				controlLayout, "Grain Size", specs.grainSize, \grainSize, 0.1
			);

			// Density
			densitySlider = ~makeSlider.value(
				controlLayout, "Density", specs.density, \density, 30
			);

			// Position
			positionSlider = ~makeSlider.value(
				controlLayout, "Position", specs.position, \position, 0.5
			);

			// Pitch
			pitchSlider = ~makeSlider.value(
				controlLayout, "Pitch", specs.pitch, \pitch, 0
			);

			controlLayout.decorator.nextLine;

			// === RANDOMIZATION ===
			StaticText(controlLayout, 460@20)
				.string_("RANDOMIZATION")
				.align_(\left)
				.font_(Font("Monaco", 12, true));

			controlLayout.decorator.nextLine;

			// Position Jitter
			posJitterSlider = ~makeSlider.value(
				controlLayout, "Position Jitter", specs.posJitter, \posJitter, 0.1
			);

			// Pitch Jitter
			pitchJitterSlider = ~makeSlider.value(
				controlLayout, "Pitch Jitter", specs.pitchJitter, \pitchJitter, 0
			);

			controlLayout.decorator.nextLine;

			// === SPATIAL ===
			StaticText(controlLayout, 460@20)
				.string_("SPATIAL")
				.align_(\left)
				.font_(Font("Monaco", 12, true));

			controlLayout.decorator.nextLine;

			// Stereo Spread
			spreadSlider = ~makeSlider.value(
				controlLayout, "Stereo Spread", specs.spread, \stereoSpread, 0.5
			);

			// Amplitude
			ampSlider = ~makeSlider.value(
				controlLayout, "Amplitude", specs.amp, \amp, 0.5
			);

			controlLayout.decorator.nextLine;

			// === ENVELOPE TYPE ===
			StaticText(controlLayout, 460@20)
				.string_("ENVELOPE SHAPE")
				.align_(\left)
				.font_(Font("Monaco", 12, true));

			controlLayout.decorator.nextLine;

			StaticText(controlLayout, 120@20)
				.string_("Envelope Type")
				.align_(\left);

			envTypeMenu = PopUpMenu(controlLayout, 320@25)
				.items_(["Percussive", "Sine", "Triangle", "Welch"])
				.value_(1) // default to Sine
				.action_({ arg menu;
					if(grainSynth.notNil, {
						grainSynth.set(\envType, menu.value);
					});
				});

			controlLayout.decorator.nextLine;
			controlLayout.decorator.nextLine;

			// === MORPHING RESONATOR (PHASE 2) ===
			StaticText(controlLayout, 460@20)
				.string_("48-BAND MORPHING RESONATOR")
				.align_(\left)
				.font_(Font("Monaco", 12, true));

			controlLayout.decorator.nextLine;

			// Filter On/Off
			StaticText(controlLayout, 120@20)
				.string_("Filter Enable")
				.align_(\left);

			Button(controlLayout, 320@25)
				.states_([
					["OFF", Color.black, Color.gray(0.5)],
					["ON", Color.white, Color.green(0.6)]
				])
				.value_(0) // default off
				.action_({ arg btn;
					if(grainSynth.notNil, {
						grainSynth.set(\filterOn, btn.value);
					});
				});

			controlLayout.decorator.nextLine;

			// Filter Frequency
			~makeSlider.value(
				controlLayout, "Frequency", specs.filterFreq, \filterFreq, 200
			);

			// Filter Morph (LP/BP/HP)
			StaticText(controlLayout, 120@20)
				.string_("Morph (LP→BP→HP)")
				.align_(\left);

			Slider(controlLayout, 200@20)
				.value_(specs.filterMorph.unmap(0.5))
				.action_({ arg sl;
					var val = specs.filterMorph.map(sl.value);
					if(grainSynth.notNil, {
						grainSynth.set(\filterMorph, val);
					});
				});

			StaticText(controlLayout, 120@20)
				.string_(" BP (0.5)")
				.align_(\left);

			controlLayout.decorator.nextLine;

			// Filter Resonance
			~makeSlider.value(
				controlLayout, "Resonance", specs.filterRes, \filterRes, 0.5
			);

			// Filter Decay
			~makeSlider.value(
				controlLayout, "Decay", specs.filterDecay, \filterDecay, 0.5
			);

			// Filter Mix (Dry/Wet)
			~makeSlider.value(
				controlLayout, "Mix (Dry/Wet)", specs.filterMix, \filterMix, 0.5
			);

			controlLayout.decorator.nextLine;

			// === FILTER ANIMATION ===
			StaticText(controlLayout, 460@20)
				.string_("ANIMATION")
				.align_(\left)
				.font_(Font("Monaco", 11, true));

			controlLayout.decorator.nextLine;

			// Filter Animate
			~makeSlider.value(
				controlLayout, "Animate Amount", specs.filterAnimate, \filterAnimate, 0
			);

			// Filter Animate Rate
			~makeSlider.value(
				controlLayout, "Animate Rate", specs.filterAnimRate, \filterAnimRate, 0.5
			);

			controlLayout.decorator.nextLine;

			// === FILTER TUNING ===
			StaticText(controlLayout, 460@20)
				.string_("TUNING")
				.align_(\left)
				.font_(Font("Monaco", 11, true));

			controlLayout.decorator.nextLine;

			// Tuning Mode
			StaticText(controlLayout, 120@20)
				.string_("Tuning Mode")
				.align_(\left);

			PopUpMenu(controlLayout, 320@25)
				.items_(["Harmonic", "Inharmonic"])
				.value_(0) // default harmonic
				.action_({ arg menu;
					if(grainSynth.notNil, {
						grainSynth.set(\filterTuning, menu.value);
					});
				});

			controlLayout.decorator.nextLine;

			// Inharmonic Spread
			~makeSlider.value(
				controlLayout, "Inharmonic Spread", specs.filterSpread, \filterSpread, 1.5
			);

			controlLayout.decorator.nextLine;
			controlLayout.decorator.nextLine;

			// === COLOR EFFECTS (PHASE 3) ===
			StaticText(controlLayout, 460@20)
				.string_("COLOR EFFECTS (DISTORTION, CRUSH, COMPRESSION)")
				.align_(\left)
				.font_(Font("Monaco", 12, true));

			controlLayout.decorator.nextLine;

			// Color Enable
			StaticText(controlLayout, 120@20)
				.string_("Color Enable")
				.align_(\left);

			Button(controlLayout, 320@25)
				.states_([
					["OFF", Color.black, Color.gray(0.5)],
					["ON", Color.white, Color.red(0.6)]
				])
				.value_(0)
				.action_({ arg btn;
					if(grainSynth.notNil, {
						grainSynth.set(\colorOn, btn.value);
					});
				});

			controlLayout.decorator.nextLine;

			// Distortion controls
			~makeSlider.value(
				controlLayout, "Dist Crossover", specs.distCrossover, \distCrossover, 500
			);

			~makeSlider.value(
				controlLayout, "Dist Lo Drive", specs.distLoDrive, \distLoDrive, 1
			);

			~makeSlider.value(
				controlLayout, "Dist Hi Drive", specs.distHiDrive, \distHiDrive, 1
			);

			~makeSlider.value(
				controlLayout, "Dist Mix", specs.distMix, \distMix, 0
			);

			// Bit crusher controls
			~makeSlider.value(
				controlLayout, "Crush Rate", specs.crushRate, \crushRate, 48000
			);

			~makeSlider.value(
				controlLayout, "Crush Bits", specs.crushBits, \crushBits, 16
			);

			~makeSlider.value(
				controlLayout, "Crush Mix", specs.crushMix, \crushMix, 0
			);

			// Compressor controls
			~makeSlider.value(
				controlLayout, "Comp Threshold", specs.compThresh, \compThresh, 0.5
			);

			~makeSlider.value(
				controlLayout, "Comp Ratio", specs.compRatio, \compRatio, 4
			);

			// Noise
			StaticText(controlLayout, 120@20)
				.string_("Noise Type")
				.align_(\left);

			PopUpMenu(controlLayout, 200@25)
				.items_(["White", "Pink", "Brown"])
				.value_(0)
				.action_({ arg menu;
					if(grainSynth.notNil, {
						grainSynth.set(\noiseType, menu.value);
					});
				});

			controlLayout.decorator.nextLine;

			~makeSlider.value(
				controlLayout, "Noise Amount", specs.noiseAmount, \noiseAmount, 0
			);

			controlLayout.decorator.nextLine;
			controlLayout.decorator.nextLine;

			// === SPACE EFFECTS (PHASE 3) ===
			StaticText(controlLayout, 460@20)
				.string_("SPACE EFFECTS (REVERB, DELAY, SHIMMER)")
				.align_(\left)
				.font_(Font("Monaco", 12, true));

			controlLayout.decorator.nextLine;

			// Space Enable
			StaticText(controlLayout, 120@20)
				.string_("Space Enable")
				.align_(\left);

			Button(controlLayout, 320@25)
				.states_([
					["OFF", Color.black, Color.gray(0.5)],
					["ON", Color.white, Color.blue(0.6)]
				])
				.value_(0)
				.action_({ arg btn;
					if(grainSynth.notNil, {
						grainSynth.set(\spaceOn, btn.value);
					});
				});

			controlLayout.decorator.nextLine;

			// Reverb controls
			~makeSlider.value(
				controlLayout, "Reverb Size", specs.reverbSize, \reverbSize, 0.5
			);

			~makeSlider.value(
				controlLayout, "Reverb Damping", specs.reverbDamp, \reverbDamp, 0.5
			);

			~makeSlider.value(
				controlLayout, "Reverb Mix", specs.reverbMix, \reverbMix, 0.3
			);

			// Reverb freeze button
			StaticText(controlLayout, 120@20)
				.string_("Reverb Freeze")
				.align_(\left);

			Button(controlLayout, 200@25)
				.states_([
					["Normal", Color.black, Color.gray(0.5)],
					["FREEZE", Color.white, Color.cyan]
				])
				.value_(0)
				.action_({ arg btn;
					if(grainSynth.notNil, {
						grainSynth.set(\reverbFreeze, btn.value);
					});
				});

			controlLayout.decorator.nextLine;

			// Delay controls
			~makeSlider.value(
				controlLayout, "Delay Time", specs.delayTime, \delayTime, 0.25
			);

			~makeSlider.value(
				controlLayout, "Delay Feedback", specs.delayFeedback, \delayFeedback, 0.5
			);

			~makeSlider.value(
				controlLayout, "Delay Filter", specs.delayFilter, \delayFilter, 5000
			);

			~makeSlider.value(
				controlLayout, "Delay Mix", specs.delayMix, \delayMix, 0.3
			);

			// Ping-pong button
			StaticText(controlLayout, 120@20)
				.string_("Ping-Pong")
				.align_(\left);

			Button(controlLayout, 200@25)
				.states_([
					["OFF", Color.black, Color.gray(0.5)],
					["ON", Color.white, Color.green]
				])
				.value_(0)
				.action_({ arg btn;
					if(grainSynth.notNil, {
						grainSynth.set(\delayPingPong, btn.value);
					});
				});

			controlLayout.decorator.nextLine;

			// Shimmer controls
			~makeSlider.value(
				controlLayout, "Shimmer Time", specs.shimmerTime, \shimmerTime, 0.5
			);

			~makeSlider.value(
				controlLayout, "Shimmer Feedback", specs.shimmerFeedback, \shimmerFeedback, 0.6
			);

			~makeSlider.value(
				controlLayout, "Shimmer Pitch", specs.shimmerPitch, \shimmerPitch, 12
			);

			~makeSlider.value(
				controlLayout, "Shimmer Mix", specs.shimmerMix, \shimmerMix, 0
			);

			controlLayout.decorator.nextLine;
			controlLayout.decorator.nextLine;

			// === INFO ===
			StaticText(controlLayout, 460@100)
				.string_("Phase 3: Granular Engine + Resonator + Effects\n128 grains | 4-second buffer | 48-band filterbank\nColor: Distortion, Bit Crush, Compression, Noise\nSpace: Reverb (freeze), Delay (ping-pong), Shimmer")
				.align_(\center)
				.font_(Font("Monaco", 10));

			self.window = window;
			self;
		},

		/*
		Function: close
		Purpose: Close GUI window
		*/
		close: {
			arg self;
			if(window.notNil, {
				window.close;
			});
		}
	);

	publicAPI;
};
)

/*
Usage example:
(
// Create GUI with synth and recorder
~gui = ~s4BasicGUI.value(~grainSynth, ~recorder, s);
~gui.create;
)

// Close GUI
~gui.close;
*/
