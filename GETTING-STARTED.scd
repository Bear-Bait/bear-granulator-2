/*
═══════════════════════════════════════════════════════════════
  S-4 RIVAL: GETTING STARTED GUIDE
  Complete walkthrough for absolute beginners
═══════════════════════════════════════════════════════════════

HOW TO USE THIS FILE:
1. Select a code block (the stuff inside parentheses)
2. Press Cmd+Enter (Mac) or Ctrl+Enter (Windows/Linux)
3. Read the comments and listen!

TIP: Execute blocks ONE AT A TIME, in order.
     Wait for each step to complete before moving to the next.

Let's get started! 🚀
*/

// ═══════════════════════════════════════════════════════════════
// STEP 1: BOOT THE SERVER
// ═══════════════════════════════════════════════════════════════

// Select this entire block (including the parentheses) and press Cmd+Enter:

(
"".postln;
"════════════════════════════════════════════".postln;
"  STEP 1: Booting SuperCollider Server...".postln;
"════════════════════════════════════════════".postln;
"".postln;
"Please wait for 'Server localhost running' message...".postln;
s.boot;
)

// WAIT! Look at the Post window (bottom panel).
// You should see: "Server 'localhost' running"
// Once you see that, continue to Step 2.


// ═══════════════════════════════════════════════════════════════
// STEP 2: LOAD THE S-4 RIVAL
// ═══════════════════════════════════════════════════════════════

// This loads all the code and opens the GUI window.
// Execute this block:

(
"".postln;
"════════════════════════════════════════════".postln;
"  STEP 2: Loading S-4 RIVAL...".postln;
"════════════════════════════════════════════".postln;
"".postln;
"This will take about 5 seconds...".postln;
"main.scd".loadRelative;
)

// WAIT! You should see:
// 1. A bunch of "✓" messages in the Post window
// 2. A big GUI window should appear
// 3. Final message: "S-4 RIVAL ready!"

// Once you see "ready", continue to Step 3.


// ═══════════════════════════════════════════════════════════════
// STEP 3: LOAD A SOUND FILE
// ═══════════════════════════════════════════════════════════════

// We'll load the Apollo 11 mission audio (included with SuperCollider)
// This is perfect for granular processing!

(
"".postln;
"════════════════════════════════════════════".postln;
"  STEP 3: Loading Apollo 11 audio...".postln;
"════════════════════════════════════════════".postln;
"".postln;

~testBuf = Buffer.read(s, Platform.resourceDir +/+ "sounds/a11wlk01.wav");
~trackManager.getTracks[0].recorder.setBuffer(~testBuf);

"Sample loaded into Track 1!".postln;
"Duration: % seconds".format(~testBuf.duration.round(0.1)).postln;
)

// You should see: "Sample loaded into Track 1!"


// ═══════════════════════════════════════════════════════════════
// STEP 4: YOUR FIRST GRANULAR SOUND
// ═══════════════════════════════════════════════════════════════

// Let's set some parameters and PLAY!

(
"".postln;
"════════════════════════════════════════════".postln;
"  STEP 4: Creating your first granular texture...".postln;
"════════════════════════════════════════════".postln;
"".postln;

// Set grain parameters
~trackManager.setParam(0, \grainSize, 0.2);    // 200ms grains (smooth)
~trackManager.setParam(0, \overlap, 16);       // 16 overlapping grains
~trackManager.setParam(0, \position, 0.5);     // Middle of the sample
~trackManager.setParam(0, \posJitter, 0.2);    // Some randomness

// Start playing!
~trackManager.getTracks[0].grainSynth.run(true);

"Playing! You should hear granular space transmission...".postln;
"Let it play for 10 seconds, then go to Step 5.".postln;
)

// LISTEN! You should hear a grainy, frozen version of the Apollo audio.
// The GUI should show the waveform and parameters.


// ═══════════════════════════════════════════════════════════════
// STEP 5: ADD SOME SPACE (REVERB)
// ═══════════════════════════════════════════════════════════════

// Let's add reverb to make it more spacious

(
"".postln;
"════════════════════════════════════════════".postln;
"  STEP 5: Adding reverb...".postln;
"════════════════════════════════════════════".postln;
"".postln;

~trackManager.setParam(0, \spaceOn, 1);        // Turn on Space FX
~trackManager.setParam(0, \reverbMix, 0.7);    // 70% reverb
~trackManager.setParam(0, \reverbSize, 0.9);   // Large room

"Reverb added! Notice the difference?".postln;
)

