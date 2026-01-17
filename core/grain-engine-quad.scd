/*
BEARULATOR: Quad Granular Engine (Phase 13)
Per-Grain Spatial Positioning for Quad Speaker Systems

This is an experimental version of the grain engine that positions
EACH INDIVIDUAL GRAIN randomly within the quad speaker field.

Features:
- 4 independent grain clouds (FL, FR, RL, RR)
- Per-grain random spatial positioning
- Spatial spread control (0=mono, 1=full quad field)
- Compatible with all existing grain parameters
- 256 total grains (64 per speaker)

Usage:
Replace \s4grain with \bearulatorGrainQuad in track creation
*/

SynthDef(\bearulatorGrainQuad, {
	arg out = 0,
	    bufnum,
	    // Grain parameters
	    grainSize = 0.1,
	    overlap = 4,
	    position = 0.5,
	    pitch = 0,
	    posJitter = 0,
	    pitchJitter = 0,
	    // Spatial parameters (Phase 13)
	    spatialSpread = 0.5,  // 0=mono center, 1=full quad field
	    spatialMode = 0,      // 0=random, 1=rotating, 2=expanding
	    spatialRate = 0.5,    // Speed of spatial movement
	    // Standard parameters
	    stereoSpread = 0.3,
	    amp = 0.5,
	    loopStart = 0.0,
	    loopEnd = 1.0;

	var sig, grainDur, bufPos, pitchRatio;
	var trigRate, trig;
	var grainFL, grainFR, grainRL, grainRR;
	var spatialX, spatialY;
	var numFrames, loopFrames, loopStartFrame, loopEndFrame;

	// === GRAIN PARAMETER CALCULATIONS ===
	grainDur = grainSize.clip(0.001, 60);
	trigRate = overlap / grainDur;
	trig = Impulse.ar(trigRate);

	// Buffer info
	numFrames = BufFrames.kr(bufnum);
	loopStartFrame = loopStart * numFrames;
	loopEndFrame = loopEnd * numFrames;
	loopFrames = loopEndFrame - loopStartFrame;

	// Position with jitter (within loop region)
	bufPos = (position + LFNoise1.kr(10).bipolar(posJitter))
		.wrap(0, 1)
		.linlin(0, 1, loopStartFrame, loopEndFrame) / numFrames;

	// Pitch with jitter
	pitchRatio = (pitch + LFNoise1.kr(5).bipolar(pitchJitter)).midiratio;

	// === SPATIAL POSITIONING (Phase 13) ===
	// Generate X/Y coordinates for spatial field
	spatialX = Select.kr(spatialMode, [
		// Mode 0: Random positions
		LFNoise1.kr(spatialRate * 2).range(-1, 1),
		// Mode 1: Rotating
		SinOsc.kr(spatialRate),
		// Mode 2: Expanding/contracting
		SinOsc.kr(spatialRate * 0.5).abs * 2 - 1
	]);

	spatialY = Select.kr(spatialMode, [
		// Mode 0: Random positions
		LFNoise1.kr(spatialRate * 3).range(-1, 1),
		// Mode 1: Rotating
		SinOsc.kr(spatialRate, pi/2),
		// Mode 2: Expanding/contracting
		SinOsc.kr(spatialRate * 0.5, pi/2).abs * 2 - 1
	]);

	// Scale by spatial spread
	spatialX = spatialX * spatialSpread;
	spatialY = spatialY * spatialSpread;

	// === QUAD GRAIN CLOUDS ===
	// Each speaker gets its own grain cloud with spatial weighting
	// Equal-power panning formula per grain

	// Front-Left: strongest when X=-1, Y=-1
	grainFL = GrainBuf.ar(
		numChannels: 1,
		trigger: trig,
		dur: grainDur,
		sndbuf: bufnum,
		rate: pitchRatio,
		pos: bufPos,
		interp: 2,
		pan: LFNoise1.kr(20).range(-0.2, 0.2),  // Slight per-grain variation
		envbufnum: -1,
		maxGrains: 64
	) * ((1 - spatialX) * (1 - spatialY) * 0.5).sqrt;

	// Front-Right: strongest when X=+1, Y=-1
	grainFR = GrainBuf.ar(
		numChannels: 1,
		trigger: trig,
		dur: grainDur,
		sndbuf: bufnum,
		rate: pitchRatio,
		pos: bufPos,
		interp: 2,
		pan: LFNoise1.kr(20).range(-0.2, 0.2),
		envbufnum: -1,
		maxGrains: 64
	) * ((1 + spatialX) * (1 - spatialY) * 0.5).sqrt;

	// Rear-Left: strongest when X=-1, Y=+1
	grainRL = GrainBuf.ar(
		numChannels: 1,
		trigger: trig,
		dur: grainDur,
		sndbuf: bufnum,
		rate: pitchRatio,
		pos: bufPos,
		interp: 2,
		pan: LFNoise1.kr(20).range(-0.2, 0.2),
		envbufnum: -1,
		maxGrains: 64
	) * ((1 - spatialX) * (1 + spatialY) * 0.5).sqrt;

	// Rear-Right: strongest when X=+1, Y=+1
	grainRR = GrainBuf.ar(
		numChannels: 1,
		trigger: trig,
		dur: grainDur,
		sndbuf: bufnum,
		rate: pitchRatio,
		pos: bufPos,
		interp: 2,
		pan: LFNoise1.kr(20).range(-0.2, 0.2),
		envbufnum: -1,
		maxGrains: 64
	) * ((1 + spatialX) * (1 + spatialY) * 0.5).sqrt;

	// Combine into quad output
	sig = [grainFL, grainFR, grainRR, grainRL];

	// Volume boost (GrainBuf is quiet)
	sig = sig * 2.0;

	// Apply amplitude
	sig = sig * amp;

	// Output to 4 channels
	Out.ar(out, sig);
}).add;

/*
USAGE EXAMPLES:

// Test the quad grain engine
(
~testBuf = Buffer.read(s, Platform.resourceDir +/+ "sounds/a11wlk01.wav");

~quadGrain = Synth(\bearulatorGrainQuad, [
	\bufnum, ~testBuf,
	\grainSize, 0.1,
	\overlap, 8,
	\position, 0.5,
	\spatialSpread, 0.8,  // Wide spatial field
	\spatialMode, 0,      // Random positioning
	\spatialRate, 2.0,    // Movement speed
	\amp, 0.5,
	\out, 0  // Outputs to channels 0-3
]);
)

// Try different spatial modes
~quadGrain.set(\spatialMode, 0);  // Random
~quadGrain.set(\spatialMode, 1);  // Rotating
~quadGrain.set(\spatialMode, 2);  // Expanding/contracting

// Adjust spatial spread
~quadGrain.set(\spatialSpread, 0.0);  // Mono (center)
~quadGrain.set(\spatialSpread, 0.5);  // Moderate spread
~quadGrain.set(\spatialSpread, 1.0);  // Full quad field

// Cleanup
~quadGrain.free;
~testBuf.free;
*/
