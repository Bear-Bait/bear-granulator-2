/*
====================================
S-4 RIVAL: GRANULAR SCULPTING SAMPLER
====================================

Main boot script
Phase 1: Core Granular Engine
Phase 2: Morphing Resonator
Phase 3: Effects Chain (Color + Space)

A SuperCollider-based granular synthesis workstation
inspired by the Torso Electronics S-4

Author: [Your Name]
Version: 0.3 (Phase 3)
Date: 2025-12-31

====================================
QUICK START:
1. Boot the server: s.boot;
2. Run this file: Cmd+A, Cmd+Enter
3. Use the GUI to control grain parameters
4. Click "Start Recording" to record live input
5. Adjust grain controls to sculpt sound
====================================
*/

(
// ============================================
// CONFIGURATION
// ============================================

var basePath = thisProcess.nowExecutingPath.dirname;

~config = (
	// Audio settings
	sampleRate: 48000,
	bufferSize: 4, // seconds
	maxGrains: 128,

	// Paths
	basePath: basePath,
	corePath: basePath +/+ "core",
	guiPath: basePath +/+ "gui",
	materialPath: basePath +/+ "material",
	ioPath: basePath +/+ "io",
	presetsPath: basePath +/+ "presets",
	samplesPath: basePath +/+ "samples",

	// Server options
	serverOptions: (
		numOutputBusChannels: 2,
		numInputBusChannels: 2,
		sampleRate: 48000,
		blockSize: 64,
		numBuffers: 1024 * 16,
		memSize: 8192 * 16
	)
);

"============================================".postln;
"S-4 RIVAL - GRANULAR SCULPTING SAMPLER".postln;
"Phase 3: Granular + Resonator + Effects".postln;
"============================================".postln;
"".postln;

// ============================================
// SERVER CONFIGURATION
// ============================================

fork {
	var serverBooted = false;

	"Configuring server...".postln;

	// Set server options
	s.options.numOutputBusChannels = ~config.serverOptions.numOutputBusChannels;
	s.options.numInputBusChannels = ~config.serverOptions.numInputBusChannels;
	s.options.sampleRate = ~config.serverOptions.sampleRate;
	s.options.blockSize = ~config.serverOptions.blockSize;
	s.options.numBuffers = ~config.serverOptions.numBuffers;
	s.options.memSize = ~config.serverOptions.memSize;

	// Check if server is running
	if(s.serverRunning.not, {
		"Server not running. Please boot server first with: s.boot;".postln;
		"Then run this script again.".postln;
		nil;
	}, {
		"Server is running.".postln;
		0.5.wait;

		// ============================================
		// LOAD CORE MODULES
		// ============================================

		"".postln;
		"Loading core modules...".postln;

		// Load filter shapes (Phase 2)
		(~config.corePath +/+ "filter-shapes.scd").load;
		0.2.wait;
		"  ✓ Filter shapes loaded".postln;

		// Load filterbank (Phase 2)
		(~config.corePath +/+ "filterbank.scd").load;
		0.2.wait;
		"  ✓ Filterbank loaded".postln;

		// Load color effects (Phase 3)
		(~config.corePath +/+ "effects-color.scd").load;
		0.2.wait;
		"  ✓ Color effects loaded".postln;

		// Load space effects (Phase 3)
		(~config.corePath +/+ "effects-space.scd").load;
		0.2.wait;
		"  ✓ Space effects loaded".postln;

		// Load grain engine SynthDef
		(~config.corePath +/+ "grain-engine.scd").load;
		0.2.wait;
		"  ✓ Grain engine loaded".postln;

		// Load buffer recorder
		(~config.corePath +/+ "buffer-recorder.scd").load;
		0.2.wait;
		"  ✓ Buffer recorder loaded".postln;

		// Load GUI (wide horizontal layout)
		(~config.guiPath +/+ "wide-gui.scd").load;
		0.2.wait;
		"  ✓ Wide GUI module loaded".postln;

		0.5.wait;

		// ============================================
		// INITIALIZE SYSTEM
		// ============================================

		"".postln;
		"Initializing system...".postln;

		// Create buffer recorder
		~recorder = ~s4BufferRecorder.value(s);
		~recorder.init;
		0.2.wait;
		"  ✓ Buffer recorder initialized".postln;

		// Create grain synth
		~grainSynth = Synth(\s4GrainEngine, [
			\bufnum, ~recorder.getBufferNum,
			\grainSize, 0.1,
			\density, 30,
			\position, 0.5,
			\pitch, 0,
			\posJitter, 0.1,
			\pitchJitter, 0,
			\envType, 1,
			\stereoSpread, 0.5,
			\amp, 0.5
		]);
		0.2.wait;
		"  ✓ Grain synth created".postln;

		// Create GUI (wide horizontal layout)
		~gui = ~s4WideGUI.value(~grainSynth, ~recorder, s);
		{ ~gui.create; }.defer;
		0.2.wait;
		"  ✓ Wide GUI created".postln;

		// ============================================
		// READY
		// ============================================

		"".postln;
		"============================================".postln;
		"SYSTEM READY!".postln;
		"============================================".postln;
		"".postln;
		"Phase 1 Features:".postln;
		"  • 128 grain granular engine".postln;
		"  • 4-second rolling buffer".postln;
		"  • Live input recording".postln;
		"  • Real-time grain control".postln;
		"  • Multiple envelope shapes".postln;
		"  • Stereo spread control".postln;
		"".postln;
		"Phase 2 Features:".postln;
		"  • 48-band morphing resonator".postln;
		"  • LP/BP/HP filter morphing".postln;
		"  • Harmonic & inharmonic tuning".postln;
		"  • Resonance & decay controls".postln;
		"  • Band animation system".postln;
		"  • Dry/wet mix control".postln;
		"".postln;
		"Phase 3 Features (NEW!):".postln;
		"  • COLOR: Dual-band distortion".postln;
		"  • COLOR: Bit crusher (lo-fi)".postln;
		"  • COLOR: Compressor/dynamics".postln;
		"  • COLOR: Noise generator".postln;
		"  • SPACE: Reverb with freeze".postln;
		"  • SPACE: Delay (ping-pong)".postln;
		"  • SPACE: Shimmer (pitch-shift delay)".postln;
		"".postln;
		"Quick Start - GET SOUND NOW:".postln;
		"  1. Click the cyan 'Load Test Sound' button (top-left)".postln;
		"  2. You should immediately hear granular synthesis!".postln;
		"  3. Adjust grain sliders to sculpt the sound".postln;
		"".postln;
		"Live Recording (MOTU Mk5):".postln;
		"  • Select input channel (1-8)".postln;
		"  • Click green 'REC' button to record live input".postln;
		"".postln;
		"Effects:".postln;
		"  • Enable Filter for 48-band morphing resonator".postln;
		"  • Enable Color FX for distortion/crush/compression".postln;
		"  • Enable Space FX for reverb/delay/shimmer".postln;
		"  • Try reverb freeze or shimmer pitch-shift!".postln;
		"".postln;
		"Global Variables:".postln;
		"  ~recorder - Buffer recording system".postln;
		"  ~grainSynth - Main grain synthesis engine".postln;
		"  ~gui - GUI controller".postln;
		"  ~config - System configuration".postln;
		"  ~filterShapes - Filter morphing functions".postln;
		"  ~filterbank - 48-band resonator functions".postln;
		"".postln;
		"Cleanup (when done):".postln;
		"  ~cleanup.value; // Stop everything and free resources".postln;
		"".postln;
		"============================================".postln;

		// Register cleanup function
		~cleanup = {
			"Cleaning up...".postln;
			if(~gui.notNil, { ~gui.close; });
			if(~grainSynth.notNil, { ~grainSynth.free; });
			if(~recorder.notNil, { ~recorder.free; });
			"Cleanup complete.".postln;
		};

		// Monitor CPU usage
		fork {
			var cpu;
			loop {
				10.wait;
				cpu = s.avgCPU;
				if(cpu > 15, {
					"Warning: CPU usage at %% (target <15%)".format(cpu.round(0.1)).postln;
				});
			};
		};
	});
};
)

/*
============================================
ADDITIONAL NOTES
============================================

Phase 1 Testing Criteria:
✓ CPU usage <15% for single track
✓ No audio dropouts at 128 grains
✓ Smooth grain triggering
✓ Clean buffer recording

Next Steps (Phase 2):
- 48-band morphing resonator
- LP/BP/HP filter morphing
- Harmonic/inharmonic tuning
- Resonance control

To reload this script:
1. Run cleanup: ~cleanup.value;
2. Re-execute this entire file

For more info, see README.md
============================================
*/