// LISTEN! The sound should now have a huge reverb tail.


// ═══════════════════════════════════════════════════════════════
// STEP 6: SAVE YOUR FIRST PRESET
// ═══════════════════════════════════════════════════════════════

// Let's save these settings as a preset!

(
"".postln;
"════════════════════════════════════════════".postln;
"  STEP 6: Saving your first preset...".postln;
"════════════════════════════════════════════".postln;
"".postln;

~presets.save("my_first_sound");

"✅ Preset saved as 'my_first_sound'!".postln;
"You can reload this anytime with:".postln;
"~presets.load(\"my_first_sound\");".postln;
)


// ═══════════════════════════════════════════════════════════════
// STEP 7: TRY CHANGING PARAMETERS
// ═══════════════════════════════════════════════════════════════

// Now let's experiment! Try these one at a time:

// 7a: Smaller grains (more glitchy)
(
~trackManager.setParam(0, \grainSize, 0.05);  // 50ms grains
"Grains are now shorter and glitchier!".postln;
)

// LISTEN for 5 seconds, then try:

// 7b: Higher pitch
(
~trackManager.setParam(0, \pitch, 12);  // +12 semitones (one octave up)
"Pitch shifted up one octave!".postln;
)

// LISTEN for 5 seconds, then try:

// 7c: Add shimmer (octave-up reverb)
(
~trackManager.setParam(0, \shimmerMix, 0.5);   // 50% shimmer
~trackManager.setParam(0, \shimmerPitch, 12);  // +1 octave
"Shimmer reverb added! Ethereal!".postln;
)

// LISTEN! This should sound very spacey and ethereal.


// ═══════════════════════════════════════════════════════════════
// STEP 8: STOP THE SOUND
// ═══════════════════════════════════════════════════════════════

// When you're done listening, stop playback:

(
~trackManager.getTracks[0].grainSynth.run(false);
"Playback stopped.".postln;
)


// ═══════════════════════════════════════════════════════════════
// STEP 9: LOAD EXAMPLE PRESETS
// ═══════════════════════════════════════════════════════════════

// Let's create 10 example presets to explore!

(
"".postln;
"════════════════════════════════════════════".postln;
"  STEP 9: Creating example presets...".postln;
"════════════════════════════════════════════".postln;
"".postln;
"This will take about 10 seconds...".postln;

"examples/preset-examples.scd".loadRelative;
)

// You should see messages like:
// "✓ Ambient Pad"
// "✓ Shimmer Heaven"
// etc.


// ═══════════════════════════════════════════════════════════════
// STEP 10: TRY THE EXAMPLE PRESETS
// ═══════════════════════════════════════════════════════════════

// Now let's try some of the example presets!

// 10a: List all presets
(
~presets.list;
)

// You should see 10+ presets listed in the Post window.


// 10b: Load "Shimmer Heaven" preset
(
~presets.load("shimmer_heaven");
"Loaded 'shimmer_heaven' preset!".postln;
"Press PLAY to hear it (Step 10c)".postln;
)


// 10c: Play it!
(
~trackManager.getTracks[0].grainSynth.run(true);
"Playing shimmer heaven... huge reverb, 2-octave shimmer!".postln;
)

// LISTEN for 10-15 seconds. This should be VERY spacious and ethereal!


// 10d: Try another preset (Drone Machine)
(
~trackManager.getTracks[0].grainSynth.run(false);  // Stop first
0.5.wait;
~presets.load("drone_machine");
~trackManager.getTracks[0].grainSynth.run(true);
"Playing drone machine... low, sustained, infinite!".postln;
)


// ═══════════════════════════════════════════════════════════════
// STEP 11: EMERGENCY STOP
// ═══════════════════════════════════════════════════════════════

// If things get too loud or weird, use the EMERGENCY STOP:

// Press: Cmd+Period (Mac) or Ctrl+Period (Windows/Linux)
// This kills ALL sound immediately!

// Or execute this:
(
s.freeAll;
"All sounds stopped!".postln;
)


// ═══════════════════════════════════════════════════════════════
// STEP 12: USING THE GUI
// ═══════════════════════════════════════════════════════════════

