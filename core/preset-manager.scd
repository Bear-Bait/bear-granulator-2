/*
BEARULATOR: Preset Manager
Phase 15 - Save/Load parameter state

Manages preset saving and loading for all track parameters including:
- Grain parameters
- Spectral parameters
- Direct playback parameters
- Effects parameters
- Material modes
- Engine modes

Preset Format: JSON-style text files in presets/ directory
*/

~bearulatorPresetManager = { arg trackManager, presetFolder;
	var presetPath, publicAPI;

	// Set preset directory (create if doesn't exist)
	presetPath = presetFolder ?? { PathName(thisProcess.nowExecutingPath).parentPath +/+ "presets" };

	// Create presets directory if it doesn't exist
	if(File.exists(presetPath).not, {
		("mkdir -p" + presetPath.quote).systemCmd;
		"Preset directory created: %".format(presetPath).postln;
	});

	publicAPI = (
		/*
		Function: savePreset
		Purpose: Save current track state to a preset file
		Args: trackNum (0-3), presetName (string)
		Returns: File path on success, nil on failure
		*/
		savePreset: { arg self, trackNum, presetName;
			var track, params, filePath, file;
			var presetData = ();

			track = trackManager.getTrack(trackNum);
			if(track.isNil, {
				"ERROR: Track % not found".format(trackNum + 1).error;
				^nil;
			});

			// Sanitize preset name (remove invalid filename characters)
			presetName = presetName.replace(" ", "_").replace("/", "-");
			filePath = presetPath +/+ "track" ++ trackNum ++ "_" ++ presetName ++ ".preset";

			// Gather all track parameters
			presetData[\trackNum] = trackNum;
			presetData[\presetName] = presetName;
			presetData[\timestamp] = Date.getDate.stamp;
			presetData[\params] = track.params.copy;  // Deep copy of params
			presetData[\filePath] = track.filePath;  // Sample file path (if any)
			presetData[\mode] = track.mode;  // Material mode (TAPE/POLY/LIVE)

			// Write to file as formatted text
			file = File(filePath, "w");
			if(file.isOpen.not, {
				"ERROR: Could not create preset file: %".format(filePath).error;
				^nil;
			});

			// Write header
			file.write("// BEARULATOR Preset\n");
			file.write("// Track: %\n".format(trackNum + 1));
			file.write("// Name: %\n".format(presetName));
			file.write("// Date: %\n".format(Date.getDate.asString));
			file.write("(\n");

			// Write parameters (sorted for readability)
			[\trackNum, \presetName, \timestamp, \mode, \filePath].do({ arg key;
				var value = presetData[key];
				file.write("\t%: %,\n".format(key, value.asCompileString));
			});

			// Write params dictionary
			file.write("\tparams: (\n");
			track.params.keys.asArray.sort.do({ arg key, i;
				var value = track.params[key];
				var comma = if(i < (track.params.size - 1), ",", "");
				file.write("\t\t%: %%\n".format(key, value.asCompileString, comma));
			});
			file.write("\t)\n");
			file.write(")\n");

			file.close;

			"✓ Preset saved: %".format(filePath).postln;
			filePath;
		},

		/*
		Function: loadPreset
		Purpose: Load preset from file and apply to track
		Args: trackNum (0-3), filePath (string)
		Returns: true on success, false on failure
		*/
		loadPreset: { arg self, trackNum, filePath;
			var track, presetData, file;

			track = trackManager.getTrack(trackNum);
			if(track.isNil, {
				"ERROR: Track % not found".format(trackNum + 1).error;
				^false;
			});

			if(File.exists(filePath).not, {
				"ERROR: Preset file not found: %".format(filePath).error;
				^false;
			});

			// Load preset data (interpret file as SC code)
			presetData = filePath.load;
			if(presetData.isNil, {
				"ERROR: Could not parse preset file: %".format(filePath).error;
				^false;
			});

			"Loading preset: % → Track %".format(
				presetData[\presetName] ? "Unnamed",
				trackNum + 1
			).postln;

			// Apply material mode
			if(presetData[\mode].notNil, {
				trackManager.setMode(trackNum, presetData[\mode]);
			});

			// Apply all parameters
			if(presetData[\params].notNil, {
				fork {
					presetData[\params].keysValuesDo({ arg key, value;
						trackManager.setParam(trackNum, key, value);
						// Small delay to prevent message flooding
						0.001.wait;
					});
				};
			});

			// Load sample file if specified and exists
			if(presetData[\filePath].notNil and: { File.exists(presetData[\filePath]) }, {
				"  Sample file: %".format(presetData[\filePath]).postln;
				// Note: File loading would need to be triggered via GUI
				// Store the path for reference
				track.filePath = presetData[\filePath];
			});

			"✓ Preset loaded: % (% params)".format(
				presetData[\presetName] ? "Unnamed",
				presetData[\params].size
			).postln;

			true;
		},

		/*
		Function: listPresets
		Purpose: Get list of all preset files in presets directory
		Args: trackNum (optional, 0-3) - filter by track number
		Returns: Array of preset file paths
		*/
		listPresets: { arg self, trackNum = nil;
			var pattern, presetFiles;

			pattern = if(trackNum.notNil, {
				presetPath +/+ ("track" ++ trackNum ++ "_*.preset");
			}, {
				presetPath +/+ "*.preset";
			});

			presetFiles = (pattern).pathMatch;

			if(presetFiles.size == 0, {
				"No presets found in %".format(presetPath).postln;
			}, {
				"Found % preset(s) in %".format(presetFiles.size, presetPath).postln;
			});

			presetFiles;
		},

		/*
		Function: deletePreset
		Purpose: Delete a preset file
		Args: filePath (string)
		Returns: true on success, false on failure
		*/
		deletePreset: { arg self, filePath;
			if(File.exists(filePath).not, {
				"ERROR: Preset file not found: %".format(filePath).error;
				^false;
			});

			File.delete(filePath);
			"✓ Preset deleted: %".format(filePath).postln;
			true;
		},

		/*
		Function: getPresetInfo
		Purpose: Get preset metadata without loading it
		Args: filePath (string)
		Returns: Event with preset info, or nil on failure
		*/
		getPresetInfo: { arg self, filePath;
			var presetData;

			if(File.exists(filePath).not, {
				^nil;
			});

			presetData = filePath.load;
			if(presetData.isNil, {
				^nil;
			});

			(
				name: presetData[\presetName] ? "Unnamed",
				trackNum: presetData[\trackNum] ? 0,
				timestamp: presetData[\timestamp] ? "",
				filePath: filePath,
				paramCount: presetData[\params].size ? 0
			);
		},

		/*
		Function: getPresetPath
		Purpose: Get the presets directory path
		Returns: String path
		*/
		getPresetPath: { arg self;
			presetPath;
		}
	);

	"✓ Preset Manager initialized".postln;
	"  Preset directory: %".format(presetPath).postln;

	publicAPI;
};

"✓ Preset Manager module loaded".postln;
