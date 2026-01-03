/*
SPECTRAL ENGINE GUI INTEGRATION TEST
Run this AFTER reloading main.scd to verify spectral controls work
*/

(
var track = ~trackManager.getTrack(0);

"=== SPECTRAL ENGINE GUI TEST ===".postln;
"".postln;

// Step 1: Verify spectral synth exists
if(track.spectralSynth.isNil, {
    "✗ ERROR: Spectral synth is NIL!".postln;
    "   Press PLAY button in Track 1 tab first.".postln;
    "".postln;
}, {
    "✓ Spectral synth exists (Node ID: %)".format(track.spectralSynth.nodeID).postln;
    "".postln;

    // Step 2: Test each spectral parameter
    "Testing parameter routing...".postln;
    "".postln;

    // Test 1: Spectral Mix
    "1. Testing Spectral Mix...".postln;
    ~trackManager.setParam(0, \spectralMix, 0.7);
    0.1.wait;
    "   Set to 0.7 → Stored: %".format(track.params[\spectralMix]).postln;
    "   Move the 'Spectral Mix' slider - you should hear spectral layer.".postln;
    "".postln;

    // Test 2: Window Size
    "2. Testing Window Size...".postln;
    ~trackManager.setParam(0, \spectralWindowSize, 0.5);
    0.1.wait;
    "   Set to 0.5 → Stored: %".format(track.params[\spectralWindowSize]).postln;
    "   Move slider to 1.0 for maximum spectral smearing.".postln;
    "".postln;

    // Test 3: Freeze
    "3. Testing Freeze...".postln;
    ~trackManager.setParam(0, \spectralFreeze, 1);
    1.0.wait;
    "   Freeze ON - spectral should hold current position.".postln;
    ~trackManager.setParam(0, \spectralFreeze, 0);
    "   Freeze OFF - spectral should resume playback.".postln;
    "".postln;

    // Test 4: Pitch Shift
    "4. Testing Pitch Shift...".postln;
    ~trackManager.setParam(0, \spectralPitch, 12);
    0.5.wait;
    "   Pitch +12 semitones (1 octave up) - should hear higher pitch.".postln;
    ~trackManager.setParam(0, \spectralPitch, 0);
    "   Pitch reset to 0.".postln;
    "".postln;

    "=== MANUAL GUI TEST ===".postln;
    "Now test these controls manually in the GUI:".postln;
    "1. Spectral Mix slider (0-1)".postln;
    "2. Window Size slider (0.05-1.0)".postln;
    "3. Overlaps slider (1-8)".postln;
    "4. Pitch slider (-24 to +24)".postln;
    "5. Smear slider (0-1)".postln;
    "6. Rate slider (0-2)".postln;
    "7. Freeze button (toggle ON/OFF)".postln;
    "".postln;
    "Each slider should affect the sound in real-time.".postln;
});

"".postln;
"=== END TEST ===".postln;
)


// Quick test: Set spectral mix to 100% wet
(
~trackManager.setParam(0, \spectralMix, 1.0);
"Spectral mix at 100% - should hear pure spectral output".postln;
)

// Reset to 50/50 blend
(
~trackManager.setParam(0, \spectralMix, 0.5);
"Spectral mix at 50% - balanced grain/spectral blend".postln;
)
