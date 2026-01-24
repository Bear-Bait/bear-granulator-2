// Stop all existing spectral synths
4.do({ |i|
    var track = ~trackManager.getTrack(i);
    if(track.spectralSynth.notNil, {
        track.spectralSynth.free;
        track.spectralSynth = nil;
    });
});

// Reload fixed spectral engine SynthDef (using absolute path)
"/Users/forrestmuelrath/Documents/supercollider/granular/core/spectral-engine.scd".load;

// Recreate spectral synths with new loop boundary support
4.do({ |i|
    var track = ~trackManager.getTrack(i);
    if(track.audioBus.notNil, {
        track.spectralSynth = Synth(\bearulatorSpectralEngine, [
            \bufnum, track.recorder.buffer.bufnum,
            \spectralMix, 0.0,
            \position, 0.5,
            \loopStart, 0.0,  // New parameters!
            \loopEnd, 1.0,    // New parameters!
            \rate, 1.0,
            \windowSize, 0.2,
            \overlaps, 4,
            \pitch, 0,
            \interp, 4,
            \freeze, 0,
            \smear, 0,
            \amp, 0.5,
            \pan, 0,
            \out, track.audioBus.index
        ], track.instrumentGroup, [\addToHead]);
    });
});

"Spectral engine recreated with loop boundary support!".postln;