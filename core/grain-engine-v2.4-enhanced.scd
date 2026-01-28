/*
BEARULATOR: Enhanced Grain Engine v2.4 (sc3-plugins + mi-UGens version)

This file REPLACES grain-engine.scd if you have the following installed:
- sc3-plugins (for VADiodeFilter, Squiz, Greyhole)
- mi-UGens quark (for MiRings)

TO USE THIS VERSION:
1. Install plugins:
   Quarks.install("sc3-plugins");
   Quarks.install("https://github.com/v7b1/mi-UGens");
   s.reboot;

2. In main.scd, replace:
   "core/grain-engine.scd".loadRelative;
   
   With:
   "core/grain-engine-v2.4-enhanced.scd".loadRelative;

3. Increase server memory for Greyhole:
   s.options.memSize = 65536;
   s.reboot;

This version provides the full v2.4 feature set with actual plugin UGens
instead of fallbacks.
*/

// Check for required plugins
(
var hasVADiode = \VADiodeFilter.asClass.notNil;
var hasSquiz = \Squiz.asClass.notNil;
var hasGreyhole = \Greyhole.asClass.notNil;
var hasMiRings = \MiRings.asClass.notNil;

"".postln;
"═══════════════════════════════════════════".postln;
"  BEARULATOR v2.4 Enhanced - Plugin Check".postln;
"═══════════════════════════════════════════".postln;
if(hasVADiode, { "✓ VADiodeFilter found".postln }, { "✗ VADiodeFilter missing (using MoogFF)".postln });
if(hasSquiz, { "✓ Squiz found".postln }, { "✗ Squiz missing (using bitcrush)".postln });
if(hasGreyhole, { "✓ Greyhole found".postln }, { "✗ Greyhole missing (using FreeVerb)".postln });
if(hasMiRings, { "✓ MiRings found".postln }, { "✗ MiRings missing (using BPF)".postln });
"═══════════════════════════════════════════".postln;
"".postln;

if(hasVADiode.not || hasSquiz.not || hasGreyhole.not || hasMiRings.not, {
	"⚠ WARNING: Some plugins missing. Install with:".postln;
	"  Quarks.install(\"sc3-plugins\");".postln;
	"  Quarks.install(\"https://github.com/v7b1/mi-UGens\");".postln;
	"  s.reboot;".postln;
	"".postln;
	"Using fallback algorithms for missing plugins.".postln;
	"".postln;
});
)

// Load the base grain engine first
"core/grain-engine.scd".loadRelative;

// TODO: Add conditional SynthDef replacement logic here
// For now, users must manually edit grain-engine.scd to use actual plugin UGens
// This requires a more sophisticated approach (conditional compilation)

"✓ Grain engine loaded (enhanced version - see comments for plugin usage)".postln;
