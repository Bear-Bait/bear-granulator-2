/*
S-4 Rival: MIDI Mapping System
Phase 12 - KeyStep Pro Integration

Features:
- 5 encoder CC mappings (customizable)
- Polyphonic note triggering (4 MIDI channels → 4 tracks)
- Velocity-sensitive grain triggering
- Note number → playback rate via .midiratio
- Visual feedback in viewfinder (green pulses, cyan overlays)

Hardware: Arturia KeyStep Pro
- 5 rotary encoders (CC 74, 71, 76, 77, 78)
- 37-key keyboard
- 4-track sequencer → 4 MIDI channels
- Touch strips for pitch/mod

Signal Flow:
KeyStep Pro → MIDI In → SuperCollider → Track Parameters
                                      → Visual Feedback
*/

~s4MIDIMapping = (
	// MIDI handlers (will be freed on cleanup)
	ccHandlers: nil,
	noteHandlers: nil,
	enabled: false,

	// Default CC mappings (KeyStep Pro encoders)
	ccMappings: (
		74: (\filterFreq, 0),    // Encoder 1 → Track 1 Filter Cutoff
		71: (\grainSize, 0),     // Encoder 2 → Track 1 Grain Size
		76: (\overlap, 0),       // Encoder 3 → Track 1 Overlap (Density)
		77: (\spectralMix, 0),   // Encoder 4 → Track 1 Spectral Mix
		78: (\filterDecay, 0)    // Encoder 5 → Track 1 Drive
	),

	// Initialize MIDI system
	init: { arg self, trackManager;
		var server = Server.default;

		"S-4 RIVAL: Initializing MIDI...".postln;

		// Initialize MIDI client
		MIDIClient.init;
		MIDIIn.connectAll;

		"MIDI Sources:".postln;
		MIDIClient.sources.do({ arg src, i;
			"  [%] %".format(i, src.name).postln;
		});

		// Store reference to track manager
		self.trackManager = trackManager;

		// Set up CC handlers
		self.setupCCHandlers;

		// Set up note handlers (polyphonic)
		self.setupNoteHandlers;

		self.enabled = true;

		"MIDI mapping initialized. 5 encoders + polyphonic notes active.".postln;
		"  CC 74 → Filter Cutoff (Track 1)".postln;
		"  CC 71 → Grain Size (Track 1)".postln;
		"  CC 76 → Overlap/Density (Track 1)".postln;
		"  CC 77 → Spectral Mix (Track 1)".postln;
		"  CC 78 → Filter Drive (Track 1)".postln;
		"  MIDI Ch 1-4 → Tracks 1-4 (polyphonic)".postln;
	},

	// Set up CC (Continuous Controller) handlers
	setupCCHandlers: { arg self;
		self.ccHandlers = List.new;

		// Create handler for each mapped CC
		self.ccMappings.keysValuesDo({ arg ccNum, paramTrack;
			var param = paramTrack[0];
			var trackNum = paramTrack[1];
			var handler;

			handler = MIDIFunc.cc({ arg val, num, chan, src;
				var normalized = val / 127.0;  // MIDI 0-127 → 0.0-1.0
				var mappedValue;

				// Map to appropriate range based on parameter
				mappedValue = case
					{ param == \filterFreq } { normalized }  // 0-1 (exponential in engine)
					{ param == \grainSize } { normalized.linexp(0, 1, 0.001, 2.0) }
					{ param == \overlap } { normalized.linlin(0, 1, 1, 128).round(1) }
					{ param == \spectralMix } { normalized }
					{ param == \filterDecay } { normalized }
					{ true } { normalized };

				// Update parameter
				self.trackManager.setParam(trackNum, param, mappedValue);

				// Visual feedback: Trigger cyan overlay in viewfinder
				if(~viewfinder.notNil, {
					self.triggerCCFeedback(trackNum, param, mappedValue);
				});

				// Debug
				// "CC % → Track % \%: %".format(num, trackNum + 1, param, mappedValue.round(0.01)).postln;
			}, ccNum);  // Match specific CC number

			self.ccHandlers.add(handler);
		});
	},

	// Set up note handlers (polyphonic, 4 channels → 4 tracks)
	setupNoteHandlers: { arg self;
		self.noteHandlers = List.new;

		// Note On: Trigger grains with velocity and pitch
		4.do({ arg trackNum;
			var midiChan = trackNum;  // MIDI channels 0-3 (displayed as 1-4)
			var noteOnHandler, noteOffHandler;

			// Note On handler
			noteOnHandler = MIDIFunc.noteOn({ arg vel, num, chan, src;
				var velocity = vel / 127.0;
				var rate = (num - 60).midiratio;  // C3 (60) = 1.0, C4 (72) = 2.0
				var track = self.trackManager.getTrack(trackNum);

				// Set playback rate based on note number
				self.trackManager.setParam(trackNum, \pitch, num - 60);

				// Trigger grain density boost on note attack
				// Store original overlap value
				if(track.noteOverlap.isNil, {
					track.noteOverlap = track.params[\overlap] ? 4;
				});

				// Boost overlap for note attack (velocity-sensitive)
				var attackOverlap = (track.noteOverlap * (1 + (velocity * 2))).min(128);
				self.trackManager.setParam(trackNum, \overlap, attackOverlap);

				// Visual feedback: Green pulse in viewfinder
				if(~viewfinder.notNil, {
					self.triggerNotePulse(trackNum, velocity);
				});

				// Debug
				"Note ON: Track % | Note % | Vel % | Rate %".format(
					trackNum + 1, num, vel, rate.round(0.01)
				).postln;
			}, chan: midiChan);

			// Note Off handler
			noteOffHandler = MIDIFunc.noteOff({ arg vel, num, chan, src;
				var track = self.trackManager.getTrack(trackNum);

				// Return to original overlap value
				if(track.noteOverlap.notNil, {
					self.trackManager.setParam(trackNum, \overlap, track.noteOverlap);
				});

				// Debug
				// "Note OFF: Track % | Note %".format(trackNum + 1, num).postln;
			}, chan: midiChan);

			self.noteHandlers.add(noteOnHandler);
			self.noteHandlers.add(noteOffHandler);
		});
	},

	// Visual feedback: CC parameter change (cyan overlay)
	triggerCCFeedback: { arg self, trackNum, param, value;
		// This will be called by viewfinder if it exists
		// Viewfinder will display parameter name + value in cyan
		{
			if(~viewfinder.windows[trackNum].notNil, {
				// Trigger visual update in viewfinder overlay
				// (Implementation in viewfinder.scd will handle display)
				~viewfinder.showCCFeedback(trackNum, param, value);
			});
		}.defer;
	},

	// Visual feedback: Note trigger (green pulse)
	triggerNotePulse: { arg self, trackNum, velocity;
		// This will be called by viewfinder if it exists
		// Viewfinder will display green expanding ring
		{
			if(~viewfinder.windows[trackNum].notNil, {
				// Trigger visual pulse in viewfinder overlay
				// (Implementation in viewfinder.scd will handle animation)
				~viewfinder.showNotePulse(trackNum, velocity);
			});
		}.defer;
	},

	// Custom CC mapping (allow user to remap encoders)
	mapCC: { arg self, ccNum, param, trackNum = 0;
		"Remapping CC % → Track % \%".format(ccNum, trackNum + 1, param).postln;
		self.ccMappings[ccNum] = [param.asSymbol, trackNum];

		// Reinitialize CC handlers with new mapping
		self.ccHandlers.do(_.free);
		self.setupCCHandlers;
	},

	// Cleanup: Free all MIDI handlers
	free: { arg self;
		if(self.enabled, {
			"Freeing MIDI handlers...".postln;

			self.ccHandlers.do(_.free);
			self.noteHandlers.do(_.free);

			self.ccHandlers = nil;
			self.noteHandlers = nil;
			self.enabled = false;

			"MIDI mapping freed.".postln;
		});
	}
);

/*
Usage example:

// Initialize MIDI system
~s4MIDIMapping.init(~trackManager);

// Custom CC mapping (optional)
~s4MIDIMapping.mapCC(74, \filterRes, 0);  // Remap CC 74 to resonance on Track 1

// Cleanup
~s4MIDIMapping.free;

// Re-initialize
~s4MIDIMapping.init(~trackManager);
*/
