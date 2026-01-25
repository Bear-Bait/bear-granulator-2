/*
BEARULATOR: Core Granular Engine v2.3
Phase 1 - Main SynthDef with GrainBuf
Phase 2 - Integrated 48-band Morphing Resonator
Phase 6 - Material Modes (TAPE/POLY/LIVE)
Phase 6b - Overlap Control (musical grain density)
Phase 15 - Time Stretch (temporal scaling without pitch shift)
v2.1 - Decoupled Time/Pitch, 64-Step Sequencer, Click-Free Switching
v2.2 - Probability Masking (Bernoulli Gate)
v2.3 - LO-FI Grain Switch (6 modes: HD→Pro→Texture→Lo-Fi→Glitch→Broken)

KEY CHANGES IN v2.3:
- Added 'loFiGrains' parameter (0-5 for density scaling)
- IMPORTANT: GrainBuf's maxGrains is INIT-ONLY (can't change dynamically!)
- LO-FI effect achieved via PROBABILITY MASKING on triggers instead
- Density multipliers: HD(1.0), Pro(0.5), Texture(0.25), Lo-Fi(0.11), Glitch(0.06), Broken(0.06+dropout)
- 500ms smooth transitions between modes (Lag.kr)
- "Broken" mode adds irregular 33% dropout using Dust.kr for glitchy character
- SendReply for /grainCount enables GUI feedback of active grain estimate

Features:
- Up to 256 grains (dynamic based on overlap setting)
- Variable buffer playback (any length)
- Grain size: 1ms-60s (microtones to full loops, no upper limit)
- Overlap control: 1-128 simultaneous grains (replaces density)
- Time stretch: 0.25x-4x (slows/speeds grain stream, maintains pitch)
- Pitch control: -2 to +2 octaves
- 4 envelope shapes
- Position jitter & pitch jitter (now sequenced via Demand UGens)
- Stereo spread
- 48-band morphing resonator (LP/BP/HP) [DEPRECATED - use per-track filter]
- Harmonic/inharmonic tuning
- Resonance and animation controls

Args:
  bufnum: Buffer number for grain source
  grainMode: Material mode (0=TAPE loop, 1=POLY sample, 2=LIVE input)
  grainSize: Grain duration in seconds (0.001-60+, unlimited)
   overlap: Number of simultaneous grains (1-256) - MAXIMUM DENSITY
  density: Grains per second (1-200) - LEGACY, use overlap instead
  useOverlap: 1=use overlap mode (default), 0=use density mode
  prob: Grain probability/density mask (0.0=silence, 1.0=always trigger) - v2.2
  loFiGrains: LO-FI mode (0=HD 256, 1=Pro 128, 2=Texture 64, 3=Lo-Fi 28, 4=Glitch 16, 5=Broken) - v2.3
  position: Playback position in buffer (0-1)
  scanSpeed: Continuous scanning speed (0=static, ±4=fast)
  timeStretch: Master time stretch (0.25-4x, scales grain rate & size, NOT pitch)
  pitch: Pitch shift in semitones (-24 to +24) - LEGACY (changes speed+pitch)
  pitchShift: True pitch shift in semitones (-24 to +24) - NEW (preserves speed)
  posJitter: Amplitude of position sequence (0-1)
  pitchJitter: Amplitude of pitch sequence (0-12 semitones)
  posSeq: 64-step position sequence array (values -1 to 1)
  pitchSeq: 64-step pitch sequence array (values in semitones)
  envType: Envelope shape (0=Perc, 1=Sine, 2=Triangle, 3=Welch)
  stereoSpread: Stereo width (0-1)
  amp: Output amplitude (0-1)
  pan: Stereo pan (-1 to 1)
  loopStart: Loop region start (0-1, TAPE mode only)
  loopEnd: Loop region end (0-1, TAPE mode only)

  filterOn: Enable per-track filter (0=off, 1=on) - Phase 10
  filterFreq: Filter cutoff frequency (0-1, mapped to 20Hz-18kHz exponential)
  filterMorph: Filter topology & type (0-0.33=Ladder, 0.33-1.0=SVF LP/BP/HP)
  filterRes: Resonance/Q factor (0-1)
  filterDecay: Pre-filter drive amount (0=clean, 1=saturated) - Phase 10
  filterMix: Filter dry/wet mix (0=dry, 1=wet)

  colorOn: Enable color effects chain (0=off, 1=on)
  spaceOn: Enable space effects chain (0=off, 1=on)

  out: Output bus
*/

