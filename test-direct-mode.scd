/*
Direct Playback Mode Test
Phase 15 - Test script for direct (non-granular) playback

Run this after booting main.scd to test direct mode.
*/

// ============================================
// TEST 1: Switch to DIRECT mode via code
// ============================================

"=== TEST 1: Switch Track 1 to DIRECT mode ===".postln;
~trackManager.setParam(0, \engineMode, 1);  // 0=GRANULAR, 1=DIRECT
0.5.wait;

// Check synth states
"Grain synth running: %".format(~trackManager.getTracks[0].grainSynth.isRunning).postln;
"Direct synth running: %".format(~trackManager.getTracks[0].directPlaybackSynth.isRunning).postln;

// ============================================
// TEST 2: Verify direct playback parameters
// ============================================

"".postln;
"=== TEST 2: Test direct playback controls ===".postln;

// Test playback rate (pitch shift)
~trackManager.setParam(0, \rate, 2.0);  // Double speed = +12 semitones
"✓ Set rate to 2.0 (double speed)".postln;
2.wait;

~trackManager.setParam(0, \rate, 0.5);  // Half speed = -12 semitones
"✓ Set rate to 0.5 (half speed)".postln;
2.wait;

~trackManager.setParam(0, \rate, 1.0);  // Normal speed
"✓ Reset rate to 1.0 (normal)".postln;
1.wait;

// Test time stretch (pitch-preserving speed change)
~trackManager.setParam(0, \timeStretch, 0.5);  // Half speed, same pitch
"✓ Set timeStretch to 0.5 (slow motion, preserves pitch)".postln;
3.wait;

~trackManager.setParam(0, \timeStretch, 2.0);  // Double speed, same pitch
"✓ Set timeStretch to 2.0 (fast forward, preserves pitch)".postln;
2.wait;

~trackManager.setParam(0, \timeStretch, 1.0);  // Normal
"✓ Reset timeStretch to 1.0".postln;
1.wait;

// Test loop boundaries
~trackManager.setParam(0, \loopStart, 0.25);
~trackManager.setParam(0, \loopEnd, 0.75);
"✓ Set loop region to 25%-75%".postln;
3.wait;

~trackManager.setParam(0, \loopStart, 0.0);
~trackManager.setParam(0, \loopEnd, 1.0);
"✓ Reset loop to full buffer".postln;
1.wait;

// ============================================
// TEST 3: Compare GRANULAR vs DIRECT
// ============================================

"".postln;
"=== TEST 3: A/B comparison ===".postln;

"Switching to GRANULAR mode...".postln;
~trackManager.setParam(0, \engineMode, 0);
3.wait;

"Switching to DIRECT mode...".postln;
~trackManager.setParam(0, \engineMode, 1);
3.wait;

"Switching back to GRANULAR mode...".postln;
~trackManager.setParam(0, \engineMode, 0);
2.wait;

// ============================================
// TEST 4: Playhead visualization
// ============================================

"".postln;
"=== TEST 4: Playhead check ===".postln;
"Open viewfinder to see playhead:".postln;
"  ~viewfinder.createWindow(0)".postln;
"".postln;
"Switch to DIRECT mode in viewfinder and watch playhead move!".postln;

// ============================================
// DONE
// ============================================

"".postln;
"=== TESTS COMPLETE ===".postln;
"".postln;
"If you heard audio and playback rate/timestretch worked, DIRECT mode is functional!".postln;
"".postln;
"Manual tests:".postln;
"  1. Open viewfinder: ~viewfinder.createWindow(0)".postln;
"  2. Click ENGINE MODE button to toggle DIRECT/GRANULAR".postln;
"  3. Watch playhead move in DIRECT mode".postln;
"  4. Adjust Rate slider (changes pitch)".postln;
"  5. Adjust Time Stretch slider (preserves pitch)".postln;
"".postln;
