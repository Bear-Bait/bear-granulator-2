/*
Minimal Safe GUI - Just essential controls
No scrollview, minimal elements
*/

(
~s4MinimalGUI = {
	arg grainSynth, recorder, server;
	var window;
	var publicAPI;

	publicAPI = (
		window: nil,

		create: {
			arg self;

			// Simple fixed-size window
			window = Window("BEARULATOR v0.3 - Minimal", Rect(100, 100, 400, 300))
				.front
				.onClose_({ "GUI closed.".postln; });

			// Title
			StaticText(window, Rect(10, 10, 380, 30))
				.string_("BEARULATOR - MINIMAL CONTROLS")
				.align_(\center)
				.font_(Font("Monaco", 14, true));

			// Record button
			Button(window, Rect(10, 50, 180, 40))
				.states_([
					["Start Recording (In 3)", Color.black, Color.green(0.7)],
					["Stop Recording", Color.white, Color.red(0.7)]
				])
				.action_({ arg btn;
					if(btn.value == 1, {
						recorder.startRecording(2, overdub: false);  // Input 3 (index 2)
					}, {
						recorder.stopRecording;
					});
				});

			// Load Test Sound button
			Button(window, Rect(200, 50, 180, 40))
				.states_([
					["Load Test Sound", Color.black, Color.cyan(0.7)]
				])
				.action_({
					var tempBuf = Buffer.alloc(server, server.sampleRate * 4, 1);
					tempBuf.sine1([1.0, 0.5, 0.3, 0.2, 0.15], true, true, true);
					fork {
						0.2.wait;
						tempBuf.copyData(recorder.buffer);
						0.2.wait;
						tempBuf.free;
						"✓ Test sound loaded!".postln;
					};
				});

			// Grain Size slider
			StaticText(window, Rect(10, 110, 100, 20))
				.string_("Grain Size");
			Slider(window, Rect(120, 110, 200, 20))
				.value_(0.5)
				.action_({ arg sl;
					var val = sl.value.linexp(0, 1, 0.01, 0.5);
					grainSynth.set(\grainSize, val);
				});

			// Density slider
			StaticText(window, Rect(10, 140, 100, 20))
				.string_("Density");
			Slider(window, Rect(120, 140, 200, 20))
				.value_(0.3)
				.action_({ arg sl;
					var val = sl.value.linexp(0, 1, 1, 200);
					grainSynth.set(\density, val);
				});

			// Amplitude slider
			StaticText(window, Rect(10, 170, 100, 20))
				.string_("Amplitude");
			Slider(window, Rect(120, 170, 200, 20))
				.value_(0.5)
				.action_({ arg sl;
					grainSynth.set(\amp, sl.value);
				});

			// Filter On/Off
			Button(window, Rect(10, 210, 180, 30))
				.states_([
					["Filter OFF", Color.black, Color.gray(0.5)],
					["Filter ON", Color.white, Color.green(0.6)]
				])
				.action_({ arg btn;
					grainSynth.set(\filterOn, btn.value);
				});

			// Reverb On/Off
			Button(window, Rect(200, 210, 180, 30))
				.states_([
					["Reverb OFF", Color.black, Color.gray(0.5)],
					["Reverb ON", Color.white, Color.blue(0.6)]
				])
				.action_({ arg btn;
					grainSynth.set(\spaceOn, btn.value, \reverbMix, 0.5);
				});

			// Info
			StaticText(window, Rect(10, 250, 380, 40))
				.string_("Minimal GUI loaded. Use code for full control.\nSee post window for commands.")
				.align_(\center)
				.font_(Font("Monaco", 9));

			self.window = window;
			self;
		},

		close: {
			arg self;
			if(window.notNil, { window.close; });
		}
	);

	publicAPI;
};
)
