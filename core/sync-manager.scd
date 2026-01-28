/*
═══════════════════════════════════════════════════════════════════
BEARULATOR: Sync Manager - Phase 18 (Dream-Tier Rhythmic Locking)
═══════════════════════════════════════════════════════════════════

PHASE 18 UPGRADES:
1. Uses OVERLAP MATH instead of forcing Density Mode
2. Calculates grainSize dynamically to maintain lush texture
3. Implements t_reset trigger for sequencer phase alignment
4. Tap tempo support
5. Per-track rhythmic subdivision control

OVERLAP MATH FORMULA:
  densityHz = (bpm / 60) * (subdivision / 4)
  grainSize = overlap / densityHz
  
  Example: 120 BPM, 1/16th notes, overlap=64
    densityHz = (120/60) * (16/4) = 8 Hz
    grainSize = 64 / 8 = 8 seconds (!)
    Result: Lush 64-grain texture locked to 1/16th grid

USAGE:
  ~syncManager.setBPM(120);
  ~syncManager.setRhythmicDensity(0, 16);  // Track 1 → 1/16th notes
  ~syncManager.playQuantized(0);           // Start on next bar with phase reset
  ~syncManager.tapTempo;                   // Tap 4 times to set tempo
  
═══════════════════════════════════════════════════════════════════
*/

