// RELOAD FOR 256 MAX GRAINS

// 1. Stop all grain synths
4.do({ |i|
    var track = ~trackManager.getTrack(i);
    if(track.grainSynth.notNil, {
        ("Stopping grain synth for track " ++ i).postln;
        track.grainSynth.free;
        track.grainSynth = nil;
    });
});

// 2. Reload updated grain engine SynthDef (256 max grains)
"/Users/forrestmuelrath/Documents/supercollider/granular/core/grain-engine.scd".load;

// 3. Recreate grain synths with 256 max grains
4.do({ |i|
    var track = ~trackManager.getTrack(i);
    if(track.audioBus.notNil and: { track.recorder.buffer.notNil }, {
        ("Creating grain synth for track " ++ i ++ " with 256 max grains").postln;
        track.grainSynth = Synth(\bearulatorGrainEngine, [
            \bufnum, track.recorder.buffer.bufnum,
            \grainMode, 0,
            \grainSize, 0.1,
            \overlap, 64,
            \density, 20,
            \useOverlap, 1,
            \prob, 1.0,
            \position, 0.5,
            \scanSpeed, 0,
            \timeStretch, 1.0,
            \pitch, 0,
            \pitchShift, 0,
            \posJitter, 0,
            \pitchJitter, 0,
            \posSeq, Array.fill(64, 0),
            \pitchSeq, Array.fill(64, 0),
            \envType, 1,
            \stereoSpread, 0.5,
            \amp, 0.5,
            \pan, 0,
            \loopStart, 0.0,
            \loopEnd, 1.0,
            \out, track.audioBus.index
        ], track.instrumentGroup, [\addToHead]);
    });
});

"✅ Updated to 256 max grains!".postln;
"🌊 Expect ultra-smooth granular textures!".postln;
"⚠️  CPU usage may increase to ~50% at full density".postln;