/*
S-4 Rival: Core Granular Engine
Phase 1 - Main SynthDef with GrainBuf
Phase 2 - Integrated 48-band Morphing Resonator
Phase 6 - Material Modes (TAPE/POLY/LIVE)
Phase 6b - Overlap Control (musical grain density)
Phase 15 - Time Stretch (temporal scaling without pitch shift)

Features:
- Up to 256 grains (dynamic based on overlap setting)
- Variable buffer playback (any length)
- Grain size: 1ms-60s (microtones to full loops, no upper limit)
- Overlap control: 1-128 simultaneous grains (replaces density)
- Time stretch: 0.25x-4x (slows/speeds grain stream, maintains pitch)
- Pitch control: -2 to +2 octaves
- 4 envelope shapes
- Position jitter & pitch jitter
- Stereo spread
- 48-band morphing resonator (LP/BP/HP)
- Harmonic/inharmonic tuning
- Resonance and animation controls

Args:
  bufnum: Buffer number for grain source
  mode: Material mode (0=TAPE loop, 1=POLY sample, 2=LIVE input)
  grainSize: Grain duration in seconds (0.001-60+, unlimited)
  overlap: Number of simultaneous grains (1-128) - RECOMMENDED
  density: Grains per second (1-200) - LEGACY, use overlap instead
  useOverlap: 1=use overlap mode (default), 0=use density mode
  position: Playback position in buffer (0-1)
  timeStretch: Master time stretch (0.25-4x, scales grain rate & size, NOT pitch)
  pitch: Pitch shift in semitones (-24 to +24) - LEGACY (changes speed+pitch)
  pitchShift: True pitch shift in semitones (-24 to +24) - NEW (preserves speed)
  posJitter: Random position offset (0-1)
  pitchJitter: Random pitch offset in semitones (0-12)
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
  filterAnimate: [DEPRECATED - use for master bus filter]
  filterAnimRate: [DEPRECATED - use for master bus filter]
  filterTuning: [DEPRECATED - use for master bus filter]
  filterSpread: [DEPRECATED - use for master bus filter]
  filterMix: Filter dry/wet mix (0=dry, 1=wet)

  out: Output bus
*/

