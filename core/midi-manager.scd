/*
BEARULATOR: MIDI Manager v2.3
- Modular CC Routing (Matrix Patch Bay)
- GUI Patcher Window
- Dynamic knob-to-parameter assignment
- Multi-track and global routing support

Usage:
  ~midiManager = ~bearulatorMidiManager.value(~trackManager);
  ~midiManager.patch(79, 0, \loFiGrains, 0, 5);  // CC79 -> Track 1 loFiGrains
  ~midiManager.patch(1, [0,1], \posJitter, 0, 1); // CC1 -> Tracks 1&2 posJitter
  ~midiManager.createPatcherWindow;  // Open GUI
*/

~bearulatorMidiManager = { arg trackManager;
	var midiMatrix = Dictionary.new;
	var responder = nil;
	var publicAPI;

	// Color scheme (matches Bearulator theme)
	var colors = (
		bg: Color.fromHexString("#262938"),
		fg: Color.white,
		cyan: Color.cyan,
		green: Color.green,
		yellow: Color(0.9, 0.8, 0.2),
		red: Color.red,
		orange: Color(1, 0.6, 0)
	);

	// Common parameters for patching (dropdown menu)
	var patchableParams = [
		// Grain Engine
		\grainSize, \overlap, \density, \position, \scanSpeed,
		\posJitter, \pitchJitter, \pitch, \pitchShift, \prob,
		\loFiGrains, \timeStretch, \stereoSpread,
		// Filter
		\filterFreq, \filterMorph, \filterRes, \filterMix,
		// Color FX
		\crushBits, \crushRate, \distMix, \compThresh,
		// Space FX
		\reverbMix, \reverbSize, \delayMix, \delayTime, \shimmerMix,
		// Spectral
		\spectralMix, \spectralPitch, \spectralRate,
		// Master
		\amp, \pan
	];

	publicAPI = (
		trackManager: trackManager,
		matrix: midiMatrix,
		params: patchableParams,

		// --- Initialize MIDI responder (call after MIDI is ready) ---
		initResponder: { arg self;
			if(responder.notNil, { responder.free });
			
			responder = MIDIFunc.cc({ arg val, num, chan;
				var map = midiMatrix[num];

				// If this CC is patched in the matrix, execute the route
				if(map.notNil, {
					var scaledVal;

					// Scale 0-127 to the target parameter's range
					if(map.warp == \exp, {
						scaledVal = val.linexp(0, 127, map.min.max(0.001), map.max);
					}, {
						scaledVal = val.linlin(0, 127, map.min, map.max);
					});

					// Check if track is "All" (collection) or single index
					if(map.track.isArray, {
						map.track.do({ |tIdx|
							trackManager.setParam(tIdx, map.param, scaledVal);
						});
					}, {
						trackManager.setParam(map.track, map.param, scaledVal);
					});

					// Visual feedback in viewfinder (if available)
					if(~viewfinder.notNil, {
						{
							if(map.track.isArray, {
								map.track.do({ |tIdx|
									~viewfinder.showCCFeedback(tIdx, map.param.asString, scaledVal);
								});
							}, {
								~viewfinder.showCCFeedback(map.track, map.param.asString, scaledVal);
							});
						}.defer;
					});
				});
			});
			"MIDI Manager: Responder initialized".postln;
		},

		// --- API: Patch a connection ---
		// trackNum can be an integer (0-3) or an array [0,1] for multi-track control
		patch: { arg self, ccNum, trackNum, param, min=0.0, max=1.0, warp=\lin;
			midiMatrix[ccNum] = (
				track: trackNum,
				param: param,
				min: min,
				max: max,
				warp: warp
			);
			"MIDI PATCH: CC % -> Track % \"%\" (%-%, %)".format(
				ccNum,
				if(trackNum.isArray, { "ALL" }, { trackNum + 1 }),
				param,
				min, max, warp
			).postln;
		},

		// --- API: Clear a connection ---
		unpatch: { arg self, ccNum;
			midiMatrix[ccNum] = nil;
			"MIDI UNPATCH: CC % cleared".format(ccNum).postln;
		},

		// --- API: List all active patches ---
		listPatches: { arg self;
			"".postln;
			"=== MIDI PATCH MATRIX ===".postln;
			midiMatrix.keysValuesDo({ |cc, map|
				"  CC % -> Track % \"%\" (%-%)".format(
					cc,
					if(map.track.isArray, { "ALL" }, { map.track + 1 }),
					map.param,
					map.min, map.max
				).postln;
			});
			if(midiMatrix.size == 0, { "  (no patches)".postln });
			"".postln;
		},

		// --- API: Clear all patches ---
		clearAll: { arg self;
			midiMatrix.clear;
			"MIDI PATCH: All patches cleared".postln;
		},

		// --- GUI: Patcher Window ---
		createPatcherWindow: { arg self;
			var win, ccBox, trkMenu, paramMenu, minBox, maxBox, warpMenu;
			var patchList, refreshList;

			win = Window("MIDI PATCHER", Rect(100, 100, 340, 350))
				.background_(colors.bg)
				.front;

			// === INPUT SECTION ===
			StaticText(win, Rect(10, 10, 80, 20))
				.string_("CC SOURCE")
				.font_(Font("DejaVu Sans Mono", 10, true))
				.stringColor_(colors.cyan);
			ccBox = NumberBox(win, Rect(10, 30, 60, 22))
				.value_(79)
				.font_(Font("DejaVu Sans Mono", 10))
				.background_(Color.gray(0.2))
				.normalColor_(colors.fg);

			StaticText(win, Rect(80, 10, 80, 20))
				.string_("TRACK")
				.font_(Font("DejaVu Sans Mono", 10, true))
				.stringColor_(colors.cyan);
			trkMenu = PopUpMenu(win, Rect(80, 30, 70, 22))
				.items_(["1", "2", "3", "4", "1+2", "ALL"])
				.font_(Font("DejaVu Sans Mono", 10))
				.background_(Color.gray(0.2))
				.stringColor_(colors.fg);

			StaticText(win, Rect(160, 10, 100, 20))
				.string_("PARAMETER")
				.font_(Font("DejaVu Sans Mono", 10, true))
				.stringColor_(colors.cyan);
			paramMenu = PopUpMenu(win, Rect(160, 30, 160, 22))
				.items_(patchableParams)
				.font_(Font("DejaVu Sans Mono", 10))
				.background_(Color.gray(0.2))
				.stringColor_(colors.fg);

			// === RANGE SECTION ===
			StaticText(win, Rect(10, 60, 40, 20))
				.string_("MIN")
				.font_(Font("DejaVu Sans Mono", 10, true))
				.stringColor_(colors.yellow);
			minBox = NumberBox(win, Rect(10, 80, 60, 22))
				.value_(0.0)
				.font_(Font("DejaVu Sans Mono", 10))
				.background_(Color.gray(0.2))
				.normalColor_(colors.fg);

			StaticText(win, Rect(80, 60, 40, 20))
				.string_("MAX")
				.font_(Font("DejaVu Sans Mono", 10, true))
				.stringColor_(colors.yellow);
			maxBox = NumberBox(win, Rect(80, 80, 60, 22))
				.value_(1.0)
				.font_(Font("DejaVu Sans Mono", 10))
				.background_(Color.gray(0.2))
				.normalColor_(colors.fg);

			StaticText(win, Rect(150, 60, 50, 20))
				.string_("WARP")
				.font_(Font("DejaVu Sans Mono", 10, true))
				.stringColor_(colors.yellow);
			warpMenu = PopUpMenu(win, Rect(150, 80, 70, 22))
				.items_(["linear", "exp"])
				.font_(Font("DejaVu Sans Mono", 10))
				.background_(Color.gray(0.2))
				.stringColor_(colors.fg);

			// === BIND BUTTON ===
			Button(win, Rect(10, 115, 150, 35))
				.states_([["BIND", Color.black, colors.green]])
				.font_(Font("DejaVu Sans Mono", 11, true))
				.action_({
					var trkVal = case
						{ trkMenu.value == 4 } { [0, 1] }      // 1+2
						{ trkMenu.value == 5 } { [0,1,2,3] }   // ALL
						{ true } { trkMenu.value };            // Single track

					var warpVal = if(warpMenu.value == 1, { \exp }, { \lin });

					self.patch(
						ccBox.value.asInteger,
						trkVal,
						paramMenu.item.asSymbol,
						minBox.value,
						maxBox.value,
						warpVal
					);
					refreshList.value;
				});

			// === CLEAR BUTTON ===
			Button(win, Rect(170, 115, 150, 35))
				.states_([["CLEAR CC", Color.white, colors.red]])
				.font_(Font("DejaVu Sans Mono", 11, true))
				.action_({
					self.unpatch(ccBox.value.asInteger);
					refreshList.value;
				});

			// === PATCH LIST ===
			StaticText(win, Rect(10, 160, 200, 20))
				.string_("ACTIVE PATCHES")
				.font_(Font("DejaVu Sans Mono", 10, true))
				.stringColor_(colors.orange);

			patchList = TextView(win, Rect(10, 180, 310, 120))
				.font_(Font("DejaVu Sans Mono", 9))
				.background_(Color.gray(0.15))
				.stringColor_(colors.fg)
				.editable_(false);

			// Refresh function for patch list
			refreshList = {
				var text = "";
				midiMatrix.keys.asArray.sort.do({ |cc|
					var map = midiMatrix[cc];
					var trkStr = if(map.track.isArray, {
						if(map.track.size == 4, { "ALL" }, { map.track.collect(_+1).join("+") });
					}, { (map.track + 1).asString });
					text = text ++ "CC% -> T% % (%-% %)\n".format(
						cc, trkStr, map.param, map.min.round(0.01), map.max.round(0.01), map.warp
					);
				});
				if(text.isEmpty, { text = "(no active patches)" });
				{ patchList.string_(text) }.defer;
			};

			// === CLEAR ALL BUTTON ===
			Button(win, Rect(10, 310, 310, 30))
				.states_([["CLEAR ALL PATCHES", Color.white, Color.gray(0.4)]])
				.font_(Font("DejaVu Sans Mono", 10, true))
				.action_({
					self.clearAll;
					refreshList.value;
				});

			// Initial refresh
			refreshList.value;

			win;
		}
	);

	// Auto-initialize responder if MIDI is already running
	if(MIDIClient.initialized, {
		publicAPI.initResponder;
	});

	"MIDI Manager initialized".postln;
	publicAPI;
};
