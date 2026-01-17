s.options.numInputBusChannels = 8;
s.options.memSize = 8192 * 256;
/*
SIMPLE AUDIO DIAGNOSTIC - BEARULATOR
====================================
Run these code blocks ONE AT A TIME to test audio step-by-step.

Select each block and press Cmd+Enter to execute.
*/

// ====================================
// STEP 1: Check Server Configuration
// ====================================
(
"====================================".postln;
"STEP 1: Server Configuration".postln;
"====================================".postln;
"Sample rate: %".format(s.sampleRate).postln;
"Input channels: %".format(s.options.numInputBusChannels).postln;
"Output channels: %".format(s.options.numOutputBusChannels).postln;
"Memory: % KB".format(s.options.memSize).postln;
"====================================".postln;
)

// ====================================
// STEP 2: Launch Meters
// ====================================
ServerMeter.new(s);
// → Watch the TOP section (inputs) - play sound into MOTU input 3

// ====================================
// STEP 3: Direct Monitoring (HEAR Input 3)
// ====================================
(
// Stop any previous monitor
if(~monitorSynth.notNil, { ~monitorSynth.free; });

// Start monitoring input 3
~monitorSynth = {
	var input = SoundIn.ar(2);  // Input 3 (0-indexed)
	input ! 2;  // Duplicate to stereo
}.play;

"✓ Monitoring input 3 - MAKE NOISE and you should HEAR yourself!".postln;
"  (Run ~monitorSynth.free; to stop)".postln;
)

// Stop monitoring
~monitorSynth.free;

// ====================================
// STEP 4: Record 4 Seconds to Buffer
// ====================================
(
"====================================".postln;
"STEP 4: Recording 4 seconds...".postln;
"→ MAKE NOISE NOW!".postln;
"====================================".postln;

// Stop monitor if running
if(~monitorSynth.notNil, { ~monitorSynth.free; });

// Create buffer
~testBuffer = Buffer.alloc(s, s.sampleRate * 4, 1);  // 4 seconds, mono

fork {
	0.2.wait;

	// Record for 4 seconds
	~recSynth = {
		var input = SoundIn.ar(2);  // Input 3
		RecordBuf.ar(input, ~testBuffer, loop: 0, doneAction: 2);
		Silent.ar;
	}.play;

	4.2.wait;  // Wait for recording to finish

	"✓ Recording finished!".postln;

	// Check buffer level
	~testBuffer.loadToFloatArray(action: { |array|
		var peak = array.abs.maxItem;
		"Buffer peak level: %".format(peak.round(0.001)).postln;
		if(peak < 0.001, {
			"❌ Buffer is SILENT! Check input meters and MOTU routing.".postln;
		}, {
			"✓ Buffer has audio! Ready for playback.".postln;
		});
	});
};
)

// ====================================
// STEP 5: Play Back Recording
// ====================================
(
if(~playSynth.notNil, { ~playSynth.free; });

~playSynth = {
	var sig = PlayBuf.ar(1, ~testBuffer, loop: 1);
	sig ! 2;  // Stereo
}.play;

"✓ Playing back your recording in loop".postln;
"  → You should HEAR yourself!".postln;
"  (Run ~playSynth.free; to stop)".postln;
)

// Stop playback
~playSynth.free;

// ====================================
// STEP 6: Test Granular Synthesis
// ====================================
(
if(~grainSynth.notNil, { ~grainSynth.free; });

~grainSynth = {
	var sig = GrainBuf.ar(
		numChannels: 2,
		trigger: Impulse.ar(40),  // 40 grains/sec
		dur: 0.1,  // 100ms grains
		sndbuf: ~testBuffer,
		rate: 1,
		pos: LFNoise1.kr(0.5).range(0, 1),  // Random position
		pan: 0
	);
	sig * 0.5;
}.play;

"✓ Granular synthesis running!".postln;
"  → You should hear GRANULAR version of your recording".postln;
"  (Run ~grainSynth.free; to stop)".postln;
)

// Stop granular
~grainSynth.free;

// ====================================
// STEP 7: Test "Load Test Sound"
// ====================================
(
"====================================".postln;
"STEP 7: Testing sine wave (like 'Load Test Sound')".postln;
"====================================".postln;

// Stop other synths
if(~monitorSynth.notNil, { ~monitorSynth.free; });
if(~playSynth.notNil, { ~playSynth.free; });
if(~grainSynth.notNil, { ~grainSynth.free; });

// Create test buffer with sine wave
~sineBuffer = Buffer.alloc(s, s.sampleRate * 4, 1);

fork {
	0.2.wait;

	// Fill buffer with sine wave
	~sineBuffer.sine1([1], normalize: true, asWavetable: false);

	0.2.wait;

	// Play granular version
	~testGrainSynth = {
		var sig = GrainBuf.ar(
			numChannels: 2,
			trigger: Impulse.ar(20),
			dur: 0.1,
			sndbuf: ~sineBuffer,
			rate: 1,
			pos: 0.5,
			pan: 0
		);
		sig * 0.3;
	}.play;

	"✓ Playing granular sine wave".postln;
	"  → You should hear a BUZZING sound (granulated sine)".postln;
	"  → This is what 'Load Test Sound' should do!".postln;
	"  (Run ~testGrainSynth.free; to stop)".postln;
};
)

