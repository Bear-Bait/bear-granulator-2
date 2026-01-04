/*
S-4 Rival: Quad Master Mix Bus
Phase 12 - Quad Speaker Output

Sums 4 independent track buses and applies:
- Per-track volume, mute controls
- Quad spatial positioning (X/Y coordinates)
- Shared 48-band morphing resonator
- Master volume control
- Soft limiting

Signal Flow:
Track 1 (Bus 10-11) ↘
Track 2 (Bus 12-13) → Quad Panner → 4-Channel Filter → Outputs 1-4
Track 3 (Bus 14-15) ↗
Track 4 (Bus 16-17) ↗

Speaker Layout:
  FL (0)     FR (1)
      [  X  ]
  RL (2)     RR (3)

Quad Panning:
- X: -1 (left) to +1 (right)
- Y: -1 (front) to +1 (rear)
- Each track is positioned in 2D space

CRITICAL: This synth MUST be created with addAction: \addToTail
to ensure it runs AFTER the track synths in the audio graph.
*/

SynthDef(\s4MasterBusQuad, {
	arg track1Bus = 10,
	    track2Bus = 12,
	    track3Bus = 14,
	    track4Bus = 16,

	    // Per-track mix controls
	    track1Vol = 0.8,
	    track1X = 0,      // -1 (left) to +1 (right)
	    track1Y = 0,      // -1 (front) to +1 (rear)
	    track1Mute = 0,

	    track2Vol = 0.8,
	    track2X = 0,
	    track2Y = 0,
	    track2Mute = 0,

	    track3Vol = 0.8,
	    track3X = 0,
	    track3Y = 0,
	    track3Mute = 0,

	    track4Vol = 0.8,
	    track4X = 0,
	    track4Y = 0,
	    track4Mute = 0,

	    // Master 48-band resonator parameters
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

	    // Master output
	    masterVol = 0.8,
	    out = 0;  // Output to channels 0-3 (quad)

	var t1, t2, t3, t4;
	var t1Quad, t2Quad, t3Quad, t4Quad;
	var mix, filtered;
	var rampTime = 0.05; // Smooth parameter changes

	// Read from track buses (stereo)
	t1 = In.ar(track1Bus, 2);
	t2 = In.ar(track2Bus, 2);
	t3 = In.ar(track3Bus, 2);
	t4 = In.ar(track4Bus, 2);

	// Apply per-track volume and mute
	t1 = t1 * Lag.kr(track1Vol, rampTime) * (1 - Lag.kr(track1Mute, rampTime));
	t2 = t2 * Lag.kr(track2Vol, rampTime) * (1 - Lag.kr(track2Mute, rampTime));
	t3 = t3 * Lag.kr(track3Vol, rampTime) * (1 - Lag.kr(track3Mute, rampTime));
	t4 = t4 * Lag.kr(track4Vol, rampTime) * (1 - Lag.kr(track4Mute, rampTime));

	// === QUAD SPATIAL PANNING ===
	// Convert stereo to mono for spatial placement
	t1 = (t1[0] + t1[1]) * 0.5;
	t2 = (t2[0] + t2[1]) * 0.5;
	t3 = (t3[0] + t3[1]) * 0.5;
	t4 = (t4[0] + t4[1]) * 0.5;

	// Quad panning function (X/Y → 4 speakers)
	// Uses equal-power panning for smooth spatial movement
	// Speaker layout: FL(0), FR(1), RL(2), RR(3)
	t1Quad = [
		// FL: strongest when X=-1, Y=-1
		((1 - Lag.kr(track1X, rampTime)) * (1 - Lag.kr(track1Y, rampTime)) * 0.5).sqrt * t1,
		// FR: strongest when X=+1, Y=-1
		((1 + Lag.kr(track1X, rampTime)) * (1 - Lag.kr(track1Y, rampTime)) * 0.5).sqrt * t1,
		// RL: strongest when X=-1, Y=+1
		((1 - Lag.kr(track1X, rampTime)) * (1 + Lag.kr(track1Y, rampTime)) * 0.5).sqrt * t1,
		// RR: strongest when X=+1, Y=+1
		((1 + Lag.kr(track1X, rampTime)) * (1 + Lag.kr(track1Y, rampTime)) * 0.5).sqrt * t1
	];

	t2Quad = [
		((1 - Lag.kr(track2X, rampTime)) * (1 - Lag.kr(track2Y, rampTime)) * 0.5).sqrt * t2,
		((1 + Lag.kr(track2X, rampTime)) * (1 - Lag.kr(track2Y, rampTime)) * 0.5).sqrt * t2,
		((1 - Lag.kr(track2X, rampTime)) * (1 + Lag.kr(track2Y, rampTime)) * 0.5).sqrt * t2,
		((1 + Lag.kr(track2X, rampTime)) * (1 + Lag.kr(track2Y, rampTime)) * 0.5).sqrt * t2
	];

	t3Quad = [
		((1 - Lag.kr(track3X, rampTime)) * (1 - Lag.kr(track3Y, rampTime)) * 0.5).sqrt * t3,
		((1 + Lag.kr(track3X, rampTime)) * (1 - Lag.kr(track3Y, rampTime)) * 0.5).sqrt * t3,
		((1 - Lag.kr(track3X, rampTime)) * (1 + Lag.kr(track3Y, rampTime)) * 0.5).sqrt * t3,
		((1 + Lag.kr(track3X, rampTime)) * (1 + Lag.kr(track3Y, rampTime)) * 0.5).sqrt * t3
	];

	t4Quad = [
		((1 - Lag.kr(track4X, rampTime)) * (1 - Lag.kr(track4Y, rampTime)) * 0.5).sqrt * t4,
		((1 + Lag.kr(track4X, rampTime)) * (1 - Lag.kr(track4Y, rampTime)) * 0.5).sqrt * t4,
		((1 - Lag.kr(track4X, rampTime)) * (1 + Lag.kr(track4Y, rampTime)) * 0.5).sqrt * t4,
		((1 + Lag.kr(track4X, rampTime)) * (1 + Lag.kr(track4Y, rampTime)) * 0.5).sqrt * t4
	];

	// Sum all 4 tracks (now quad)
	mix = t1Quad + t2Quad + t3Quad + t4Quad;

	// === MASTER 48-BAND MORPHING RESONATOR ===
	// Processes all 4 channels through the filterbank
	filtered = Select.ar(filterOn > 0.5, [
		// Filter off: pass through
		mix,
		// Filter on: process each quad channel through 48-band filterbank
		[
			// FL channel filterbank
			Mix.ar(48.collect({ arg i;
				var harmonic = i + 1;
				var freq = filterFreq * harmonic;
				var rq = filterRes.linexp(0.01, 1, 0.5, 0.005);
				var bandGain = 1.0 - ((i / 48) * (1.0 - filterDecay));
				var phase = (i / 48) * 2pi;
				var modulation = SinOsc.kr(filterAnimRate, phase);
				var animGain = bandGain * (1 + (modulation * filterAnimate * 0.5));
				var lp, bp, hp, lpAmt, bpAmt, hpAmt;

				lpAmt = (1 - (filterMorph * 2)).clip(0, 1);
				bpAmt = (1 - ((filterMorph - 0.5).abs * 2)).clip(0, 1);
				hpAmt = ((filterMorph - 0.5) * 2).clip(0, 1);

				lp = RLPF.ar(mix[0], freq, rq);
				bp = Resonz.ar(mix[0], freq, rq);
				hp = RHPF.ar(mix[0], freq, rq);

				((lp * lpAmt) + (bp * bpAmt) + (hp * hpAmt)) * animGain;
			})) / 48.sqrt,

			// FR channel filterbank
			Mix.ar(48.collect({ arg i;
				var harmonic = i + 1;
				var freq = filterFreq * harmonic;
				var rq = filterRes.linexp(0.01, 1, 0.5, 0.005);
				var bandGain = 1.0 - ((i / 48) * (1.0 - filterDecay));
				var phase = (i / 48) * 2pi;
				var modulation = SinOsc.kr(filterAnimRate, phase);
				var animGain = bandGain * (1 + (modulation * filterAnimate * 0.5));
				var lp, bp, hp, lpAmt, bpAmt, hpAmt;

				lpAmt = (1 - (filterMorph * 2)).clip(0, 1);
				bpAmt = (1 - ((filterMorph - 0.5).abs * 2)).clip(0, 1);
				hpAmt = ((filterMorph - 0.5) * 2).clip(0, 1);

				lp = RLPF.ar(mix[1], freq, rq);
				bp = Resonz.ar(mix[1], freq, rq);
				hp = RHPF.ar(mix[1], freq, rq);

				((lp * lpAmt) + (bp * bpAmt) + (hp * hpAmt)) * animGain;
			})) / 48.sqrt,

			// RL channel filterbank
			Mix.ar(48.collect({ arg i;
				var harmonic = i + 1;
				var freq = filterFreq * harmonic;
				var rq = filterRes.linexp(0.01, 1, 0.5, 0.005);
				var bandGain = 1.0 - ((i / 48) * (1.0 - filterDecay));
				var phase = (i / 48) * 2pi;
				var modulation = SinOsc.kr(filterAnimRate, phase);
				var animGain = bandGain * (1 + (modulation * filterAnimate * 0.5));
				var lp, bp, hp, lpAmt, bpAmt, hpAmt;

				lpAmt = (1 - (filterMorph * 2)).clip(0, 1);
				bpAmt = (1 - ((filterMorph - 0.5).abs * 2)).clip(0, 1);
				hpAmt = ((filterMorph - 0.5) * 2).clip(0, 1);

				lp = RLPF.ar(mix[2], freq, rq);
				bp = Resonz.ar(mix[2], freq, rq);
				hp = RHPF.ar(mix[2], freq, rq);

				((lp * lpAmt) + (bp * bpAmt) + (hp * hpAmt)) * animGain;
			})) / 48.sqrt,

			// RR channel filterbank
			Mix.ar(48.collect({ arg i;
				var harmonic = i + 1;
				var freq = filterFreq * harmonic;
				var rq = filterRes.linexp(0.01, 1, 0.5, 0.005);
				var bandGain = 1.0 - ((i / 48) * (1.0 - filterDecay));
				var phase = (i / 48) * 2pi;
				var modulation = SinOsc.kr(filterAnimRate, phase);
				var animGain = bandGain * (1 + (modulation * filterAnimate * 0.5));
				var lp, bp, hp, lpAmt, bpAmt, hpAmt;

				lpAmt = (1 - (filterMorph * 2)).clip(0, 1);
				bpAmt = (1 - ((filterMorph - 0.5).abs * 2)).clip(0, 1);
				hpAmt = ((filterMorph - 0.5) * 2).clip(0, 1);

				lp = RLPF.ar(mix[3], freq, rq);
				bp = Resonz.ar(mix[3], freq, rq);
				hp = RHPF.ar(mix[3], freq, rq);

				((lp * lpAmt) + (bp * bpAmt) + (hp * hpAmt)) * animGain;
			})) / 48.sqrt
		]
	]);

	// Dry/wet mix for filter
	mix = XFade2.ar(
		mix,      // dry signal (quad)
		filtered, // filtered signal (quad)
		filterMix.linlin(0, 1, -1, 1)
	);

	// Master volume control
	mix = mix * Lag.kr(masterVol, rampTime);

	// Phase 9: Master Bus "Glue" Compressor (quad)
	mix = Compander.ar(
		in: mix,
		control: Mix.ar(mix) / 4,  // Use average of 4 channels for sidechain
		thresh: 0.6,
		slopeBelow: 1.0,
		slopeAbove: 0.5,    // 2:1 ratio
		clampTime: 0.01,    // 10ms attack
		relaxTime: 0.1      // 100ms release
	);

	// Soft limiter to prevent clipping
	mix = mix.tanh;

	// DC offset protection
	mix = LeakDC.ar(mix, coef: 0.995);

	// Output to hardware (4 channels)
	Out.ar(out, mix);
}).add;

