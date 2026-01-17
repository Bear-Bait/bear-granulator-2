/*
BEARULATOR: 48-Band Morphing Resonator
Phase 2 - Tuned Filterbank

Features:
- 48 parallel resonant filters
- Harmonic and inharmonic tuning modes
- LP/BP/HP morphing
- Resonance/Q control
- Decay time (resonance tail)
- Animation (LFO on band gains)
- Master cutoff control

This creates a spectral resonator similar to:
- 4ms Spectral Multiband Resonator (SMR)
- Mutable Instruments Rings
- Torso S-4's resonator section
*/

(
~bearulatorFilterbank = {

	/*
	Function: createFilterbank
	Purpose: Generate a 48-band resonator as an audio function
	Args:
	  input: Audio input signal
	  fundamental: Base frequency (default 100 Hz)
	  numBands: Number of filter bands (default 48)
	  morph: Filter type (0=LP, 0.5=BP, 1.0=HP)
	  resonance: Resonance amount (0-1)
	  decay: Decay time multiplier (0-1)
	  animate: Animation amount (0-1)
	  animateRate: Animation LFO rate (Hz)
	  tuning: Tuning mode (0=harmonic, 1=inharmonic)
	  spread: Frequency spread for inharmonic (1.0-2.0)
	  masterGain: Master output gain
	Returns: Processed audio signal
	*/
	var createFilterbank = { arg
		input,
		fundamental = 100,
		numBands = 48,
		morph = 0.5,
		resonance = 0.5,
		decay = 0.5,
		animate = 0,
		animateRate = 0.5,
		tuning = 0,
		spread = 1.5,
		masterGain = 1.0;

		var filters, freqs, gains, rq, sig;
		var animateLFO, bandGains;

		// Calculate frequencies for each band
		freqs = numBands.collect({ arg i;
			var harmonic = i + 1;
			var freq;

			// Mix between harmonic and inharmonic based on tuning param
			freq = Select.kr(tuning > 0.5, [
				// Harmonic: perfect integer multiples
				fundamental * harmonic,
				// Inharmonic: stretched/compressed partials
				fundamental * (harmonic ** spread.linlin(1.0, 2.0, 0.9, 1.1))
			]);

			freq.clip(20, 18000);  // Keep in audible range
		});

		// Calculate RQ from resonance
		// Higher resonance = lower RQ = narrower bandwidth
		rq = resonance.linexp(0, 1, 0.5, 0.005);

		// Animation LFO (creates movement across bands)
		animateLFO = SinOsc.kr(animateRate);

		// Create individual band gains with animation
		bandGains = numBands.collect({ arg i;
			var phase = (i / numBands) * 2pi;
			var modulation = SinOsc.kr(animateRate, phase);
			var baseGain = 1.0;
			var animatedGain = baseGain + (modulation * animate * 0.5);

			// Apply decay envelope shape
			// Higher band numbers decay faster (natural resonator behavior)
			var decayMult = 1.0 - ((i / numBands) * (1.0 - decay));

			animatedGain * decayMult;
		});

		// Create 48 parallel filters
		filters = numBands.collect({ arg i;
			var freq = freqs[i];
			var gain = bandGains[i];
			var filtered;

			// Apply morphing resonant filter
			filtered = ~filterShapes.resonantMorphingFilter.value(
				input,
				freq,
				rq,
				morph,
				resonance
			);

			filtered * gain;
		});

		// Sum all filters
		sig = Mix(filters);

		// Normalize and apply master gain
		// Divide by sqrt(numBands) to prevent volume buildup
		sig = sig / numBands.sqrt * masterGain;

		// Soft limiting
		sig = sig.softclip;

		sig;
	};

	/*
	Function: harmonicScale
	Purpose: Generate harmonic series frequencies
	Args:
	  fundamental: Base frequency
	  numPartials: Number of harmonics
	Returns: Array of frequencies
	*/
	var harmonicScale = { arg fundamental = 100, numPartials = 48;
		numPartials.collect({ arg i; fundamental * (i + 1) });
	};

	/*
	Function: inharmonicScale
	Purpose: Generate inharmonic (stretched) frequencies
	Args:
	  fundamental: Base frequency
	  numPartials: Number of partials
	  stretch: Stretch factor (1.0 = harmonic, >1.0 = stretched)
	Returns: Array of frequencies
	*/
	var inharmonicScale = { arg fundamental = 100, numPartials = 48, stretch = 1.02;
		numPartials.collect({ arg i;
			fundamental * ((i + 1) ** stretch)
		});
	};

	/*
	Function: customScale
	Purpose: Tune filterbank to a specific scale/chord
	Args:
	  root: Root frequency
	  ratios: Array of frequency ratios
	  octaves: Number of octaves to span
	Returns: Array of frequencies
	*/
	var customScale = { arg root = 100, ratios = [1, 5/4, 3/2, 2], octaves = 4;
		var freqs = [];
		octaves.do({ arg oct;
			ratios.do({ arg ratio;
				freqs = freqs.add(root * ratio * (2 ** oct));
			});
		});
		freqs.sort;
	};

	// Return public API
	(
		createFilterbank: createFilterbank,
		harmonicScale: harmonicScale,
		inharmonicScale: inharmonicScale,
		customScale: customScale
	);
};

// Initialize
~filterbank = ~bearulatorFilterbank.value;
)

/*
Usage examples:

// Test with noise (good for hearing filter structure)
(
{
	var sig = WhiteNoise.ar(0.1);
	~filterbank.createFilterbank.value(
		sig,
		fundamental: 200,
		numBands: 48,
		morph: 0.5,        // Bandpass
		resonance: 0.7,    // High resonance
		decay: 0.8,
		animate: 0,
		animateRate: 0.5,
		tuning: 0,         // Harmonic
		masterGain: 1.0
	);
}.play;
)

// Test with sawtooth (rich harmonic source)
(
{
	var sig = Saw.ar(110) * 0.1;
	var morph = SinOsc.kr(0.2).range(0, 1);  // Morph over time
	~filterbank.createFilterbank.value(
		sig,
		fundamental: 110,
		morph: morph,
		resonance: 0.6,
		animate: 0.5,      // Some animation
		animateRate: 0.3
	);
}.play;
)

// Animated resonator
(
{
	var sig = PinkNoise.ar(0.05);
	~filterbank.createFilterbank.value(
		sig,
		fundamental: 150,
		morph: 0.5,
		resonance: 0.8,
		animate: 0.8,      // Lots of animation
		animateRate: 0.4,
		tuning: 0
	);
}.play;
)

// Inharmonic mode
(
{
	var sig = WhiteNoise.ar(0.1);
	~filterbank.createFilterbank.value(
		sig,
		fundamental: 100,
		morph: 0.5,
		resonance: 0.7,
		tuning: 1,         // Inharmonic
		spread: 1.8        // More stretched
	);
}.play;
)

// Generate scale frequencies
~filterbank.harmonicScale.value(100, 16);     // First 16 harmonics of 100 Hz
~filterbank.inharmonicScale.value(100, 16, 1.05);  // Stretched partials
~filterbank.customScale.value(220, [1, 5/4, 3/2, 2], 3);  // Major triad, 3 octaves
*/
