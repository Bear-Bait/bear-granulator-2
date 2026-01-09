//1. The "Modular" Approach (Signal-Rate Triggering)
//Instead of telling the synth to play a note from the language, you build the rhythm generator inside the SynthDef. This is how modular /synths work and produces the tightest, glitchiest timing.

//How it works: You replace a steady Impulse.ar (which makes a buzz or tone) with a dynamic trigger system.

//The Glitch Factor: Use Dust.ar (random impulses) or mix Impulse.ar with LFNoise0 to randomly change the speed of the grains.

//Key UGens: Impulse.kr, Dust.kr, Stepper.kr, Select.kr.

//Vibe: Unpredictable, organic, fizzing, Geiger-counter textures.

// 1. The Synth (One-shot grain cloud)
SynthDef(\grainHit, { |out=0, buf, pos=0, dur=0.1, pitch=1|
    var env = EnvGen.kr(Env.perc(0.01, dur), doneAction: 2); // Percussive envelope
    var grains = GrainBuf.ar(2, Impulse.ar(50), 0.1, buf, pitch, pos);
    Out.ar(out, grains * env);
}).add;

// 2. The Sequence (Pbind)
Pbind(
    \instrument, \grainHit,
    \dur, 0.25,  // 16th notes
    \pos, Pseq([0.1, 0.2, 0.1, 0.5], inf), // Change sample position per beat
    \pitch, Pseq([0.5, 1, 0.5, 2], inf)    // Pitch shift per beat
).play;