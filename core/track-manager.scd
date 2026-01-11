/*
S-4 Rival: Track Manager
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

~s4TrackManager = { arg server;
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
			track.recorder = ~s4BufferRecorder.value(server);
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

			// Default parameters for grain synth
			defaultParams = (
				// Grain parameters
				grainMode: 0,  // Phase 6: Default to TAPE mode (v2.1: renamed from mode)
				engineMix: 0.0,  // HYBRID ENGINE: 0.0=Granular, 1.0=Direct, 0.5=Equal mix
				scale: [0, 2, 4, 5, 7, 9, 11],  // Phase 16: Major scale (MIDI note offsets)
				quantizePitch: 0,  // Phase 16: Enable pitch quantization (0=off, 1=on)
				grainSize: 0.1,
				density: 30,      // Legacy parameter
				overlap: 1,       // Phase 6b: Default overlap count (1 = full sample playback)
				useOverlap: 1,    // Phase 6b: Use overlap mode by default
				prob: 1.0,        // v2.2: Probability mask (1.0 = 100% grain density)
				position: 0.0,    // Default to start of buffer
				scanSpeed: 0,     // Phase 7c: Continuous scanning (0=static)
				timeStretch: 1.0, // Phase 15: Master time stretch (1.0 = normal)
				pitch: 0,         // Legacy: changes speed+pitch
				pitchShift: 0,    // Phase 7: True pitch shift (preserves speed)
				posJitter: 0.1,
				pitchJitter: 0,
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
				filterFreq: 200,
				filterMorph: 0.5,
				filterRes: 0.5,
				filterDecay: 0.5,
				filterAnimate: 0,
				filterAnimRate: 0.5,
				filterTuning: 0,
				filterSpread: 1.5,
				filterMix: 0.5,

				// Color effects (default off)
				colorOn: 0,
				distCrossover: 500,
				distLoDrive: 1,
				distHiDrive: 1,
				distMix: 0,
				crushRate: 8000,
				crushBits: 8,
				crushMix: 0,
				compThresh: 0.5,
				compRatio: 4,
				compAttack: 0.01,
				compRelease: 0.1,
				noiseType: 0,
				noiseAmount: 0,

				// Space effects (default off)
				spaceOn: 0,
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
				spectralWindowSize: 0.2, // Window size (0.05-1.0, larger=more smear)
				spectralOverlaps: 4,   // Overlap factor (1-8, M4 can handle 8)
				spectralPitch: 0,      // Pitch shift (-24 to +24)
				spectralFreeze: 0,     // Freeze toggle (1=freeze)
				spectralSmear: 0       // Spectral smear (0-1)
			);

			track.params = defaultParams.copy;

			// Create grain synth with parameters (STOPPED by default)
			// Phase 13: Place in instrumentGroup (runs AFTER modGroup)
			track.grainSynth = Synth(\s4GrainEngine, [
				\out, track.audioBus.index,
				\bufnum, track.recorder.getBufferNum
			] ++ track.params.asPairs, track.instrumentGroup);

			// Phase 15.5: Grain synth stays RUNNING but with amp controlled by engineMode
			// Start in GRANULAR mode (engineMode=0), so grain has full amp, direct has zero
			track.grainSynth.set(\amp, track.params[\amp]);

			// Phase 8: Create spectral synth (Warp1) - runs in parallel
			track.spectralSynth = Synth(\s4SpectralEngine, [
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
			track.directPlaybackSynth = Synth(\s4DirectPlayback, [
				\out, track.audioBus.index,
				\bufnum, track.recorder.getBufferNum,
				\rate, 1.0,
				\position, track.params[\position],
				\loop, 1,
				\loopStart, track.params[\loopStart],
				\loopEnd, track.params[\loopEnd],
				\amp, track.params[\amp],
				\pan, track.params[\pan],
				\pitch, track.params[\pitch]
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

			"Track manager: Track % freed".format(trackNum + 1).postln;
		},

		// Set a parameter on a specific track
		setParam: { arg self, trackNum, param, value;
			var track = tracks[trackNum];
			var spectralParams = [\spectralMix, \spectralPosition, \spectralRate,
			                       \spectralWindowSize, \spectralOverlaps, \spectralPitch,
			                       \spectralFreeze, \spectralSmear, \spectralAmp];
			var directPlaybackParams = [\position, \loopStart, \loopEnd, \amp, \pan, \pitch, \rate, \timeStretch];
			var synthParam;  // For spectral parameter mapping
			var wasPlaying;  // For engine mode switching

			if(track.grainSynth.isNil, {
				"Track manager: Track % not initialized".format(trackNum + 1).postln;
				^nil;
			});

			// Phase 16: Pitch quantization to musical scales
			if((param == \pitch or: { param == \pitchShift or: { param == \spectralPitch }}) and: {
				track.params[\quantizePitch] == 1
			}, {
				var scale = track.params[\scale] ? [0, 2, 4, 5, 7, 9, 11];
				var roundedPitch = value.round;
				var octave = (roundedPitch / 12).floor * 12;
				var degree = roundedPitch % 12;
				var nearestDegree;

				// Find nearest scale degree
				nearestDegree = scale.minItem({ |deg|
					(degree - deg).abs
				});

				// Quantize to nearest scale degree
				value = octave + nearestDegree;
				"Track %: Quantized pitch % to scale degree %".format(
					trackNum + 1, param, value
				).postln;
			});

			// Update stored parameter
			track.params[param] = value;

			// HYBRID ENGINE: Continuous crossfade between Granular and Direct
			// NOTE: Knob only adjusts amplitude, does NOT start/stop engines
			// Engines are controlled ONLY by PLAY/STOP buttons in viewfinder
			if(param == \engineMix, {
				var granAmp, directAmp, baseAmp;  // All vars at top

				case
					{ value <= 0.01 } {  // Pure GRANULAR (0.0)
						granAmp = 1.0;
						directAmp = 0.0;
					}
					{ value >= 0.99 } {  // Pure DIRECT (1.0)
						granAmp = 0.0;
						directAmp = 1.0;
					}
					{ true } {  // MIX MODE (0.01-0.99) - Equal-power crossfade
						// Equal-power crossfade law (constant energy)
						granAmp = (1 - value).sqrt;  // Full at 0.0, silent at 1.0
						directAmp = value.sqrt;      // Silent at 0.0, full at 1.0
					};

				// Apply amplitude scaling to both engines (silently - no console spam)
				baseAmp = track.params[\amp] ? 0.5;
				track.grainSynth.set(\amp, baseAmp * granAmp);
				track.directPlaybackSynth.set(\amp, baseAmp * directAmp);

				^this;  // Done, don't send to synths again
			});


			// Phase 8: Route spectral parameters to spectral synth
			if(spectralParams.includes(param), {
				if(track.spectralSynth.notNil, {
					// Map spectralMix → spectralMix, spectralPosition → position, etc.
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
					track.spectralSynth.set(synthParam, value);
				});
			}, {
				// Non-spectral parameters: ALWAYS send to ALL engines
				// This ensures parameters update even when engine is paused

				// Send to grain synth (always update, even if paused)
				if(track.grainSynth.notNil, {
					track.grainSynth.set(param, value);
				});

				// Send to direct playback synth if parameter is compatible
				if(directPlaybackParams.includes(param), {
					if(track.directPlaybackSynth.notNil, {
						track.directPlaybackSynth.set(param, value);
					});
				});
			});
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
			var track = tracks[trackNum];

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
			track.modulators[modNum] = ~s4Modulator.value(server).create(
				type,
				track.modBusses[modNum].index,
				rate,
				depth,
				shape,
				track.audioBus.index,  // For envelope follower
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
				this.createModulator(trackNum, modNum, 0, 1.0, 1.0, 0);  // LFO, 1Hz, full depth, sine
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
				track.modMappers[modNum] = ~s4Modulator.value(server).createMapper(
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
			track.modMappers[modNum] = ~s4Modulator.value(server).createMapper(
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
		resetParams: { arg self, trackNum;
			var track = tracks[trackNum];

			if(track.grainSynth.isNil, {
				"Track manager: Track % not initialized".format(trackNum + 1).postln;
				^nil;
			});

			// 1. HARD RESET AUDIO (Kill all active effects immediately)
			// This makes the track sound "New" again by directly setting the synth.
			if(track.grainSynth.notNil) {
				track.grainSynth.set(
					\pitch, 0, \pitchShift, 0,
					\timeStretch, 1.0, \scanSpeed, 0,
					\feedback, 0.0, \posJitter, 0.1, \pitchJitter, 0.0,
					\grainSize, 0.1 // Default starting size
				);
			};

			// 2. RESTORE FACTORY DEFAULTS
			// We overwrite the current params with the original "Init" values.
			// Using setParam ensures GUI (Viewfinder) updates automatically.
			[
				[\amp, 0.5], [\pan, 0],
				[\grainSize, 0.1], [\density, 30], [\overlap, 1], [\useOverlap, 1],
				[\pitch, 0], [\pitchShift, 0], [\timeStretch, 1.0],
				[\scanSpeed, 0], [\position, 0.0],
				[\posJitter, 0.1], [\pitchJitter, 0.0],
				[\posSeq, Array.fill(64, 0)], [\pitchSeq, Array.fill(64, 0)],
				[\grainMode, 0], [\engineMix, 0.0], // Back to Granular Tape Mode
				[\filterOn, 0], [\colorOn, 0], [\spaceOn, 0], // All FX Off
				[\spectralMix, 0.0], [\spectralPosition, 0.5], [\spectralRate, 1.0],
				[\spectralWindowSize, 0.2], [\spectralOverlaps, 4],
				[\spectralPitch, 0], [\spectralFreeze, 0], [\spectralSmear, 0],
				[\loopStart, 0.0], [\loopEnd, 1.0],
				[\envType, 1], [\stereoSpread, 0.5],
				[\scale, [0, 2, 4, 5, 7, 9, 11]], [\quantizePitch, 0]
			].do({ |pair|
				// Use setParam so the GUI (Viewfinder) updates automatically
				self.setParam(trackNum, pair[0], pair[1]);
			});

			"✓ Track % Recycled (Reset to New)".format(trackNum + 1).postln;
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
			this.resetParams(trackNum);

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
					masterBus = Synth(\s4MasterBus, [
						\track1Bus, tracks[0].audioBus.index,
						\track2Bus, tracks[1].audioBus.index,
						\track3Bus, tracks[2].audioBus.index,
						\track4Bus, tracks[3].audioBus.index,
						\out, 0
					] ++ filterState.asPairs, addAction: \addToTail);

					"✓ Switched to STEREO mode (2-channel output)".postln;
				}, {
					// QUAD MODE
					masterBus = Synth(\s4MasterBusQuad, [
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
~trackManager = ~s4TrackManager.value(s);
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