SynthDef(\bearulatorGrainEngine, {
	arg bufnum = 0,
	    grainMode = 0,     // v2.1: RENAMED from 'mode' to avoid collision
	    grainSize = 0.1,
	    overlap = 4,
	    useOverlap = 1,
	    prob = 1.0,        // v2.2: Probability Mask (1.0 = 100% active)
	    loFiGrains = 0,    // v2.3: LO-FI Switch (0=HD 256, 1=Pro 128, 2=Texture 64, 3=Lo-Fi 28, 4=Glitch 16, 5=Broken)
	    position = 0.5,
	    scanSpeed = 1,     // v2.1: Normal playback speed default

	    // --- TIME & PITCH (v2.1 Decoupled) ---
	    timeStretch = 1.0, // Multiplier for scan speed (Time only)
	    pitch = 0,         // Coarse pitch (semitones)
	    pitchShift = 0,    // Fine pitch (semitones)

	    // --- MUSICAL JITTER CONTROLS (64 STEPS) ---
	    posJitter = 0.0,   // Amplitude of the Position Sequence
	    pitchJitter = 0.0, // Amplitude of the Pitch Sequence

	    // 64-step arrays (KeyStep Pro/Digitone standard)
	    posSeq = #[
	        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	    ],
	    pitchSeq = #[
	        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	    ],

	    // --- STANDARD PARAMS ---
	    density = 20,      // Legacy parameter (kept for compatibility)
	    phaseAlign = 0,
	    envType = 1,
	    stereoSpread = 0.5,
	    amp = 0.5,
	    pan = 0,
	    loopStart = 0.0,
	    loopEnd = 1.0,

	    // --- FILTER PARAMS (Phase 10) ---
	    filterOn = 0,
	    filterFreq = 200,
	    filterMorph = 0.5,
	    filterRes = 0.5,
	    filterDecay = 0.5,
	    filterAnimate = 0,      // DEPRECATED - kept for compatibility
	    filterAnimRate = 0.5,   // DEPRECATED
	    filterTuning = 0,       // DEPRECATED
	    filterSpread = 1.5,     // DEPRECATED
	    filterMix = 0.5,

	    // --- COLOR PARAMS (Phase 3) ---
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

	    // --- SPACE PARAMS (Phase 3) ---
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
	    shimmerMix = 0,
	    out = 0;

	// Variables (v2.1: Updated for new architecture)
	var sig, trig, bufPos, bufFrames, pitchRatio;
	var grainDur, actualDensity, trigL, trigR, phasor, scanPos;
	var scanRate, grainRate;
	var posPattern, pitchPattern, musicalPosJitter, musicalPitchJitter;
	var rawTrig, rawTrigL, rawTrigR; // v2.2: Vars for probability masking
	// v2.3 FIX: LO-FI uses probability masking, not maxGrains (which is init-only in GrainBuf)
	var loFiDensity, loFiLag, isBroken, brokenDropout, finalProb;
	var activeGrains; // For GUI feedback

	bufFrames = BufFrames.kr(bufnum);

	// 1. CALCULATE DECOUPLED RATES (v2.1)
	grainRate = (pitch + pitchShift).midiratio;
	scanRate = scanSpeed * BufRateScale.kr(bufnum) * timeStretch;

	// 2. DENSITY & TRIGGER BASE
	grainDur = (grainSize / timeStretch.clip(0.25, 4)).max(0.001);
	actualDensity = Select.kr(useOverlap, [
		density * timeStretch,
		(overlap / grainDur).max(0.1)
	]);

	// === LO-FI PROBABILITY MASKING (v2.3 FIX) ===
	// GrainBuf's maxGrains is an INIT-ONLY constant - can't be changed dynamically!
	// Instead, we "choke" the trigger rate using probability masking.
	// Map menu index (0-5) to probability multiplier: HD(1.0) → Broken(0.06)
	loFiDensity = Select.kr(loFiGrains, [1.0, 0.5, 0.25, 0.11, 0.06, 0.06]);
	loFiLag = Lag.kr(loFiDensity, 0.5); // 500ms smooth transitions between modes

	// Broken mode (index 5): Add irregular 33% dropout using Dust for glitchy character
	isBroken = (loFiGrains >= 5);
	brokenDropout = Select.kr(isBroken, [
		0,                                      // Normal modes: no dropout
		TRand.kr(0.0, 0.33, Dust.kr(20))       // Broken: irregular 33% dropout
	]);

	// Combine user prob, LO-FI scaling, and broken dropout
	finalProb = (prob * loFiLag * (1 - brokenDropout)).clip(0.001, 1);

	// Raw triggers at full density
	rawTrig = Impulse.ar(actualDensity);

	// Apply combined probability mask to main trigger
	trig = rawTrig * (TRand.ar(0.0, 1.0, rawTrig) < finalProb);

	// 3. MUSICAL JITTER (Demand UGens) - v2.1
	// Position Sequence
	posPattern = Dseq(posSeq, inf);
	musicalPosJitter = Demand.ar(trig, 0, posPattern) * posJitter;

	// Pitch Sequence
	pitchPattern = Dseq(pitchSeq, inf);
	musicalPitchJitter = Demand.ar(trig, 0, pitchPattern);
	musicalPitchJitter = (musicalPitchJitter * (pitchJitter > 0)).midiratio;

	// 4. STEREO TRIGGERS with LO-FI probability mask
	rawTrigL = Impulse.ar(actualDensity + LFNoise1.kr(3).range(stereoSpread.neg*5, stereoSpread*5));
	rawTrigR = Impulse.ar(actualDensity + LFNoise1.kr(4).range(stereoSpread.neg*5, stereoSpread*5));

	trigL = rawTrigL * (TRand.ar(0.0, 1.0, rawTrigL) < finalProb);
	trigR = rawTrigR * (TRand.ar(0.0, 1.0, rawTrigR) < finalProb);

	// === GRAIN COUNT MONITORING (for GUI feedback) ===
	activeGrains = (actualDensity * grainDur * finalProb).round(1).max(0);
	SendReply.kr(Impulse.kr(10), '/grainCount', [activeGrains]);

	// 5. PHASOR (TAPE HEAD) - v2.1
	phasor = Phasor.ar(0, scanRate, loopStart*bufFrames, loopEnd*bufFrames, loopStart*bufFrames) / bufFrames;

	// 6. UNIFIED POSITION LOGIC (v2.2.1 FIX)
	// Create unified "Absolute Buffer Position" in loop-relative coordinates (loopStart to loopEnd)
	// This handles both Static (position 0-1) and Scanning (phasor already absolute) modes correctly
	// Note: Use K2A on selector to ensure audio-rate Select.ar works correctly
	scanPos = Select.ar(K2A.ar(scanSpeed.abs > 0.01), [
		// Static Mode: Map normalized position (0-1) to loop range
		K2A.ar(position.linlin(0, 1, loopStart, loopEnd)),
		// Scanning Mode: Phasor is already in loop range (loopStart to loopEnd)
		phasor
	]);

	// 7. APPLY JITTER & CALCULATE AUDIO POINTER
	// scanPos is now consistently in absolute coordinates (loopStart to loopEnd)
	// Note: A2K converts audio-rate scanPos to control rate for Select.kr
	bufPos = Select.kr(grainMode, [
		// TAPE: scanPos is absolute, add jitter and wrap within loop
		(A2K.kr(scanPos) + musicalPosJitter).wrap(loopStart, loopEnd),
		// POLY: scanPos is absolute
		A2K.kr(scanPos) + musicalPosJitter,
		// LIVE: Invert for lookback buffer
		(1.0 - A2K.kr(scanPos) + musicalPosJitter).wrap(0, 1)
	]);

	// 8. VISUALIZATION - scanPos is already in absolute coordinates, send directly
	SendReply.ar(Impulse.ar(60), '/grainPlayhead', [scanPos]);

	pitchRatio = grainRate * musicalPitchJitter;

	// 7. GRAIN GENERATION
	// NOTE: maxGrains=256 is FIXED at init (GrainBuf limitation). LO-FI effect achieved via trigger probability masking above.
	sig = [
		GrainBuf.ar(1, trigL, grainDur, bufnum, pitchRatio, bufPos, 4, stereoSpread.neg, -1, 256),
		GrainBuf.ar(1, trigR, grainDur, bufnum, pitchRatio, bufPos, 4, stereoSpread.neg, -1, 256)
	] * 2.0;

	// --- FILTER SECTION (Phase 10) ---
	// v2.1 FIX: Use SelectX with lag to prevent clicks when switching
	sig = SelectX.ar(filterOn.lag(0.05), [
		sig,
		{
			var filtered = sig;
			var freq = filterFreq.linexp(0, 1, 20, 18000);
			var rq = filterRes.linexp(0.01, 1, 1.0, 0.01);

			// Pre-Filter Drive
			var driven = Select.ar(filterDecay > 0.01, [
				filtered, (filtered * filterDecay.linexp(0.01, 1, 1, 10)).tanh
			]);

			// Moog Ladder (0.0 - 0.33)
			var ladder = Select.ar(filterMorph < 0.33, [
				DC.ar(0),
				{
					var m = MoogFF.ar(driven, freq, filterRes.linlin(0, 1, 0, 3.5));
					m + (BLowPass.ar(driven, 100, 1.0) * filterRes * 0.3);
				}.value
			]);

			// SVF (State Variable) (0.33 - 1.0)
			var svf = Select.ar(filterMorph >= 0.33, [
				DC.ar(0),
				{
					var morph = (filterMorph - 0.33) / 0.67;
					var lp = RLPF.ar(driven, freq, rq);
					var bp = BPF.ar(driven, freq, rq);
					var hp = RHPF.ar(driven, freq, rq);
					(lp * (1 - (morph * 2)).clip(0, 1)) +
					(bp * (1 - ((morph - 0.5).abs * 2)).clip(0, 1)) +
					(hp * ((morph - 0.5) * 2).clip(0, 1));
				}.value
			]);

			filtered = Select.ar(filterMorph < 0.33, [svf, ladder]);
			XFade2.ar(sig, filtered, filterMix.linlin(0, 1, -1, 1));
		}.value
	]);

	// --- COLOR EFFECTS (Phase 3) ---
	// v2.1 FIX: Use SelectX with lag to prevent clicks
	sig = SelectX.ar(colorOn.lag(0.05), [
		sig,
		{
			var colored = sig;
			var low, high, loProc, hiProc, distorted, crushed;

			// Distortion
			low = LPF.ar(colored, distCrossover);
			high = HPF.ar(colored, distCrossover);
			loProc = (low * distLoDrive).tanh;
			hiProc = (high * distHiDrive).tanh;
			colored = XFade2.ar(colored, loProc + hiProc, distMix.linlin(0, 1, -1, 1));

			// Bitcrush
			crushed = Latch.ar(colored, Impulse.ar(crushRate));
			crushed = crushed.round(0.5 ** crushBits);
			colored = XFade2.ar(colored, crushed, crushMix.linlin(0, 1, -1, 1));

			// Compressor
			Compander.ar(colored, colored, compThresh, 1.0, 1.0/compRatio, compAttack, compRelease);
		}.value
	]);

	// --- SPACE EFFECTS (Phase 3) ---
	// v2.1 FIX: Use SelectX with lag to prevent clicks
	sig = SelectX.ar(spaceOn.lag(0.05), [
		sig,
		{
			var spaced = sig;
			var wet, freezeGain, delayL, delayR, wetL, wetR, shimL, shimR;

			// Reverb
			freezeGain = reverbFreeze.linlin(0, 1, 0.9, 0.9999);
			wet = [
				FreeVerb.ar(spaced[0], 1.0, reverbSize * freezeGain, reverbDamp),
				FreeVerb.ar(spaced[1], 1.0, reverbSize * freezeGain, reverbDamp)
			];
			spaced = XFade2.ar(spaced, wet, reverbMix.linlin(0, 1, -1, 1));

			// Delay
			delayL = LocalIn.ar(1); delayR = LocalIn.ar(1);
			wetL = DelayC.ar(spaced[0] + delayL, 2.0, delayTime);
			wetR = DelayC.ar(spaced[1] + delayR, 2.0, delayTime);
			LocalOut.ar([
				LPF.ar(wetL, delayFilter) * delayFeedback,
				LPF.ar(wetR, delayFilter) * delayFeedback
			]);
			spaced = XFade2.ar(spaced, [wetL, wetR], delayMix.linlin(0, 1, -1, 1));

			// Shimmer (Simplified for v2.1)
			shimL = PitchShift.ar(spaced[0], 0.2, shimmerPitch.midiratio);
			shimR = PitchShift.ar(spaced[1], 0.2, shimmerPitch.midiratio);
			XFade2.ar(spaced, [shimL, shimR], shimmerMix.linlin(0, 1, -1, 1));
		}.value
	]);

	// Output
	sig = sig * amp;
	sig = Balance2.ar(sig[0], sig[1], pan);
	Out.ar(out, sig.tanh);
}).add;