~bearulatorSyncManager = { arg trackManager;
	var clock = TempoClock.default;
	var tapTimes = List.new;  // For tap tempo
	var lastTap = 0;
	var publicAPI;

	// ═════════════════════════════════════════════════════
	// PRIVATE: Calculate Grain Size from Overlap Math
	// ═════════════════════════════════════════════════════
	
	var calculateGrainSize = { arg bpm, subdivision, overlap;
		var beatsPerSecond = bpm / 60;
		var notesPerBeat = subdivision / 4;  // 16th = 4 notes per beat, 8th = 2, etc.
		var densityHz = beatsPerSecond * notesPerBeat;
		var requiredGrainSize = overlap / densityHz;
		
		requiredGrainSize;
	};

	// ═════════════════════════════════════════════════════
	// PUBLIC API
	// ═════════════════════════════════════════════════════

	publicAPI = (
		// --- Get/Set Global Tempo ---
		
		setBPM: { arg self, bpm;
			clock.tempo = bpm / 60;
			"✓ Global Tempo: % BPM (% beats/sec)".format(bpm, clock.tempo.round(0.01)).postln;
		},

		getBPM: { arg self;
			(clock.tempo * 60).round(0.1);
		},

		// --- Snap Track to Rhythmic Grid (OVERLAP MATH) ---
		
		setRhythmicDensity: { arg self, trackNum, subdivision = 16;
			var track = trackManager.getTrack(trackNum);
			var currentOverlap, bpm, densityHz, requiredGrainSize;
			
			// Get current overlap (preserve user's texture setting)
			currentOverlap = track.params[\overlap] ? 64;
			
			// Get current BPM
			bpm = self.getBPM;
			
			// Calculate required grain size using Overlap Math
			requiredGrainSize = calculateGrainSize.(bpm, subdivision, currentOverlap);
			
			// Calculate density for display
			densityHz = (bpm / 60) * (subdivision / 4);
			
			// ✓ Keep Overlap Mode (lush texture)
			trackManager.setParam(trackNum, \useOverlap, 1);
			
			// ✓ Set calculated grain size
			trackManager.setParam(trackNum, \grainSize, requiredGrainSize);
			
			"✓ Track % → 1/% notes".format(trackNum + 1, subdivision).postln;
			"  Overlap: % grains | Density: % Hz | Grain Size: % sec".format(
				currentOverlap, 
				densityHz.round(0.01), 
				requiredGrainSize.round(0.001)
			).postln;
		},

		// --- Set All Tracks to Same Subdivision ---
		
		setAllRhythmicDensity: { arg self, subdivision = 16;
			4.do({ |i|
				self.setRhythmicDensity(i, subdivision);
			});
			"✓ All tracks locked to 1/% notes".format(subdivision).postln;
		},

		// --- Quantized Playback with Phase Reset ---
		
		playQuantized: { arg self, trackNum, bars = 1;
			var track = trackManager.getTrack(trackNum);
			
			"⏳ Track % will start in % bar(s)...".format(trackNum + 1, bars).postln;
			
			clock.schedAbs(clock.nextBar(bars), {
				// 1. Reset playback position to loop start
				trackManager.setParam(trackNum, \position, track.params[\loopStart]);
				
				// 2. PHASE RESET: Fire t_reset trigger to jump sequencer to step 0
				if(track.grainSynth.notNil) {
					track.grainSynth.set(\t_reset, 1);
				};
				
				// 3. Start playback
				if(track.grainSynth.notNil) { track.grainSynth.run(true) };
				if(track.directPlaybackSynth.notNil) { track.directPlaybackSynth.run(true) };
				
				"▶ Track % STARTED (on grid, phase aligned)".format(trackNum + 1).postln;
				
				nil;  // Don't reschedule
			});
		},

		// --- Stop Track Quantized (on next bar) ---
		
		stopQuantized: { arg self, trackNum, bars = 1;
			var track = trackManager.getTrack(trackNum);
			
			"⏳ Track % will stop in % bar(s)...".format(trackNum + 1, bars).postln;
			
			clock.schedAbs(clock.nextBar(bars), {
				if(track.grainSynth.notNil) { track.grainSynth.run(false) };
				if(track.directPlaybackSynth.notNil) { track.directPlaybackSynth.run(false) };
				
				"⏸ Track % STOPPED (on grid)".format(trackNum + 1).postln;
				
				nil;  // Don't reschedule
			});
		},

		// --- Tap Tempo ---
		
		tapTempo: { arg self;
			var now = Main.elapsedTime;
			var interval, avgInterval, newBPM;
			
			// Reset if more than 2 seconds since last tap
			if((now - lastTap) > 2.0, {
				tapTimes.clear;
				"Tap tempo reset. Tap 4 times...".postln;
			});
			
			tapTimes.add(now);
			lastTap = now;
			
			// Need at least 2 taps to calculate
			if(tapTimes.size >= 2, {
				// Calculate average interval between taps
				avgInterval = (tapTimes.last - tapTimes.first) / (tapTimes.size - 1);
				newBPM = (60 / avgInterval).round(1);
				
				if(tapTimes.size >= 4, {
					self.setBPM(newBPM);
					"✓ Tap tempo: % BPM (% taps)".format(newBPM, tapTimes.size).postln;
					tapTimes.clear;  // Reset after 4 taps
				}, {
					"Tap %/4: ~% BPM".format(tapTimes.size, newBPM).postln;
				});
			}, {
				"Tap 1/4".postln;
			});
		},

		// --- GUI: Sync Manager Window ---
		
		createSyncWindow: { arg self;
			var win = Window("SYNC MANAGER - Phase 18", Rect(100, 350, 450, 340)).front;
			var bpmBox, tapButton;
			var colors = (
				bg: Color.fromHexString("#262938"),
				fg: Color.white,
				cyan: Color.cyan,
				green: Color.green(0.7),
				yellow: Color(0.9, 0.8, 0.2),
				orange: Color(1, 0.6, 0)
			);
			
			win.view.background_(colors.bg);
			
			// ═════════════════════════════════════════════════════
			// TEMPO SECTION
			// ═════════════════════════════════════════════════════
			
			StaticText(win, Rect(10, 10, 430, 20))
				.string_("GLOBAL TEMPO")
				.stringColor_(colors.yellow)
				.font_(Font("DejaVu Sans Mono", 12, true));
			
			StaticText(win, Rect(10, 35, 50, 25))
				.string_("BPM:")
				.stringColor_(colors.fg)
				.font_(Font("DejaVu Sans Mono", 10));
			
			bpmBox = NumberBox(win, Rect(60, 35, 60, 25))
				.value_(self.getBPM)
				.decimals_(1)
				.font_(Font("DejaVu Sans Mono", 14))
				.action_({ |nb| self.setBPM(nb.value) });
			
			tapButton = Button(win, Rect(130, 35, 100, 25))
				.states_([["TAP TEMPO", colors.fg, colors.cyan]])
				.font_(Font("DejaVu Sans Mono", 9))
				.action_({ self.tapTempo });
			
			Button(win, Rect(240, 35, 80, 25))
				.states_([["60 BPM", colors.fg, Color.gray(0.3)]])
				.font_(Font("DejaVu Sans Mono", 9))
				.action_({ bpmBox.value_(60); self.setBPM(60) });
			
			Button(win, Rect(325, 35, 80, 25))
				.states_([["120 BPM", colors.fg, Color.gray(0.3)]])
				.font_(Font("DejaVu Sans Mono", 9))
				.action_({ bpmBox.value_(120); self.setBPM(120) });
			
			// ═════════════════════════════════════════════════════
			// RHYTHMIC LOCKING SECTION
			// ═════════════════════════════════════════════════════
			
			StaticText(win, Rect(10, 75, 430, 20))
				.string_("RHYTHMIC LOCKING (All Tracks)")
				.stringColor_(colors.yellow)
				.font_(Font("DejaVu Sans Mono", 12, true));
			
			StaticText(win, Rect(10, 100, 430, 30))
				.string_("Locks grain density to tempo grid while preserving overlap texture")
				.stringColor_(Color.gray(0.7))
				.font_(Font("DejaVu Sans Mono", 9));
			
			// Subdivision buttons (all tracks)
			[\eighth, \sixteenth, \thirtysecond, \quarter].do({ |name, i|
				var subdivisions = [8, 16, 32, 4];
				var labels = ["1/8th", "1/16th", "1/32nd", "1/4"];
				var x = 10 + (i * 110);
				
				Button(win, Rect(x, 135, 105, 30))
					.states_([[labels[i], colors.fg, colors.cyan]])
					.font_(Font("DejaVu Sans Mono", 10, true))
					.action_({ 
						self.setAllRhythmicDensity(subdivisions[i]);
					});
			});
			
			// ═════════════════════════════════════════════════════
			// QUANTIZED TRANSPORT
			// ═════════════════════════════════════════════════════
			
			StaticText(win, Rect(10, 180, 430, 20))
				.string_("QUANTIZED TRANSPORT")
				.stringColor_(colors.yellow)
				.font_(Font("DejaVu Sans Mono", 12, true));
			
			StaticText(win, Rect(10, 205, 430, 30))
				.string_("Start/stop tracks on beat with sequencer phase alignment")
				.stringColor_(Color.gray(0.7))
				.font_(Font("DejaVu Sans Mono", 9));
			
			4.do({ |trackNum|
				var y = 240 + (trackNum * 22);
				
				StaticText(win, Rect(10, y, 60, 20))
					.string_("Track %".format(trackNum + 1))
					.stringColor_(colors.fg)
					.font_(Font("DejaVu Sans Mono", 9));
				
				Button(win, Rect(70, y, 80, 20))
					.states_([["▶ PLAY", colors.fg, colors.green]])
					.font_(Font("DejaVu Sans Mono", 8))
					.action_({ self.playQuantized(trackNum, 1) });
				
				Button(win, Rect(155, y, 80, 20))
					.states_([["⏸ STOP", colors.fg, colors.orange]])
					.font_(Font("DejaVu Sans Mono", 8))
					.action_({ self.stopQuantized(trackNum, 1) });
				
				Button(win, Rect(240, y, 95, 20))
					.states_([["1/4 → T%".format(trackNum + 1), colors.fg, Color.gray(0.4)]])
					.font_(Font("DejaVu Sans Mono", 8))
					.action_({ self.setRhythmicDensity(trackNum, 4) });
				
				Button(win, Rect(340, y, 95, 20))
					.states_([["1/16 → T%".format(trackNum + 1), colors.fg, Color.gray(0.4)]])
					.font_(Font("DejaVu Sans Mono", 8))
					.action_({ self.setRhythmicDensity(trackNum, 16) });
			});
		}
	);

	"✓ Sync Manager (Phase 18) initialized".postln;
	publicAPI;
};
