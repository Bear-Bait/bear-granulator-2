/*
BEARULATOR: Warp1 Spectral Engine
Phase 8 - M4 Extreme Performance

HIGH-RESOLUTION SPECTRAL TIME-STRETCHING ENGINE
Runs concurrently with GrainBuf for layered sculpting.

Features:
- Warp1: FFT-based time-stretching (freeze time while preserving pitch)
- Independent from granular engine (runs in parallel)
- Spectral "smearing" and "freezing" effects
- Window size control (spectral resolution vs time resolution)
- Overlap factor (quality vs CPU, M4 can handle high overlap)
- Position control (independent from grain engine)
- Pitch shift (spectral formant-preserving)

Signal Flow:
  Buffer → Warp1 → Output Bus (summed with grain engine)

Args:
  bufnum: Buffer number for spectral source
  spectralMix: Wet/dry mix (0=off, 1=full spectral)
  position: Playback position (0-1, can be modulated for "smearing")
  rate: Playback rate (0=freeze, 1=normal, -1=reverse)
  windowSize: FFT window size in seconds (0.05-1.0)
                - Small (0.05): tight time resolution, loose pitch
                - Large (1.0): tight pitch, smeared time (spectral freeze)
  overlaps: Overlap factor (1-8, higher=smoother, M4 can handle 8)
  pitch: Pitch shift in semitones (-24 to +24, formant-preserving)
  interp: Interpolation quality (1-4, 4=best for M4)
  amp: Output amplitude
  out: Output bus
*/

SynthDef(\bearulatorSpectralEngine, {
	arg bufnum = 0,
	    spectralMix = 0.0,      // Wet/dry (0=off, 1=full)
	    position = 0.5,         // Position in buffer (0-1)
	    loopStart = 0.0,        // Loop start position (0-1) - BUG FIX
	    loopEnd = 1.0,          // Loop end position (0-1) - BUG FIX
	    rate = 1.0,             // Playback rate (0=freeze, 1=normal)
	    windowSize = 0.2,       // Window size in seconds (0.05-1.0)
	    overlaps = 4,           // Overlap factor (1-8, M4 can handle 8)
	    pitch = 0,              // Pitch shift in semitones (-24 to +24)
	    interp = 4,             // Interpolation (1-4, 4=best)
	    freeze = 0,             // Freeze toggle (1=freeze at current position)
	    smear = 0,              // Spectral smear amount (0-1)
	    amp = 0.5,
	    pan = 0,
	    out = 0;

	var sig, bufFrames, bufDur, pointer, freezePos, pitchRatio;
	var startFrame, endFrame, absolutePos;  // v2.2.1: Loop constraint vars
	var rampTime = 0.05;

	// Get buffer info
	bufFrames = BufFrames.kr(bufnum);
	bufDur = BufDur.kr(bufnum);

	// Pitch shift ratio (semitones to ratio)
	pitchRatio = pitch.midiratio;

	// === WARP1: Spectral Time-Stretching ===
	// Warp1 pointer: Phasor advances through buffer at specified rate
	// When freeze=1, rate becomes 0 (locks in place)
	// BUG FIX: Constrain to loop boundaries like grain engine
	startFrame = loopStart * bufFrames;
	endFrame = loopEnd * bufFrames;
	pointer = Phasor.ar(
		trig: 0,
		rate: BufRateScale.kr(bufnum) * rate * (1 - freeze),  // freeze=1 → rate=0
		start: startFrame,
		end: endFrame,
		resetPos: startFrame
	);

	// Warp1.ar(numChannels, bufnum, pointer, freqScale, windowSize, envbufnum, overlaps, windowRandRatio, interp)
	// numChannels must match buffer channels (mono buffer = 1 channel output)
	sig = Warp1.ar(
		numChannels: 1,           // Mono (buffer is mono)
		bufnum: bufnum,
		pointer: pointer,
		freqScale: pitchRatio,    // Pitch shift (formant-preserving)
		windowSize: windowSize.lag(rampTime),   // Window size in seconds
		envbufnum: -1,            // -1 = use default Hann window
		overlaps: overlaps.lag(rampTime),       // Overlap factor
		windowRandRatio: smear.lag(rampTime),   // Spectral smear
		interp: interp            // Interpolation quality
	);

	// Phase 15: Send playhead position for GUI visualization @ 60Hz
	// Broadcasts position for viewfinder window
	// Use '/spectralPlayhead' to distinguish from grain engine
	// pointer is in FRAMES [startFrame, endFrame], divide by bufFrames to get [loopStart, loopEnd]
	// This is already the correct absolute buffer position - send directly!
	absolutePos = pointer / bufFrames.max(1);
	SendReply.ar(Impulse.ar(60), '/spectralPlayhead', [absolutePos]);

	// Convert mono to stereo and apply pan
	sig = Pan2.ar(sig, pan.lag(rampTime));

	// Apply amplitude
	sig = sig * amp.lag(rampTime);

	// Wet/dry mix (0=silent, 1=full spectral)
	sig = sig * spectralMix.lag(rampTime);

	// DC offset protection (spectral processing can create DC)
	sig = LeakDC.ar(sig, coef: 0.995);

	// Output to track bus
	Out.ar(out, sig);
}).add;

/*
USAGE EXAMPLES:

// Create spectral engine on Track 1 bus
~spectralEngine = Synth(\bearulatorSpectralEngine, [
    \bufnum, ~myBuffer,
    \spectralMix, 0.5,        // 50% spectral, 50% grain (when summed)
    \position, 0.5,
    \rate, 1.0,               // Normal speed
    \windowSize, 0.2,         // 200ms window (balanced)
    \overlaps, 4,             // 4x overlap (smooth)
    \pitch, 0,                // No pitch shift
    \interp, 4,               // Best quality
    \out, ~trackBuses[0]      // Output to Track 1 bus
], addAction: \addToHead);

// SPECTRAL FREEZE (time stands still)
~spectralEngine.set(\freeze, 1);     // Freeze at current position
~spectralEngine.set(\windowSize, 1.0); // Large window = spectral smear

// SPECTRAL SMEAR (randomize phase)
~spectralEngine.set(\smear, 0.8);    // Heavy spectral smearing

// PITCH SHIFT (formant-preserving)
~spectralEngine.set(\pitch, 12);     // +1 octave, no formant shift

// LAYERED SCULPTING (grain + spectral)
// Run GrainBuf for rhythmic pulses
// Run Warp1 for spectral bed underneath
~grainEngine.set(\amp, 0.6);
~spectralEngine.set(\spectralMix, 0.4);
~spectralEngine.set(\windowSize, 0.5);  // Smeared spectral texture

// REVERSE SPECTRAL PLAYBACK
~spectralEngine.set(\rate, -1.0);    // Reverse time

// Cleanup
~spectralEngine.free;
*/

"✓ Spectral Engine (Warp1) loaded".postln;
