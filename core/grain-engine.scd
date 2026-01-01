/*
S-4 Rival: Core Granular Engine
Phase 1 - Main SynthDef with GrainBuf
Phase 2 - Integrated 48-band Morphing Resonator

Features:
- Up to 128 grains
- Variable buffer playback (any length)
- Grain size: 1ms-60s (microtones to full loops, no upper limit)
- Density: 1-200 grains/second
- Pitch control: -2 to +2 octaves
- 4 envelope shapes
- Position jitter & pitch jitter
- Stereo spread
- 48-band morphing resonator (LP/BP/HP)
- Harmonic/inharmonic tuning
- Resonance and animation controls

Args:
  bufnum: Buffer number for grain source
  grainSize: Grain duration in seconds (0.001-60+, unlimited)
  density: Grains per second (1-200)
  position: Playback position in buffer (0-1)
  pitch: Pitch shift in semitones (-24 to +24)
  posJitter: Random position offset (0-1)
  pitchJitter: Random pitch offset in semitones (0-12)
  envType: Envelope shape (0=Perc, 1=Sine, 2=Triangle, 3=Welch)
  stereoSpread: Stereo width (0-1)
  amp: Output amplitude (0-1)
  pan: Stereo pan (-1 to 1)

  filterOn: Enable filterbank (0=off, 1=on)
  filterFreq: Filter fundamental frequency (20-2000 Hz)
  filterMorph: Filter type (0=LP, 0.5=BP, 1.0=HP)
  filterRes: Resonance (0-1)
  filterDecay: Decay time (0-1)
  filterAnimate: Animation amount (0-1)
  filterAnimRate: Animation rate (0.01-10 Hz)
  filterTuning: Tuning mode (0=harmonic, 1=inharmonic)
  filterSpread: Inharmonic spread (1.0-2.0)
  filterMix: Dry/wet mix (0=dry, 1=wet)

  out: Output bus
*/

