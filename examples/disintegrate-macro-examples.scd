/*
BEARULATOR: Disintegrate Macro Examples
Phase 16 - One Knob to Destroy

The DISINTEGRATE knob is a master entropy control.
One slider controls 5 parameters simultaneously across ALL tracks:
- ↑ Position Jitter (chaos)
- ↓ Bit Depth (lo-fi degradation)
- ↑ Reverb Mix (space/wash)
- ↓ Scan Speed (slowdown/time stretch)
- ↑ Crush Mix (digital destruction)

Perfect for live performance transitions!

Run these AFTER loading main.scd and creating tracks.
*/

(
"═══════════════════════════════════════".postln;
"  DISINTEGRATE MACRO EXAMPLES".postln;
"  Phase 16 - Entropy Control".postln;
"═══════════════════════════════════════".postln;
)

// ═══════════════════════════════════════
// EXAMPLE 1: Slow Disintegration
// ═══════════════════════════════════════
// Gradually destroy a 4-track arrangement
(
fork {
	var steps = 100;  // Number of steps
	var duration = 30; // 30 seconds total

	"Example 1: Slow Disintegration (30 seconds)".postln;
	"".postln;

	// Load samples on all tracks (using actual stock samples)
	~trackManager.loadSample(0, "samples/stock/a11wlk01.wav");
	~trackManager.loadSample(1, "samples/stock/A3.wav");
	~trackManager.loadSample(2, "samples/stock/coins.wav");
	~trackManager.loadSample(3, "samples/stock/SinedPink.aiff");

	// Start all tracks playing
	4.do({ arg i| ~trackManager.setParam(i, \amp, 0.5) });

	"Starting clean...".postln;
	1.wait;

	// Slowly increase entropy from 0.0 to 1.0
	steps.do({ arg i;
		var val = i.linlin(0, steps, 0.0, 1.0);

		// Apply EXTREME disintegration
		4.do({ arg trackNum;
			~trackManager.setParam(trackNum, \posJitter, val.linlin(0, 1, 0.1, 5.0));        // 0.1 → 5.0 (extreme chaos)
			~trackManager.setParam(trackNum, \crushBits, val.linexp(0.01, 1, 16, 1));        // 16 → 1 bit (severe lo-fi)
			~trackManager.setParam(trackNum, \reverbMix, val.linlin(0, 1, 0.0, 1.0));        // 0 → 100% wet
			~trackManager.setParam(trackNum, \scanSpeed, val.linlin(0, 1, 0, -2.0));         // Reverse at 2x speed
			~trackManager.setParam(trackNum, \crushMix, val);                                 // 0 → 100% destruction
			~trackManager.setParam(trackNum, \pitchJitter, val.linlin(0, 1, 0, 12.0));       // 0 → 1 octave jitter
			~trackManager.setParam(trackNum, \filterRes, val.linlin(0, 1, 0.1, 0.99));       // Screaming resonance
			~trackManager.setParam(trackNum, \distortionAmount, val.linlin(0, 1, 0, 1.0));   // Add distortion
		});

		if(i % 10 == 0, {
			"Entropy: %% complete".format((val * 100).round).postln;
		});

		(duration / steps).wait;
	});

	"".postln;
	"✓ Total disintegration complete!".postln;
}
)

