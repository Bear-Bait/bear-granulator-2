/*
═══════════════════════════════════════════════════════════════════
SIGUR ROS - GENERATIVE AMBIENT PRESET
═══════════════════════════════════════════════════════════════════

OBJECTIVE: Create a generative ambient preset rivaling "1-5fq" (Yoshimura/Eno inspiration)

RECIPE (from TODO.md):
- Sample: Pure Rhodes, Chime, or Female Vocal
- Settings: timeStretch = 0.1, reverbMix = 0.7, shimmerMix = 0.5
- Sequencer: 64-step slow drift on Pentatonic scale

INSPIRATION:
- Sigur Rós "Hoppípolla" - slow-building, glacial beauty
- Brian Eno "1/1" - infinite sustain, harmonic shimmer
- Hiroshi Yoshimura "Creek" - pentatonic drift, wide intervals

USAGE:
1. Load a clean, sustained sample (Rhodes, vocal "ah", or chime)
2. Run this script to configure Track 1
3. Press PLAY in GUI
4. Let it evolve for 5-10 minutes

REQUIRES: v2.4 with shimmer effects
*/

(
fork {
	"".postln;
	"═══════════════════════════════════════════".postln;
	"  Creating SIGUR ROS Generative Preset".postln;
	"═══════════════════════════════════════════".postln;
	"".postln;

	// ============================================
	// STEP 1: RESET TRACK 1
	// ============================================
	
	"→ Resetting Track 1 to defaults...".postln;
	
	~trackManager.setParam(0, \grainSize, 0.1);
	~trackManager.setParam(0, \overlap, 1);
	~trackManager.setParam(0, \colorOn, 0);
	~trackManager.setParam(0, \spaceOn, 0);
	~trackManager.setParam(0, \spectralMix, 0.0);
	~trackManager.setParam(0, \spectralFreeze, 0);
	~trackManager.setParam(0, \filterOn, 0);
	
	0.2.wait;

	// ============================================
	// STEP 2: GRANULAR ENGINE - GLACIAL TIME
	// ============================================
	
	"→ Configuring granular engine (ultra-slow time stretch)...".postln;
	
	// CRITICAL: timeStretch = 0.1 (10x slower than real-time)
	~trackManager.setParam(0, \timeStretch, 0.1);
	
	// Dense grain cloud for smooth texture
	~trackManager.setParam(0, \grainSize, 0.3);   // Long grains
	~trackManager.setParam(0, \overlap, 64);      // Dense overlap
	
	// Minimal jitter for stability (Sigur Rós = patient, not jittery)
	~trackManager.setParam(0, \posJitter, 0.03);
	~trackManager.setParam(0, \pitchJitter, 0);   // No pitch jitter yet (sequencer handles melody)
	
	// Scanning mode: very slow forward drift
	~trackManager.setParam(0, \scanSpeed, 0.05);  // Barely moving
	
	0.2.wait;

	// ============================================
	// STEP 3: PITCH SEQUENCER - PENTATONIC DRIFT
	// ============================================
	
	"→ Generating 64-step pentatonic sequence (slow drift)...".postln;
	
	// Generate Yoshimura-inspired pentatonic pattern with wide intervals
	{
		var pentatonic = [0, 2, 4, 7, 9, 12, 14, 16];  // Two octaves
		var pitchSeq = Array.newClear(64);
		var currentPitch = 0;
		var jump;
		
		// Generate slow-moving melody with occasional wide jumps
		64.do({ |i|
			if(i % 8 == 0, {
				// Every 8 steps: wide jump (Yoshimura "Creek" style)
				jump = pentatonic.choose;
			}, {
				// Small steps: drift up or down by 1-2 scale degrees
				jump = [0, 2, -2, 4].wchoose([0.5, 0.25, 0.15, 0.1]);
			});
			
			currentPitch = (currentPitch + jump).clip(-12, 24);
			
			// Snap to pentatonic scale
			currentPitch = pentatonic.minItem({ |deg| (currentPitch - deg).abs });
			
			pitchSeq[i] = currentPitch;
		});
		
		// Apply pitch sequence
		~trackManager.setParam(0, \pitchSeq, pitchSeq);
		~trackManager.setParam(0, \pitchJitter, 1.0);  // Enable sequencer (full strength)
		
		pitchSeq;  // Return value
	}.value;
	
	"  ✓ Pitch sequence: slow pentatonic drift with occasional leaps".postln;
	
	0.2.wait;

	// ============================================
	// STEP 4: SPECTRAL ENGINE - INFINITE SUSTAIN
	// ============================================
	
	"→ Adding spectral layer (Eno-style infinite sustain)...".postln;
	
	~trackManager.setParam(0, \spectralMix, 0.3);        // 30% spectral blend
	~trackManager.setParam(0, \spectralWindowSize, 0.4); // Smooth, not glitchy
	~trackManager.setParam(0, \spectralRate, 0.2);       // Almost frozen
	~trackManager.setParam(0, \spectralFreeze, 0.5);     // Partial freeze
	~trackManager.setParam(0, \spectralSmear, 0.2);      // Subtle smear
	
	0.2.wait;

	// ============================================
	// STEP 5: SPACE EFFECTS - CATHEDRAL REVERB
	// ============================================
	
	"→ Configuring space effects (massive shimmer reverb)...".postln;
	
	~trackManager.setParam(0, \spaceOn, 1);
	
	// CRITICAL: reverbMix = 0.7 (70% wet - huge space)
	~trackManager.setParam(0, \reverbSize, 0.9);
	~trackManager.setParam(0, \reverbMix, 0.7);
	~trackManager.setParam(0, \reverbDamp, 0.3);    // Bright, not dark
	~trackManager.setParam(0, \reverbFreeze, 0.6);  // Long tails
	
	// CRITICAL: shimmerMix = 0.5 (octave-up shimmer like Sigur Rós strings)
	~trackManager.setParam(0, \shimmerPitch, 12);   // +1 octave
	~trackManager.setParam(0, \shimmerMix, 0.5);
	~trackManager.setParam(0, \shimmerFeedback, 0.7);
	~trackManager.setParam(0, \shimmerTime, 0.6);
	
	// Subtle delay for rhythmic pulse (Eno "1/1" style)
	~trackManager.setParam(0, \delayTime, 0.75);    // Dotted quarter
	~trackManager.setParam(0, \delayMix, 0.2);
	~trackManager.setParam(0, \delayFeedback, 0.5);
	
	"  ✓ Space: 70% reverb, 50% shimmer, subtle delay".postln;
	
	0.2.wait;

	// ============================================
	// STEP 6: FILTER - GENTLE HIGH-PASS
	// ============================================
	
	"→ Adding subtle filter (clarity in the highs)...".postln;
	
	~trackManager.setParam(0, \filterOn, 1);
	~trackManager.setParam(0, \filterType, 0);      // Morphing filter
	~trackManager.setParam(0, \filterMorph, 0.9);   // High-pass
	~trackManager.setParam(0, \filterFreq, 0.2);    // Gentle (200 Hz)
	~trackManager.setParam(0, \filterRes, 0.1);     // Minimal resonance
	~trackManager.setParam(0, \filterMix, 0.3);     // Subtle
	
	0.2.wait;

	// ============================================
	// STEP 7: FINAL SETTINGS
	// ============================================
	
	"→ Setting volume and amp...".postln;
	
	~trackManager.setParam(0, \amp, 0.6);
	~trackManager.setVolume(0, 0.7);
	
	0.2.wait;

	// ============================================
	// STEP 8: SAVE PRESET
	// ============================================
	
	"→ Saving preset...".postln;
	~presets.save("sigur_ros_generative");
	
	"".postln;
	"═══════════════════════════════════════════".postln;
	"  ✓ SIGUR ROS PRESET CREATED!".postln;
	"═══════════════════════════════════════════".postln;
	"".postln;
	"USAGE:".postln;
	"  1. Load a clean sustained sample (Rhodes/Vocal/Chime)".postln;
	"  2. Press PLAY in Track 1".postln;
	"  3. Let it evolve for 5-10 minutes".postln;
	"  4. Adjust timeStretch (0.05-0.2) for slower/faster drift".postln;
	"".postln;
	"CHARACTERISTICS:".postln;
	"  • Ultra-slow time (timeStretch = 0.1)".postln;
	"  • Pentatonic melody with wide interval leaps".postln;
	"  • 70% cathedral reverb".postln;
	"  • 50% octave-up shimmer".postln;
	"  • Partial spectral freeze (30% blend)".postln;
	"  • Gentle high-pass filter for clarity".postln;
	"".postln;
	"RIVALS: Yoshimura 'Green', Eno '1/1', Sigur Rós 'Hoppípolla'".postln;
	"".postln;
	
	// ============================================
	// BONUS: LOAD IT TO VERIFY
	// ============================================
	
	2.wait;
	"".postln;
	"→ Verifying preset...".postln;
	~presets.info("sigur_ros_generative");
};
)
