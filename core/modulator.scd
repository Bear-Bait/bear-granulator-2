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

	publicAPI = (
		/*
		Create a modulator synth
		Args:
		  type: 0=LFO, 1=EnvFollow, 2=Random, 3=Envelope
		  outBus: Control bus for output
		  rate: Frequency/speed (Hz)
		  depth: Output scaling (0-1)
		  shape: Waveform/behavior selector
		  inputBus: Audio bus for envelope follower (optional)
		*/
		create: { arg self, type = 0, outBus, rate = 1.0, depth = 1.0, shape = 0, inputBus = nil;
			var synth;

			synth = {
				arg modType = 0, out = 0, freq = 1.0, amp = 1.0, waveform = 0,
				    attack = 0.01, decay = 0.1, sustain = 0.7, release = 0.3,
				    audioIn = 0, smoothTime = 0.1, gate = 1;

				var sig, lfoSig, envSig, randSig, envFollowSig;

				// === LFO (Type 0) ===
				lfoSig = Select.kr(waveform, [
					SinOsc.kr(freq),                    // 0: Sine
					LFTri.kr(freq),                     // 1: Triangle
					LFSaw.kr(freq),                     // 2: Sawtooth
					LFPulse.kr(freq, width: 0.5),       // 3: Square
					LFNoise1.kr(freq),                  // 4: Smooth random
					LFNoise0.kr(freq)                   // 5: Stepped random
				]).range(0, 1);

				// === Envelope Follower (Type 1) ===
				envFollowSig = Amplitude.kr(
					In.ar(audioIn, 1),
					attackTime: smoothTime * 0.1,
					releaseTime: smoothTime
				);

				// === Random (Type 2) ===
				randSig = Select.kr(waveform.min(1), [
					LFNoise0.kr(freq).range(0, 1),      // 0: Stepped
					LFNoise1.kr(freq).range(0, 1)       // 1: Smooth
				]);

				// === Envelope (Type 3) ===
				envSig = EnvGen.kr(
					Env.adsr(attack, decay, sustain, release),
					gate: gate
				);

				// Select modulator type
				sig = Select.kr(modType, [
					lfoSig,          // 0: LFO
					envFollowSig,    // 1: Envelope Follower
					randSig,         // 2: Random
					envSig           // 3: Envelope
				]);

				// Apply depth and output to control bus
				Out.kr(out, sig * amp);
			}.play(server, [
				\modType, type,
				\out, outBus,
				\freq, rate,
				\amp, depth,
				\waveform, shape,
				\audioIn, inputBus ? 0
			], addAction: \addToTail);

			synth;
		},

		/*
		Create a modulation bus mapper
		Reads from control bus and applies to synth parameter with scaling
		*/
		createMapper: { arg self, modBus, targetSynth, targetParam, minVal, maxVal;
			var synth;

			synth = {
				arg inBus = 0, min = 0, max = 1;
				var modValue = In.kr(inBus, 1);
				var scaled = modValue.linlin(0, 1, min, max);
				// Send to target synth parameter via set
				SendReply.kr(Impulse.kr(30), '/modUpdate', [scaled]);
			}.play(server, [
				\inBus, modBus,
				\min, minVal,
				\max, maxVal
			], addAction: \addToTail);

			// Listen for updates and apply to target
			OSCdef('modMapper_' ++ modBus, { arg msg;
				var value = msg[3];
				if(targetSynth.notNil and: { targetSynth.isPlaying }, {
					targetSynth.set(targetParam, value);
				});
			}, '/modUpdate');

			synth;
		}
	);

	publicAPI;
};

"✓ Modulator module loaded".postln;