// ═══════════════════════════════════════
// EXAMPLE 2: Instant Destroy (KeyStep Pro)
// ═══════════════════════════════════════
// Map Disintegrate to a KeyStep Pro knob
(
"Example 2: Map to KeyStep Pro Knob".postln;
"".postln;

// Map CC 78 (Knob 5) to control EXTREME disintegration
MIDIdef.cc(\disintegrate_macro, { arg val;
	var entropy = val / 127.0;  // 0.0 to 1.0

	// Apply EXTREME disintegration to all tracks
	4.do({ arg i;
		~trackManager.setParam(i, \posJitter, entropy.linlin(0, 1, 0.1, 5.0));        // Extreme chaos
		~trackManager.setParam(i, \crushBits, entropy.linexp(0.01, 1, 16, 1));        // 1-bit destruction
		~trackManager.setParam(i, \reverbMix, entropy.linlin(0, 1, 0.0, 1.0));        // Full wet reverb
		~trackManager.setParam(i, \scanSpeed, entropy.linlin(0, 1, 0, -2.0));         // Fast reverse
		~trackManager.setParam(i, \crushMix, entropy);                                 // Full bitcrusher
		~trackManager.setParam(i, \pitchJitter, entropy.linlin(0, 1, 0, 12.0));       // Octave jitter
		~trackManager.setParam(i, \filterRes, entropy.linlin(0, 1, 0.1, 0.99));       // Resonance scream
		~trackManager.setParam(i, \distortionAmount, entropy.linlin(0, 1, 0, 1.0));   // Distortion
	});

}, ccNum: 78);

"✓ KeyStep Pro Knob 5 → Disintegrate Macro".postln;
"  → Turn knob to destroy the universe!".postln;
)

// ═══════════════════════════════════════
// EXAMPLE 3: Automated Entropy Pulse
// ═══════════════════════════════════════
// Pulse entropy in and out like a heartbeat
(
fork {
	var pulseRate = 2.0;  // Hz
	var duration = 20;    // seconds

	"Example 3: Entropy Pulse (20 seconds)".postln;
	"".postln;

	inf.do({
		var phase = SystemClock.seconds.wrap(0, 1.0 / pulseRate) * pulseRate;
		var entropy = sin(phase * 2pi).range(0, 1);  // Sine wave 0-1

		// Apply EXTREME pulsing entropy
		4.do({ arg i;
			~trackManager.setParam(i, \posJitter, entropy.linlin(0, 1, 0.1, 5.0));        // Chaos pulses
			~trackManager.setParam(i, \crushBits, entropy.linexp(0.01, 1, 16, 1));        // Lo-fi pulses
			~trackManager.setParam(i, \reverbMix, entropy.linlin(0, 1, 0.0, 1.0));        // Reverb wash
			~trackManager.setParam(i, \scanSpeed, entropy.linlin(0, 1, 0, -2.0));         // Reverse pulses
			~trackManager.setParam(i, \crushMix, entropy);                                 // Crush pulses
			~trackManager.setParam(i, \pitchJitter, entropy.linlin(0, 1, 0, 12.0));       // Pitch chaos
			~trackManager.setParam(i, \filterRes, entropy.linlin(0, 1, 0.1, 0.99));       // Resonance pulses
			~trackManager.setParam(i, \distortionAmount, entropy.linlin(0, 1, 0, 1.0));   // Distortion pulses
		});

		0.05.wait;  // Update 20x per second
	});
}
)

// ═══════════════════════════════════════
// EXAMPLE 4: GUI Usage
// ═══════════════════════════════════════
(
"Example 4: Using the GUI Slider".postln;
"".postln;
"Look in the MASTER tab for:".postln;
"".postln;
"  DISINTEGRATE (red text)".postln;
"  Entropy → [long slider]".postln;
"".postln;
"Move the slider:".postln;
"  • Left (0.0)  = Clean, pristine audio".postln;
"  • Middle (0.5) = Starting to break apart".postln;
"  • Right (1.0)  = Total sonic destruction".postln;
"".postln;
"Perfect for:".postln;
"  • Live performance transitions".postln;
"  • Building/releasing tension".postln;
"  • Destroying the universe with one hand".postln;
"  • Holding a beer with the other hand".postln;
)

// ═══════════════════════════════════════
// RESET TO CLEAN STATE
// ═══════════════════════════════════════
(
"Resetting all tracks to clean state...".postln;

4.do({ arg i;
	~trackManager.setParam(i, \posJitter, 0.1);
	~trackManager.setParam(i, \crushBits, 16);
	~trackManager.setParam(i, \reverbMix, 0.0);
	~trackManager.setParam(i, \scanSpeed, 0);
	~trackManager.setParam(i, \crushMix, 0);
});

"✓ All tracks clean".postln;
)