SynthDef(\s4GrainEngine, {
	arg bufnum = 0,
	    grainSize = 0.1,
	    density = 20,
	    position = 0.5,
	    pitch = 0,
	    posJitter = 0.0,
	    pitchJitter = 0.0,
	    envType = 1,
	    stereoSpread = 0.5,
	    amp = 0.5,
	    pan = 0,
	    loopStart = 0.0,  // Loop region start (0-1)
	    loopEnd = 1.0,    // Loop region end (0-1)
	    // Filter parameters (Phase 2)
	    filterOn = 0,
	    filterFreq = 200,
	    filterMorph = 0.5,
	    filterRes = 0.5,
	    filterDecay = 0.5,
	    filterAnimate = 0,
	    filterAnimRate = 0.5,
	    filterTuning = 0,
	    filterSpread = 1.5,
	    filterMix = 0.5,
	    // Color effects (Phase 3)
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
	    // Space effects (Phase 3)
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
	    shimmerMix = 0,
	    out = 0;

	var sig, trig, bufPos, bufFrames, pitchRatio, env;
	var grainDur, maxGrains, panL, panR, envBuf;
	var delayL, delayR, shiftL, shiftR; // for effects

	// Calculate buffer parameters
	bufFrames = BufFrames.kr(bufnum);

	// Grain triggering (using Dust for irregular triggering)
	trig = Impulse.ar(density);

	// Buffer position with jitter mapped to loop region
	// Position parameter (0-1) maps to loop region (loopStart-loopEnd)
	bufPos = position.linlin(0, 1, loopStart, loopEnd) + LFNoise1.kr(10).range(posJitter.neg, posJitter);
	bufPos = bufPos.wrap(loopStart, loopEnd);

	// Convert pitch (semitones) to ratio
	pitchRatio = (pitch + LFNoise1.kr(5).range(pitchJitter.neg, pitchJitter)).midiratio;

	// Grain duration (no upper limit - can be as long as buffer)
	grainDur = grainSize.max(0.001);

	// Create envelope buffer based on envType
	envBuf = Select.kr(envType, [
		// 0: Percussive (sharp attack, exponential decay)
		Env.perc(0.01, 0.99, 1, -4).asSignal(512).asWavetable,
		// 1: Sine (smooth, no clicks)
		Env.sine(1, 1).asSignal(512).asWavetable,
		// 2: Triangle (linear)
		Env.triangle(1, 1).asSignal(512).asWavetable,
		// 3: Welch (parabolic, smooth)
		Env([0, 1, 0], [0.5, 0.5], \welch).asSignal(512).asWavetable
	]);

	// Stereo grain clouds with spread
	// Left channel: grains panned left
	panL = GrainBuf.ar(
		numChannels: 1,
		trigger: trig,
		dur: grainDur,
		sndbuf: bufnum,
		rate: pitchRatio,
		pos: bufPos,
		interp: 2, // cubic interpolation
		pan: stereoSpread.neg, // pan left
		envbufnum: -1, // use default envelope for now
		maxGrains: 64 // 64 grains per channel = 128 total
	);

	// Right channel: grains panned right
	panR = GrainBuf.ar(
		numChannels: 1,
		trigger: trig,
		dur: grainDur,
		sndbuf: bufnum,
		rate: pitchRatio,
		pos: bufPos,
		interp: 2,
		pan: stereoSpread, // pan right
		envbufnum: -1,
		maxGrains: 64
	);

	// Combine stereo channels
	sig = [panL, panR];

	// === PHASE 2: FILTERBANK (MOVED TO MASTER BUS IN PHASE 4) ===
	// The 48-band morphing resonator is now applied on the master bus
	// (post-mix) to save CPU when running 4 tracks. Filter parameters
	// are still accepted for backward compatibility but are ignored.

	// === PHASE 3: COLOR EFFECTS ===
	sig = Select.ar(colorOn > 0.5, [
		sig,  // bypass
		// Color effects chain
		{
			var colored = sig;
			var low, high, loProc, hiProc, distorted, crushed;

			// 1. Dual-band distortion
			low = LPF.ar(colored, distCrossover);
			high = HPF.ar(colored, distCrossover);
			loProc = (low * distLoDrive).tanh;
			hiProc = (high * distHiDrive).tanh;
			distorted = loProc + hiProc;
			colored = XFade2.ar(colored, distorted, distMix.linlin(0, 1, -1, 1));

			// 2. Bit crusher
			crushed = Latch.ar(colored, Impulse.ar(crushRate));
			crushed = crushed.round(0.5 ** crushBits);
			colored = XFade2.ar(colored, crushed, crushMix.linlin(0, 1, -1, 1));

			// 3. Compressor
			colored = Compander.ar(
				colored,
				colored,
				thresh: compThresh,
				slopeBelow: 1.0,
				slopeAbove: 1.0 / compRatio,
				clampTime: compAttack,
				relaxTime: compRelease
			);

			// 4. Add noise
			colored + (Select.ar(noiseType, [
				WhiteNoise.ar([1, 1]),
				PinkNoise.ar([1, 1]),
				BrownNoise.ar([1, 1])
			]) * noiseAmount);
		}.value
	]);

	// === PHASE 3: SPACE EFFECTS ===
	sig = Select.ar(spaceOn > 0.5, [
		sig,  // bypass
		// Space effects chain
		{
			var spaced = sig;
			var maxDelay = 2.0;
			var wet, freezeGain, fbL, fbR, wetL, wetR;
			var shimFbL, shimFbR, shimDelayL, shimDelayR, shimShiftL, shimShiftR;

			// 1. Reverb
			freezeGain = reverbFreeze.linlin(0, 1, 0.9, 0.9999);
			wet = [
				FreeVerb.ar(spaced[0], mix: 1.0, room: reverbSize * freezeGain, damp: reverbDamp),
				FreeVerb.ar(spaced[1], mix: 1.0, room: reverbSize * freezeGain, damp: reverbDamp)
			];
			spaced = XFade2.ar(spaced, wet, reverbMix.linlin(0, 1, -1, 1));

			// 2. Delay with ping-pong
			delayL = LocalIn.ar(1);
			delayR = LocalIn.ar(1);
			wetL = DelayC.ar(spaced[0] + delayL, maxDelay, delayTime.clip(0.01, maxDelay));
			wetR = DelayC.ar(spaced[1] + delayR, maxDelay, delayTime.clip(0.01, maxDelay));
			fbL = LPF.ar(wetL, delayFilter) * delayFeedback;
			fbR = LPF.ar(wetR, delayFilter) * delayFeedback;
			LocalOut.ar([
				Select.ar(delayPingPong, [fbL, fbR]),
				Select.ar(delayPingPong, [fbR, fbL])
			]);
			spaced = XFade2.ar(spaced, [wetL, wetR], delayMix.linlin(0, 1, -1, 1));

			// 3. Shimmer (pitch-shifted delay)
			shimFbL = LocalIn.ar(1);
			shimFbR = LocalIn.ar(1);
			shimDelayL = DelayC.ar(spaced[0] + shimFbL, maxDelay, shimmerTime.clip(0.1, maxDelay));
			shimDelayR = DelayC.ar(spaced[1] + shimFbR, maxDelay, shimmerTime.clip(0.1, maxDelay));
			shimShiftL = PitchShift.ar(shimDelayL, pitchRatio: shimmerPitch.midiratio, pitchDispersion: 0.01, timeDispersion: 0.01);
			shimShiftR = PitchShift.ar(shimDelayR, pitchRatio: shimmerPitch.midiratio, pitchDispersion: 0.01, timeDispersion: 0.01);
			LocalOut.ar([shimShiftL * shimmerFeedback, shimShiftR * shimmerFeedback]);
			spaced = XFade2.ar(spaced, [shimShiftL, shimShiftR], shimmerMix.linlin(0, 1, -1, 1));

			spaced;
		}.value
	]);

	// Apply panning and amplitude
	sig = Balance2.ar(sig[0], sig[1], pan, amp);

	// Soft limiter to prevent clipping
	sig = sig.tanh;

	// Output
	Out.ar(out, sig);
}).add;

/*
Usage example:
(
// Create a test buffer with a simple tone
~testBuf = Buffer.alloc(s, s.sampleRate * 4, 1); // 4 seconds
~testBuf.sine1([1, 0.5, 0.25], true, true, true);

// Create grain synth with filter
~grainSynth = Synth(\s4GrainEngine, [
	\bufnum, ~testBuf,
	\grainSize, 0.1,
	\density, 30,
	\position, 0.5,
	\pitch, 0,
	\posJitter, 0.1,
	\pitchJitter, 2,
	\envType, 1,
	\stereoSpread, 0.5,
	\amp, 0.5,
	// Filter parameters (Phase 2)
	\filterOn, 1,
	\filterFreq, 200,
	\filterMorph, 0.5,
	\filterRes, 0.7,
	\filterDecay, 0.6,
	\filterAnimate, 0.3,
	\filterAnimRate, 0.5,
	\filterTuning, 0,
	\filterMix, 0.7
]);
)

// Try adjusting filter in real-time
~grainSynth.set(\filterMorph, 0.0);  // Lowpass
~grainSynth.set(\filterMorph, 0.5);  // Bandpass
~grainSynth.set(\filterMorph, 1.0);  // Highpass
~grainSynth.set(\filterAnimate, 0.8); // More animation
~grainSynth.set(\filterTuning, 1);    // Inharmonic mode

// Cleanup
~grainSynth.free;
~testBuf.free;
*/
