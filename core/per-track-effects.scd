/*
BEARULATOR: Per-Track Effects Chain
Phase 16 - Unified effects chain for all engines

Sits AFTER grain/direct engines in the signal chain.
Handles:
- Engine crossfading (GRANULAR ↔ DIRECT blend)
- Color effects (distortion, bitcrusher, compressor, noise)
- Space effects (reverb, delay, shimmer)

Signal Flow:
grainBus → [effects chain] → trackBus → master
directBus → ↑
*/

SynthDef(\bearulatorPerTrackEffects, {
	arg grainIn = 10,        // Input bus from grain engine
	    directIn = 12,       // Input bus from direct engine
	    out = 0,             // Output bus (track audio bus)
	    engineMorph = 0,     // Engine blend (0=grain only, 1=direct only, 0.5=50/50)

	    // Color effects
	    colorOn = 0,
	    distCrossover = 500,
	    distLoDrive = 1,
	    distHiDrive = 1,
	    distMix = 0,
	    crushRate = 8000,
	    crushBits = 8,
	    crushMix = 0,
	    compThresh = 0.5,
	    compRatio = 4,
	    compAttack = 0.01,
	    compRelease = 0.1,
	    noiseType = 0,
	    noiseAmount = 0,

	    // Space effects
	    spaceOn = 0,
	    reverbSize = 0.5,
	    reverbDamp = 0.5,
	    reverbFreeze = 0,
	    reverbMix = 0.3,
	    delayTime = 0.25,
	    delayFeedback = 0.5,
	    delayFilter = 5000,
	    delayPingPong = 0,
	    delayMix = 0.3,
	    shimmerTime = 0.5,
	    shimmerFeedback = 0.6,
	    shimmerPitch = 12,
	    shimmerWindowSize = 0.2,
	    shimmerMix = 0;

	var grainSig, directSig, sig;
	var colorSig, spaceSig;

	// Read from both engine buses
	grainSig = In.ar(grainIn, 2);
	directSig = In.ar(directIn, 2);

	// Crossfade between engines using XFade2
	// engineMorph: 0=grain, 0.5=equal mix, 1=direct
	sig = XFade2.ar(
		grainSig,
		directSig,
		engineMorph.linlin(0, 1, -1, 1)  // Convert 0-1 to -1 to 1 for XFade2
	);

	// === COLOR EFFECTS ===
	colorSig = Select.ar(colorOn, [
		sig,  // Bypass
		sig   // Effects chain (to be implemented)
	]);

	// === SPACE EFFECTS ===
	spaceSig = Select.ar(spaceOn, [
		colorSig,  // Bypass
		colorSig   // Effects chain (to be implemented)
	]);

	Out.ar(out, spaceSig);
}).add;

"✓ Per-track effects chain loaded".postln;
