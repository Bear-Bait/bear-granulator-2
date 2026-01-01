/*
AUDIO DIAGNOSTIC - S-4 Rival
============================
Run this FIRST to verify audio routing before using main.scd

This script will:
1. Check server configuration
2. Show input meters for MOTU inputs 1-8
3. Test that you can hear input 3 (or 4)
4. Verify recording to a buffer works
5. Test playback from buffer works

IMPORTANT: Run AFTER doing s.quit; s.boot;
*/

(
"====================================".postln;
"AUDIO DIAGNOSTIC".postln;
"====================================".postln;
"".postln;

// Step 1: Check server config
"STEP 1: Server Configuration".postln;
"  Sample rate: %".format(s.sampleRate).postln;
"  Input channels: %".format(s.options.numInputBusChannels).postln;
"  Output channels: %".format(s.options.numOutputBusChannels).postln;
"  Audio device: %".format(s.options.device ? "default").postln;
"  Memory: % KB".format(s.options.memSize).postln;
"".postln;

if(s.options.numInputBusChannels < 4, {
	"❌ WARNING: Not enough input channels!".postln;
	"   Need at least 4 for input 3/4".postln;
	"   Current: %".format(s.options.numInputBusChannels).postln;
	"   Run: s.options.numInputBusChannels = 8; then s.reboot;".postln;
	"".postln;
});

// Step 2: Launch meters
"STEP 2: Launching meters...".postln;
ServerMeter.new(s);
0.5.wait;
"  ✓ Meters launched (top = inputs, bottom = outputs)".postln;
"  → Play sound into MOTU input 3 - watch for green meter movement!".postln;
"".postln;

// Step 3: Test direct monitoring (input → output)
"STEP 3: Testing direct monitoring...".postln;
"  Click to continue when ready...".postln;
)

// STEP 3: Run this to hear input 3 directly
(
~monitorSynth = {
	var input;
	input = SoundIn.ar(2);  // Input 3 (0-indexed: 0=In1, 1=In2, 2=In3)
	input ! 2;  // Duplicate to stereo
}.play;

"  ✓ Monitoring input 3".postln;
"  → You should HEAR yourself in speakers/headphones now!".postln;
"  → If you hear nothing:".postln;
"     1. Check MOTU is selected as audio device".postln;
"     2. Check input 3 has signal (watch meters!)".postln;
"     3. Check speaker/headphone volume".postln;
"".postln;
"  Run this to STOP monitoring:".postln;
"    ~monitorSynth.free;".postln;
)

// STEP 4: Record to buffer
(
"====================================".postln;
"STEP 4: Testing buffer recording...".postln;

// Create 4-second buffer
~testBuffer = Buffer.alloc(s, s.sampleRate * 4, 1);  // Mono, 4 seconds
0.2.wait;
"  ✓ Buffer allocated: % frames".format(~testBuffer.numFrames).postln;

// Stop monitoring if running
if(~monitorSynth.notNil, { ~monitorSynth.free; });
0.1.wait;

// Create recording synth
~recSynth = {
	var input = SoundIn.ar(2);  // Input 3
	RecordBuf.ar(input, ~testBuffer, loop: 0, doneAction: 2);
	Silent.ar;
}.play;

"  ✓ Recording from input 3 for 4 seconds...".postln;
"  → MAKE NOISE NOW! (speak, clap, sing)".postln;

// Wait for recording to finish
fork {
	4.2.wait;
	"  ✓ Recording finished!".postln;
	"".postln;

	// Check buffer has data
	~testBuffer.loadToFloatArray(action: { |array|
		var peak = array.abs.maxItem;
		"  Buffer peak level: %".format(peak.round(0.001)).postln;
		if(peak < 0.001, {
			"  ❌ WARNING: Buffer is silent! Check:".postln;
			"     1. Is audio reaching input 3? (check meters)".postln;
			"     2. Is MOTU selected as input device?".postln;
		}, {
			"  ✓ Buffer has audio! Peak: %".format(peak.round(0.001)).postln;
		});
		"".postln;
		"  Run STEP 5 to play back recording...".postln;
	});
};
)

// STEP 5: Play back buffer
(
"====================================".postln;
"STEP 5: Testing buffer playback...".postln;

~playSynth = {
	var sig = PlayBuf.ar(1, ~testBuffer, loop: 1);
	sig ! 2;  // Stereo
}.play;

"  ✓ Playing back recording in loop".postln;
"  → You should HEAR your recording now!".postln;
"".postln;
"  Run this to STOP playback:".postln;
"    ~playSynth.free;".postln;
"".postln;
"  If you hear your recording, AUDIO IS WORKING! ✓".postln;
)

// STEP 6: Test granular synthesis
(
"====================================".postln;
"STEP 6: Testing granular synthesis...".postln;

// Stop playback if running
if(~playSynth.notNil, { ~playSynth.free; });
0.1.wait;

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
	sig * 0.5;  // Volume
}.play;

"  ✓ Granular synthesis running".postln;
"  → You should hear granular version of your recording!".postln;
"".postln;
"  Run this to STOP:".postln;
"    ~grainSynth.free;".postln;
)

// CLEANUP
(
"====================================".postln;
"CLEANUP: Stopping all test synths...".postln;

if(~monitorSynth.notNil, { ~monitorSynth.free; });
if(~recSynth.notNil, { ~recSynth.free; });
if(~playSynth.notNil, { ~playSynth.free; });
if(~grainSynth.notNil, { ~grainSynth.free; });
if(~testBuffer.notNil, { ~testBuffer.free; });

"  ✓ Cleanup complete".postln;
"".postln;
"====================================".postln;
"DIAGNOSTIC SUMMARY".postln;
"====================================".postln;
"If all steps worked:".postln;
"  1. ✓ Meters showed input signal".postln;
"  2. ✓ Direct monitoring worked (heard yourself)".postln;
"  3. ✓ Recording to buffer worked".postln;
"  4. ✓ Playback from buffer worked".postln;
"  5. ✓ Granular synthesis worked".postln;
"".postln;
"→ Audio system is WORKING! Safe to use main.scd".postln;
"".postln;
"If any step failed, check:".postln;
"  - MOTU Mk5 is connected via USB".postln;
"  - MOTU is selected in macOS Sound Preferences".postln;
"  - Input 3 has signal (mic/line connected)".postln;
"  - Speaker/headphone volume is up".postln;
"  - SuperCollider preferences → Audio device = MOTU".postln;
"====================================".postln;
)
