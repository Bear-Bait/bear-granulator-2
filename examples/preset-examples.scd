/*
BEARULATOR: Preset Examples & Sound Design Templates
Phase 14 - Production-Ready Starting Points

10 Curated Presets:
1. Ambient Pad - Dense grain cloud, slow evolution
2. Rhythmic Glitch - Sparse grains, spectral freeze
3. Drone Machine - Low pitch, frozen spectral texture
4. Vocal Granulator - Speech-optimized settings
5. Percussion Mangler - Short grains, high density
6. Tape Delay Emulation - Vintage tape character
7. Shimmer Reverb Heaven - Spectral shimmer + reverb
8. Filter Sweep Texture - Auto-sweeping filter
9. Quad Spatial Journey - 4-track spatial preset
10. Live Input Setup - Ready for live processing

Usage:
  Load main.scd first, then run:
  "examples/preset-examples.scd".loadRelative;
*/

(
"".postln;
"════════════════════════════════════════════════".postln;
"  BEARULATOR: Creating Example Presets".postln;
"  Phase 14 - Sound Design Templates".postln;
"════════════════════════════════════════════════".postln;
"".postln;

fork {

	// ============================================
	// PRESET 1: AMBIENT PAD
	// ============================================

	"Creating: Ambient Pad...".postln;

	// Track 1: Dense grain cloud
	~trackManager.setParam(0, \grainSize, 0.2);
	~trackManager.setParam(0, \overlap, 64);
	~trackManager.setParam(0, \position, 0.5);
	~trackManager.setParam(0, \posJitter, 0.3);
	~trackManager.setParam(0, \pitchJitter, 2);
	~trackManager.setParam(0, \stereoSpread, 0.8);

	// Space FX
	~trackManager.setParam(0, \spaceOn, 1);
	~trackManager.setParam(0, \reverbSize, 0.9);
	~trackManager.setParam(0, \reverbDamp, 0.3);
	~trackManager.setParam(0, \reverbMix, 0.6);
	~trackManager.setParam(0, \shimmerPitch, 12);
	~trackManager.setParam(0, \shimmerMix, 0.3);

	// Spectral layer
	~trackManager.setParam(0, \spectralMix, 0.2);
	~trackManager.setParam(0, \spectralWindowSize, 0.4);
	~trackManager.setParam(0, \spectralRate, 0.5);

	~trackManager.setVolume(0, 0.7);

	0.1.wait;
	~presets.save("ambient_pad");
	"  ✓ Ambient Pad".postln;

	// ============================================
	// PRESET 2: RHYTHMIC GLITCH
	// ============================================

	"Creating: Rhythmic Glitch...".postln;

	// Reset all tracks first
	4.do({ arg i;
		~trackManager.setParam(i, \grainSize, 0.1);
		~trackManager.setParam(i, \overlap, 1);
		~trackManager.setParam(i, \colorOn, 0);
		~trackManager.setParam(i, \spaceOn, 0);
		~trackManager.setParam(i, \spectralMix, 0.0);
	});

	0.1.wait;

	// Track 1: Short grains, low overlap
	~trackManager.setParam(0, \grainSize, 0.05);
	~trackManager.setParam(0, \overlap, 4);
	~trackManager.setParam(0, \posJitter, 0.8);
	~trackManager.setParam(0, \pitchJitter, 5);

	// Spectral freeze for texture
	~trackManager.setParam(0, \spectralMix, 0.5);
	~trackManager.setParam(0, \spectralFreeze, 1);
	~trackManager.setParam(0, \spectralSmear, 0.4);

	// Color FX
	~trackManager.setParam(0, \colorOn, 1);
	~trackManager.setParam(0, \crushBits, 6);
	~trackManager.setParam(0, \crushMix, 0.4);

	~trackManager.setVolume(0, 0.8);

	0.1.wait;
	~presets.save("rhythmic_glitch");
	"  ✓ Rhythmic Glitch".postln;

	// ============================================
	// PRESET 3: DRONE MACHINE
	// ============================================

	"Creating: Drone Machine...".postln;

	// Reset
	4.do({ arg i;
		~trackManager.setParam(i, \grainSize, 0.1);
		~trackManager.setParam(i, \overlap, 1);
		~trackManager.setParam(i, \colorOn, 0);
		~trackManager.setParam(i, \spaceOn, 0);
		~trackManager.setParam(i, \spectralMix, 0.0);
		~trackManager.setParam(i, \spectralFreeze, 0);
	});

	0.1.wait;

	// Track 1: Low, sustained drone
	~trackManager.setParam(0, \grainSize, 0.5);
	~trackManager.setParam(0, \overlap, 32);
	~trackManager.setParam(0, \pitchShift, -12);  // One octave down
	~trackManager.setParam(0, \posJitter, 0.05);  // Very tight

	// Spectral engine for infinite sustain
	~trackManager.setParam(0, \spectralMix, 0.8);
	~trackManager.setParam(0, \spectralFreeze, 1);
	~trackManager.setParam(0, \spectralRate, 0.0);  // Frozen
	~trackManager.setParam(0, \spectralWindowSize, 0.5);

	// Subtle reverb
	~trackManager.setParam(0, \spaceOn, 1);
	~trackManager.setParam(0, \reverbMix, 0.4);
	~trackManager.setParam(0, \reverbFreeze, 1);

	~trackManager.setVolume(0, 0.6);

	0.1.wait;
	~presets.save("drone_machine");
	"  ✓ Drone Machine".postln;

	// ============================================
	// PRESET 4: VOCAL GRANULATOR
	// ============================================

	"Creating: Vocal Granulator...".postln;

	// Reset
	4.do({ arg i;
		~trackManager.setParam(i, \grainSize, 0.1);
		~trackManager.setParam(i, \overlap, 1);
		~trackManager.setParam(i, \colorOn, 0);
		~trackManager.setParam(i, \spaceOn, 0);
		~trackManager.setParam(i, \spectralMix, 0.0);
		~trackManager.setParam(i, \spectralFreeze, 0);
		~trackManager.setParam(i, \pitchShift, 0);
	});

	0.1.wait;

	// Track 1: Speech-optimized grain size
	~trackManager.setParam(0, \grainSize, 0.08);  // ~80ms for formants
	~trackManager.setParam(0, \overlap, 16);
	~trackManager.setParam(0, \posJitter, 0.15);
	~trackManager.setParam(0, \stereoSpread, 0.6);

	// Filter for presence
	~trackManager.setParam(0, \filterFreq, 3000);
	~trackManager.setParam(0, \filterMorph, 0.33);  // Lowpass
	~trackManager.setParam(0, \filterRes, 0.3);
	~trackManager.setParam(0, \filterMix, 0.5);

	// Subtle space
	~trackManager.setParam(0, \spaceOn, 1);
	~trackManager.setParam(0, \reverbMix, 0.25);
	~trackManager.setParam(0, \delayTime, 0.375);
	~trackManager.setParam(0, \delayMix, 0.15);

	~trackManager.setVolume(0, 0.75);

	0.1.wait;
	~presets.save("vocal_granulator");
	"  ✓ Vocal Granulator".postln;

	// ============================================
	// PRESET 5: PERCUSSION MANGLER
	// ============================================

	"Creating: Percussion Mangler...".postln;

	// Reset
	4.do({ arg i;
		~trackManager.setParam(i, \grainSize, 0.1);
		~trackManager.setParam(i, \overlap, 1);
		~trackManager.setParam(i, \colorOn, 0);
		~trackManager.setParam(i, \spaceOn, 0);
		~trackManager.setParam(i, \spectralMix, 0.0);
		~trackManager.setParam(i, \spectralFreeze, 0);
		~trackManager.setParam(i, \pitchShift, 0);
		~trackManager.setParam(i, \filterMix, 0.0);
	});

	0.1.wait;

	// Track 1: Tight grains, high density
	~trackManager.setParam(0, \grainSize, 0.01);  // 10ms grains
	~trackManager.setParam(0, \overlap, 32);
	~trackManager.setParam(0, \posJitter, 0.9);  // Highly scattered
	~trackManager.setParam(0, \pitchJitter, 12);  // Wide pitch range

	// Color FX for grit
	~trackManager.setParam(0, \colorOn, 1);
	~trackManager.setParam(0, \distMix, 0.5);
	~trackManager.setParam(0, \crushBits, 8);
	~trackManager.setParam(0, \crushMix, 0.3);

	// Ping-pong delay
	~trackManager.setParam(0, \spaceOn, 1);
	~trackManager.setParam(0, \delayTime, 0.25);
	~trackManager.setParam(0, \delayFeedback, 0.4);
	~trackManager.setParam(0, \delayPingPong, 1);
	~trackManager.setParam(0, \delayMix, 0.3);

	~trackManager.setVolume(0, 0.8);

	0.1.wait;
	~presets.save("percussion_mangler");
	"  ✓ Percussion Mangler".postln;

	// ============================================
	// PRESET 6: TAPE DELAY EMULATION
	// ============================================

	"Creating: Tape Delay Emulation...".postln;

	// Reset
	4.do({ arg i;
		~trackManager.setParam(i, \grainSize, 0.1);
		~trackManager.setParam(i, \overlap, 1);
		~trackManager.setParam(i, \colorOn, 0);
		~trackManager.setParam(i, \spaceOn, 0);
		~trackManager.setParam(i, \spectralMix, 0.0);
		~trackManager.setParam(i, \spectralFreeze, 0);
		~trackManager.setParam(i, \pitchShift, 0);
		~trackManager.setParam(i, \filterMix, 0.0);
	});

	0.1.wait;

	// Track 1: Vintage tape character
	~trackManager.setParam(0, \grainSize, 0.15);
	~trackManager.setParam(0, \overlap, 8);
	~trackManager.setParam(0, \posJitter, 0.05);  // Slight wow/flutter
	~trackManager.setParam(0, \pitchJitter, 0.5);  // Tape speed variation

	// Filter for tape darkness
	~trackManager.setParam(0, \filterFreq, 4000);
	~trackManager.setParam(0, \filterMorph, 0.2);  // Lowpass
	~trackManager.setParam(0, \filterRes, 0.2);
	~trackManager.setParam(0, \filterMix, 0.7);

	// Tape saturation
	~trackManager.setParam(0, \colorOn, 1);
	~trackManager.setParam(0, \distMix, 0.3);

	// Tape delay
	~trackManager.setParam(0, \spaceOn, 1);
	~trackManager.setParam(0, \delayTime, 0.5);
	~trackManager.setParam(0, \delayFeedback, 0.6);
	~trackManager.setParam(0, \delayMix, 0.5);

	~trackManager.setVolume(0, 0.7);

	0.1.wait;
	~presets.save("tape_delay");
	"  ✓ Tape Delay Emulation".postln;

	// ============================================
	// PRESET 7: SHIMMER REVERB HEAVEN
	// ============================================

	"Creating: Shimmer Reverb Heaven...".postln;

	// Reset
	4.do({ arg i;
		~trackManager.setParam(i, \grainSize, 0.1);
		~trackManager.setParam(i, \overlap, 1);
		~trackManager.setParam(i, \colorOn, 0);
		~trackManager.setParam(i, \spaceOn, 0);
		~trackManager.setParam(i, \spectralMix, 0.0);
		~trackManager.setParam(i, \spectralFreeze, 0);
		~trackManager.setParam(i, \pitchShift, 0);
		~trackManager.setParam(i, \filterMix, 0.0);
	});

	0.1.wait;

	// Track 1: Large grains, dense cloud
	~trackManager.setParam(0, \grainSize, 0.3);
	~trackManager.setParam(0, \overlap, 48);
	~trackManager.setParam(0, \posJitter, 0.2);
	~trackManager.setParam(0, \stereoSpread, 1.0);

	// Space FX: Maximum shimmer
	~trackManager.setParam(0, \spaceOn, 1);
	~trackManager.setParam(0, \reverbSize, 1.0);
	~trackManager.setParam(0, \reverbDamp, 0.2);
	~trackManager.setParam(0, \reverbMix, 0.7);
	~trackManager.setParam(0, \reverbFreeze, 1);
	~trackManager.setParam(0, \shimmerPitch, 24);  // Two octaves up
	~trackManager.setParam(0, \shimmerWindowSize, 0.3);
	~trackManager.setParam(0, \shimmerMix, 0.8);

	~trackManager.setVolume(0, 0.65);

	0.1.wait;
	~presets.save("shimmer_heaven");
	"  ✓ Shimmer Reverb Heaven".postln;

	// ============================================
	// PRESET 8: FILTER SWEEP TEXTURE
	// ============================================

	"Creating: Filter Sweep Texture...".postln;

	// Reset
	4.do({ arg i;
		~trackManager.setParam(i, \grainSize, 0.1);
		~trackManager.setParam(i, \overlap, 1);
		~trackManager.setParam(i, \colorOn, 0);
		~trackManager.setParam(i, \spaceOn, 0);
		~trackManager.setParam(i, \spectralMix, 0.0);
		~trackManager.setParam(i, \spectralFreeze, 0);
		~trackManager.setParam(i, \pitchShift, 0);
		~trackManager.setParam(i, \filterMix, 0.0);
	});

	0.1.wait;

	// Track 1: Ready for filter automation
	~trackManager.setParam(0, \grainSize, 0.12);
	~trackManager.setParam(0, \overlap, 24);
	~trackManager.setParam(0, \posJitter, 0.1);

	// Filter setup (ready for LFO modulation)
	~trackManager.setParam(0, \filterFreq, 1000);
	~trackManager.setParam(0, \filterMorph, 0.1);  // Ladder filter
	~trackManager.setParam(0, \filterRes, 0.6);
	~trackManager.setParam(0, \filterDrive, 0.3);
	~trackManager.setParam(0, \filterMix, 0.8);

	// Subtle space
	~trackManager.setParam(0, \spaceOn, 1);
	~trackManager.setParam(0, \reverbMix, 0.3);

	~trackManager.setVolume(0, 0.7);

	0.1.wait;
	~presets.save("filter_sweep");
	"  ✓ Filter Sweep Texture".postln;

	"  (Route LFO → Filter Frequency for auto-sweep!)".postln;

	// ============================================
	// PRESET 9: QUAD SPATIAL JOURNEY
	// ============================================

	"Creating: Quad Spatial Journey...".postln;

	// Reset
	4.do({ arg i;
		~trackManager.setParam(i, \grainSize, 0.1);
		~trackManager.setParam(i, \overlap, 1);
		~trackManager.setParam(i, \colorOn, 0);
		~trackManager.setParam(i, \spaceOn, 0);
		~trackManager.setParam(i, \spectralMix, 0.0);
		~trackManager.setParam(i, \spectralFreeze, 0);
		~trackManager.setParam(i, \pitchShift, 0);
		~trackManager.setParam(i, \filterMix, 0.0);
	});

	0.1.wait;

	// All 4 tracks: Complementary settings
	// Track 1: Front-left corner
	~trackManager.setParam(0, \grainSize, 0.15);
	~trackManager.setParam(0, \overlap, 16);
	~trackManager.setParam(0, \pitchShift, 0);
	~trackManager.setQuadPosition(0, -0.7, -0.7);
	~trackManager.setVolume(0, 0.65);

	// Track 2: Front-right corner
	~trackManager.setParam(1, \grainSize, 0.2);
	~trackManager.setParam(1, \overlap, 20);
	~trackManager.setParam(1, \pitchShift, 7);  // Perfect fifth
	~trackManager.setQuadPosition(1, 0.7, -0.7);
	~trackManager.setVolume(1, 0.6);

	// Track 3: Rear-left corner
	~trackManager.setParam(2, \grainSize, 0.25);
	~trackManager.setParam(2, \overlap, 24);
	~trackManager.setParam(2, \pitchShift, -5);  // Fourth down
	~trackManager.setQuadPosition(2, -0.7, 0.7);
	~trackManager.setVolume(2, 0.55);

	// Track 4: Rear-right corner
	~trackManager.setParam(3, \grainSize, 0.3);
	~trackManager.setParam(3, \overlap, 32);
	~trackManager.setParam(3, \pitchShift, 12);  // Octave up
	~trackManager.setQuadPosition(3, 0.7, 0.7);
	~trackManager.setVolume(3, 0.5);

	// Add reverb to all
	4.do({ arg i;
		~trackManager.setParam(i, \spaceOn, 1);
		~trackManager.setParam(i, \reverbMix, 0.4);
	});

	0.1.wait;
	~presets.save("quad_spatial");
	"  ✓ Quad Spatial Journey (4 tracks configured)".postln;

	// ============================================
	// PRESET 10: LIVE INPUT SETUP
	// ============================================

	"Creating: Live Input Setup...".postln;

	// Reset
	4.do({ arg i;
		~trackManager.setParam(i, \grainSize, 0.1);
		~trackManager.setParam(i, \overlap, 1);
		~trackManager.setParam(i, \colorOn, 0);
		~trackManager.setParam(i, \spaceOn, 0);
		~trackManager.setParam(i, \spectralMix, 0.0);
		~trackManager.setParam(i, \spectralFreeze, 0);
		~trackManager.setParam(i, \pitchShift, 0);
		~trackManager.setParam(i, \filterMix, 0.0);
		~trackManager.setParam(i, \mode, 2);  // LIVE mode
	});

	0.1.wait;

	// Track 1: Live processing preset
	~trackManager.setParam(0, \grainSize, 0.1);
	~trackManager.setParam(0, \overlap, 12);
	~trackManager.setParam(0, \posJitter, 0.2);
	~trackManager.setParam(0, \stereoSpread, 0.7);

	// Moderate space FX
	~trackManager.setParam(0, \spaceOn, 1);
	~trackManager.setParam(0, \reverbMix, 0.35);
	~trackManager.setParam(0, \delayTime, 0.375);
	~trackManager.setParam(0, \delayMix, 0.2);

	~trackManager.setVolume(0, 0.75);

	0.1.wait;
	~presets.save("live_input");
	"  ✓ Live Input Setup".postln;

	"".postln;
	"════════════════════════════════════════════════".postln;
	"  ✅ 10 Example Presets Created!".postln;
	"════════════════════════════════════════════════".postln;
	"".postln;

	"Available Presets:".postln;
	~presets.list;
	"".postln;

	"Try loading a preset:".postln;
	"  ~presets.load(\"ambient_pad\");".postln;
	"  ~presets.load(\"shimmer_heaven\");".postln;
	"  ~presets.load(\"quad_spatial\");".postln;
	"".postln;

	"Show preset info:".postln;
	"  ~presets.info(\"drone_machine\");".postln;
	"".postln;
};
)
