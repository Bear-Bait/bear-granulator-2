/*
S-4 Rival: Space Effects Section
Phase 3 - Reverb, Delay, Shimmer

Features:
- Reverb with freeze function (FreeVerb/JPverb)
- Delay with feedback and filtering
- Ping-pong stereo delay
- Shimmer (pitch-shifted delay)
- Wet/dry mix controls

This module provides inline UGen code for use in SynthDefs.
All functions return audio signals for direct integration.
*/

(
~s4SpaceEffects = {

	/*
	Function: reverb
	Purpose: Reverb with freeze capability
	Args:
	  input: Stereo audio signal [L, R]
	  size: Room size (0-1)
	  damping: High frequency damping (0-1)
	  freeze: Freeze reverb tail (0=off, 1=freeze)
	  mix: Dry/wet mix (0-1)
	Returns: Stereo processed audio signal
	*/
	var reverb = { arg input, size = 0.5, damping = 0.5, freeze = 0, mix = 0.3;
		var wet, freezeGain;

		// Freeze increases feedback to ~1.0
		freezeGain = freeze.linlin(0, 1, 0.9, 0.9999);

		// Use FreeVerb for each channel
		wet = [
			FreeVerb.ar(input[0], mix: 1.0, room: size * freezeGain, damp: damping),
			FreeVerb.ar(input[1], mix: 1.0, room: size * freezeGain, damp: damping)
		];

		// Mix
		XFade2.ar(input, wet, mix.linlin(0, 1, -1, 1));
	};

	/*
	Function: delay
	Purpose: Stereo delay with feedback and filtering
	Args:
	  input: Stereo audio signal [L, R]
	  time: Delay time in seconds (0.01-2.0)
	  feedback: Feedback amount (0-0.95)
	  filterFreq: Feedback filter frequency (200-10000 Hz)
	  pingPong: Ping-pong mode (0=off, 1=on)
	  mix: Dry/wet mix (0-1)
	Returns: Stereo processed audio signal
	*/
	var delay = { arg input, time = 0.25, feedback = 0.5, filterFreq = 5000, pingPong = 0, mix = 0.3;
		var maxDelay = 2.0;
		var delayL, delayR, wetL, wetR;
		var fbL, fbR;

		// Delay lines with feedback
		delayL = LocalIn.ar(1);
		delayR = LocalIn.ar(1);

		// Mix input with feedback
		wetL = DelayC.ar(input[0] + delayL, maxDelay, time.clip(0.01, maxDelay));
		wetR = DelayC.ar(input[1] + delayR, maxDelay, time.clip(0.01, maxDelay));

		// Apply filtering to feedback
		fbL = LPF.ar(wetL, filterFreq) * feedback;
		fbR = LPF.ar(wetR, filterFreq) * feedback;

		// Ping-pong: swap channels in feedback
		LocalOut.ar([
			Select.ar(pingPong, [fbL, fbR]),
			Select.ar(pingPong, [fbR, fbL])
		]);

		// Mix with dry
		XFade2.ar(input, [wetL, wetR], mix.linlin(0, 1, -1, 1));
	};

	/*
	Function: shimmer
	Purpose: Pitch-shifted delay for shimmer effect
	Args:
	  input: Stereo audio signal [L, R]
	  time: Delay time in seconds (0.1-2.0)
	  feedback: Feedback amount (0-0.9)
	  pitch: Pitch shift in semitones (typically +7 or +12)
	  windowSize: FFT window size (0.05-0.5, smaller=glitchy, larger=smooth)
	  mix: Dry/wet mix (0-1)
	Returns: Stereo processed audio signal
	*/
	var shimmer = { arg input, time = 0.5, feedback = 0.6, pitch = 12, windowSize = 0.2, mix = 0.3;
		var maxDelay = 2.0;
		var delayL, delayR, shiftL, shiftR, wetL, wetR;
		var fbL, fbR;

		// Feedback from local bus
		fbL = LocalIn.ar(1);
		fbR = LocalIn.ar(1);

		// Delay
		delayL = DelayC.ar(input[0] + fbL, maxDelay, time.clip(0.1, maxDelay));
		delayR = DelayC.ar(input[1] + fbR, maxDelay, time.clip(0.1, maxDelay));

		// Pitch shift the delayed signal
		// Phase 7c: Variable windowSize allows morphing between granular and smooth textures
		shiftL = PitchShift.ar(
			delayL,
			windowSize: windowSize.clip(0.05, 0.5),  // Smaller = glitchy, larger = smooth
			pitchRatio: pitch.midiratio,
			pitchDispersion: 0.01,
			timeDispersion: 0.01
		);

		shiftR = PitchShift.ar(
			delayR,
			windowSize: windowSize.clip(0.05, 0.5),
			pitchRatio: pitch.midiratio,
			pitchDispersion: 0.01,
			timeDispersion: 0.01
		);

		// Feed back the shifted signal
		LocalOut.ar([shiftL * feedback, shiftR * feedback]);

		wetL = shiftL;
		wetR = shiftR;

		// Mix with dry
		XFade2.ar(input, [wetL, wetR], mix.linlin(0, 1, -1, 1));
	};

	// Return API
	(
		reverb: reverb,
		delay: delay,
		shimmer: shimmer
	);
};

// Initialize
~spaceEffects = ~s4SpaceEffects.value;
)

/*
Usage examples (for testing):

// Reverb
(
{
	var sig = Impulse.ar([2, 2.1]) * 0.3;
	~spaceEffects.reverb.value(sig, size: 0.9, damping: 0.3, freeze: 0, mix: 0.5);
}.play;
)

// Delay
(
{
	var sig = Impulse.ar([1, 1.05]) * 0.3;
	~spaceEffects.delay.value(sig, time: 0.25, feedback: 0.6, filterFreq: 3000, pingPong: 1, mix: 0.5);
}.play;
)

// Shimmer
(
{
	var sig = Impulse.ar([0.5, 0.51]) * 0.3;
	~spaceEffects.shimmer.value(sig, time: 0.5, feedback: 0.7, pitch: 12, mix: 0.6);
}.play;
)
*/
