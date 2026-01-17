/*
BEARULATOR: Test Sample Generator

Run this to create test audio samples in the buffer
Useful when you don't have audio input available
*/

(
"============================================".postln;
"TEST SAMPLE GENERATOR".postln;
"============================================".postln;
"".postln;

~createTestSamples = {
	var samples = ();

	samples.drone = {
		"Creating harmonic drone...".postln;
		if(~recorder.buffer.notNil, {
			fork {
				var synth = {
					var sig, freq = 200;
					sig = Mix([
						SinOsc.ar(freq * 1) * 0.3,
						SinOsc.ar(freq * 2) * 0.2,
						SinOsc.ar(freq * 3) * 0.15,
						SinOsc.ar(freq * 4) * 0.1,
						SinOsc.ar(freq * 5) * 0.08,
						SinOsc.ar(freq * 7) * 0.05
					]);
					sig = sig * EnvGen.kr(Env.linen(0.5, 2.5, 0.5), doneAction: 2);
					RecordBuf.ar(sig, ~recorder.buffer, loop: 0);
					sig * 0.3;
				}.play;
				4.wait;
				"✓ Harmonic drone created".postln;
			};
		}, {
			"Error: Recorder not initialized".postln;
		});
	};

	samples.noise = {
		"Creating filtered noise sweep...".postln;
		if(~recorder.buffer.notNil, {
			fork {
				var synth = {
					var sig, freq;
					freq = XLine.kr(200, 4000, 3.5);
					sig = BPF.ar(WhiteNoise.ar, freq, 0.1) * 4;
					sig = sig * EnvGen.kr(Env.linen(0.1, 3.5, 0.4), doneAction: 2);
					RecordBuf.ar(sig, ~recorder.buffer, loop: 0);
					sig * 0.3;
				}.play;
				4.wait;
				"✓ Noise sweep created".postln;
			};
		}, {
			"Error: Recorder not initialized".postln;
		});
	};

	samples.melody = {
		"Creating melodic sequence...".postln;
		if(~recorder.buffer.notNil, {
			fork {
				var synth = {
					var sig, freq, trig;
					trig = Impulse.kr(8);
					freq = Demand.kr(trig, 0, Dseq([
						60, 64, 67, 72, 67, 64,
						60, 62, 65, 69, 65, 62
					].midicps, inf));
					sig = SinOsc.ar(freq) * 0.5;
					sig = sig * EnvGen.kr(Env.perc(0.01, 0.12), trig);
					sig = sig * EnvGen.kr(Env.linen(0.1, 3.5, 0.4), doneAction: 2);
					RecordBuf.ar(sig, ~recorder.buffer, loop: 0);
					sig * 0.3;
				}.play;
				4.wait;
				"✓ Melodic sequence created".postln;
			};
		}, {
			"Error: Recorder not initialized".postln;
		});
	};

	samples.percussion = {
		"Creating percussive hits...".postln;
		if(~recorder.buffer.notNil, {
			fork {
				var synth = {
					var sig, trig;
					trig = Impulse.kr(4);
					sig = Mix([
						// Kick
						SinOsc.ar(XLine.kr(120, 40, 0.1, doneAction: 0), 0, 0.5) *
							EnvGen.kr(Env.perc(0.001, 0.2), trig),
						// Snare
						BPF.ar(WhiteNoise.ar, 2000, 0.5, 0.3) *
							EnvGen.kr(Env.perc(0.001, 0.1), Delay1.kr(trig)),
						// Hat
						HPF.ar(WhiteNoise.ar, 8000, 0.15) *
							EnvGen.kr(Env.perc(0.001, 0.05), Impulse.kr(16))
					]);
					sig = sig * EnvGen.kr(Env.linen(0.1, 3.5, 0.4), doneAction: 2);
					RecordBuf.ar(sig, ~recorder.buffer, loop: 0);
					sig * 0.3;
				}.play;
				4.wait;
				"✓ Percussion created".postln;
			};
		}, {
			"Error: Recorder not initialized".postln;
		});
	};

	samples.complex = {
		"Creating complex texture...".postln;
		if(~recorder.buffer.notNil, {
			fork {
				var synth = {
					var sig, freq;
					freq = LFNoise1.kr(3).range(200, 800);
					sig = Mix([
						SinOsc.ar(freq) * 0.2,
						Pulse.ar(freq * 1.5, LFNoise1.kr(2).range(0.3, 0.7)) * 0.15,
						LFTri.ar(freq * 0.5) * 0.2,
						BPF.ar(WhiteNoise.ar, freq * 2, 0.2) * 0.3
					]);
					sig = sig * EnvGen.kr(Env.linen(0.5, 2.5, 0.5), doneAction: 2);
					RecordBuf.ar(sig, ~recorder.buffer, loop: 0);
					sig * 0.2;
				}.play;
				4.wait;
				"✓ Complex texture created".postln;
			};
		}, {
			"Error: Recorder not initialized".postln;
		});
	};

	samples;
};

"Available test samples:".postln;
"".postln;
"  ~createTestSamples.value.drone      - Harmonic overtone series".postln;
"  ~createTestSamples.value.noise      - Filtered noise sweep".postln;
"  ~createTestSamples.value.melody     - Melodic sequence".postln;
"  ~createTestSamples.value.percussion - Percussive pattern".postln;
"  ~createTestSamples.value.complex    - Complex texture".postln;
"".postln;
"Usage:".postln;
"  ~createTestSamples.value.drone; // Creates drone in buffer".postln;
"  ~createTestSamples.value.melody; // Creates melody in buffer".postln;
"".postln;
"Note: Make sure main.scd is running before creating samples!".postln;
"============================================".postln;
)

/*
USAGE EXAMPLES:

// Create a harmonic drone to granulate
~createTestSamples.value.drone;

// Wait 4 seconds, then adjust grain parameters
// Try: small grain size (20ms), high density (100), sine envelope

// Create a melody
~createTestSamples.value.melody;

// Try: large grain size (200ms), low density (20), position scrubbing

// Create percussion
~createTestSamples.value.percussion;

// Try: tiny grains (10ms), very high density (150), percussive envelope

// Create complex texture
~createTestSamples.value.complex;

// Try: medium grains (100ms), moderate density (40), lots of jitter

RECOMMENDED SETTINGS FOR EACH SAMPLE:

Drone:
  Grain Size: 150ms
  Density: 30
  Position: 0.5
  Pitch: 0
  Pos Jitter: 0.1
  Pitch Jitter: 0
  Envelope: Sine

Noise:
  Grain Size: 50ms
  Density: 80
  Position: slowly move 0→1
  Pitch: -12
  Pos Jitter: 0.3
  Pitch Jitter: 2
  Envelope: Sine

Melody:
  Grain Size: 80ms
  Density: 25
  Position: 0.5
  Pitch: 7
  Pos Jitter: 0.15
  Pitch Jitter: 0
  Envelope: Triangle

Percussion:
  Grain Size: 15ms
  Density: 120
  Position: 0.3
  Pitch: 0
  Pos Jitter: 0.4
  Pitch Jitter: 7
  Envelope: Percussive

Complex:
  Grain Size: 100ms
  Density: 45
  Position: slowly modulate
  Pitch: -5
  Pos Jitter: 0.25
  Pitch Jitter: 3
  Envelope: Welch
*/
