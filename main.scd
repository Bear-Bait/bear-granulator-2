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
Version: 0.4 (Phase 4)
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
		numInputBusChannels: 8,  // MOTU Mk5 has 8 inputs - enable all
		sampleRate: 48000,
		blockSize: 64,
		numBuffers: 1024 * 16,
		memSize: 8192 * 256  // Total memory: ~2GB for 4 tracks + delays/pitch-shift
	)
);

"============================================".postln;
"S-4 RIVAL - GRANULAR SCULPTING SAMPLER".postln;
"Phase 4: 4-Track Architecture".postln;
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
	s.options.memSize = ~config.serverOptions.memSize;  // ~2GB total for all synth memory

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

		// Load modulator system (Phase 5)
		(~config.corePath +/+ "modulator.scd").load;
		0.2.wait;
		"  ✓ Modulator system loaded".postln;

		// Load track manager (Phase 4)
		(~config.corePath +/+ "track-manager.scd").load;
		0.2.wait;
		"  ✓ Track manager loaded".postln;

		// Load master mix bus (Phase 4)
		(~config.corePath +/+ "mix-bus.scd").load;
		0.2.wait;
		"  ✓ Master mix bus loaded".postln;

		// Load visualizer module (Phase 8 - early implementation)
		(~config.guiPath +/+ "visualizer.scd").load;
		0.2.wait;
		"  ✓ Visualizer module loaded".postln;

		// Load modulation window (Phase 5)
		(~config.guiPath +/+ "modulation-window.scd").load;
		0.2.wait;
		"  ✓ Modulation window loaded".postln;

		// Load 4-track GUI (Phase 4)
		(~config.guiPath +/+ "four-track-view.scd").load;
		0.2.wait;
		"  ✓ Four-track GUI module loaded".postln;

		0.5.wait;

		// ============================================
		// INITIALIZE SYSTEM
		// ============================================

		"".postln;
		"Initializing 4-track system...".postln;

		// Initialize track manager
		~trackManager = ~s4TrackManager.value(s);
		~trackManager.init;
		0.2.wait;
		"  ✓ Track manager initialized".postln;

		// Create 4 track instances (stagger to avoid CPU spike)
		4.do({ |i|
			~trackManager.createTrack(i);
			0.1.wait;
		});
		"  ✓ 4 tracks created".postln;

		// Create master bus synth (MUST use addToTail)
		~masterBus = Synth(\s4MasterBus, [
			\track1Bus, ~trackManager.getTracks[0].audioBus.index,
			\track2Bus, ~trackManager.getTracks[1].audioBus.index,
			\track3Bus, ~trackManager.getTracks[2].audioBus.index,
			\track4Bus, ~trackManager.getTracks[3].audioBus.index,
			\filterOn, 0,
			\masterVol, 0.8
		], addAction: \addToTail);
		0.2.wait;
		"  ✓ Master bus created".postln;

		// Set master bus reference in track manager
		~trackManager.setMasterBus(~masterBus);

		// Create 4-track GUI
		~gui = ~s4FourTrackGUI.value(~trackManager, ~masterBus, s);
		{ ~gui.create; }.defer;
		0.2.wait;
		"  ✓ Four-track GUI created".postln;

		// Backward compatibility: expose track 1 as ~grainSynth
		~grainSynth = ~trackManager.getTracks[0].grainSynth;
		~recorder = ~trackManager.getTracks[0].recorder;

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
		"Phase 3 Features:".postln;
		"  • COLOR: Dual-band distortion".postln;
		"  • COLOR: Bit crusher (lo-fi)".postln;
		"  • COLOR: Compressor/dynamics".postln;
		"  • COLOR: Noise generator".postln;
		"  • SPACE: Reverb with freeze".postln;
		"  • SPACE: Delay (ping-pong)".postln;
		"  • SPACE: Shimmer (pitch-shift delay)".postln;
		"".postln;
		"Phase 4 Features (NEW!):".postln;
		"  • 4 independent granular tracks".postln;
		"  • 512 total grains (128 per track)".postln;
		"  • Per-track Color + Space effects".postln;
		"  • Shared 48-band resonator (master bus)".postln;
		"  • Per-track volume/pan/mute/solo".postln;
		"  • Optimized CPU usage (<50% target)".postln;
		"".postln;
		"Quick Start - GET SOUND NOW:".postln;
		"  1. Click the cyan 'Load Test Sound' button (top-left)".postln;
		"  2. You should immediately hear granular synthesis on Track 1!".postln;
		"  3. Adjust grain sliders to sculpt the sound".postln;
		"".postln;
		"Multi-Track Control (Phase 4):".postln;
		"  • ~trackManager.setParam(trackNum, param, value)".postln;
		"  • ~trackManager.setVolume(trackNum, 0-1)".postln;
		"  • ~trackManager.setPan(trackNum, -1 to 1)".postln;
		"  • ~trackManager.setMute(trackNum, true/false)".postln;
		"  • ~trackManager.setSolo(trackNum, true/false)".postln;
		"  • Example: ~trackManager.setParam(1, \\grainSize, 0.2)".postln;
		"".postln;
		"Live Recording (MOTU Mk5):".postln;
		"  • Select input channel (1-8)".postln;
		"  • Click green 'REC' button to record live input".postln;
		"".postln;
		"Effects:".postln;
		"  • Enable Color FX for distortion/crush/compression (per-track)".postln;
		"  • Enable Space FX for reverb/delay/shimmer (per-track)".postln;
		"  • Enable Filter on MASTER BUS for 48-band resonator (all tracks)".postln;
		"  • Master filter: ~masterBus.set(\\filterOn, 1)".postln;
		"".postln;
		"Global Variables:".postln;
		"  ~trackManager - 4-track management system (Phase 4)".postln;
		"  ~masterBus - Master mix bus with 48-band filter (Phase 4)".postln;
		"  ~grainSynth - Track 1 synth (backward compatibility)".postln;
		"  ~recorder - Track 1 recorder (backward compatibility)".postln;
		"  ~gui - GUI controller".postln;
		"  ~config - System configuration".postln;
		"".postln;
		"Cleanup (when done):".postln;
		"  ~cleanup.value; // Stop everything and free resources".postln;
		"".postln;
		"============================================".postln;

		// Register cleanup function
		~cleanup = {
			"Cleaning up...".postln;
			if(~gui.notNil, { ~gui.close; });
			if(~masterBus.notNil, { ~masterBus.free; });
			if(~trackManager.notNil, { ~trackManager.free; });
			"Cleanup complete.".postln;
		};

		// Monitor CPU usage
		fork {
			var cpu;
			loop {
				10.wait;
				cpu = s.avgCPU;
				if(cpu > 50, {
					"Warning: CPU usage at %% (target <50%)".format(cpu.round(0.1)).postln;
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