SynthDef(\s4GrainEngine, {
	arg bufnum = 0,
	    mode = 0,  // Phase 6: 0=TAPE, 1=POLY, 2=LIVE
	    grainSize = 0.1,
	    density = 20,      // Legacy parameter (kept for compatibility)
	    overlap = 4,       // Phase 6b: Number of simultaneous grains (1-128)
	    useOverlap = 1,    // Phase 6b: 0=use density, 1=use overlap (default)
	    position = 0.5,
	    scanSpeed = 0,     // Phase 7c: Continuous scanning speed (-4 to 4, 0=static)
	    timeStretch = 1.0, // Phase 15: Master time stretch (0.25-4x, affects grain rate & size, NOT pitch)
	    pitch = 0,         // Legacy: changes speed+pitch (playback rate)
	    pitchShift = 0,    // Phase 7: True pitch shift (preserves speed)
	    posJitter = 0.0,
	    pitchJitter = 0.0,
	    phaseAlign = 0,    // Phase 9: 1=zero-crossing aligned grains (prevents phase cancellation)
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
	    shimmerWindowSize = 0.2,  // Phase 7c: 0.05=glitchy, 0.5=smooth
	    shimmerMix = 0,
	    out = 0;

	var sig, trig, bufPos, bufFrames, pitchRatio, env;
	var grainDur, maxGrains, panL, panR, envBuf;
	var delayL, delayR, shiftL, shiftR; // for effects
	var actualDensity; // Calculated from overlap or direct
	var trigL, trigR; // Phase 7b: Per-channel triggers for stereo spread
	var phasor, scanPos; // Phase 7c: Phasor for continuous scanning

	// Calculate buffer parameters
	bufFrames = BufFrames.kr(bufnum);

	// Phase 15: Time stretch affects grain size inversely
	// timeStretch = 0.5 → grains 2x longer (slower temporal feel)
	// timeStretch = 2.0 → grains 2x shorter (faster temporal feel)
	grainDur = (grainSize / timeStretch.clip(0.25, 4)).max(0.001);

	// Calculate actual density based on mode
	// Phase 15: Time stretch affects density directly
	// timeStretch = 0.5 → fire half as often (slower)
	// timeStretch = 2.0 → fire twice as often (faster)
	// useOverlap=1: density = overlap / grainSize (musical control)
	// useOverlap=0: use density directly (legacy mode)
	actualDensity = Select.kr(useOverlap, [
		density * timeStretch,                    // Legacy mode: scale density
		(overlap / grainDur).max(0.1)  // Overlap mode: auto-adjusts via grainDur
	]);

	// Grain triggering with calculated density
	trig = Impulse.ar(actualDensity);

	// Phase 7b: Per-channel trigger jitter for enhanced stereo spread
	// When stereoSpread > 0, grains fire at slightly different times L/R
	// This creates a wider, more immersive stereo field
	// Phase 9: Optional phase-alignment - triggers on zero-crossings to prevent phase cancellation
	trigL = Select.ar(phaseAlign, [
		// Standard mode: regular impulses with stereo spread jitter
		Impulse.ar(actualDensity + LFNoise1.kr(3).range(stereoSpread.neg * 5, stereoSpread * 5)),
		// Phase-aligned mode: trigger on zero-crossings of the buffer
		// Sample buffer at current position and detect zero-crossings
		(ZeroCrossing.ar(PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum), loop: 1)) * actualDensity / 10).clip(0, actualDensity)
	]);

	trigR = Select.ar(phaseAlign, [
		// Standard mode: regular impulses with stereo spread jitter
		Impulse.ar(actualDensity + LFNoise1.kr(4).range(stereoSpread.neg * 5, stereoSpread * 5)),
		// Phase-aligned mode: slightly offset zero-crossing detection for stereo
		(ZeroCrossing.ar(PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum) * 1.001, loop: 1)) * actualDensity / 10).clip(0, actualDensity)
	]);

	// Phase 7c: Phasor.ar for continuous buffer scanning
	// Provides sample-accurate, bidirectional scrubbing
	// scanSpeed: -4 to 4 (negative = reverse, 0 = static, positive = forward)
	phasor = Phasor.ar(
		trig: 0,  // Free-running (no reset)
		rate: scanSpeed * BufRateScale.kr(bufnum),
		start: loopStart * bufFrames,
		end: loopEnd * bufFrames,
		resetPos: loopStart * bufFrames
	) / bufFrames;  // Normalize to 0-1

	// Scan position: blend between static position and phasor
	// When scanSpeed = 0, use static position; otherwise use phasor
	// Use XFade2 for smooth blending (avoids Select.ar audio-rate requirement)
	scanPos = XFade2.ar(
		K2A.ar(position),  // Static position (converted to audio-rate)
		phasor,            // Continuous phasor scan
		(scanSpeed.abs > 0.01).lag(0.1).linlin(0, 1, -1, 1)  // Smooth crossfade
	);

	// Phase 8: Send playhead position for GUI visualization @ 60Hz
	// Broadcasts normalized position (0-1) for viewfinder window
	// Phase 15: Use '/grainPlayhead' to distinguish from spectral engine
	SendReply.ar(Impulse.ar(60), '/grainPlayhead', [scanPos]);

	// Buffer position calculation depends on mode
	// Mode 0 (TAPE): Looping playback position
	// Mode 1 (POLY): Fixed start position per grain
	// Mode 2 (LIVE): Lookback time from current write position
	// Phase 7c: Now uses scanPos (which can be phasor or static position)
	bufPos = Select.kr(mode, [
		// TAPE mode: loop through buffer
		(scanPos.linlin(0, 1, loopStart, loopEnd) + LFNoise1.kr(10).range(posJitter.neg, posJitter)).wrap(loopStart, loopEnd),
		// POLY mode: fixed position (no looping)
		scanPos + LFNoise1.kr(10).range(posJitter.neg, posJitter),
		// LIVE mode: position represents "time ago" (0=now, 1=buffer start)
		// In LIVE mode, grains read from recent past
		(1.0 - scanPos + LFNoise1.kr(10).range(posJitter.neg, posJitter)).wrap(0, 1)
	]);

	// Convert pitch (semitones) to ratio
	pitchRatio = (pitch + LFNoise1.kr(5).range(pitchJitter.neg, pitchJitter)).midiratio;

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
	// Phase 6b: Fixed maxGrains allocation
	// GrainBuf requires maxGrains to be a constant at compile time
	// Set to 64 per channel (128 total) to support overlap up to 128

	// Left channel: grains panned left with independent trigger timing
	panL = GrainBuf.ar(
		numChannels: 1,
		trigger: trigL,  // Phase 7b: Independent left trigger
		dur: grainDur,
		sndbuf: bufnum,
		rate: pitchRatio,
		pos: bufPos,
		interp: 2, // cubic interpolation
		pan: stereoSpread.neg, // pan left
		envbufnum: -1, // use default envelope for now
		maxGrains: 64 // Fixed at compile time
	);

	// Right channel: grains panned right with independent trigger timing
	panR = GrainBuf.ar(
		numChannels: 1,
		trigger: trigR,  // Phase 7b: Independent right trigger
		dur: grainDur,
		sndbuf: bufnum,
		rate: pitchRatio,
		pos: bufPos,
		interp: 2,
		pan: stereoSpread, // pan right
		envbufnum: -1,
		maxGrains: 64 // Fixed at compile time
	);

	// Combine stereo channels
	sig = [panL, panR];

	// Phase 6b: Volume boost for overlap mode
	// 2x gain boost - GrainBuf output is quiet compared to hardware synths
	sig = sig * 2.0;

	// === PHASE 7: TRUE PITCH SHIFTING (preserves speed) ===
	// PitchShift uses FFT-based time-stretching to shift pitch independently
	// pitchDispersion and timeDispersion add slight randomness for smoother texture
	sig = Select.ar(pitchShift.abs > 0.01, [
		sig,  // bypass if pitch shift is near 0
		PitchShift.ar(
			sig,
			windowSize: 0.2,           // Window size (smaller = better transients, larger = smoother)
			pitchRatio: pitchShift.midiratio,  // Convert semitones to ratio
			pitchDispersion: 0.0,      // Slight pitch randomness (0-1)
			timeDispersion: 0.0        // Slight time randomness (0-1)
		)
	]);

	// === PHASE 2: FILTERBANK (MOVED TO MASTER BUS IN PHASE 4) ===
	// The 48-band morphing resonator is now applied on the master bus
	// (post-mix) to save CPU when running 4 tracks. Filter parameters
	// are still accepted for backward compatibility but are ignored.

	// === PHASE 10: PER-TRACK DUAL-TOPOLOGY FILTER ===
	// Professional-grade filtering with two topologies:
	// - ZDF Ladder Filter (Moog-style): Liquid resonance, self-oscillation
	// - State Variable Filter (SVF): LP/HP/BP morph capability
	// Supports audio-rate cutoff modulation for FM synthesis
	sig = Select.ar(filterOn > 0.5, [
		sig,  // bypass
		{
			var filtered = sig;
			var freq, rq, driven;
			var ladder, svf, lp, hp, bp;
			var lpAmt, bpAmt, hpAmt;

			// Cutoff frequency (20Hz - 18kHz, exponential)
			freq = filterFreq.linexp(0, 1, 20, 18000);

			// Resonance (0-1 → Q factor)
			// For SVF: 0-1 → rq 1.0 to 0.01 (inverse relationship)
			// For Ladder: 0-1 → gain 0 to 4 (self-oscillation at 4)
			rq = filterRes.linexp(0.01, 1, 1.0, 0.01);

			// Pre-filter drive stage (optional nonlinear saturation)
			// Adds harmonic content before filtering for "grit"
			// filterDecay is repurposed as drive amount (0-1)
			driven = Select.ar(filterDecay > 0.01, [
				filtered,  // No drive
				(filtered * filterDecay.linexp(0.01, 1, 1, 10)).tanh
			]);

			// TOPOLOGY SELECTION via filterMorph:
			// 0.0 - 0.33: ZDF Ladder Filter (lowpass with resonance)
			// 0.33 - 1.0: State Variable Filter (LP/BP/HP morph)

			// ZDF Ladder Filter (MoogFF)
			ladder = Select.ar(filterMorph < 0.33, [
				DC.ar(0),  // Silent when not in ladder range
				{
					var moogSig = MoogFF.ar(
						in: driven,
						freq: freq,
						gain: filterRes.linlin(0, 1, 0, 3.5),  // 0-3.5 for safety (4 can blow up)
						reset: 0
					);
					// Bass compensation (MoogFF loses bass at high resonance)
					var bass = BLowPass.ar(driven, 100, 1.0);
					moogSig + (bass * filterRes * 0.3);
				}.value
			]);

			// State Variable Filter (LP/HP/BP morph)
			// filterMorph: 0.33=LP, 0.66=BP, 1.0=HP
			svf = Select.ar(filterMorph >= 0.33, [
				DC.ar(0),  // Silent when in ladder range
				{
					var morphNorm = (filterMorph - 0.33) / 0.67;  // Normalize 0.33-1.0 → 0-1
					lp = RLPF.ar(driven, freq, rq);
					bp = BPF.ar(driven, freq, rq);
					hp = RHPF.ar(driven, freq, rq);

					// Equal-power crossfade between filter types
					lpAmt = (1 - (morphNorm * 2)).clip(0, 1);
					bpAmt = (1 - ((morphNorm - 0.5).abs * 2)).clip(0, 1);
					hpAmt = ((morphNorm - 0.5) * 2).clip(0, 1);

					(lp * lpAmt) + (bp * bpAmt) + (hp * hpAmt);
				}.value
			]);

			// Blend ladder and SVF based on filterMorph position
			filtered = Select.ar(filterMorph < 0.33, [
				svf,    // SVF range (0.33-1.0)
				ladder  // Ladder range (0.0-0.33)
			]);

			// Dry/wet mix (repurpose filterMix parameter)
			XFade2.ar(sig, filtered, filterMix.linlin(0, 1, -1, 1));
		}.value
	]);

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
			// Phase 7c: Variable windowSize for morphing between glitchy and smooth textures
			shimShiftL = PitchShift.ar(shimDelayL, windowSize: shimmerWindowSize.clip(0.05, 0.5), pitchRatio: shimmerPitch.midiratio, pitchDispersion: 0.01, timeDispersion: 0.01);
			shimShiftR = PitchShift.ar(shimDelayR, windowSize: shimmerWindowSize.clip(0.05, 0.5), pitchRatio: shimmerPitch.midiratio, pitchDispersion: 0.01, timeDispersion: 0.01);
			LocalOut.ar([shimShiftL * shimmerFeedback, shimShiftR * shimmerFeedback]);
			spaced = XFade2.ar(spaced, [shimShiftL, shimShiftR], shimmerMix.linlin(0, 1, -1, 1));

			spaced;
		}.value
	]);

	// Apply amplitude (stereo field already created by GrainBuf panning)
	sig = sig * amp;

	// THEN apply master pan control (adjusts the pre-panned stereo field)
	sig = Balance2.ar(sig[0], sig[1], pan);

	// Soft limiter to prevent clipping
	sig = sig.tanh;

	// === PHASE 11: FFT SPECTROGRAM BROADCAST ===
	// Broadcast spectral analysis data for viewfinder visualization
	// Simple approach: Analyze multiple frequency bands with BPF
	// This avoids complex FFT operations and reduces CPU overhead
	SendReply.kr(
		trig: Impulse.kr(30),  // 30fps update rate
		cmdName: '/s4_fft',
		values: [
			// 16 frequency bands from 20Hz to ~16kHz (log-spaced)
			Amplitude.kr(BPF.ar(Mix.ar(sig), 40, 0.5)).ampdb.linlin(-60, 0, 0, 1).clip(0, 1),
			Amplitude.kr(BPF.ar(Mix.ar(sig), 80, 0.5)).ampdb.linlin(-60, 0, 0, 1).clip(0, 1),
			Amplitude.kr(BPF.ar(Mix.ar(sig), 160, 0.5)).ampdb.linlin(-60, 0, 0, 1).clip(0, 1),
			Amplitude.kr(BPF.ar(Mix.ar(sig), 320, 0.5)).ampdb.linlin(-60, 0, 0, 1).clip(0, 1),
			Amplitude.kr(BPF.ar(Mix.ar(sig), 640, 0.5)).ampdb.linlin(-60, 0, 0, 1).clip(0, 1),
			Amplitude.kr(BPF.ar(Mix.ar(sig), 1280, 0.5)).ampdb.linlin(-60, 0, 0, 1).clip(0, 1),
			Amplitude.kr(BPF.ar(Mix.ar(sig), 2560, 0.5)).ampdb.linlin(-60, 0, 0, 1).clip(0, 1),
			Amplitude.kr(BPF.ar(Mix.ar(sig), 5120, 0.5)).ampdb.linlin(-60, 0, 0, 1).clip(0, 1),
			Amplitude.kr(BPF.ar(Mix.ar(sig), 10240, 0.5)).ampdb.linlin(-60, 0, 0, 1).clip(0, 1),
			Amplitude.kr(BPF.ar(Mix.ar(sig), 16000, 0.5)).ampdb.linlin(-60, 0, 0, 1).clip(0, 1)
		]
	);

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
