// TEST LOOP PLAYHEAD FIX
// Reload both grain and spectral engines with loop-constrained playheads

"Testing loop playhead constraint fix...".postln;

// 1. Reload both engines with fixes
"/Users/forrestmuelrath/Documents/supercollider/granular/core/grain-engine.scd".load;
"/Users/forrestmuelrath/Documents/supercollider/granular/core/spectral-engine.scd".load;

// 2. Recreate both synths with proper loop constraint
4.do({ |i|
    var track = ~trackManager.getTrack(i);
    if(track.audioBus.notNil and: { track.recorder.buffer.notNil }, {
        ("Recreating synths for track " ++ i ++ " with loop-constrained playheads").postln;
        
        // Recreate grain synth
        if(track.grainSynth.notNil, { track.grainSynth.free });
        track.grainSynth = Synth(\bearulatorGrainEngine, [
            \bufnum, track.recorder.buffer.bufnum,
            \grainMode, 0,
            \grainSize, 0.1,
            \overlap, 64,
            \loopStart, 0.2,  // Test with 20%-80% loop
            \loopEnd, 0.8,
            \position, 0.5,
            \out, track.audioBus.index
        ], track.instrumentGroup, [\addToHead]);
        
        // Recreate spectral synth
        if(track.spectralSynth.notNil, { track.spectralSynth.free });
        track.spectralSynth = Synth(\bearulatorSpectralEngine, [
            \bufnum, track.recorder.buffer.bufnum,
            \loopStart, 0.2,  // Same loop region
            \loopEnd, 0.8,
            \position, 0.5,
            \out, track.audioBus.index
        ], track.instrumentGroup, [\addToHead]);
    });
});

// 3. Open viewfinder to test visual feedback
{
    ~viewfinder.createWindow(0);  // Track 1
}.defer;

"✅ Both engines recreated with loop-constrained playheads!".postln;
"🧪 Open viewfinder and:".postln;
"   1. Drag to select loop region (e.g., 20%-80%)".postln;
"   2. Both green (grain) and yellow (spectral) playheads should stay within selection".postln;
"   3. Playheads should loop back at red boundary".postln;
"   4. Changing loop region should immediately constrain both playheads".postln;