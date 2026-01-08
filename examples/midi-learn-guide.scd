/*
═══════════════════════════════════════════════════════════════════
MIDI LEARN FOR 64-STEP SEQUENCER
═══════════════════════════════════════════════════════════════════

v2.1 Feature: Capture MIDI sequences directly into posSeq/pitchSeq arrays.

Instead of manually programming 64-step arrays, play a melody on your
MIDI controller and the Bearulator captures it automatically.

Perfect for KeyStep Pro, Digitone, or any MIDI keyboard.

═══════════════════════════════════════════════════════════════════
*/

// PREREQUISITE: MIDI must be initialized
// This happens automatically when running main.scd
// If MIDI not initialized: ~midiMapping.init(~trackManager);

// ═══════════════════════════════════════════════════════════════
// EXAMPLE 1: CAPTURE PITCH SEQUENCE
// ═══════════════════════════════════════════════════════════════
(
// Enable learn mode for Track 1, pitch sequence
~midiMapping.enableLearn(trackNum: 0, type: \pitch);

// Now play up to 64 notes on your MIDI controller
// They will be captured as semitone offsets from middle C
// Progress indicators every 16 notes
// Auto-finishes at 64 notes or call finishLearn manually
)

// If you want to stop before 64 notes:
~midiMapping.finishLearn;

// If you want to cancel:
~midiMapping.disableLearn;

// ═══════════════════════════════════════════════════════════════
// EXAMPLE 2: CAPTURE POSITION SEQUENCE
// ═══════════════════════════════════════════════════════════════
(
// Enable learn mode for Track 2, position sequence
~midiMapping.enableLearn(trackNum: 1, type: \position);

// Play notes on your MIDI controller
// Note numbers 0-127 will be mapped to position offsets -0.5 to +0.5
)

// ═══════════════════════════════════════════════════════════════
// EXAMPLE 3: DIFFERENT TRACKS
// ═══════════════════════════════════════════════════════════════

// Track 1 - Pitch sequence
~midiMapping.enableLearn(0, \pitch);
// Play melody...
~midiMapping.finishLearn;

// Track 2 - Different pitch sequence
~midiMapping.enableLearn(1, \pitch);
// Play different melody...
~midiMapping.finishLearn;

// Track 3 - Position sequence
~midiMapping.enableLearn(2, \position);
// Play position pattern...
~midiMapping.finishLearn;

// ═══════════════════════════════════════════════════════════════
// WORKFLOW EXAMPLE: BUILDING A COMPLEX TEXTURE
// ═══════════════════════════════════════════════════════════════
(
fork {
	// Load sample on Track 1
	~trackManager.loadSample(0, "/path/to/sample.wav");
	1.wait;

	// Start playback
	~trackManager.setParam(0, \amp, 0.6);
	1.wait;

	// Capture a pentatonic melody
	"═══════════════════════════════════════════".postln;
	"Play a pentatonic melody (64 notes)...".postln;
	~midiMapping.enableLearn(0, \pitch);
	// User plays C-D-E-G-A pattern on keyboard...

	// After capture completes:
	10.wait;  // Wait for user to finish

	"Sequence captured! Adjusting parameters...".postln;

	// Fine-tune the sequence intensity
	~trackManager.setParam(0, \pitchJitter, 0.8);  // 80% intensity
	~trackManager.setParam(0, \grainSize, 0.05);   // Small grains
	~trackManager.setParam(0, \overlap, 16);       // Dense texture

	"Complex texture ready!".postln;
};
)

// ═══════════════════════════════════════════════════════════════
// TIPS & TRICKS
// ═══════════════════════════════════════════════════════════════

// 1. SHORT SEQUENCES (e.g., 8 notes)
//    - Play 8 notes, then call finishLearn
//    - Sequence will repeat to fill 64 steps
(
~midiMapping.enableLearn(0, \pitch);
// Play 8 notes: C-D-E-F-G-A-B-C
// Wait a moment, then:
~midiMapping.finishLearn;
// Result: 8-note pattern repeated 8 times
)

