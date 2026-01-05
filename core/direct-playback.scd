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
	    pitch = 0;          // Pitch shift in semitones (added to rate)

	var sig, bufFrames, loopStartFrame, loopEndFrame;
	var playbackRate, phase;
	var smoothRate, smoothLoopStart, smoothLoopEnd, smoothAmp, smoothPan;

	// Get buffer info
	bufFrames = BufFrames.kr(bufnum);
	loopStartFrame = loopStart * bufFrames;
	loopEndFrame = loopEnd * bufFrames;

	// Add lag smoothing to prevent glitchy jumps (expert's suggestion #1)
	smoothRate = rate.lag(0.05);  // Smooth rate changes
	smoothLoopStart = loopStart.lag(0.1);  // Smooth loop boundary changes
	smoothLoopEnd = loopEnd.lag(0.1);
	smoothAmp = amp.lag(0.05);  // Smooth amplitude changes
	smoothPan = pan.lag(0.05);  // Smooth pan changes

	// Calculate playback rate (combine rate param + pitch shift)
	playbackRate = smoothRate * (2 ** (pitch.lag(0.05) / 12));

	// Use Phasor to track position within loop boundaries
	// This runs continuously without retriggering (fixes glitch issue)
	phase = Phasor.ar(
		trig: 0,  // Never retrigger - just loop continuously
		rate: BufRateScale.kr(bufnum) * playbackRate / bufFrames,
		start: smoothLoopStart,
		end: smoothLoopEnd,
		resetPos: smoothLoopStart  // Start at loop start
	);

	// Use BufRd instead of PlayBuf for smoother reading
	// This eliminates the retriggering issue entirely
	sig = BufRd.ar(
		numChannels: 1,
		bufnum: bufnum,
		phase: phase * bufFrames,  // Convert normalized phase to frame position
		loop: 1,  // Always loop
		interpolation: 4  // Cubic interpolation for smoother sound
	);

	// Send playhead position @ 60Hz for GUI visualization
	// Note: This sends with the synth's node ID automatically
	SendReply.ar(Impulse.ar(60), '/directPlayhead', [phase]);

	// Debug: Send a trigger on synth creation
	SendReply.kr(Impulse.kr(0.5), '/directDebug', [phase]);

	// Apply amplitude and pan with smoothing
	sig = sig * smoothAmp;
	sig = Pan2.ar(sig, smoothPan);

	Out.ar(out, sig);
}).add;

"✓ Direct Playback engine loaded".postln;
