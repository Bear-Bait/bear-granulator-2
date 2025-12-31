/*
S-4 Rival: Filter Shapes
Phase 2 - LP/BP/HP Morphing Logic

This module provides filter morphing functionality.
Morphs between lowpass, bandpass, and highpass filters.

Morph parameter:
  0.0 = Pure lowpass
  0.5 = Pure bandpass
  1.0 = Pure highpass

Implementation uses crossfading between filter types.
*/

(
~s4FilterShapes = {

	/*
	Function: morphingFilter
	Purpose: Create a filter that morphs between LP/BP/HP
	Args:
	  input: Audio signal
	  freq: Filter frequency
	  rq: Reciprocal of Q (bandwidth / freq)
	  morph: Morph position (0=LP, 0.5=BP, 1.0=HP)
	Returns: Filtered audio signal
	*/
	var morphingFilter = { arg input, freq, rq, morph;
		var lp, bp, hp, lpAmt, bpAmt, hpAmt;

		// Calculate morph amounts for each filter type
		// Uses piecewise linear interpolation:
		// 0.0 - 0.5: LP → BP
		// 0.5 - 1.0: BP → HP

		morph = morph.clip(0, 1);

		lpAmt = (1 - (morph * 2)).clip(0, 1);  // 1.0 at 0, 0.0 at 0.5+
		bpAmt = (1 - ((morph - 0.5).abs * 2)).clip(0, 1);  // 0 at edges, 1.0 at 0.5
		hpAmt = ((morph - 0.5) * 2).clip(0, 1);  // 0.0 at 0-0.5, 1.0 at 1.0

		// Create each filter type
		lp = LPF.ar(input, freq);
		bp = BPF.ar(input, freq, rq);
		hp = HPF.ar(input, freq);

		// Crossfade between filter types
		(lp * lpAmt) + (bp * bpAmt) + (hp * hpAmt);
	};

	/*
	Function: resonantMorphingFilter
	Purpose: Morphing filter with resonance (using Resonz)
	Args:
	  input: Audio signal
	  freq: Filter frequency
	  rq: Reciprocal of Q (controls resonance)
	  morph: Morph position (0=LP, 0.5=BP, 1.0=HP)
	  resonance: Resonance amount (0-1), controls Q
	Returns: Filtered audio signal
	*/
	var resonantMorphingFilter = { arg input, freq, rq, morph, resonance = 0.5;
		var lp, bp, hp, lpAmt, bpAmt, hpAmt;
		var actualRQ;

		// Map resonance (0-1) to RQ (wider to narrower)
		// Higher resonance = lower RQ = narrower bandwidth
		actualRQ = rq.linexp(0, 1, 0.5, 0.01) * (1 - (resonance * 0.9));

		morph = morph.clip(0, 1);

		lpAmt = (1 - (morph * 2)).clip(0, 1);
		bpAmt = (1 - ((morph - 0.5).abs * 2)).clip(0, 1);
		hpAmt = ((morph - 0.5) * 2).clip(0, 1);

		// Use RLPF/Resonz/RHPF for resonant versions
		lp = RLPF.ar(input, freq, actualRQ);
		bp = Resonz.ar(input, freq, actualRQ);
		hp = RHPF.ar(input, freq, actualRQ);

		// Compensate for Resonz gain loss
		bp = bp * actualRQ.reciprocal.sqrt;

		(lp * lpAmt) + (bp * bpAmt) + (hp * hpAmt);
	};

	/*
	Function: formantFilter
	Purpose: Single formant (resonant peak) using Resonz
	Args:
	  input: Audio signal
	  freq: Center frequency
	  q: Q factor (1-100, higher = narrower)
	  gain: Gain multiplier
	Returns: Filtered audio signal
	*/
	var formantFilter = { arg input, freq, q = 10, gain = 1;
		var rq = 1 / q;
		Resonz.ar(input, freq, rq) * rq.reciprocal.sqrt * gain;
	};

	// Return public API
	(
		morphingFilter: morphingFilter,
		resonantMorphingFilter: resonantMorphingFilter,
		formantFilter: formantFilter,

		// Helper: Calculate RQ from Q
		qToRQ: { arg q; 1 / q },

		// Helper: Calculate Q from RQ
		rqToQ: { arg rq; 1 / rq }
	);
};

// Initialize
~filterShapes = ~s4FilterShapes.value;
)

/*
Usage examples:

// Basic morphing filter
(
{
	var sig = WhiteNoise.ar(0.1);
	var morph = SinOsc.kr(0.2).range(0, 1);  // Morph slowly
	~filterShapes.morphingFilter.value(sig, 1000, 0.1, morph);
}.play;
)

// Resonant morphing filter
(
{
	var sig = Saw.ar(110) * 0.1;
	var morph = MouseX.kr(0, 1);  // Control with mouse X
	var res = MouseY.kr(0, 1);    // Control resonance with mouse Y
	~filterShapes.resonantMorphingFilter.value(sig, 800, 0.1, morph, res);
}.play;
)

// Single formant
(
{
	var sig = WhiteNoise.ar(0.1);
	~filterShapes.formantFilter.value(sig, 1200, 20, 1);
}.play;
)
*/