// 2. RHYTHMIC PATTERNS
//    - Use position sequence for rhythmic stutters
//    - High notes = jump forward, low notes = jump back
(
~midiMapping.enableLearn(0, \position);
// Play: Low-Low-Low-High (creates rewind effect)
// Repeat pattern to fill 64 steps
~midiMapping.finishLearn;
)

// 3. COMBINING WITH MANUAL EDITING
//    - Capture sequence, then modify it
(
~midiMapping.enableLearn(0, \pitch);
// Capture melody...
~midiMapping.finishLearn;

// Now manually edit the captured sequence
var seq = ~trackManager.getTrack(0).params[\pitchSeq];
seq[0] = 12;  // Force first note to +1 octave
seq[63] = -12;  // Force last note to -1 octave
~trackManager.setParam(0, \pitchSeq, seq);
)

// 4. LAYERING MULTIPLE TRACKS
//    - Capture different melodies on each track
//    - Create polyrhythmic textures
(
fork {
	// Track 1: Bass line (low notes)
	~midiMapping.enableLearn(0, \pitch);
	// Play low melody...
	5.wait;
	~midiMapping.finishLearn;

	1.wait;

	// Track 2: High melody
	~midiMapping.enableLearn(1, \pitch);
	// Play high melody...
	5.wait;
	~midiMapping.finishLearn;

	"Polyrhythmic texture ready!".postln;
};
)

// 5. TEMPO SYNC WITH KEYSTEP PRO
//    - KeyStep Pro sends MIDI clock
//    - Bearulator tracks tempo automatically
//    - Your sequences will sync with hardware tempo
// (This feature already works via MIDI clock handler)

// ═══════════════════════════════════════════════════════════════
// DISABLE/RESET SEQUENCES
// ═══════════════════════════════════════════════════════════════

// Turn off jitter to disable sequence playback
~trackManager.setParam(0, \pitchJitter, 0);
~trackManager.setParam(0, \posJitter, 0);

// Reset to zeros
~trackManager.setParam(0, \pitchSeq, Array.fill(64, 0));
~trackManager.setParam(0, \posSeq, Array.fill(64, 0));

// ═══════════════════════════════════════════════════════════════
// TECHNICAL DETAILS
// ═══════════════════════════════════════════════════════════════

// PITCH SEQUENCE:
// - MIDI note numbers converted to semitone offsets from C3 (60)
// - C3 (60) → 0, C4 (72) → +12, C2 (48) → -12
// - Stored in pitchSeq array
// - Applied via pitchJitter parameter (0-1 amplitude)

// POSITION SEQUENCE:
// - MIDI note numbers mapped to position offsets
// - MIDI 0 → -0.5, MIDI 127 → +0.5
// - Stored in posSeq array
// - Applied via posJitter parameter (0-1 amplitude)

// LEARN MODE BEHAVIOR:
// - Intercepts MIDI notes (doesn't trigger normal playback)
// - Captures up to 64 notes
// - Auto-finishes at 64 notes
// - Can manually finish early (pattern repeats to fill 64)
// - Progress printed every 16 notes

// ═══════════════════════════════════════════════════════════════
// TROUBLESHOOTING
// ═══════════════════════════════════════════════════════════════

// Problem: MIDI Learn not responding
// Solution: Check MIDI is initialized
~midiMapping.enabled;  // Should return true

// Problem: Notes still trigger playback during learn
// Solution: Make sure learn mode is active
~midiMapping.learnMode;  // Should return true

// Problem: Sequence doesn't play back
// Solution: Enable jitter parameter
~trackManager.setParam(0, \pitchJitter, 1);  // Turn ON

// Problem: Sequence sounds random
// Solution: Check if array was actually captured
~trackManager.getTrack(0).params[\pitchSeq];  // Should show your notes

// ═══════════════════════════════════════════════════════════════
