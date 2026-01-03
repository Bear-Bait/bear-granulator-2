/*
NUMBER BOX BIDIRECTIONAL TEST
Tests that number boxes in Loop View and Modulation windows work correctly
*/

(
"=== NUMBER BOX TEST ===".postln;
"".postln;

"INSTRUCTIONS:".postln;
"".postln;

"1. LOOP VIEW (Viewfinder Window):".postln;
"   - Open the viewfinder window".postln;
"   - Try typing a value in the Start number box (e.g., 0.3)".postln;
"   - Slider should jump to match".postln;
"   - Try dragging the Start slider".postln;
"   - Number box should update to match".postln;
"   - Repeat for End number box".postln;
"".postln;

"2. MODULATION WINDOW:".postln;
"   - Click the 'Modulation' button in Track 1 tab".postln;
"   - Try typing a value in the Rate number box (e.g., 0.5)".postln;
"   - Slider should jump to match".postln;
"   - Try dragging the Rate slider".postln;
"   - Number box should update to match".postln;
"   - Repeat for Depth number box".postln;
"".postln;

"✓ If BOTH directions work (type→slider and slider→type), number boxes are FIXED".postln;
"✗ If only one direction works, there's still an issue".postln;
"".postln;

"=== END TEST ===".postln;
)
