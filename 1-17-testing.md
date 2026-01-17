# Document Title

# BEARULATOR: PHASE 4 REMEDIATION PLAN & SMOKE TESTS
**Target System:** SuperCollider 3.13+ (M4 Mac Mini)
**Date:** 2026-01-17

## 1. CRITICAL FIXES (The "Big Three")

### [ ] Fix 1: The "Ghost Engine" (CPU Leak)
[cite_start]**Issue:** `createTrack` [cite: 186] instantiates all three engines (Grain, Spectral, Direct) immediately. While they start with amplitude 0, they are technically "running" on the server, consuming CPU even when muted.
**Solution:** Implement "Smart Sleep" in `track-manager.scd`. When mixing between engines, we must explicitly `.run(false)` the unused engines.

[cite_start]**ACTION:** Update `setParam` in `core/track-manager.scd` (around line 200 [cite: 200]):

```supercollider
// FIND THIS SECTION inside setParam:
if(param == \engineMix, {
    var granAmp, directAmp, baseAmp;  // All vars at top

    case
        { value <= 0.01 } {  // Pure GRANULAR (0.0)
            granAmp = 1.0;
            directAmp = 0.0;
            // NEW: Sleep Direct Engine to save CPU
            if(track.directPlaybackSynth.notNil) { track.directPlaybackSynth.run(false) };
            if(track.grainSynth.notNil) { track.grainSynth.run(true) };
        }
        { value >= 0.99 } {  // Pure DIRECT (1.0)
            granAmp = 0.0;
            directAmp = 1.0;
            // NEW: Sleep Grain Engine to save CPU
            if(track.grainSynth.notNil) { track.grainSynth.run(false) };
            if(track.directPlaybackSynth.notNil) { track.directPlaybackSynth.run(true) };
        }
        { true } {  // MIX MODE (0.01-0.99)
            // Equal-power crossfade law
            granAmp = (1 - value).sqrt;
            directAmp = value.sqrt;
            // NEW: Wake up BOTH engines
            if(track.grainSynth.notNil) { track.grainSynth.run(true) };
            if(track.directPlaybackSynth.notNil) { track.directPlaybackSynth.run(true) };
        };

    // Apply amplitude scaling... (rest of code remains the same)
    baseAmp = track.params[\amp] ? 0.5;
    track.grainSynth.set(\amp, baseAmp * granAmp);
    track.directPlaybackSynth.set(\amp, baseAmp * directAmp);

    ^this;
});
[ ] Fix 2: The "Reset Glitch" (Audio Tail)

Issue: resetParams  only resets the knobs. It does not flush the delay lines or reverb buffers in effects-space.scd. If a delay feedback loop is active, hitting "Clear Track" leaves a ghost sound spinning forever. Solution: Explicitly zero out feedback and freeze parameters during the reset.



ACTION: Update resetParams in core/track-manager.scd (around line 257 ):

Supercollider

// REPLACE the "1. HARD RESET AUDIO" section with this:
if(track.grainSynth.notNil) {
    track.grainSynth.set(
        \pitch, 0, \pitchShift, 0,
        \timeStretch, 1.0, \scanSpeed, 0,
        // KILL SWITCHES (The Fix):
        \feedback, 0.0,      // Kill internal feedback
        \delayFeedback, 0.0, // Kill delay line
        \reverbFreeze, 0,    // Unfreeze reverb
        \shimmerFeedback, 0.0, // Kill shimmer
        \posJitter, 0.1, \pitchJitter, 0.0,
        \grainSize, 0.1
    );
};
[ ] Fix 3: The spectralAmp Mismatch

Issue: The spectral engine  expects amp but the GUI sends spectralAmp. The remapping logic in track-manager.scd maps spectralAmp -> amp for the spectral synth, but relies on a list of spectralParams  that must be perfectly maintained. Solution: Add a safety catch to ensure spectralAmp is always treated correctly.



ACTION: Verify line 202 in track-manager.scd:

Supercollider

if(param == \spectralAmp, { synthParam = \amp }); // Ensure this line exists and is correct!
2. SMOKE TESTS (Run these in SC IDE)
[ ] Test 1: "Smart Sleep" CPU Check
Does the CPU drop when we switch engines?

Supercollider

(
fork {
    "--- STARTING CPU TEST ---".postln;
    ~trackManager.createTrack(0);
    0.5.wait;
    
    // 1. Turn on Hybrid Mode (Both engines running)
    "Step 1: Hybrid Mode (High CPU expected)".postln;
    ~trackManager.setParam(0, \engineMix, 0.5);
    1.wait;
    ("CPU: " ++ s.avgCPU).postln;

    // 2. Switch to Pure Granular (Direct should sleep)
    "Step 2: Pure Granular (CPU should drop)".postln;
    ~trackManager.setParam(0, \engineMix, 0.0);
    1.wait;
    ("CPU: " ++ s.avgCPU).postln;
    
    // 3. Switch to Pure Direct (Granular should sleep)
    "Step 3: Pure Direct (CPU should drop)".postln;
    ~trackManager.setParam(0, \engineMix, 1.0);
    1.wait;
    ("CPU: " ++ s.avgCPU).postln;
    "--- TEST COMPLETE ---".postln;
}
)
[ ] Test 2: The "Panic" Reset
Does the reset actually kill the audio tail?

Supercollider

(
fork {
    "--- STARTING RESET TEST ---".postln;
    // 1. Create a delay loop
    ~trackManager.setParam(0, \spaceOn, 1);
    ~trackManager.setParam(0, \delayFeedback, 0.95);
    ~trackManager.setParam(0, \delayMix, 1.0);
    "DELAY ACTIVE: Make some noise then wait...".postln;
    3.wait; 
    
    // 2. Trigger Reset
    "--- TRIGGERING RESET ---".postln;
    ~trackManager.resetParams(0);
    
    // 3. Check
    "If silence is immediate, PASS. If delay continues, FAIL.".postln;
}
)

---

### **IV. Daydreaming: Future Features**
*Concepts for Phase 5 and beyond.*

1.  **"Mosaic" Mode (Cross-Modulation Matrix)**
    * **The Dream:** Your tracks talk to each other. Track 1's kick drum automatically "ducks" the volume of Track 2's pads, or Track 3's LFO modulates Track 4's Grain Size.
    * **The Tech:** We patch the `Envelope Follower` in `modulator.scd` [cite: 8] to listen to neighbor tracks instead of just `audioIn`.
    * **Vibe:** Creates a cohesive, "living" ecosystem rather than 4 separate stems.

2.  **The "Disintegrate" Macro Knob**
    * **The Dream:** One knob to rule them all. A global "entropy" control.
    * **The Tech:** A single GUI fader that maps to 5 parameters simultaneously: increases `posJitter`, decreases `bitDepth`, increases `reverbMix`, and slows down `scanSpeed`.
    * **Vibe:** Perfect for live performance transitions where you need to destroy the universe with one hand while holding a beer with the other.

3.  **"Wow & Flutter" Tape Degradation**
    * **The Dream:** Since we have the `direct-playback.scd` engine[cite: 277], we can make it sound like a broken cassette deck.
    * **The Tech:** Add a slow, random LFO to the `rate` parameter in the Direct synth.
    * **Vibe:** Adds that Boards of Canada / William Basinski nostalgia glue to the clean digital samples.

4.  **Spectral Freeze "Photobooth"**
    * **The Dream:** A button that captures the current spectral frame and "prints" it as a new sample.
    * **The Tech:** Use `RecordBuf` to capture the output of the Warp1 engine  into a new buffer, then instantly load that buffer into a neighbor track.
    * **Vibe:** Instant texture generation. You find a beautiful spectral smear, hit "Print," and now you can play it rhythmically on another track.

<!-- Local Variables: -->
<!-- gptel-model: claude-haiku-4-5-20251001 -->
<!-- gptel--backend-name: "Claude-Haiku-4.5" -->
<!-- gptel-max-tokens: 6000 -->
<!-- gptel--bounds: nil -->
<!-- End: -->
