/*
S-4 Rival: Master Mix Bus
Phase 4 - 4-Track Architecture

Sums 4 independent track buses and applies:
- Per-track volume, pan, mute controls
- Shared 48-band morphing resonator (moved from grain engine)
- Master volume control
- Soft limiting

Signal Flow:
Track 1 (Bus 10-11) ↘
Track 2 (Bus 12-13) → Master Mix → 48-Band Filter → Output
Track 3 (Bus 14-15) ↗
Track 4 (Bus 16-17) ↗

CRITICAL: This synth MUST be created with addAction: \addToTail
to ensure it runs AFTER the track synths in the audio graph.
*/

SynthDef(\s4MasterBus, {
	arg track1Bus = 10,
	    track2Bus = 12,
	    track3Bus = 14,
	    track4Bus = 16,

	    // Per-track mix controls
	    track1Vol = 0.8,
	    track1Pan = 0,
	    track1Mute = 0,

	    track2Vol = 0.8,
	    track2Pan = 0,
	    track2Mute = 0,

	    track3Vol = 0.8,
	    track3Pan = 0,
	    track3Mute = 0,

	    track4Vol = 0.8,
	    track4Pan = 0,
	    track4Mute = 0,

	    // Master 48-band resonator parameters (from Phase 2)
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
	    out = 0;

	var t1, t2, t3, t4, mix, filtered;
	var rampTime = 0.05; // Smooth parameter changes

	// Read from track buses (stereo)
	t1 = In.ar(track1Bus, 2);
	t2 = In.ar(track2Bus, 2);
	t3 = In.ar(track3Bus, 2);
	t4 = In.ar(track4Bus, 2);

	// Apply per-track controls
	t1 = t1 * Lag.kr(track1Vol, rampTime) * (1 - Lag.kr(track1Mute, rampTime));
	t2 = t2 * Lag.kr(track2Vol, rampTime) * (1 - Lag.kr(track2Mute, rampTime));
	t3 = t3 * Lag.kr(track3Vol, rampTime) * (1 - Lag.kr(track3Mute, rampTime));
	t4 = t4 * Lag.kr(track4Vol, rampTime) * (1 - Lag.kr(track4Mute, rampTime));

	// Apply per-track panning
	t1 = Balance2.ar(t1[0], t1[1], Lag.kr(track1Pan, rampTime));
	t2 = Balance2.ar(t2[0], t2[1], Lag.kr(track2Pan, rampTime));
	t3 = Balance2.ar(t3[0], t3[1], Lag.kr(track3Pan, rampTime));
	t4 = Balance2.ar(t4[0], t4[1], Lag.kr(track4Pan, rampTime));

	// Sum all 4 tracks
	mix = t1 + t2 + t3 + t4;

	// === PHASE 15: 128-BAND RESONATOR (M4 Extreme Plan) ===
	// Upgraded from 48 bands to 128 bands using DynKlank for efficiency
	// Provides professional spectral resolution and smooth morphing

	filtered = Select.ar(filterOn > 0.5, [
		// Filter off: pass through
		mix,
		// Filter on: process through 128-band resonator
		[
			// Left channel: 128-band DynKlank resonator
			DynKlank.ar(
				// Specifications: [frequencies, amplitudes, ring times]
				`[
					// Frequencies: 128 harmonic bands
					Array.fill(128, { arg i;
						var harmonic = i + 1;
						filterFreq * harmonic * (filterTuning.linlin(0, 1, 0.98, 1.02));
					}),
					// Amplitudes: Decay envelope with animation
					Array.fill(128, { arg i;
						var bandGain = 1.0 - ((i / 128) * (1.0 - filterDecay));
						var phase = (i / 128) * 2pi * filterSpread;
						var modulation = SinOsc.kr(filterAnimRate, phase);
						bandGain * (1 + (modulation * filterAnimate * 0.5));
					}),
					// Ring times: Controlled by resonance parameter
					Array.fill(128, { arg i;
						filterRes.linexp(0.01, 1, 0.1, 2.0);
					})
				],
				// Input signal
				mix[0],
				// Frequency scaling (for morph effect)
				freqscale: 1.0 + (filterMorph * 0.5),
				// Frequency offset
				freqoffset: 0,
				// Decay time scaling
				decayscale: 1.0
			) / 128.sqrt,

			// Right channel: 128-band DynKlank resonator (slight detuning for width)
			DynKlank.ar(
				`[
					Array.fill(128, { arg i;
						var harmonic = i + 1;
						var detune = filterSpread.linlin(1.0, 2.0, 1.0, 1.01); // Stereo width
						filterFreq * harmonic * (filterTuning.linlin(0, 1, 0.98, 1.02)) * detune;
					}),
					Array.fill(128, { arg i;
						var bandGain = 1.0 - ((i / 128) * (1.0 - filterDecay));
						var phase = (i / 128) * 2pi * filterSpread;
						var modulation = SinOsc.kr(filterAnimRate, phase);
						bandGain * (1 + (modulation * filterAnimate * 0.5));
					}),
					Array.fill(128, { arg i;
						filterRes.linexp(0.01, 1, 0.1, 2.0);
					})
				],
				mix[1],
				freqscale: 1.0 + (filterMorph * 0.5),
				freqoffset: 0,
				decayscale: 1.0
			) / 128.sqrt
		]
	]);

	// Dry/wet mix for filter
	mix = XFade2.ar(
		mix,      // dry signal
		filtered, // filtered signal
		filterMix.linlin(0, 1, -1, 1)
	);

	// Master volume control
	mix = mix * Lag.kr(masterVol, rampTime);

	// Phase 15: DC SAFETY & HEADROOM (M4 Extreme Plan)
	// CRITICAL: Remove DC offset BEFORE dynamics processing
	// High-resonance filters can create dangerous DC voltage
	mix = LeakDC.ar(mix, coef: 0.995);

	// Phase 9: Master Bus "Glue" Compressor
	// Bonds the 4 tracks together with gentle compression
	// Soft-knee design for transparent cohesion
	mix = Compander.ar(
		in: mix,
		control: mix,
		thresh: 0.6,        // Threshold (0-1)
		slopeBelow: 1.0,    // No compression below threshold
		slopeAbove: 0.5,    // 2:1 ratio above threshold
		clampTime: 0.01,    // 10ms attack (fast enough to catch transients)
		relaxTime: 0.1      // 100ms release (smooth, musical)
	);

	// Phase 15: BRICK-WALL LIMITER (Safety + Headroom)
	// Upgrade from .tanh to proper Limiter.ar
	// Prevents clipping while preserving dynamics
	// Allows extreme filter/saturation without fear of speaker damage
	mix = Limiter.ar(
		mix,
		level: 0.95,        // Ceiling at -0.4dB (safe headroom)
		dur: 0.01           // 10ms lookahead (catches transients)
	);

	// Output to hardware
	Out.ar(out, mix);
}).add;

/*
Usage example:

// Create 4 track buses
~trackBuses = 4.collect({ Bus.audio(s, 2) });

// Create master bus synth (MUST use addToTail)
~masterBus = Synth(\s4MasterBus, [
    \track1Bus, ~trackBuses[0],
    \track2Bus, ~trackBuses[1],
    \track3Bus, ~trackBuses[2],
    \track4Bus, ~trackBuses[3],
    \masterVol, 0.8
], addAction: \addToTail);

// Control per-track volume
~masterBus.set(\track1Vol, 0.5);
~masterBus.set(\track2Vol, 1.0);

// Control per-track panning
~masterBus.set(\track1Pan, -0.5);  // left
~masterBus.set(\track2Pan, 0.5);   // right

// Mute/unmute tracks
~masterBus.set(\track1Mute, 1);  // mute track 1
~masterBus.set(\track1Mute, 0);  // unmute track 1

// Enable master filter
~masterBus.set(\filterOn, 1);
~masterBus.set(\filterMorph, 0.0);  // Lowpass
~masterBus.set(\filterMorph, 0.5);  // Bandpass
~masterBus.set(\filterMorph, 1.0);  // Highpass

// Cleanup
~masterBus.free;
~trackBuses.do(_.free);
*/