/*
Usage example:

// Create 4 track buses (stereo)
~trackBuses = 4.collect({ Bus.audio(s, 2) });

// Create quad master bus synth (MUST use addToTail)
~masterBusQuad = Synth(\s4MasterBusQuad, [
    \track1Bus, ~trackBuses[0],
    \track2Bus, ~trackBuses[1],
    \track3Bus, ~trackBuses[2],
    \track4Bus, ~trackBuses[3],
    \out, 0  // Outputs to channels 0-3
], addAction: \addToTail);

// Position tracks in quad space
~masterBusQuad.set(\track1X, -0.5, \track1Y, -0.5);  // Front-Left
~masterBusQuad.set(\track2X,  0.5, \track2Y, -0.5);  // Front-Right
~masterBusQuad.set(\track3X, -0.5, \track3Y,  0.5);  // Rear-Left
~masterBusQuad.set(\track4X,  0.5, \track4Y,  0.5);  // Rear-Right

// Control volume
~masterBusQuad.set(\track1Vol, 0.8);
~masterBusQuad.set(\masterVol, 0.7);

// Mute/unmute tracks
~masterBusQuad.set(\track1Mute, 1);  // mute track 1
~masterBusQuad.set(\track1Mute, 0);  // unmute track 1

// Cleanup
~masterBusQuad.free;
~trackBuses.do(_.free);
*/