/*
Now that you've tried code, explore the GUI!

The big window has 5 tabs at the top:
- TRACK 1, TRACK 2, TRACK 3, TRACK 4, MASTER

Click TRACK 1 tab and you'll see:
- PLAY button (starts/stops grain playback)
- LOAD AUDIO FILE button (load your own samples!)
- Sliders for:
  - Grain Size (0.001s to 60s)
  - Overlap (1 to 128 grains)
  - Position (where in the sample to read)
  - Pitch (transpose up/down)
- Buttons:
  - COLOR FX ON (distortion, bit crusher)
  - SPACE FX ON (reverb, delay, shimmer)
  - LOOP VIEW (waveform editor)
  - MOD (modulation routing)

Try moving the sliders while sound is playing!
*/


// ═══════════════════════════════════════════════════════════════
// STEP 13: NEXT STEPS
// ═══════════════════════════════════════════════════════════════

/*
Congratulations! You've learned:
✅ How to boot the server
✅ How to load the S-4 RIVAL
✅ How to load a sample
✅ How to create granular textures
✅ How to add effects
✅ How to save and load presets
✅ How to use example presets
✅ Where the GUI controls are

WHAT TO DO NEXT:

1. Load your own audio files:
   - Click "LOAD AUDIO FILE" in the GUI (Track 1 tab)
   - Navigate to your samples folder
   - Try granulating drums, vocals, field recordings!

2. Read the tutorial:
   - Open: docs/PHASE-13-TUTORIAL.md
   - 20 sound design recipes
   - Audio-rate modulation examples
   - Spatial automation cookbook

3. Explore the quad spatial system:
   - See: examples/quad-spatial-examples.scd
   - Open quad panner: ~quadPanner.createWindow();
   - Position tracks in 3D space!

4. Try modulation:
   - Click "MOD" button in Track 1
   - Route LFOs to parameters
   - Automatic parameter movement!

5. Read the full documentation:
   - README.md (basic workflow)
   - FEATURES.md (complete feature list)
   - PERFORMANCE-GUIDE.md (optimization tips)

HAVE FUN MAKING GRANULAR MUSIC! 🎵✨
*/


// ═══════════════════════════════════════════════════════════════
// QUICK REFERENCE COMMANDS
// ═══════════════════════════════════════════════════════════════

/*
PLAYBACK:
~trackManager.getTracks[0].grainSynth.run(true);   // Play Track 1
~trackManager.getTracks[0].grainSynth.run(false);  // Stop Track 1

PRESETS:
~presets.save("name");                   // Save current state
~presets.load("name");                   // Load preset
~presets.list;                           // Show all presets
~presets.quickSave;                      // Auto-named save

PARAMETERS:
~trackManager.setParam(0, \grainSize, 0.1);     // Set grain size
~trackManager.setParam(0, \overlap, 32);        // Set overlap
~trackManager.setParam(0, \pitch, 7);           // Set pitch
~trackManager.setParam(0, \reverbMix, 0.7);     // Set reverb

EMERGENCY:
Cmd+Period  (Mac) or Ctrl+Period (Windows/Linux)  // Kill all sound
s.freeAll;                                         // Stop all synths

GUI WINDOWS:
~quadPanner.createWindow();                        // Quad spatial panner
~viewfinder.createWindow(0);                       // Waveform editor (Track 1)

MONITORING:
s.meter;     // Audio level meters
s.scope;     // Oscilloscope
s.avgCPU;    // CPU usage
s.plotTree;  // See all running synths
*/


// ═══════════════════════════════════════════════════════════════
// TROUBLESHOOTING
// ═══════════════════════════════════════════════════════════════

/*
PROBLEM: No sound
FIX:
1. Check server is running: s.serverRunning
2. Check volume: s.volume = -10;  (in dB)
3. Press PLAY button in GUI
4. Unmute if muted: s.unmute;

PROBLEM: Audio crackling
FIX:
1. Increase buffer size:
   s.quit;
   s.options.blockSize = 512;
   s.boot;
   "main.scd".loadRelative;

PROBLEM: GUI looks weird
FIX:
- Install "DejaVu Sans Mono" font
- Or edit gui/four-track-view.scd to use different font

PROBLEM: Error messages
FIX:
1. Read the error in Post window
2. Try restarting:
   s.quit;
   s.boot;
   "main.scd".loadRelative;

PROBLEM: Can't find preset
FIX:
~presets.list;  // Shows all available presets
// Check spelling (case-sensitive!)

STILL STUCK?
- Check README.md
- Check docs/TROUBLESHOOTING.md (if it exists)
- Post an issue on GitHub
*/


// ═══════════════════════════════════════════════════════════════
// END OF GETTING STARTED GUIDE
// ═══════════════════════════════════════════════════════════════

"✅ You've reached the end of the Getting Started guide!".postln;
"Happy granular synthesis! 🎉".postln;
