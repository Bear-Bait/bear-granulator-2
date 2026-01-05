/*
S-4 Rival: Modulation System
Phase 5 - 4 Modulators Per Track

Features:
- 4 independent modulators per track (20 total system-wide)
- Types: LFO, Envelope Follower, Random, Envelope
- Multiple LFO waveforms (sine, triangle, saw, square, random)
- Envelope follower tracks input amplitude
- Random: sample & hold and smooth random
- Route to any parameter with depth control

Modulator Types:
  0 = LFO (periodic waveforms)
  1 = Envelope Follower (amplitude tracking)
  2 = Random (stepped or smooth)
  3 = Envelope (triggered envelope)

Each modulator outputs to a control bus (0-1 range)
*/

~s4Modulator = { arg server;
	var publicAPI;

	// Define the SynthDef once at initialization
	SynthDef(\s4Modulator, {
		arg modType = 0, out = 0, freq = 1.0, amp = 1.0, waveform = 0,
		    attack = 0.01, decay = 0.1, sustain = 0.7, release = 0.3,
		    audioIn = 0, smoothTime = 0.1, gate = 1,
		    // Phase 15.5: MIDI Clock Sync parameters
		    tempo = 120,        // BPM from MIDI clock
		    syncMode = 0,       // 0=Hz (free), 1=1/4, 2=1/8, 3=1/16, 4=1/8t, 5=1/16t
		    tempoSync = 0;      // 0=off (use freq), 1=on (use tempo+syncMode)

		var sig, lfoSig, envSig, randSig, envFollowSig;
		var effectiveFreq, tempoBPS, beatDiv;

		// Phase 13: Audio-Rate Modulation (48kHz vs 750Hz control-rate)

		// Phase 15.5: Calculate effective frequency (Hz or tempo-synced)
		tempoBPS = tempo / 60.0;  // Convert BPM to beats-per-second
		beatDiv = Select.kr(syncMode, [
			1.0,      // 0: 1/4 note (1 cycle per beat)
			2.0,      // 1: 1/8 note (2 cycles per beat)
			4.0,      // 2: 1/16 note (4 cycles per beat)
			3.0,      // 3: 1/8 triplet (3 cycles per beat)
			6.0       // 4: 1/16 triplet (6 cycles per beat)
		]);
		effectiveFreq = Select.kr(tempoSync, [
			freq,                      // Free-running Hz
			tempoBPS * beatDiv         // Tempo-synced divisions
		]);

		// === LFO (Type 0) - AUDIO RATE ===
		lfoSig = Select.ar(waveform, [
			SinOsc.ar(effectiveFreq).range(0, 1),             // 0: Sine
			LFTri.ar(effectiveFreq).range(0, 1),              // 1: Triangle
			LFSaw.ar(effectiveFreq).range(0, 1),              // 2: Sawtooth
			LFPulse.ar(effectiveFreq, width: 0.5),            // 3: Square (already 0-1)
			LFNoise1.ar(effectiveFreq).range(0, 1),           // 4: Smooth random
			LFNoise0.ar(effectiveFreq).range(0, 1)            // 5: Stepped random
		]);

		// === Envelope Follower (Type 1) - AUDIO RATE ===
		envFollowSig = Amplitude.ar(
			In.ar(audioIn, 1),
			attackTime: smoothTime * 0.1,
			releaseTime: smoothTime
		);

		// === Random (Type 2) - AUDIO RATE ===
		randSig = Select.ar(waveform.min(1), [
			LFNoise0.ar(effectiveFreq).range(0, 1),           // 0: Stepped
			LFNoise1.ar(effectiveFreq).range(0, 1)            // 1: Smooth
		]);

		// === Envelope (Type 3) - AUDIO RATE ===
		envSig = EnvGen.ar(
			Env.adsr(attack, decay, sustain, release),
			gate: gate
		);

		// Select modulator type (audio-rate)
		sig = Select.ar(modType, [
			lfoSig,          // 0: LFO
			envFollowSig,    // 1: Envelope Follower
			randSig,         // 2: Random
			envSig           // 3: Envelope
		]);

		// Apply depth and output to AUDIO BUS (Phase 13)
		Out.ar(out, sig * amp);
	}).add;

	// Define the mapper SynthDef
	SynthDef(\s4Mapper, {
		arg inBus = 0, out = 0, minVal = 0, maxVal = 1;
		var rawMod = In.ar(inBus, 1);
		var range = maxVal - minVal;
		var scaled = (rawMod * range) + minVal;
		Out.ar(out, scaled);
	}).add;

	publicAPI = (
		/*
		Create a modulator synth
		Args:
		  type: 0=LFO, 1=EnvFollow, 2=Random, 3=Envelope
		  outBus: Audio bus for output (Phase 13)
		  rate: Frequency/speed (Hz)
		  depth: Output scaling (0-1)
		  shape: Waveform/behavior selector
		  inputBus: Audio bus for envelope follower (optional)
		  group: Target group (Phase 13: modGroup for execution order)
		*/
		create: { arg self, type = 0, outBus, rate = 1.0, depth = 1.0, shape = 0, inputBus = nil, group = nil;
			var synth;

			synth = Synth(\s4Modulator, [
				\modType, type,
				\out, outBus,
				\freq, rate,
				\amp, depth,
				\waveform, shape,
				\audioIn, inputBus ? 0
			], group ? server);

			synth;
		},

		/*
		Create a modulation bus mapper (Phase 13: Audio-Rate)
		Reads from AUDIO bus and applies to synth parameter with scaling
		Args:
		  group: Target group (should be modGroup, AFTER modulator but BEFORE instruments)
		*/
		createMapper: { arg self, modBus, modulatorSynth, targetSynth, targetParam, minVal, maxVal, group = nil;
			var scaledBus, mapperSynth;

			// Phase 13: Keep AUDIO-RATE for 48kHz precision
			scaledBus = Bus.audio(server, 1);

			// Create mapper synth - place in modGroup, AFTER modulator synth
			mapperSynth = Synth(\s4Mapper, [
				\inBus, modBus,
				\out, scaledBus.index,
				\minVal, minVal,
				\maxVal, maxVal
			], modulatorSynth, \addAfter);

			// Map audio bus to parameter using \a prefix (SC 3.14+ syntax)
			if(targetSynth.notNil, {
				targetSynth.set(targetParam, ("a" ++ scaledBus.index).asSymbol);
				("Mapped " ++ targetParam ++ " to AUDIO bus a" ++ scaledBus.index).postln;
			});

			// Return both synth and bus so caller can free both
			(synth: mapperSynth, bus: scaledBus);
		}
	);

	publicAPI;
};

"✓ Modulator module loaded".postln;
