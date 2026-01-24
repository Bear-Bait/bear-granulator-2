// Stop all existing spectral synths (with safety checks)
4.do({ |i|
    var track;
    ("Checking track " ++ i).postln;
    
    track = ~trackManager.getTrack(i);
    if(track.isNil, {
        ("Track " ++ i ++ " is nil").postln;
        ^nil;  // Skip this track
    });
    
    if(track.spectralSynth.notNil, {
        ("Freeing spectral synth for track " ++ i).postln;
        track.spectralSynth.free;
        track.spectralSynth = nil;
    });
});

// Reload fixed spectral engine SynthDef
"/Users/forrestmuelrath/Documents/supercollider/granular/core/spectral-engine.scd".load;

// Wait a moment for SynthDef to compile
0.1.wait;

// Recreate spectral synths with new loop boundary support (with safety checks)
4.do({ |i|
    var track;
    
    track = ~trackManager.getTrack(i);
    if(track.isNil, {
        ("Track " ++ i ++ " is nil - skipping").postln;
        ^nil;
    });
    
    if(track.audioBus.isNil, {
        ("Track " ++ i ++ " has no audioBus - skipping").postln;
        ^nil;
    });
    
    if(track.recorder.isNil or: { track.recorder.buffer.isNil }, {
        ("Track " ++ i ++ " has no buffer - skipping").postln;
        ^nil;
    });
    
    ("Creating spectral synth for track " ++ i).postln;
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

"Spectral engine recreated with loop boundary support!".postln;