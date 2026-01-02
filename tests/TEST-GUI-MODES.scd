/*
PHASE 6 GUI MATERIAL MODE TEST
Manual test procedure for the Material Mode dropdown in the GUI

SETUP:
1. Run main.scd to boot server and open GUI
2. Load an audio file on Track 1 (use Load File button)
3. Set grain parameters for clear audio:
   - Grain Size: ~50ms
   - Density: ~40 grains/sec
   - Position: 0.5 (middle of buffer)
   - Amp: 0.5

TEST PROCEDURE:

Step 1: TAPE Mode (default)
- Locate "Material Mode" dropdown in Track 1 section
- Should show "TAPE (Loop)" selected by default
- Adjust Position slider (0.0 to 1.0)
- Expected: Smooth scanning through buffer, wraps around at edges
- Try loopStart/loopEnd if visible - should respect loop region

Step 2: POLY Mode
- Change dropdown to "POLY (Sample)"
- Check post window for: "Track 1: Mode set to 1 (POLY)"
- Adjust Position slider
- Expected: Grains always attack from same position
- Should sound like repeatedly triggering a sample
- No smooth scanning or looping

Step 3: LIVE Mode
- Change dropdown to "LIVE (Input)"
- Check post window for: "Track 1: Mode set to 2 (LIVE)"
- Adjust Position slider
- Position now means "time ago": 0.0 = most recent, 1.0 = buffer start
- Expected: Delay/echo-like effect
- Good for live input processing (if implemented)

Step 4: Mode Switching Stability
- Rapidly switch between all three modes
- Expected: No crashes, no error messages
- Audio should change immediately
- Post window should show mode changes

VERIFICATION:
✓ Dropdown exists and is visible
✓ All three mode names display correctly
✓ Clicking each mode changes synth behavior audibly
✓ Post window shows mode changes
✓ No crashes when switching modes
✓ Each mode has distinct sonic character
✓ Can switch modes while audio is playing

If all checks pass, Phase 6 implementation is successful!
*/

"=== GUI MATERIAL MODE TEST GUIDE ===".postln;
"Follow the steps in this file to manually test the Material Mode dropdown.".postln;
"See comments above for detailed procedure.".postln;
