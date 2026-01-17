/*
BEARULATOR: Mosaic Mode Examples
Phase 16 - Cross-Track Modulation

MOSAIC MODE allows tracks to listen to each other!
The Envelope Follower can now follow ANY track's audio,
creating a living, breathing ecosystem.

Run these AFTER loading main.scd and creating tracks.
*/

(
"═══════════════════════════════════════".postln;
"  MOSAIC MODE EXAMPLES".postln;
"  Phase 16 - Cross-Track Modulation".postln;
"═══════════════════════════════════════".postln;
)

// ═══════════════════════════════════════
// EXAMPLE 1: Rhythmic Cross-Modulation
// ═══════════════════════════════════════
// Track 1's amplitude modulates Track 2's grain size
(
"Example 1: Rhythmic Cross-Modulation".postln;
"".postln;

// Load samples (use stock samples that actually exist)
~trackManager.loadSample(0, "samples/stock/coins.wav");      // Track 1: Rhythmic
~trackManager.loadSample(1, "samples/stock/a11wlk01.wav");   // Track 2: Voice

// Setup Track 2 modulator to listen to Track 1
~trackManager.createModulator(1, 0, 1);  // Track 2, Mod 1, Type: Envelope Follower

// Make it listen to Track 1
~trackManager.setModSourceTrack(1, 0, 0);  // Track 2, Mod 0, Source: Track 1

// Route to Track 2's grain size
~trackManager.routeModulation(1, 0, \grainSize, 0.01, 0.5);

"✓ Track 1's amplitude now modulates Track 2's grain size".postln;
"  → Play both tracks to hear cross-modulation".postln;
)

// ═══════════════════════════════════════
// EXAMPLE 2: Dual Source Modulation
// ═══════════════════════════════════════
// Track 3 follows Track 1, Track 4 follows Track 3
(
"Example 2: Dual Source Modulation".postln;
"".postln;

// Load samples (using stock samples)
~trackManager.loadSample(2, "samples/stock/A3.wav");           // Track 3: Tone
~trackManager.loadSample(3, "samples/stock/SinedPink.aiff");   // Track 4: Noise

// Setup Track 4 modulator to follow Track 3's amplitude
~trackManager.createModulator(3, 0, 1);  // Track 4, Mod 1, Envelope Follower

// Make Track 4 listen to Track 3
~trackManager.setModSourceTrack(3, 0, 2);  // Track 4, Mod 0, Source: Track 3

// Route to position for scanning effect
~trackManager.routeModulation(3, 0, \position, 0.0, 1.0);

"✓ Track 3's amplitude modulates Track 4's position".postln;
"  → Play both tracks to hear scanning effect".postln;
)

// ═══════════════════════════════════════
// EXAMPLE 3: The Living System
// ═══════════════════════════════════════
// All 4 tracks influence each other (requires samples loaded in Examples 1 & 2)
(
"Example 3: The Living System".postln;
"".postln;
"NOTE: Run Examples 1 & 2 first to load samples on all 4 tracks".postln;
"".postln;

// Track 1 → Track 2 (amplitude)
~trackManager.createModulator(1, 0, 1);
~trackManager.setModSourceTrack(1, 0, 0);
~trackManager.routeModulation(1, 0, \amp, 0.3, 1.0);

// Track 2 → Track 3 (position)
~trackManager.createModulator(2, 0, 1);
~trackManager.setModSourceTrack(2, 0, 1);
~trackManager.routeModulation(2, 0, \position, 0.0, 1.0);

// Track 3 → Track 4 (grain size)
~trackManager.createModulator(3, 0, 1);
~trackManager.setModSourceTrack(3, 0, 2);
~trackManager.routeModulation(3, 0, \grainSize, 0.01, 0.3);

// Track 4 → Track 1 (pitch)
~trackManager.createModulator(0, 0, 1);
~trackManager.setModSourceTrack(0, 0, 3);
~trackManager.routeModulation(0, 0, \pitch, -5, 5);

"✓ All 4 tracks now form a circular ecosystem".postln;
"  → Changes ripple through the entire system".postln;
)

// ═══════════════════════════════════════
// EXAMPLE 4: Manual GUI Setup
// ═══════════════════════════════════════
(
"Example 4: Using the GUI".postln;
"".postln;
"To set up Mosaic Mode in the GUI:".postln;
"".postln;
"1. Open modulation window for a track".postln;
"2. Create a modulator (Type: Env Follow)".postln;
"3. Use the 'Listen:' dopdown (cyan label)".postln;
"4. Select which track to follow".postln;
"5. Route to any parameter".postln;
"".postln;
"The 'Listen:' selector appears in CYAN - that's Mosaic Mode!".postln;
)

// ═══════════════════════════════════════
// RESET ALL MODULATION
// ═══════════════════════════════════════
(
"Clearing all modulation...".postln;
4.do({ arg i;
	4.do({ arg m;
		~trackManager.removeModulation(i, m);
	});
});
"✓ All modulation cleared".postln;
)



// Track 1 → Track 2 → Track 3 → Track 4 (chain reaction)
// Each track modulates the next track's position

// Track 2 follows Track 1
~trackManager.createModulator(1, 0, 1);
~trackManager.setModSourceTrack(1, 0, 0);
~trackManager.routeModulation(1, 0, \position, 0, 1);

// Track 3 follows Track 2
~trackManager.createModulator(2, 0, 1);
~trackManager.setModSourceTrack(2, 0, 1);
~trackManager.routeModulation(2, 0, \position, 0, 1);

// Track 4 follows Track 3
~trackManager.createModulator(3, 0, 1);
~trackManager.setModSourceTrack(3, 0, 2);
~trackManager.routeModulation(3, 0, \position, 0, 1);



// Track 1 = Kick (playing continuously)
// Track 2 = Snare (triggered by kick)

~trackManager.createModulator(1, 0, 1);  // Envelope Follower
~trackManager.setModSourceTrack(1, 0, 0);  // Listen to Track 1
~trackManager.setModParam(1, 0, \threshold, 0.5);  // Trigger at 50% amplitude
~trackManager.routeModulation(1, 0, \trigger, 0, 1);  // Route to trigger input

// Result: Every time Track 1 kicks, Track 2 restarts its grain playback