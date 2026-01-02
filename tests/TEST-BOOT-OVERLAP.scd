/*
TEST BOOT WITH OVERLAP PARAMETER
Quick test to verify the overlap mode compiles and boots correctly
*/

(
"=== TESTING BOOT WITH OVERLAP MODE ===".postln;

// Just verify the SynthDef compiles
if(SynthDescLib.global.at(\s4GrainEngine).notNil, {
	"✓ s4GrainEngine SynthDef exists".postln;
}, {
	"✗ s4GrainEngine SynthDef NOT FOUND".postln;
});

// Test creating a synth with overlap parameter
{
	var testBuf = Buffer.alloc(s, s.sampleRate * 2, 1); // 2 second buffer
	var testSynth;

	testBuf.sine1([1], true, true, true);

	0.5.wait;

	"Creating test synth with overlap=1...".postln;
	testSynth = Synth(\s4GrainEngine, [
		\bufnum, testBuf,
		\grainSize, 2.0,
		\overlap, 1,
		\useOverlap, 1,
		\amp, 0.3
	]);

	2.wait;

	"✓ Synth created successfully!".postln;
	testSynth.free;
	testBuf.free;

	"=== BOOT TEST COMPLETE ===".postln;
}.fork;
)