// Stop test
~testGrainSynth.free;

// ====================================
// CLEANUP ALL
// ====================================
(
"====================================".postln;
"CLEANUP: Stopping all test synths...".postln;
"====================================".postln;

if(~monitorSynth.notNil, { ~monitorSynth.free; });
if(~recSynth.notNil, { ~recSynth.free; });
if(~playSynth.notNil, { ~playSynth.free; });
if(~grainSynth.notNil, { ~grainSynth.free; });
if(~testGrainSynth.notNil, { ~testGrainSynth.free; });
if(~testBuffer.notNil, { ~testBuffer.free; });
if(~sineBuffer.notNil, { ~sineBuffer.free; });

"✓ Cleanup complete".postln;
)

/*
====================================
SUMMARY
====================================

If all steps worked:
  ✓ Step 1: Server configured correctly
  ✓ Step 2: Meters show input 3 signal
  ✓ Step 3: You heard yourself (direct monitoring)
  ✓ Step 4: Recording captured audio to buffer
  ✓ Step 5: Playback worked
  ✓ Step 6: Granular synthesis worked
  ✓ Step 7: Test sine wave worked (like "Load Test Sound")

→ Audio system is WORKING!

If any step failed:
  - STEP 2 no meters: Check MOTU connected and selected
  - STEP 3 no sound: Check speaker volume / MOTU output routing
  - STEP 4 silent buffer: Input 3 not reaching SC (check meters!)
  - STEP 7 no sound: GrainBuf or buffer problem

Next: Run main.scd and test "Load Test Sound" button
*/

(
"Recording 4 seconds from input 3...".postln;
"→ MAKE NOISE NOW!".postln;
// Stop any running synths
if(~monitorSynth.notNil, { ~monitorSynth.free; });

// Create buffer
~testBuffer = Buffer.alloc(s, s.sampleRate * 4, 1);

fork {
	0.2.wait;

	// Record
	~recSynth = {
		var input = SoundIn.ar(2);  // Input 3 (0-indexed)
		RecordBuf.ar(input, ~testBuffer, loop: 0, doneAction: 2);
		Silent.ar;
	}.play;

	4.2.wait;

	"✓ Recording finished!".postln;

	// Check buffer
	~testBuffer.loadToFloatArray(action: { |array|
		var peak = array.abs.maxItem;
		"Buffer peak level: %".format(peak.round(0.001)).postln;
		if(peak < 0.001, {
			"❌ BUFFER IS SILENT!".postln;
		}, {
			"✓ BUFFER HAS AUDIO! Peak: %".format(peak).postln;
		});
	});
};
)










(
~playSynth = {
	var sig = PlayBuf.ar(1, ~testBuffer, loop: 1);
	sig ! 2;
}.play;

"✓ Playing back - you should hear your recording!".postln;
)



(
if(~grainSynth.notNil, { ~grainSynth.free; });

~grainSynth = {
	GrainBuf.ar(
		numChannels: 2,
		trigger: Impulse.ar(40),
		dur: 0.1,
		sndbuf: ~testBuffer,
		rate: 1,
		pos: LFNoise1.kr(0.5).range(0, 1),
		pan: 0
	) * 0.5;
}.play;

"✓ Granular synthesis - you should hear granulated version!".postln;
)













(
// Stop other tests
if(~playSynth.notNil, { ~playSynth.free; });
if(~grainSynth.notNil, { ~grainSynth.free; });

"Creating sine wave buffer...".postln;

~sineBuffer = Buffer.alloc(s, s.sampleRate * 4, 1);

fork {
	0.2.wait;
	~sineBuffer.sine1([1], normalize: true, asWavetable: false);
	0.2.wait;

	~testGrainSynth = {
		GrainBuf.ar(
			numChannels: 2,
			trigger: Impulse.ar(20),
			dur: 0.1,
			sndbuf: ~sineBuffer,
			rate: 1,
			pos: 0.5,
			pan: 0
		) * 0.3;
	}.play;

	"✓ Playing granular sine - you should hear buzzing!".postln;
};
)

// Check if sine buffer exists and has data
(
if(~sineBuffer.notNil, {
	"Buffer exists".postln;
	"Num frames: %".format(~sineBuffer.numFrames).postln;
	"Num channels: %".format(~sineBuffer.numChannels).postln;

	// Check if it has data
	~sineBuffer.loadToFloatArray(action: { |array|
		var peak = array.abs.maxItem;
		"Peak level: %".format(peak).postln;
		if(peak > 0, {
			"✓ Buffer has sine wave data!".postln;
		}, {
			"❌ Buffer is empty!".postln;
		});
	});
}, {
	"❌ Buffer doesn't exist!".postln;
});
)

// Stop all test synths first
(
if(~testGrainSynth.notNil, { ~testGrainSynth.free; });
if(~grainSynth.notNil, { ~grainSynth.free; });
if(~playSynth.notNil, { ~playSynth.free; });
)


(
~simpleSine = { SinOsc.ar(440) ! 2 * 0.3 }.play;
"Playing 440Hz tone - can you hear it?".postln;
)


