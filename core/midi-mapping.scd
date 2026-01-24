/*
BEARULATOR: MIDI Mapping System
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

~bearulatorMIDIMapping = (
	// MIDI handlers (will be freed on cleanup)
	ccHandlers: nil,
	noteHandlers: nil,
	midiClockHandler: nil,
	enabled: false,

	// Phase 15.5: MIDI Clock Tempo Tracking
	tempo: 120.0,           // Current BPM from MIDI clock
	lastClockTime: 0,       // For tempo calculation
	clockCount: 0,          // MIDI clock pulses (24 per quarter note)

	// v2.1: MIDI Learn for 64-Step Sequencer
	learnMode: false,       // Is learn mode active?
	learnType: \pitch,      // \pitch or \position
	learnTrack: 0,          // Which track to apply to
	learnBuffer: nil,       // Captured notes (up to 64)
	learnCount: 0,          // How many notes captured

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

		"BEARULATOR: Initializing MIDI...".postln;

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

		// Phase 15.5: Set up MIDI clock handler for tempo sync
		self.setupMIDIClockHandler;

		self.enabled = true;

		"MIDI mapping initialized. 5 encoders + polyphonic notes + clock sync active.".postln;
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
					{ param == \overlap } { normalized.linlin(0, 1, 1, 256).round(1) }
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
				// v2.1: MIDI Learn mode intercepts notes
				if(self.learnMode, {
					self.captureLearnNote(num);
					^nil;  // Don't trigger normal note behavior
				});

				// Phase 15.5: LOGARITHMIC velocity mapping (sounds more "analog")
				// Linear mapping feels static; exponential feels responsive like real instruments
				// Maps MIDI 0-127 to 0.01-1.0 with exponential curve
				var velocity = vel.linexp(1, 127, 0.01, 1.0);
				var rate = (num - 60).midiratio;  // C3 (60) = 1.0, C4 (72) = 2.0
				var track = self.trackManager.getTrack(trackNum);

				// Set playback rate based on note number
				self.trackManager.setParam(trackNum, \pitch, num - 60);

				// Trigger grain density boost on note attack
				// Store original overlap value
				if(track.noteOverlap.isNil, {
					track.noteOverlap = track.params[\overlap] ? 4;
				});

				// Boost overlap for note attack (velocity-sensitive with exponential response)
				var attackOverlap = (track.noteOverlap * (1 + (velocity * 2))).min(256);
				self.trackManager.setParam(trackNum, \overlap, attackOverlap);

				// Phase 15.5: Map velocity to saturation & resonator (musical dynamics)
				// Soft notes = clean, hard notes = saturated (like acoustic instruments)
				// Uncomment to enable velocity→saturation mapping:
				// self.trackManager.setParam(trackNum, \saturationDrive, velocity.linexp(0.01, 1.0, 0.5, 5.0));
				// self.trackManager.setParam(trackNum, \filterRes, velocity.linlin(0.01, 1.0, 0.3, 0.9));

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

	// Phase 15.5: Set up MIDI clock handler for tempo-synced LFOs
	setupMIDIClockHandler: { arg self;
		// MIDI Clock sends 24 pulses per quarter note (PPQN)
		// We measure time between pulses to calculate BPM
		self.midiClockHandler = MIDIFunc.clock({ arg src;
			var currentTime, timeDelta, calculatedBPM;

			self.clockCount = self.clockCount + 1;

			// Calculate tempo every 24 clocks (1 beat)
			if(self.clockCount % 24 == 0, {
				currentTime = Main.elapsedTime;
				if(self.lastClockTime > 0, {
					timeDelta = currentTime - self.lastClockTime;
					// 24 clocks = 1 beat, so BPM = 60 / timeDelta
					calculatedBPM = 60.0 / timeDelta;

					// Smooth tempo changes (low-pass filter)
					self.tempo = (self.tempo * 0.9) + (calculatedBPM * 0.1);

					// Update all modulators with new tempo
					// (Each track has 4 modulators)
					4.do({ arg trackNum;
						var track = self.trackManager.getTrack(trackNum);
						4.do({ arg modNum;
							if(track.modulators[modNum].notNil, {
								track.modulators[modNum].set(\tempo, self.tempo);
							});
						});
					});

					// Debug: Show tempo every 4 beats
					if(self.clockCount % 96 == 0, {
						"MIDI Clock: % BPM".format(self.tempo.round(0.1)).postln;
					});
				});
				self.lastClockTime = currentTime;
			});
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

	// v2.1: Enable MIDI Learn Mode for 64-Step Sequencer
	enableLearn: { arg self, trackNum = 0, type = \pitch;
		self.learnMode = true;
		self.learnType = type;
		self.learnTrack = trackNum;
		self.learnBuffer = Array.newClear(64);
		self.learnCount = 0;

		"".postln;
		"═══════════════════════════════════════════".postln;
		"  MIDI LEARN MODE ACTIVE".postln;
		"═══════════════════════════════════════════".postln;
		"Track: % | Type: %".format(trackNum + 1, type).postln;
		"Play up to 64 notes on your MIDI controller...".postln;
		"".postln;
	},

	// v2.1: Disable MIDI Learn Mode
	disableLearn: { arg self;
		self.learnMode = false;
		"MIDI Learn Mode: OFF".postln;
	},

	// v2.1: Capture MIDI note during learn mode (called from note handler)
	captureLearnNote: { arg self, noteNum;
		var value;

		if(self.learnCount < 64, {
			// Convert MIDI note to appropriate value
			value = case
				{ self.learnType == \pitch } {
					// Pitch: Store as semitone offset from middle C
					(noteNum - 60)
				}
				{ self.learnType == \position } {
					// Position: Map note number 0-127 to position 0-1
					noteNum.linlin(0, 127, -0.5, 0.5)
				};

			self.learnBuffer[self.learnCount] = value;
			self.learnCount = self.learnCount + 1;

			// Progress indicator
			if(self.learnCount % 16 == 0, {
				"  → Captured % / 64 notes".format(self.learnCount).postln;
			});

			// Auto-finish at 64 notes
			if(self.learnCount == 64, {
				self.finishLearn;
			});
		});
	},

	// v2.1: Apply captured sequence to track
	finishLearn: { arg self;
		var param, finalBuffer;

		if(self.learnCount == 0, {
			"MIDI Learn: No notes captured.".postln;
			self.disableLearn;
			^nil;
		});

		// Pad buffer to 64 if needed (repeat pattern)
		finalBuffer = Array.fill(64, { |i|
			self.learnBuffer[i % self.learnCount]
		});

		// Apply to track
		param = case
			{ self.learnType == \pitch } { \pitchSeq }
			{ self.learnType == \position } { \posSeq };

		self.trackManager.setParam(self.learnTrack, param, finalBuffer);

		// Enable jitter to activate sequence
		if(self.learnType == \pitch, {
			self.trackManager.setParam(self.learnTrack, \pitchJitter, 1);
		}, {
			self.trackManager.setParam(self.learnTrack, \posJitter, 1);
		});

		"".postln;
		"═══════════════════════════════════════════".postln;
		"  SEQUENCE CAPTURED!".postln;
		"═══════════════════════════════════════════".postln;
		"Captured % notes (repeated to fill 64 steps)".format(self.learnCount).postln;
		"Applied to Track % % sequence".format(
			self.learnTrack + 1,
			self.learnType
		).postln;
		"".postln;

		self.disableLearn;
	},

	// Cleanup: Free all MIDI handlers
	free: { arg self;
		if(self.enabled, {
			"Freeing MIDI handlers...".postln;

			self.ccHandlers.do(_.free);
			self.noteHandlers.do(_.free);
			if(self.midiClockHandler.notNil, { self.midiClockHandler.free });

			self.ccHandlers = nil;
			self.noteHandlers = nil;
			self.midiClockHandler = nil;
			self.enabled = false;

			"MIDI mapping freed.".postln;
		});
	}
);

/*
Usage example:

// Initialize MIDI system
~bearulatorMIDIMapping.init(~trackManager);

// Custom CC mapping (optional)
~bearulatorMIDIMapping.mapCC(74, \filterRes, 0);  // Remap CC 74 to resonance on Track 1

// Cleanup
~bearulatorMIDIMapping.free;

// Re-initialize
~bearulatorMIDIMapping.init(~trackManager);
*/
