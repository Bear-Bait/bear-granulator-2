/*
BEARULATOR: KeyStep Pro MIDI Mapping
Smart Mapper System

Hardware: Arturia KeyStep Pro
- 5 rotary knobs (CC 74, 75, 76, 77, 78)
- Mod strip (CC 1)
- Pitch bend (±2 semitones)
- 37-key keyboard (polyphonic pitch control)
- Panic/Reset: Note 84 (High C)

Features:
- Smart mapper function: ~mapKnob.(cc, param, min, max, warp)
- One-line remapping without math
- Automatic visual feedback in viewfinder
- Polyphonic keyboard control with root at C3 (Note 60)
- Pitch bend wheel support (±2 semitones default)
- Global parameter reset on Note 84
*/

~keyStepProMapping = (
	// MIDI handlers storage
	ccHandlers: IdentityDictionary.new,
	noteHandlers: List.new,
	bendHandler: nil,
	enabled: false,
	trackManager: nil,

	// --- 🎛️ SMART MAPPER TOOL ---
	// Arguments: CC Number, Parameter Name, Min, Max, Warp (\lin or \exp), Track Number
	mapKnob: { arg self, cc, param, min=0.0, max=1.0, warp=\lin, trackNum=0;
		var key = ("ksp_cc_" ++ cc).asSymbol;

		// Free existing handler if remapping
		if(self.ccHandlers[key].notNil, {
			self.ccHandlers[key].free;
		});

		// Create new CC handler
		self.ccHandlers[key] = MIDIdef.cc(key, { arg val;
			var norm;

			// 1. Handle Math (Linear or Exponential)
			if(warp == \exp, {
				norm = val.linexp(0, 127, min.max(0.0001), max);
			}, {
				norm = val.linlin(0, 127, min, max);
			});

			// 2. Update Engine
			self.trackManager.setParam(trackNum, param, norm);

			// 3. Special Case: Sync Spectral Pitch if mapping Pitch
			if(param == \pitch, {
				self.trackManager.setParam(trackNum, \spectralPitch, norm);
			});

			// 4. Update Visuals (Cyan Overlay)
			if(~viewfinder.notNil, {
				{
					~viewfinder.showCCFeedback(trackNum, param.asString, norm);
				}.defer;
			});

		}, cc, srcID: nil, argTemplate: nil, dispatcher: nil);

		"✅ CC % mapped to '%' (Range: % to %, Warp: %)".format(cc, param, min, max, warp).postln;
	},

	// Initialize MIDI system
	init: { arg self, trackManager;
		self.trackManager = trackManager;

		"".postln;
		"═══════════════════════════════════════════".postln;
		"  KeyStep Pro MIDI System".postln;
		"═══════════════════════════════════════════".postln;

		// Initialize MIDI client
		MIDIClient.init;
		MIDIIn.connectAll;

		"MIDI Sources:".postln;
		MIDIClient.sources.do({ arg src, i;
			"  [%] %".format(i, src.name).postln;
		});
		"".postln;

		// Load default KeyStep Pro mappings
		self.loadDefaultMappings;

		// Set up keyboard note handlers
		self.setupKeyboardHandlers;

		// Set up panic/reset handler
		self.setupPanicHandler;

		// Set up pitch bend handler
		self.setupPitchBend;

		self.enabled = true;

		"".postln;
		"✅ KeyStep Pro MIDI initialized".postln;
		"".postln;
		"Mappings:".postln;
		"  Knob 1 (CC 74) → Position".postln;
		"  Knob 2 (CC 75) → Pitch (-24 to +24)".postln;
		"  Knob 3 (CC 76) → Grain Size (exponential)".postln;
		"  Knob 4 (CC 77) → Overlap/Density".postln;
		"  Knob 5 (CC 78) → Amplitude".postln;
		"  Mod Strip (CC 1) → Position Jitter".postln;
		"  Pitch Bend → Pitch (±2 semitones)".postln;
		"".postln;
		"Keyboard:".postln;
		"  Notes 48-83 → Polyphonic pitch control".postln;
		"  Root: C3 (Note 60) = 0 semitones".postln;
		"  Note 84 (High C) → PANIC/RESET".postln;
		"".postln;
		"Remap anytime with:".postln;
		"  ~mapKnob.(74, \\spectralMix, 0, 1);".postln;
		"═══════════════════════════════════════════".postln;
		"".postln;
	},

	// Load default KeyStep Pro mappings from user specification
	loadDefaultMappings: { arg self;
		var trackNum = 0;  // All controls → Track 1 by default

		// Knob 1: Position (0.0 to 1.0, Linear)
		self.mapKnob(74, \position, 0.0, 1.0, \lin, trackNum);

		// Knob 2: Pitch (-24 to +24 semitones, Linear)
		self.mapKnob(75, \pitch, -24, 24, \lin, trackNum);

		// Knob 3: Grain Size (0.001 to 1.5, Exponential)
		self.mapKnob(76, \grainSize, 0.001, 1.5, \exp, trackNum);

		// Knob 4: Overlap (0.5 to 16, Linear)
		self.mapKnob(77, \overlap, 0.5, 16, \lin, trackNum);

		// Knob 5: Amplitude (0.0 to 1.0, Linear)
		self.mapKnob(78, \amp, 0.0, 1.0, \lin, trackNum);

		// Mod Strip: Position Jitter (0.0 to 1.0, Linear)
		self.mapKnob(1, \posJitter, 0.0, 1.0, \lin, trackNum);

		"Default mappings loaded (Track 1)".postln;
	},

	// Set up polyphonic keyboard handlers
	setupKeyboardHandlers: { arg self;
		var trackNum = 0;  // Keyboard controls Track 1
		var noteOnHandler, noteOffHandler;

		// Note On: Set pitch based on key
		noteOnHandler = MIDIdef.noteOn(\ksp_noteOn, { arg vel, num, chan, src;
			var pitchOffset, velocity;

			// PANIC/RESET on Note 84 (handled separately)
			if(num == 84, {
				^nil;  // Let panic handler deal with it
			});

			// Calculate pitch offset from Middle C (Note 60)
			pitchOffset = num - 60;

			// Logarithmic velocity mapping (1-127 → 0.01-1.0)
			velocity = vel.linexp(1, 127, 0.01, 1.0);

			// Set pitch on track
			self.trackManager.setParam(trackNum, \pitch, pitchOffset);
			self.trackManager.setParam(trackNum, \spectralPitch, pitchOffset);

			// Optional: Boost grain density on attack (velocity-sensitive)
			// Uncomment to enable:
			// var baseOverlap = self.trackManager.getTrack(trackNum).params[\overlap] ? 4;
			// var attackOverlap = (baseOverlap * (1 + velocity)).min(16);
			// self.trackManager.setParam(trackNum, \overlap, attackOverlap);

			// Visual feedback
			if(~viewfinder.notNil, {
				{
					~viewfinder.showNotePulse(trackNum, velocity);
				}.defer;
			});

			// Debug
			"♪ Note ON: % (MIDI %) → Pitch: % semitones".format(
				num.midicps.round(0.01), num, pitchOffset
			).postln;
		});

		// Note Off: Return to original state (optional)
		noteOffHandler = MIDIdef.noteOff(\ksp_noteOff, { arg vel, num, chan, src;
			// Optional: Return overlap to baseline after note release
			// (Currently disabled - let the user control density manually)
		});

		self.noteHandlers.add(noteOnHandler);
		self.noteHandlers.add(noteOffHandler);

		"Keyboard handlers initialized (Root: C3 = Note 60)".postln;
	},

	// Set up panic/reset handler on Note 84 (High C)
	setupPanicHandler: { arg self;
		var panicHandler;

		panicHandler = MIDIdef.noteOn(\ksp_panic, { arg vel, num, chan, src;
			"".postln;
			"🚨 PANIC/RESET TRIGGERED (Note 84)".postln;
			"".postln;

			// Reset all tracks to factory defaults
			4.do({ arg trackNum;
				self.trackManager.resetParams(trackNum);
			});

			"✅ All tracks reset to factory defaults".postln;
			"".postln;
		}, noteNum: 84);

		self.noteHandlers.add(panicHandler);

		"Panic/Reset handler initialized (Note 84)".postln;
	},

	// Set up pitch bend handler
	setupPitchBend: { arg self;
		var trackNum = 0;  // Pitch bend controls Track 1
		var bendRange = 2; // ±2 semitones (standard pitch wheel range)

		self.bendHandler = MIDIdef.bend(\ksp_pitchbend, { arg val, chan, src;
			var norm, semitones;

			// val is 0-16383, center is 8192
			// Map to -bendRange to +bendRange semitones
			semitones = val.linlin(0, 16383, bendRange.neg, bendRange);

			// Get current pitch parameter and add bend offset
			// Note: This is additive to the current pitch setting
			self.trackManager.setParam(trackNum, \pitch, semitones);
			self.trackManager.setParam(trackNum, \spectralPitch, semitones);

			// Visual feedback
			if(~viewfinder.notNil, {
				{
					~viewfinder.showCCFeedback(trackNum, "PitchBend", semitones);
				}.defer;
			});

		}, chan: nil, srcID: nil);

		"Pitch Bend handler initialized (±% semitones)".format(bendRange).postln;
	},

	// Cleanup: Free all MIDI handlers
	free: { arg self;
		if(self.enabled, {
			"Freeing KeyStep Pro MIDI handlers...".postln;

			// Free CC handlers
			self.ccHandlers.keysValuesDo({ arg key, handler;
				handler.free;
			});
			self.ccHandlers.clear;

			// Free note handlers
			self.noteHandlers.do(_.free);
			self.noteHandlers.clear;

			// Free pitch bend handler
			if(self.bendHandler.notNil, {
				self.bendHandler.free;
				self.bendHandler = nil;
			});

			self.enabled = false;

			"KeyStep Pro MIDI freed.".postln;
		});
	}
);

// Expose smart mapper as global function for convenience
~mapKnob = { arg cc, param, min=0.0, max=1.0, warp=\lin, trackNum=0;
	if(~keyStepProMapping.notNil, {
		~keyStepProMapping.mapKnob(cc, param, min, max, warp, trackNum);
	}, {
		"ERROR: KeyStep Pro mapping not initialized. Run ~keyStepProMapping.init(~trackManager) first.".postln;
	});
};

/*
Usage Examples:

// 1. Initialize (run once after track manager is ready)
~keyStepProMapping.init(~trackManager);

// 2. Remap a knob on-the-fly
~mapKnob.(74, \spectralMix, 0, 1);  // Knob 1 → Spectral Mix
~mapKnob.(76, \stereoSpread, 0, 1);  // Knob 3 → Stereo Spread
~mapKnob.(77, \filterFreq, 0, 1);    // Knob 4 → Filter Cutoff

// 3. Control different tracks
~mapKnob.(74, \position, 0, 1, \lin, 1);  // Knob 1 → Track 2 Position

// 4. Cleanup
~keyStepProMapping.free;

// 5. Re-initialize with new mappings
~keyStepProMapping.init(~trackManager);
*/
