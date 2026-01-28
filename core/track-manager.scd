/*
BEARULATOR: Track Manager
Phase 4 - 4-Track Architecture

Manages 4 independent granular synthesis tracks.
Each track has:
- Grain synth (128 grains)
- Buffer recorder (4 seconds)
- Audio bus (stereo)
- Mix controls (volume, pan, mute, solo)
- Parameter storage (Dictionary)

Public API:
- init: Initialize track array
- createTrack: Create synth + recorder for a track
- freeTrack: Free track resources
- setParam: Set synth parameter for a track
- setVolume/setPan/setMute/setSolo: Mix controls
- getTracks: Return tracks array
- free: Cleanup all tracks
*/

~bearulatorTrackManager = { arg server;
	var tracks, masterBus;
	var publicAPI;

	// Initialize 4 track containers
	tracks = 4.collect({ arg i;
		(
			trackNum: i,
			grainSynth: nil,
			spectralSynth: nil,  // Phase 8: Warp1 spectral engine
			recorder: nil,
			audioBus: nil,
			volume: 0.8,
			pan: 0.0,
			mute: false,
			solo: false,
			params: IdentityDictionary.new,
			// Phase 13: Execution order groups
			modGroup: Group.head(server),     // Modulators run first
			instrumentGroup: Group.tail(server), // Instruments run after
			// Phase 5: Modulation system (4 modulators per track)
			modulators: 4.collect({ nil }),           // Modulator synths
			modBusses: 4.collect({ nil }),            // Control busses
			modMappers: 4.collect({ nil }),           // Mapper synths
			modTargets: 4.collect({ nil }),           // Target parameters
			modRanges: 4.collect({ (min: 0, max: 1) }), // Min/max ranges
			modSourceTracks: 4.collect({ i }),        // Phase 16: Source track for envelope follower (default = self)
			// Phase 6: Material modes
			mode: 0  // 0=TAPE, 1=POLY, 2=LIVE
		);
	});

	// Store reference to master bus (set externally)
	masterBus = nil;

	// === PUBLIC API ===

	publicAPI = (
		// Initialize track manager
		init: {
			"Track manager: Initialized with 4 track slots".postln;
		},

		// Create a track (synth + recorder + bus)
		createTrack: { arg self, trackNum;
			var track = tracks[trackNum];
			var defaultParams;

			if(trackNum < 0 or: { trackNum > 3 }, {
				"Track manager: Invalid track number %".format(trackNum).postln;
				^nil;
			});

			// Create audio bus (stereo)
			// Bus allocation: Track 0 → Bus 10-11, Track 1 → Bus 12-13, etc.
			track.audioBus = Bus.audio(server, 2);

			// Phase 16: Create shared phase bus for rhythmic synchronization
			// Allows all engines (Grain, Direct, Spectral) to share same playhead position
			track.phaseBus = Bus.control(server, 1);

			// Create buffer recorder instance
			track.recorder = ~bearulatorBufferRecorder.value(server);
			track.recorder.init;

			// Set up callback to update filePath when recording stops
			track.recorder.onRecordStop = {
				var path = track.recorder.tempFilePath;  // Access directly from recorder
				"═══════════════════════════════════════════".postln;
				"  RECORDING COMPLETE - Track %".format(trackNum + 1).postln;
				"═══════════════════════════════════════════".postln;
				"  File: %".format(path).postln;
				"  → Click REFRESH in viewfinder to see waveform".postln;
				"═══════════════════════════════════════════".postln;
				track.filePath = path;  // Set track's filePath for viewfinder
			};

			// Phase 17: Spectral Photobooth - Capture buffer for spectral snapshots
			track.spectralCaptureBuffer = Buffer.alloc(server, server.sampleRate * 4, 2);  // 4 sec stereo
			track.spectralCaptureRecorder = nil;  // RecordBuf synth (created on-demand)
			track.spectralCaptureStatus = \ready;  // \ready, \capturing, \captured

			// Default parameters for grain synth
			defaultParams = (
				// Grain parameters
				grainMode: 0,  // Phase 6: Default to TAPE mode (v2.1: renamed from mode)
				engineMix: 0.0,  // HYBRID ENGINE: 0.0=Granular, 1.0=Direct, 0.5=Equal mix
				grainOn: 1,       // Phase 16: Explicit toggle for Grain Engine (1=enabled)
				spectralOn: 1,    // Phase 16: Explicit toggle for Spectral Engine (1=enabled)
				directOn: 1,      // Phase 16: Explicit toggle for Direct Engine (1=enabled)
				scale: [0, 2, 4, 5, 7, 9, 11],  // Phase 16: Major scale (MIDI note offsets)
				quantizePitch: 0,  // Phase 16: Enable pitch quantization (0=off, 1=on)
				grainSize: 0.1,
				density: 30,      // Legacy parameter
				overlap: 1,       // Phase 6b: Default overlap count (1 = full sample playback)
				useOverlap: 1,    // Phase 6b: Use overlap mode by default
				prob: 1.0,        // v2.2: Probability mask (1.0 = 100% grain density)
				loFiGrains: 0,    // v2.3: LO-FI Switch (0=HD 256 grains, default)
				position: 0.0,    // Default to start of buffer
				scanSpeed: 0,     // Phase 7c: Continuous scanning (0=static)
				timeStretch: 1.0, // Phase 15: Master time stretch (1.0 = normal)
				pitch: 0,         // Legacy: changes speed+pitch
			pitchShift: 0,    // Phase 7: True pitch shift (preserves speed)
			posJitter: 0.1,
			pitchJitter: 0,
			t_reset: 0,       // Phase 18: Sequencer reset trigger (for sync quantization)
			// v2.1: 64-step sequencer arrays (KeyStep Pro/Digitone standard)
			posSeq: Array.fill(64, 0),
			pitchSeq: Array.fill(64, 0),
				envType: 1,
				stereoSpread: 0.5,
				amp: 0.5,
				pan: 0,
				loopStart: 0.0,  // Loop region start (0-1)
				loopEnd: 1.0,    // Loop region end (0-1)

			// Filter parameters (kept for backward compat, but ignored)
			filterOn: 0,
			filterType: 0,         // v2.4: 0=Morphing, 1=Diode, 2=Rings
			filterFreq: 200,
			filterMorph: 0.5,
			filterRes: 0.5,
			filterDecay: 0.5,
			filterAnimate: 0,
			filterAnimRate: 0.5,
			filterTuning: 0,
			filterSpread: 1.5,
			filterMix: 0.5,
			// v2.4: MiRings parameters (filterType 2)
			ringsBright: 0.5,
			ringsDamp: 0.7,
			ringsPos: 0.25,
			ringsModel: 0,

			// Color effects (default off)
			colorOn: 0,
			phaserRate: 0.5,       // v2.4: Barberpole phaser (0-1 mapped to -100 to +100 Hz)
			phaserMix: 0,
			distCrossover: 500,
			distLoDrive: 1,
			distHiDrive: 1,
			distMix: 0,
			crushRate: 8000,
			crushBits: 8,
			crushMix: 0,
			squizAmount: 1,        // v2.4: Squiz artifacts (1-10)
			squizMix: 0,
			compThresh: 0.5,
			compRatio: 4,
			compAttack: 0.01,
			compRelease: 0.1,
			noiseType: 0,
			noiseAmount: 0,

			// Space effects (default off)
			spaceOn: 0,
			reverbType: 0,         // v2.4: 0=FreeVerb, 1=Greyhole
			reverbSize: 0.5,
			reverbDamp: 0.5,
			reverbFreeze: 0,
			reverbMix: 0.3,
				delayTime: 0.25,
				delayFeedback: 0.5,
				delayFilter: 5000,
				delayPingPong: 0,
				delayMix: 0.3,
				shimmerTime: 0.5,
				shimmerFeedback: 0.6,
				shimmerPitch: 12,
				shimmerWindowSize: 0.2,  // Phase 7c: Shimmer texture (0.05=glitchy, 0.5=smooth)
				shimmerMix: 0,

				// Phase 8: Spectral engine (Warp1) - M4 Extreme Performance
				spectralMix: 0.0,      // Wet/dry (0=off, 1=full spectral)
				spectralPosition: 0.5, // Independent position control
				spectralRate: 1.0,     // Playback rate (0=freeze, 1=normal)
				spectralWindowSize: 0.1, // Window size (0.02-0.4, sweet spot for clarity)
				spectralOverlaps: 4,   // Overlap factor (1,2,4,8 - integer steps)
				spectralPitch: 0,      // Pitch shift (-24 to +24, semitone steps)
				spectralFreeze: 0,     // Freeze toggle (1=freeze)
				spectralSmear: 0,      // Spectral smear (0-1)
				spectralAmp: 0.5,      // Spectral output volume (0-1)

				// Phase 16: Wow & Flutter (Tape Degradation)
				wowRate: 0.5,          // Wow LFO frequency (0.1-2 Hz)
				wowDepth: 0.0,         // Wow intensity (0.0-1.0)
				flutterRate: 10.0,     // Flutter LFO frequency (5-15 Hz)
				flutterDepth: 0.0      // Flutter intensity (0.0-1.0)
			);

			track.params = defaultParams.copy;

			// Create grain synth with parameters (STOPPED by default)
			// Phase 13: Place in instrumentGroup (runs AFTER modGroup)
			track.grainSynth = Synth(\bearulatorGrainEngine, [
				\out, track.audioBus.index,
				\bufnum, track.recorder.getBufferNum
			] ++ track.params.asPairs, track.instrumentGroup);

			// Phase 15.5: Grain synth stays RUNNING but with amp controlled by engineMode
			// Start in GRANULAR mode (engineMode=0), so grain has full amp, direct has zero
			track.grainSynth.set(\amp, track.params[\amp]);

			// Phase 8: Create spectral synth (Warp1) - runs in parallel
			track.spectralSynth = Synth(\bearulatorSpectralEngine, [
				\out, track.audioBus.index,
				\bufnum, track.recorder.getBufferNum,
				\spectralMix, track.params[\spectralMix],
				\position, track.params[\spectralPosition],
				\rate, track.params[\spectralRate],
				\windowSize, track.params[\spectralWindowSize],
				\overlaps, track.params[\spectralOverlaps],
				\pitch, track.params[\spectralPitch],
				\freeze, track.params[\spectralFreeze],
				\smear, track.params[\spectralSmear],
				\amp, track.params[\spectralAmp],
				\interp, 4  // Best quality for M4
			], track.instrumentGroup);

			// Spectral synth starts STOPPED too
			track.spectralSynth.run(false);

			// Phase 15: Create direct playback synth (PlayBuf) - alternative to granular
			track.directPlaybackSynth = Synth(\bearulatorDirectPlayback, [
				\out, track.audioBus.index,
				\bufnum, track.recorder.getBufferNum,
				\rate, 1.0,
				\position, track.params[\position],
				\loop, 1,
				\loopStart, track.params[\loopStart],
				\loopEnd, track.params[\loopEnd],
				\amp, track.params[\amp],
				\pan, track.params[\pan],
				\pitch, track.params[\pitch],
				// Phase 16: Wow & Flutter parameters
				\wowRate, track.params[\wowRate],
				\wowDepth, track.params[\wowDepth],
				\flutterRate, track.params[\flutterRate],
				\flutterDepth, track.params[\flutterDepth]
			], track.instrumentGroup);

			// Phase 15: Direct synth starts STOPPED (granular mode is default)
			track.directPlaybackSynth.run(false);

			"Track manager: Track % created (bus: %) - Grain + Spectral + Direct - STOPPED (press PLAY to start)".format(
				trackNum + 1,
				track.audioBus.index
			).postln;

			track;
		},

		// Free a specific track
		freeTrack: { arg self, trackNum;
			var track = tracks[trackNum];

			if(track.grainSynth.notNil, {
				track.grainSynth.free;
				track.grainSynth = nil;
			});

			// Phase 8: Free spectral synth
			if(track.spectralSynth.notNil, {
				track.spectralSynth.free;
				track.spectralSynth = nil;
			});

			// Phase 15: Free direct playback synth
			if(track.directPlaybackSynth.notNil, {
				track.directPlaybackSynth.free;
				track.directPlaybackSynth = nil;
			});

			if(track.recorder.notNil, {
				track.recorder.free;
				track.recorder = nil;
			});

			if(track.audioBus.notNil, {
				track.audioBus.free;
				track.audioBus = nil;
			});

			// Phase 17: Free spectral capture buffer and recorder
			if(track.spectralCaptureBuffer.notNil, {
				track.spectralCaptureBuffer.free;
				track.spectralCaptureBuffer = nil;
			});

			if(track.spectralCaptureRecorder.notNil, {
				track.spectralCaptureRecorder.free;
				track.spectralCaptureRecorder = nil;
			});

			"Track manager: Track % freed".format(trackNum + 1).postln;
		},

		// Set a parameter on a specific track
		// Set a parameter on a specific track - SAFE VERSION (No Non-Local Returns)
	setParam: { arg self, trackNum, param, value;
		var track = tracks[trackNum];
		var spectralParams = [\spectralMix, \spectralPosition, \spectralRate,
		                       \spectralWindowSize, \spectralOverlaps, \spectralPitch,
		                       \spectralFreeze, \spectralSmear, \spectralAmp,
		                       \loopStart, \loopEnd]; // BUG FIX: Route loop boundaries to spectral
		var directPlaybackParams = [\position, \loopStart, \loopEnd, \amp, \pan, \pitch, \rate, \timeStretch,
	                             \wowRate, \wowDepth, \flutterRate, \flutterDepth];
		var synthParam;
		var handled = false; // Flow control flag

		// Early exit for uninitialized track (no ^ return - breaks try/catch)
		if(track.grainSynth.isNil, {
			"Track manager: Track % not initialized".format(trackNum + 1).postln;
		}, {

		// Phase 16: Pitch quantization logic
		if((param == \pitch or: { param == \pitchShift or: { param == \spectralPitch }}) and: {
			track.params[\quantizePitch] == 1
		}, {
			var scale = track.params[\scale] ? [0, 2, 4, 5, 7, 9, 11];
			var roundedPitch = value.round;
			var octave = (roundedPitch / 12).floor * 12;
			var degree = roundedPitch % 12;
			var nearestDegree = scale.minItem({ |deg| (degree - deg).abs });
			value = octave + nearestDegree;
			"Track %: Quantized pitch % to scale degree %".format(trackNum + 1, param, value).postln;
		});

		// Update stored parameter
		track.params[param] = value;

		// --- SPECIAL PARAMETER HANDLING (Using 'handled' flag instead of ^return) ---

		// 1. ENGINE MIX (Smart Sleep)
		if(param == \engineMix, {
			var granAmp, directAmp, baseAmp;
			var grainEnabled = track.params[\grainOn] ? 1;
			var directEnabled = track.params[\directOn] ? 1;

			granAmp = if(value > 0.999, { 0.0 }, { (1 - value).sqrt });
			directAmp = if(value < 0.001, { 0.0 }, { value.sqrt });

			if(track.grainSynth.notNil, {
				var shouldRun = (value < 0.999) and: { grainEnabled == 1 };
				track.grainSynth.run(shouldRun);
			});
			if(track.directPlaybackSynth.notNil, {
				var shouldRun = (value > 0.001) and: { directEnabled == 1 };
				track.directPlaybackSynth.run(shouldRun);
			});

			baseAmp = track.params[\amp] ? 0.5;
			if(track.grainSynth.notNil, { track.grainSynth.set(\amp, baseAmp * granAmp) });
			if(track.directPlaybackSynth.notNil, { track.directPlaybackSynth.set(\amp, baseAmp * directAmp) });

			handled = true;
		});

		// 2. EXPLICIT ON/OFF TOGGLES
		if(handled.not and: { (param == \grainOn) or: { param == \directOn } }, {
			self.setParam(trackNum, \engineMix, track.params[\engineMix]);
			handled = true;
		});

		// 3. SPECTRAL ON/OFF
		if(handled.not and: { param == \spectralOn }, {
			if(track.spectralSynth.notNil, {
				track.spectralSynth.run(value == 1);
			});
			handled = true;
		});

		// 4. STANDARD PARAMETER ROUTING (If not handled above)
		// v2.2.1 FIX: Route to ALL synths that accept the parameter (not mutually exclusive)
		if(handled.not, {
			// Spectral Routing
			if(spectralParams.includes(param), {
				if(track.spectralSynth.notNil, {
					synthParam = param.asString.replace("spectral", "").toLower.asSymbol;
					if(param == \spectralMix, { synthParam = \spectralMix });
					if(param == \spectralPosition, { synthParam = \position });
					if(param == \spectralRate, { synthParam = \rate });
					if(param == \spectralWindowSize, { synthParam = \windowSize });
					if(param == \spectralOverlaps, { synthParam = \overlaps });
					if(param == \spectralPitch, { synthParam = \pitch });
					if(param == \spectralFreeze, { synthParam = \freeze });
					if(param == \spectralSmear, { synthParam = \smear });
					if(param == \spectralAmp, { synthParam = \amp });
					// Route loop boundaries directly (no prefix change)
					if(param == \loopStart, { synthParam = \loopStart });
					if(param == \loopEnd, { synthParam = \loopEnd });
					track.spectralSynth.set(synthParam, value);
				});
			});

			// Grain Routing (NOT else - loopStart/loopEnd go to ALL engines)
			if(track.grainSynth.notNil, {
				track.grainSynth.set(param, value);
			});

			// Direct Playback Routing
			if(directPlaybackParams.includes(param), {
				if(track.directPlaybackSynth.notNil, {
					track.directPlaybackSynth.set(param, value);
				});
			});
		});

		}); // Close the if(track.grainSynth.isNil) else block

		self; // Return self at the end
	},
		// Set material mode (Phase 6: 0=TAPE, 1=POLY, 2=LIVE)
		setMode: { arg self, trackNum, newMode;
			var track = tracks[trackNum];
			var modeNames = ["TAPE", "POLY", "LIVE"];

			if(track.grainSynth.isNil, {
				"Track manager: Track % not initialized".format(trackNum + 1).postln;
				^nil;
			});

			// Validate mode
			if((newMode < 0) or: { newMode > 2 }, {
				"Track manager: Invalid mode %. Must be 0 (TAPE), 1 (POLY), or 2 (LIVE)".format(newMode).postln;
				^nil;
			});

			// Update mode
			track.mode = newMode;
			track.grainSynth.set(\grainMode, newMode);  // v2.1: renamed to grainMode

			"Track %: Mode set to % (%)".format(trackNum + 1, newMode, modeNames[newMode]).postln;
		},

		// Get current mode
		getMode: { arg self, trackNum;
			var track = tracks[trackNum];
			track.mode;
		},

		// Set track volume (also updates master bus)
		setVolume: { arg self, trackNum, vol;
			var track = tracks[trackNum];
			var paramName;

			track.volume = vol.clip(0, 1);

			// Update master bus if it exists
			if(masterBus.notNil, {
				paramName = ("track" ++ (trackNum + 1) ++ "Vol").asSymbol;
				masterBus.set(paramName, track.volume);
			});
		},

		// Set track pan (also updates master bus)
		setPan: { arg self, trackNum, pan;
			var track = tracks[trackNum];
			var paramName;

			track.pan = pan.clip(-1, 1);

			// Update master bus if it exists
			if(masterBus.notNil, {
				paramName = ("track" ++ (trackNum + 1) ++ "Pan").asSymbol;
				masterBus.set(paramName, track.pan);
			});
		},

		// Phase 12: Set quad position (X/Y coordinates for quad speaker output)
		setQuadPosition: { arg self, trackNum, x, y;
			var track = tracks[trackNum];
			var xParamName, yParamName;

			// Store quad position in track
			track.quadX = x.clip(-1, 1);
			track.quadY = y.clip(-1, 1);

			// Update quad master bus if it exists
			if(masterBus.notNil, {
				xParamName = ("track" ++ (trackNum + 1) ++ "X").asSymbol;
				yParamName = ("track" ++ (trackNum + 1) ++ "Y").asSymbol;
				masterBus.set(xParamName, track.quadX, yParamName, track.quadY);
			});
		},

		// Set track mute (also updates master bus)
		setMute: { arg self, trackNum, mute;
			var track = tracks[trackNum];
			var paramName;

			track.mute = mute.asBoolean;

			// If any track is solo'd, don't change mute state
			// (solo logic overrides)
			if(tracks.any({ |t| t.solo }), {
				"Track manager: Solo active, use setSolo to change".postln;
				^nil;
			});

			// Update master bus if it exists
			if(masterBus.notNil, {
				paramName = ("track" ++ (trackNum + 1) ++ "Mute").asSymbol;
				masterBus.set(paramName, track.mute.asInteger);
			});
		},

		// Set track solo (implements solo logic)
		setSolo: { arg self, trackNum, solo;
			var track = tracks[trackNum];
			var anySolo;

			track.solo = solo.asBoolean;

			// Check if ANY track is now solo'd
			anySolo = tracks.any({ |t| t.solo });

			if(masterBus.notNil, {
				if(anySolo, {
					// Solo mode: mute all non-solo tracks
					tracks.do({ |t, i|
						var shouldMute = t.solo.not;
						var paramName = ("track" ++ (i + 1) ++ "Mute").asSymbol;
						masterBus.set(paramName, shouldMute.asInteger);
					});
					"Track manager: Solo mode active".postln;
				}, {
					// No solo: restore original mute states
					tracks.do({ |t, i|
						var paramName = ("track" ++ (i + 1) ++ "Mute").asSymbol;
						masterBus.set(paramName, t.mute.asInteger);
					});
					"Track manager: Solo mode deactivated".postln;
				});
			});
		},

		// Get tracks array
		getTracks: {
			tracks;
		},

		// Get a specific track
		getTrack: { arg self, trackNum;
			tracks[trackNum];
		},

		// Set master bus reference (called from main.scd)
		setMasterBus: { arg self, bus;
			masterBus = bus;
			"Track manager: Master bus reference set".postln;
		},

		// === PHASE 5: MODULATION SYSTEM ===

		// Create a modulator for a track
		createModulator: { arg self, trackNum, modNum, type = 0, rate = 1.0, depth = 1.0, shape = 0;
			var track, sourceTrack, audioInBus;
			track = tracks[trackNum];

			if(trackNum < 0 or: { trackNum > 3 }, {
				"Track manager: Invalid track number %".format(trackNum).postln;
				^nil;
			});

			if(modNum < 0 or: { modNum > 3 }, {
				"Track manager: Invalid modulator number %".format(modNum).postln;
				^nil;
			});

			// Free existing modulator if it exists
			if(track.modulators[modNum].notNil, {
				track.modulators[modNum].free;
				track.modulators[modNum] = nil;
			});

			// Phase 13: Allocate AUDIO bus for audio-rate modulation
			if(track.modBusses[modNum].isNil, {
				track.modBusses[modNum] = Bus.audio(server, 1);
			});

			// Create modulator synth in modGroup (Phase 13: execution order)
			// Phase 16: MOSAIC MODE - Get source track for envelope follower
			sourceTrack = tracks[track.modSourceTracks[modNum]];
			audioInBus = if(sourceTrack.notNil, { sourceTrack.audioBus.index }, { track.audioBus.index });

			track.modulators[modNum] = ~bearulatorModulator.value(server).create(
				type,
				track.modBusses[modNum].index,
				rate,
				depth,
				shape,
				audioInBus,  // Phase 16: Can be from ANY track (cross-modulation)
				track.modGroup  // Phase 13: Place in modGroup
			);

			"Track %: Modulator % created (type: %, bus: %)".format(
				trackNum + 1,
				modNum + 1,
				type,
				track.modBusses[modNum].index
			).postln;

			track.modulators[modNum];
		},

		// Route modulator to parameter
		routeModulator: { arg self, trackNum, modNum, targetParam, minVal, maxVal;
			var track = tracks[trackNum];
			var trackMgr = this;

			// Auto-create modulator if it doesn't exist (Phase 15.5 bugfix)
			if(track.modulators[modNum].isNil, {
				"Track %: Modulator % not created, creating with defaults...".format(trackNum + 1, modNum + 1).postln;
				self.createModulator(trackNum, modNum, 0, 1.0, 1.0, 0);  // LFO, 1Hz, full depth, sine
			});

			// Store routing info
			track.modTargets[modNum] = targetParam;
			track.modRanges[modNum] = (min: minVal, max: maxVal);

			// Free old mapper if exists
			if(track.modMappers[modNum].notNil, {
				var mapper = track.modMappers[modNum];
				// Safe access to the Event returned by createMapper
				if(mapper[\synth].notNil, { mapper[\synth].free });
				if(mapper[\bus].notNil, { mapper[\bus].free });
				track.modMappers[modNum] = nil;
			});

			// Phase 13: Special handling for spatial modulation (quadX/quadY)
			if((targetParam == \quadX) or: { targetParam == \quadY }, {
				var spatialSynth;

				// Create synth that reads modulation and updates quad position
				spatialSynth = {
					arg modBus, minVal, maxVal;
					var modValue = In.ar(modBus, 1);
					var scaled = modValue.linlin(0, 1, minVal, maxVal);

					// Send position updates via OSC (20Hz to avoid flooding)
					SendTrig.kr(Impulse.kr(20), 0, scaled);
				}.play(server, [
					\modBus, track.modBusses[modNum].index,
					\minVal, minVal,
					\maxVal, maxVal
				], addAction: \addToTail);

				// Register OSC responder to update quad position
				OSCdef(("spatialMod_" ++ trackNum ++ "_" ++ modNum).asSymbol, { arg msg;
					var value = msg[3];  // ['/tr', nodeID, trigID, value]
					{
						if(targetParam == \quadX, {
							trackMgr.setQuadPosition(trackNum, value, track.quadY ? 0);
						}, {
							trackMgr.setQuadPosition(trackNum, track.quadX ? 0, value);
						});
					}.defer;
				}, '/tr', server.addr);

				track.modMappers[modNum] = (synth: spatialSynth, bus: nil);

				"Track %: Mod % → SPATIAL % (range: % to %)".format(
					trackNum + 1,
					modNum + 1,
					targetParam,
					minVal,
					maxVal
				).postln;
			}, {
				// Normal synth parameter mapping
				track.modMappers[modNum] = ~bearulatorModulator.value(server).createMapper(
					track.modBusses[modNum].index,
					track.modulators[modNum],  // Pass modulator synth for order-of-execution
					track.grainSynth,
					targetParam,
					minVal,
					maxVal,
					track.modGroup  // Phase 13: Place in modGroup
				);

				"Track %: Mod % → % (range: % to %)".format(
					trackNum + 1,
					modNum + 1,
					targetParam,
					minVal,
					maxVal
				).postln;
			});
		},

		// Phase 15: Route modulator to MASTER BUS parameter
		routeModulatorToMaster: { arg self, trackNum, modNum, targetParam, minVal, maxVal;
			var track = tracks[trackNum];
			var paramName;

			if(track.modulators[modNum].isNil, {
				"Track %: Modulator % not created yet".format(trackNum + 1, modNum + 1).postln;
				^nil;
			});

			// Store routing info
			track.modTargets[modNum] = targetParam;
			track.modRanges[modNum] = (min: minVal, max: maxVal);

			// Free old mapper if exists
			if(track.modMappers[modNum].notNil, {
				var mapper = track.modMappers[modNum];
				if(mapper[\synth].notNil, { mapper[\synth].free });
				if(mapper[\bus].notNil, { mapper[\bus].free });
				track.modMappers[modNum] = nil;
			});

			// Map master parameter name to actual master bus param
			paramName = targetParam.asString.replace("master", "").asSymbol;

			// Create mapper that routes to master bus
			track.modMappers[modNum] = ~bearulatorModulator.value(server).createMapper(
				track.modBusses[modNum].index,
				track.modulators[modNum],
				masterBus,  // Target is master bus instead of track synth
				paramName,  // e.g., \filterFreq, \filterMorph
				minVal,
				maxVal,
				track.modGroup
			);

			"Track %: Mod % → MASTER % (range: % to %)".format(
				trackNum + 1,
				modNum + 1,
				paramName,
				minVal,
				maxVal
			).postln;
		},

		// Phase 16: MOSAIC MODE - Set source track for envelope follower
		setModSourceTrack: { arg self, trackNum, modNum, sourceTrackNum;
			var track = tracks[trackNum];

			if(trackNum < 0 or: { trackNum > 3 }, {
				"Track manager: Invalid track number %".format(trackNum).postln;
				^nil;
			});

			if(sourceTrackNum < 0 or: { sourceTrackNum > 3 }, {
				"Track manager: Invalid source track number %".format(sourceTrackNum).postln;
				^nil;
			});

			// Store the source track number
			track.modSourceTracks[modNum] = sourceTrackNum;

			// If modulator already exists, recreate it with new source
			if(track.modulators[modNum].notNil, {
				var type, rate, depth, shape;
				// Get current settings (we'll need to query the synth or store them)
				// For now, just recreate with defaults
				"Track %: Mod % now listening to Track %".format(
					trackNum + 1,
					modNum + 1,
					sourceTrackNum + 1
				).postln;
				"  → Recreate modulator to apply change".postln;
			});
		},

		// Update modulator parameter
		setModParam: { arg self, trackNum, modNum, param, value;
			var track = tracks[trackNum];

			if(track.modulators[modNum].notNil, {
				track.modulators[modNum].set(param, value);
			}, {
				"Track %: Modulator % not active".format(trackNum + 1, modNum + 1).postln;
			});
		},

		// Free a modulator
		freeModulator: { arg self, trackNum, modNum;
			var track = tracks[trackNum];
			var mapper;

			if(track.modulators[modNum].notNil, {
				track.modulators[modNum].free;
				track.modulators[modNum] = nil;
			});

			if(track.modMappers[modNum].notNil, {
				mapper = track.modMappers[modNum];
				// Safe access to the Event returned by createMapper
				if(mapper[\synth].notNil, { mapper[\synth].free });
				if(mapper[\bus].notNil, { mapper[\bus].free });
				track.modMappers[modNum] = nil;
			});

			track.modTargets[modNum] = nil;

			"Track %: Modulator % freed".format(trackNum + 1, modNum + 1).postln;
		},

		// CORE LOGIC: RECYCLE TRACK (Reset to Init State)
		// Makes the track feel "new" by killing audio glitches immediately,
		// then restoring factory defaults. This is the "Source of Truth" for
		// default parameter values - update here when changing defaults.
		// CORE LOGIC: RECYCLE TRACK (Reset to Init State) - VERBOSE DEBUG
		resetParams: { arg self, trackNum;
			var track = tracks[trackNum];
			var defaults;

			"--- DEBUG: resetParams called for Track % ---".format(trackNum + 1).postln;

			if(track.grainSynth.isNil, {
				"ERROR: Track % grainSynth is nil".format(trackNum + 1).postln;
				^nil;
			});

			// 1. HARD RESET AUDIO
			"DEBUG: 1. Engaging Audio Kill Switches...".postln;
			if(track.grainSynth.notNil) {
				try {
					track.grainSynth.set(
						\pitch, 0, \pitchShift, 0,
						\timeStretch, 1.0, \scanSpeed, 0,
						\delayFeedback, 0.0,
						\reverbFreeze, 0,
						\shimmerFeedback, 0.0,
						\feedback, 0.0, \posJitter, 0.1, \pitchJitter, 0.0,
						\grainSize, 0.1
					);
					"DEBUG:    > Audio killed successfully".postln;
				} { |err|
					"ERROR: Failed during Audio Kill Switch".postln;
					err.errorString.postln;
				};
			};

			// 2. RESTORE FACTORY DEFAULTS
			"DEBUG: 2. Restoring Default Parameters...".postln;

			defaults = [
				[\amp, 0.5], [\pan, 0],
				[\grainSize, 0.1], [\density, 30], [\overlap, 1], [\useOverlap, 1],
				[\prob, 1.0], [\loFiGrains, 0],  // v2.2 & v2.3 additions
				[\pitch, 0], [\pitchShift, 0], [\timeStretch, 1.0],
				[\scanSpeed, 0], [\position, 0.0],
				[\posJitter, 0.1], [\pitchJitter, 0.0],
				// Note: Arrays like posSeq might be tricky, watch these
				[\posSeq, Array.fill(64, 0)], [\pitchSeq, Array.fill(64, 0)],
				[\grainMode, 0], [\engineMix, 0.0],
				[\filterOn, 0], [\colorOn, 0], [\spaceOn, 0],
				[\spectralMix, 0.0], [\spectralPosition, 0.5], [\spectralRate, 1.0],
				[\spectralWindowSize, 0.1], [\spectralOverlaps, 4],
				[\spectralPitch, 0], [\spectralFreeze, 0], [\spectralSmear, 0],
				[\loopStart, 0.0], [\loopEnd, 1.0],
				[\envType, 1], [\stereoSpread, 0.5],
				[\scale, [0, 2, 4, 5, 7, 9, 11]], [\quantizePitch, 0]
			];

			"DEBUG: About to process % parameters...".format(defaults.size).postln;

			defaults.do({ |pair, i|
				// UNCOMMENTED DEBUG LINE:
				"DEBUG:    [%] Setting % ...".format(i, pair[0]).postln;

				try {
					self.setParam(trackNum, pair[0], pair[1]);
					"DEBUG:       > OK".postln;
				} { |err|
					"!!! CRASH ON PARAMETER: % !!!".format(pair[0]).postln;
					"ERROR: %".format(err.errorString).postln;
				};
			});

			"DEBUG: Loop complete. About to print final message...".postln;
			"✓ DEBUG: Track % reset complete.".format(trackNum + 1).postln;
			"-------------------------------------------".postln;
		},

		// HYBRID ENGINE: Clear track (wipe buffer, reset params, stop synths)
		clearTrack: { arg self, trackNum;
			var track = tracks[trackNum];

			if(track.grainSynth.isNil, {
				"Track manager: Track % not initialized".format(trackNum + 1).postln;
				^nil;
			});

			// Stop all synths
			track.grainSynth.run(false);
			track.directPlaybackSynth.run(false);
			track.spectralSynth.run(false);

			// Zero the buffer (silent)
			if(track.recorder.buffer.notNil, {
				track.recorder.buffer.zero;
			});

			// Reset all params to defaults
			self.resetParams(trackNum);

			"✓ Track % cleared (buffer wiped, params reset, synths stopped)".format(trackNum + 1).postln;
		},

		// Phase 15: Switch between stereo and quad master buses
		setMasterBusMode: { arg self, mode;
			var oldMasterBus = masterBus;
			var filterState, trackState;

			if(masterBus.isNil, {
				"Track manager: No master bus to switch".warn;
				^nil;
			});

			// Capture current filter state
			filterState = (
				filterOn: 0,  // Will be set by user
				filterFreq: 200,
				filterMorph: 0.5,
				filterRes: 0.5,
				filterDecay: 0.5,
				filterAnimate: 0,
				filterAnimRate: 0.5,
				filterMix: 0.5,
				masterVol: 0.8
			);

			// Capture track volumes, pans, mutes
			trackState = tracks.collect({ |track, i|
				(
					volume: track.volume,
					pan: track.pan,
					mute: track.mute,
					quadX: track.quadX ? 0,
					quadY: track.quadY ? 0
				);
			});

			// Free old master bus
			fork {
				"Switching master bus mode...".postln;

				if(oldMasterBus.notNil, {
					oldMasterBus.free;
					0.2.wait;
				});

				// Create new master bus based on mode
				if(mode == 0, {
					// STEREO MODE
					masterBus = Synth(\bearulatorMasterBus, [
						\track1Bus, tracks[0].audioBus.index,
						\track2Bus, tracks[1].audioBus.index,
						\track3Bus, tracks[2].audioBus.index,
						\track4Bus, tracks[3].audioBus.index,
						\out, 0
					] ++ filterState.asPairs, addAction: \addToTail);

					"✓ Switched to STEREO mode (2-channel output)".postln;
				}, {
					// QUAD MODE
					masterBus = Synth(\bearulatorMasterBusQuad, [
						\track1Bus, tracks[0].audioBus.index,
						\track2Bus, tracks[1].audioBus.index,
						\track3Bus, tracks[2].audioBus.index,
						\track4Bus, tracks[3].audioBus.index,
						\out, 0
					] ++ filterState.asPairs, addAction: \addToTail);

					"✓ Switched to QUAD mode (4-channel output)".postln;
				});

				0.1.wait;

				// Restore track states
				trackState.do({ |state, i|
					var track = tracks[i];
					var volParam = ("track" ++ (i + 1) ++ "Vol").asSymbol;
					var muteParam = ("track" ++ (i + 1) ++ "Mute").asSymbol;

					masterBus.set(volParam, state.volume);
					masterBus.set(muteParam, state.mute.asInteger);

					if(mode == 0, {
						// Stereo: restore pan
						var panParam = ("track" ++ (i + 1) ++ "Pan").asSymbol;
						masterBus.set(panParam, state.pan);
					}, {
						// Quad: restore X/Y position
						var xParam = ("track" ++ (i + 1) ++ "X").asSymbol;
						var yParam = ("track" ++ (i + 1) ++ "Y").asSymbol;
						masterBus.set(xParam, state.quadX);
						masterBus.set(yParam, state.quadY);
					});
				});

				// Refresh quad panner positions if in quad mode
				if((mode == 1) and: { ~quadPanner.notNil }, {
					trackState.do({ |state, i|
						publicAPI.setQuadPosition(i, state.quadX, state.quadY);
					});
					"✓ Quad panner positions refreshed".postln;
				});
			};
		},

		// Load sample from file path (convenience function for examples/tests)
		loadSample: { arg self, trackNum, filePath;
			var track, absolutePath;
			track = tracks[trackNum];

			if(track.grainSynth.isNil, {
				"Track manager: Track % not initialized".format(trackNum + 1).postln;
				^nil;
			});

			// Convert relative path to absolute
			absolutePath = if(filePath.beginsWith("/"), {
				filePath;  // Already absolute
			}, {
				// Relative to granular/ directory
				PathName(thisProcess.nowExecutingPath).pathOnly.dirname +/+ filePath;
			});

			// Check file exists
			if(File.exists(absolutePath).not, {
				"Track manager: File not found: %".format(absolutePath).error;
				^nil;
			});

			fork {
				// Stop synths to prevent clicks
				if(track.grainSynth.notNil, { track.grainSynth.run(false) });
				if(track.spectralSynth.notNil, { track.spectralSynth.run(false) });
				if(track.directPlaybackSynth.notNil, { track.directPlaybackSynth.run(false) });

				// Free old buffer
				track.recorder.buffer.free;

				// Load new buffer
				track.recorder.buffer = Buffer.readChannel(server, absolutePath, channels: [0]);
				track.filePath = absolutePath;

				// Wait for buffer to load
				server.sync;

				// Update synth buffer numbers
				if(track.grainSynth.notNil, {
					track.grainSynth.set(\bufnum, track.recorder.buffer.bufnum);
					track.grainSynth.run(true);
				});

				if(track.spectralSynth.notNil, {
					track.spectralSynth.set(\bufnum, track.recorder.buffer.bufnum);
					track.spectralSynth.run(true);
				});

				if(track.directPlaybackSynth.notNil, {
					track.directPlaybackSynth.set(\bufnum, track.recorder.buffer.bufnum);
					track.directPlaybackSynth.run(true);
				});

				"✓ Track %: Loaded %".format(trackNum + 1, PathName(absolutePath).fileName).postln;
			};
		},

		// Phase 17: Capture spectral engine output
		captureSpectral: { arg self, trackNum;
			var track = tracks[trackNum];

			if(track.spectralSynth.isNil, {
				"Track %: No spectral engine to capture".format(trackNum + 1).warn;
				^nil;
			});

			if(track.spectralCaptureStatus == \capturing, {
				"Track %: Already capturing".format(trackNum + 1).warn;
				^nil;
			});

			// Clear previous capture
			track.spectralCaptureBuffer.zero;

			// Update status
			track.spectralCaptureStatus = \capturing;

			// Create recorder synth (reads from track's audio bus)
			track.spectralCaptureRecorder = Synth(\spectralCapture, [
				\inBus, track.audioBus.index,
				\captureBuffer, track.spectralCaptureBuffer
			], track.instrumentGroup, \addAfter);

			// Register completion callback
			OSCdef(("spectralCaptureDone_" ++ trackNum).asSymbol, { arg msg;
				{
					track.spectralCaptureStatus = \captured;
					"✓ Track %: Spectral capture complete (4 seconds)!".format(trackNum + 1).postln;
				}.defer;
			}, '/spectralCaptureDone');

			"Track %: Capturing spectral output (4 seconds)...".format(trackNum + 1).postln;
			this;
		},

		// Phase 17: Load captured spectral buffer to target track
		loadCapturedSpectral: { arg self, sourceTrack, targetTrack;
			var source = tracks[sourceTrack];
			var target = tracks[targetTrack];
			var tempFilePath;

			if(source.spectralCaptureStatus != \captured, {
				"Track %: No captured spectral data (status: %)".format(
					sourceTrack + 1,
					source.spectralCaptureStatus
				).warn;
				^nil;
			});

			fork {
				// 1. Stop target synths to prevent clicks
				if(target.grainSynth.notNil, { target.grainSynth.run(false) });
				if(target.spectralSynth.notNil, { target.spectralSynth.run(false) });
				if(target.directPlaybackSynth.notNil, { target.directPlaybackSynth.run(false) });

				// 2. Free old buffer
				target.recorder.buffer.free;
				server.sync;

				// 3. Allocate new buffer matching capture size
				target.recorder.buffer = Buffer.alloc(server, source.spectralCaptureBuffer.numFrames, 2);
				server.sync;

				// 4. Copy RAM data (fast)
				source.spectralCaptureBuffer.copyData(target.recorder.buffer);
				server.sync;

				// 5. WRITE TO TEMP FILE (The Fix - enables waveform display)
				// Consistent with buffer-recorder.scd naming convention
				tempFilePath = PathName.tmp +/+ "bearulator_spectral_t%_%.wav".format(
					targetTrack + 1,
					Date.getDate.stamp
				);

				target.recorder.buffer.write(tempFilePath, "WAV", "int16");
				server.sync; // CRITICAL: Wait for file write to finish

				// 6. Update track state
				target.filePath = tempFilePath;
				target.recorder.tempFilePath = tempFilePath; // Keep recorder in sync

				// 7. Update synth buffer references
				if(target.grainSynth.notNil, {
					target.grainSynth.set(\bufnum, target.recorder.buffer.bufnum);
					target.grainSynth.run(true);
				});

				if(target.spectralSynth.notNil, {
					target.spectralSynth.set(\bufnum, target.recorder.buffer.bufnum);
					target.spectralSynth.run(true);
				});

				if(target.directPlaybackSynth.notNil, {
					target.directPlaybackSynth.set(\bufnum, target.recorder.buffer.bufnum);
					target.directPlaybackSynth.run(true);
				});

				// 8. Update GUI (Must be deferred)
				{
					if(~viewfinder.notNil, {
						~viewfinder.updateWaveform(targetTrack);
					});

					"✓ Track %: Loaded spectral capture from Track % (4 sec)".format(
						targetTrack + 1,
						sourceTrack + 1
					).postln;

					// Reset capture status
					source.spectralCaptureStatus = \ready;
				}.defer;
			};
		},

		// Free all tracks
		free: {
			tracks.do({ |track, i|
				publicAPI.freeTrack(i);
			});
			"Track manager: All tracks freed".postln;
		}
	);

	publicAPI;
};

/*
Usage example:

// Create track manager
~trackManager = ~bearulatorTrackManager.value(s);
~trackManager.init;

// Create 4 tracks
4.do({ |i|
    ~trackManager.createTrack(i);
});

// Set parameters on track 1
~trackManager.setParam(0, \grainSize, 0.05);
~trackManager.setParam(0, \density, 50);

// Control track 2 volume/pan
~trackManager.setVolume(1, 0.6);
~trackManager.setPan(1, -0.5);

// Mute track 3
~trackManager.setMute(2, true);

// Solo track 4 (mutes all others)
~trackManager.setSolo(3, true);

// Unsolo
~trackManager.setSolo(3, false);

// Get track for direct access
~myTrack = ~trackManager.getTrack(0);
~myTrack.grainSynth.set(\amp, 0.8);

// Cleanup
~trackManager.free;
*/
