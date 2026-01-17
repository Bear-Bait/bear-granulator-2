/*
BEARULATOR: Preset System (Simple & Native)
Phase 14 - Complete State Save/Load

Format: .scd files (SuperCollider dictionaries)
Storage: presets/ directory in project root

Saves complete state:
- All 4 track parameters (80+ params per track)
- Mix settings (volume, pan, mute, solo)
- Spatial positions (quad X/Y)
- Material modes
- Modulation targets (for reference - not auto-restored)

Usage:
  ~presets.save("myPreset");
  ~presets.load("myPreset");
  ~presets.list;
*/

~bearulatorPresetSystem = { arg trackManager;
	var presetDir, publicAPI;

	// Preset directory (relative to project root)
	presetDir = thisProcess.nowExecutingPath.dirname.dirname +/+ "presets";

	publicAPI = (
		// Initialize
		init: { arg self;
			// Create presets directory if needed
			File.exists(presetDir).not.if({
				File.mkdir(presetDir);
				"Preset System: Created directory at %".format(presetDir).postln;
			});
			"Preset System: Ready (% presets available)".format(self.list.size).postln;
		},

		// Save current state
		save: { arg self, name;
			var state, filePath, file;
			var timestamp = Date.getDate.stamp;

			// Validate name
			name = name ? ("preset_" ++ timestamp);

			// Capture state
			state = self.captureState();
			state[\metadata] = (
				name: name.asString,
				saved: timestamp,
				version: "Phase 14"
			);

			// Write to file
			filePath = presetDir +/+ (name.asString ++ ".scd");
			file = File(filePath, "w");

			if(file.isOpen, {
				file.write("// BEARULATOR Preset: %\n".format(name));
				file.write("// Saved: %\n".format(timestamp));
				file.write("// Phase 14 - Audio-Rate Modulation + Spatial Automation\n\n");
				file.write(state.cs);  // .cs = compile string (pretty print)
				file.close();
				"✅ SAVED: '%' → %".format(name, filePath).postln;
				^true;
			}, {
				"❌ FAILED: Could not save '%'".format(name).error;
				^false;
			});
		},

		// Load preset
		load: { arg self, name;
			var filePath, state;

			filePath = presetDir +/+ (name.asString ++ ".scd");

			if(File.exists(filePath).not, {
				"❌ NOT FOUND: Preset '%' does not exist".format(name).error;
				"Available presets:".postln;
				self.list;
				^false;
			});

			// Load state from file
			state = filePath.load;

			if(state.isNil, {
				"❌ CORRUPT: Preset '%' could not be loaded".format(name).error;
				^false;
			});

			// Apply state
			self.applyState(state);

			"✅ LOADED: '%' (saved: %)".format(
				name,
				state[\metadata][\saved]
			).postln;
			^true;
		},

		// Capture complete state
		captureState: { arg self;
			var state = ();
			var tracks = trackManager.getTracks();

			state[\tracks] = 4.collect({ arg i;
				var track = tracks[i];
				var trackState = ();

				// All parameters (deep copy)
				trackState[\params] = track[\params].copy;

				// Mix controls
				trackState[\volume] = track[\volume];
				trackState[\pan] = track[\pan];
				trackState[\mute] = track[\mute];
				trackState[\solo] = track[\solo];
				trackState[\mode] = track[\mode];

				// Spatial (quad)
				trackState[\quadX] = track[\params][\quadX] ? 0.0;
				trackState[\quadY] = track[\params][\quadY] ? 0.0;

				// Modulation targets (for reference only - not auto-restored)
				trackState[\modInfo] = 4.collect({ arg modNum;
					var target = track[\modTargets][modNum];
					var range = track[\modRanges][modNum];
					(
						target: target,
						min: range[\min],
						max: range[\max],
						active: track[\modulators][modNum].notNil
					);
				});

				trackState;
			});

			state;
		},

		// Apply state to system
		applyState: { arg self, state;
			var tracks = state[\tracks];

			tracks.do({ arg trackState, i;
				// Set all parameters
				trackState[\params].keysValuesDo({ arg param, value;
					trackManager.setParam(i, param, value);
				});

				// Set mix controls
				trackManager.setVolume(i, trackState[\volume]);
				trackManager.setPan(i, trackState[\pan]);
				trackManager.setMute(i, trackState[\mute]);
				trackManager.setSolo(i, trackState[\solo]);

				// Set material mode
				// Use setMode to ensure both internal state and synth parameter (\grainMode) are updated
				trackManager.setMode(i, trackState[\mode]);

				// Set spatial position
				trackManager.setQuadPosition(i, trackState[\quadX], trackState[\quadY]);
			});

			"Applied state to all 4 tracks".postln;
			"Note: Modulation routings NOT restored (manual re-route if needed)".postln;
		},

		// List all presets
		list: { arg self;
			var files = PathName(presetDir).files;
			var presets = files.select({ arg f; f.extension == "scd" });

			if(presets.isEmpty, {
				"No presets found in %".format(presetDir).postln;
				^[];
			});

			"Available Presets (%):".format(presets.size).postln;
			presets.do({ arg file, i;
				var name = file.fileNameWithoutExtension;
				"  [%] %".format(i + 1, name).postln;
			});

			presets.collect({ arg f; f.fileNameWithoutExtension });
		},

		// Delete preset
		delete: { arg self, name;
			var filePath = presetDir +/+ (name.asString ++ ".scd");

			if(File.exists(filePath), {
				File.delete(filePath);
				"✅ DELETED: '%'".format(name).postln;
				^true;
			}, {
				"❌ NOT FOUND: '%'".format(name).error;
				^false;
			});
		},

		// Quick save with timestamp
		quickSave: { arg self;
			var timestamp = Date.getDate.format("%Y%m%d_%H%M%S");
			var name = "quick_" ++ timestamp;
			self.save(name);
			name;
		},

		// Show preset info
		info: { arg self, name;
			var filePath = presetDir +/+ (name.asString ++ ".scd");
			var state;

			if(File.exists(filePath).not, {
				"❌ NOT FOUND: '%'".format(name).error;
				^nil;
			});

			state = filePath.load;

			"=== PRESET INFO: % ===".format(name).postln;
			"Saved: %".format(state[\metadata][\saved]).postln;
			"Version: %".format(state[\metadata][\version]).postln;
			"".postln;

			"Track States:".postln;
			state[\tracks].do({ arg track, i;
				"  Track %: % mode, vol=%, pan=%".format(
					i + 1,
					[\TAPE, \POLY, \LIVE][track[\mode]],
					track[\volume].round(0.01),
					track[\pan].round(0.01)
				).postln;

				// Show active modulations
				track[\modInfo].do({ arg mod, modNum;
					if(mod[\active], {
						"    Mod %: % (% to %)".format(
							modNum + 1,
							mod[\target],
							mod[\min].round(0.01),
							mod[\max].round(0.01)
						).postln;
					});
				});
			});

			state;
		},

		// Get preset directory
		getDir: { arg self;
			presetDir;
		}
	);

	publicAPI;
};
