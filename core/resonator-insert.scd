// ============================================
// BEARULATOR - RESONATOR INSERT MODULE
// Modular 48-Band Morphing Resonator
// Can be used on Master Bus or Per-Track
// ============================================

(
var numBands = 48;
var dMinorRatios = [1, 9/8, 6/5, 4/3, 3/2, 8/5, 9/5];

// ========================================
// SYNTHDEF: Resonator Insert Effect
// ========================================
SynthDef(\resonatorInsert, { |inBus = 0, outBus = 0, amp = 1.0, gate = 1,
	                          resOn = 1, resMix = 0.5, fbAmt = 0.0|
	var input, dry, sigL, sigR, wet, env, feedback;
	var freqs = \freqs.kr(Array.fill(numBands, { |i| 100 * (i + 1) }));
	var ampsL = \ampsL.kr(Array.fill(numBands, { |i| 1 / (i + 1) }));
	var ampsR = \ampsR.kr(Array.fill(numBands, { |i| 1 / (i + 1) }));
	var rings = \rings.kr(Array.fill(numBands, { 1.0 }));

	input = In.ar(inBus, 2);
	dry = input;

	// Feedback with safety limiting
	feedback = LocalIn.ar(2);
	feedback = LeakDC.ar(feedback);  // Remove DC buildup
	feedback = (feedback * 0.5).tanh;  // Soft limit before scaling
	feedback = feedback * Lag.kr(fbAmt, 0.1);
	input = input + feedback;

	sigL = DynKlank.ar(`[freqs, ampsL, rings], input[0]);
	sigR = DynKlank.ar(`[freqs, ampsR, rings], input[1]);

	// Limit feedback send to prevent runaway
	LocalOut.ar(Limiter.ar([sigL, sigR] * 0.15, 0.8));

	sigL = (sigL * 0.1).tanh * 2;
	sigR = (sigR * 0.1).tanh * 2;
	wet = Limiter.ar([sigL, sigR], 0.95);

	wet = Select.ar(resOn > 0.5, [dry, XFade2.ar(dry, wet, Lag.kr(resMix, 0.1).linlin(0, 1, -1, 1))]);

	env = EnvGen.kr(Env.asr(0.01, 1, 0.1), gate, doneAction: 2);
	Out.ar(outBus, wet * amp * env);
}).add;

// ========================================
// RESONATOR MANAGER (Flat structure)
// ========================================
~resonatorManager = (
	instances: Dictionary.new,
	numBands: numBands,
	dMinorRatios: dMinorRatios,

	calcFreqs: { |self, baseFreq, morph, quantize|
		var nyquist = s.sampleRate * 0.5;
		Array.fill(self.numBands, { |i|
			var freq = baseFreq * ((i + 1) ** morph);
			if(quantize == true, {
				var octave = (freq / baseFreq).log2.floor;
				var ratio = freq / (baseFreq * (2 ** octave));
				var nearestRatio = self.dMinorRatios.minItem({ |r| (r - ratio).abs });
				freq = baseFreq * (2 ** octave) * nearestRatio;
			});
			freq.clip(20, nyquist - 100);
		});
	},

	calcAmps: { |self, damp, split|
		var baseAmps = Array.fill(self.numBands, { |i|
			var normalized = i / (self.numBands - 1);
			var tiltAmt = (damp - 1.0).abs * 4;
			var result = case
				{ damp < 1.0 } { (1 - normalized) ** tiltAmt }
				{ damp > 1.0 } { (normalized.max(0.01)) ** tiltAmt }
				{ 1.0 };
			result.max(0.01);
		});
		baseAmps = baseAmps.normalizeSum * self.numBands * 0.5;

		if(split == true, {
			[
				Array.fill(self.numBands, { |i| if(i.odd, { baseAmps[i] }, { 0.0 }) }),
				Array.fill(self.numBands, { |i| if(i.even, { baseAmps[i] }, { 0.0 }) })
			];
		}, {
			[baseAmps, baseAmps];
		});
	},

	calcRings: { |self, decay|
		Array.fill(self.numBands, { |i|
			var normalized = i / (self.numBands - 1);
			(decay * (1 - (normalized * 0.7))).clip(0.05, 10);
		});
	},

	create: { |self, id, inBus, outBus, addAction = \addToTail, target = nil|
		var state, amps;

		// Flat state structure (no nested Events!)
		state = Dictionary.new;
		state[\synth] = nil;
		state[\inBus] = inBus;
		state[\outBus] = outBus;
		state[\freq] = 100;
		state[\morph] = 1.0;
		state[\damp] = 1.0;
		state[\decay] = 1.0;
		state[\feedback] = 0.0;
		state[\mix] = 0.5;
		state[\on] = 1;
		state[\quantize] = false;
		state[\split] = false;

		// Calculate initial arrays
		state[\freqs] = self.calcFreqs(100, 1.0, false);
		amps = self.calcAmps(1.0, false);
		state[\ampsL] = amps[0];
		state[\ampsR] = amps[1];
		state[\rings] = self.calcRings(1.0);

		// Create synth
		if(target.notNil, {
			state[\synth] = Synth(\resonatorInsert, [
				\inBus, inBus, \outBus, outBus,
				\freqs, state[\freqs], \ampsL, state[\ampsL],
				\ampsR, state[\ampsR], \rings, state[\rings],
				\resOn, 1, \resMix, 0.5, \fbAmt, 0
			], target, addAction);
		}, {
			state[\synth] = Synth(\resonatorInsert, [
				\inBus, inBus, \outBus, outBus,
				\freqs, state[\freqs], \ampsL, state[\ampsL],
				\ampsR, state[\ampsR], \rings, state[\rings],
				\resOn, 1, \resMix, 0.5, \fbAmt, 0
			], addAction: addAction);
		});

		self.instances[id] = state;
		("Resonator '" ++ id ++ "' created").postln;
		state;
	},

	setParam: { |self, id, param, value|
		var state = self.instances[id];
		var needsArrayUpdate = false;
		var amps;

		if(state.isNil, {
			("Resonator '" ++ id ++ "' not found").warn;
		}, {
			// Store param
			state[param] = value;

			// Handle different params
			case
				{ param == \freq } { needsArrayUpdate = true }
				{ param == \morph } { needsArrayUpdate = true }
				{ param == \damp } { needsArrayUpdate = true }
				{ param == \decay } { needsArrayUpdate = true }
				{ param == \quantize } { needsArrayUpdate = true }
				{ param == \split } { needsArrayUpdate = true }
				{ param == \feedback } { if(state[\synth].notNil, { state[\synth].set(\fbAmt, value) }) }
				{ param == \mix } { if(state[\synth].notNil, { state[\synth].set(\resMix, value) }) }
				{ param == \on } { if(state[\synth].notNil, { state[\synth].set(\resOn, value) }) };

			// Recalculate arrays if needed
			if(needsArrayUpdate, {
				state[\freqs] = self.calcFreqs(
					state[\freq] ? 100,
					state[\morph] ? 1.0,
					state[\quantize] == true
				);
				amps = self.calcAmps(
					state[\damp] ? 1.0,
					state[\split] == true
				);
				state[\ampsL] = amps[0];
				state[\ampsR] = amps[1];
				state[\rings] = self.calcRings(state[\decay] ? 1.0);

				if(state[\synth].notNil, {
					state[\synth].setn(\freqs, state[\freqs]);
					state[\synth].setn(\ampsL, state[\ampsL]);
					state[\synth].setn(\ampsR, state[\ampsR]);
					state[\synth].setn(\rings, state[\rings]);
				});
			});
		});
		value;
	},

	getState: { |self, id|
		self.instances[id];
	},

	free: { |self, id|
		var state = self.instances[id];
		if(state.notNil, {
			if(state[\synth].notNil, { state[\synth].release });
			self.instances.removeAt(id);
			("Resonator '" ++ id ++ "' freed").postln;
		});
	},

	freeAll: { |self|
		self.instances.keysValuesDo({ |id, state|
			if(state[\synth].notNil, { state[\synth].release });
		});
		self.instances.clear;
		"All resonators freed".postln;
	}
);

"✓ Resonator Insert module loaded".postln;
)
