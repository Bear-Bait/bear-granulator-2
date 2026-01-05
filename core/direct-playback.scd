/*
S-4 Rival: Direct Playback Engine
Phase 15 - Non-granular sample playback

Simple PlayBuf-based engine for direct sample playback without granulation.
Works alongside the granular engine as an alternative mode.

Features:
- Linear buffer playback (no grains)
- Variable playback rate (pitch shift via speed)
- Loop support
- Position control
- Compatible with existing modulation system
*/

SynthDef(\s4DirectPlayback, {
	arg bufnum = 0,
	    out = 0,
	    rate = 1.0,         // Playback rate (1.0 = normal, 2.0 = double speed/+12st, 0.5 = half/-12st)
	    position = 0.0,     // Start position (0-1) - only used for initial start
	    loop = 1,           // Loop mode (1 = loop, 0 = one-shot)
	    loopStart = 0.0,    // Loop start (0-1)
	    loopEnd = 1.0,      // Loop end (0-1)
	    amp = 0.5,          // Output amplitude
	    pan = 0.0,          // Stereo pan (-1 to 1)
	    pitch = 0,          // Pitch shift in semitones (added to rate)
	    timeStretch = 1.0;  // Time stretch (speed without pitch change, 0.5-2.0)

	var sig, bufFrames, loopStartFrame, loopEndFrame, bufChannels;
	var playbackRate, phase, pitchShiftRatio, needsPitchShift;
	var smoothRate, smoothLoopStart, smoothLoopEnd, smoothAmp, smoothPan, smoothTimeStretch;

	// Get buffer info
	bufFrames = BufFrames.kr(bufnum);
	bufChannels = BufChannels.kr(bufnum);  // Auto-detect mono/stereo
	loopStartFrame = loopStart * bufFrames;
	loopEndFrame = loopEnd * bufFrames;

	// Add lag smoothing to prevent glitchy jumps (expert's suggestion #1)
	smoothRate = rate.lag(0.05);  // Smooth rate changes
	smoothLoopStart = loopStart.lag(0.1);  // Smooth loop boundary changes
	smoothLoopEnd = loopEnd.lag(0.1);
	smoothAmp = amp.lag(0.05);  // Smooth amplitude changes
	smoothPan = pan.lag(0.05);  // Smooth pan changes
	smoothTimeStretch = timeStretch.lag(0.1);  // Smooth time stretch changes

	// Calculate playback rate (combine rate param + pitch shift + time stretch)
	// timeStretch affects speed, then PitchShift compensates to maintain pitch
	playbackRate = smoothRate * (2 ** (pitch.lag(0.05) / 12)) * smoothTimeStretch;
	pitchShiftRatio = 1.0 / smoothTimeStretch;  // Compensate for time stretch

	// Only enable PitchShift when timeStretch != 1.0 (M4 CPU optimization)
	needsPitchShift = (smoothTimeStretch - 1.0).abs > 0.01;

	// Use Phasor to track position within loop boundaries
	// This runs continuously without retriggering (fixes glitch issue)
	phase = Phasor.ar(
		trig: 0,  // Never retrigger - just loop continuously
		rate: BufRateScale.kr(bufnum) * playbackRate / bufFrames,
		start: smoothLoopStart,
		end: smoothLoopEnd,
		resetPos: smoothLoopStart  // Start at loop start
	);

	// Stereo-aware BufRd: Read mono or stereo based on buffer
	// BufRd needs literal numChannels, so we read both and select
	sig = Select.ar((bufChannels - 1).min(1), [
		// Mono path: read 1 channel
		BufRd.ar(
			numChannels: 1,
			bufnum: bufnum,
			phase: phase * bufFrames,
			loop: 1,
			interpolation: 4
		),
		// Stereo path: read 2 channels
		BufRd.ar(
			numChannels: 2,
			bufnum: bufnum,
			phase: phase * bufFrames,
			loop: 1,
			interpolation: 4
		)
	]);

	// CONDITIONAL PitchShift: Only process when timeStretch != 1.0
	// This saves significant CPU on M4 when not actively time-stretching
	sig = Select.ar(needsPitchShift, [
		sig,  // Bypass when timeStretch ~= 1.0
		PitchShift.ar(
			in: sig,
			windowSize: 0.2,  // 200ms window for good quality
			pitchRatio: pitchShiftRatio,  // Compensate for time stretch
			pitchDispersion: 0.0,  // No pitch dispersion
			timeDispersion: 0.0  // No time dispersion
		)
	]);

	// Send playhead position @ 60Hz for GUI visualization
	SendReply.ar(Impulse.ar(60), '/directPlayhead', [phase]);

	// Debug: Send a trigger on synth creation
	SendReply.kr(Impulse.kr(0.5), '/directDebug', [phase]);

	// Apply amplitude and pan with smoothing
	sig = sig * smoothAmp;

	// Stereo-aware panning based on buffer channels
	sig = Select.ar((bufChannels - 1).min(1), [
		Pan2.ar(sig, smoothPan),                    // Mono: use Pan2
		Balance2.ar(sig[0], sig[1], smoothPan)      // Stereo: use Balance2
	]);

	Out.ar(out, sig);
}).add;

"✓ Direct Playback engine loaded".postln;
