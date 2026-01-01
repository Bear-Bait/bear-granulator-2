/*
BOOT SERVER WITH CORRECT SETTINGS
==================================
Run this FIRST before running main.scd
*/

(
"Setting server options...".postln;

// Configure BEFORE booting
s.options.numInputBusChannels = 8;
s.options.numOutputBusChannels = 2;
s.options.sampleRate = 48000;
s.options.memSize = 8192 * 256;  // 2GB
s.options.numBuffers = 1024 * 16;

"Options set:".postln;
"  Inputs: %".format(s.options.numInputBusChannels).postln;
"  Outputs: %".format(s.options.numOutputBusChannels).postln;
"  Memory: % KB".format(s.options.memSize).postln;
"".postln;

// Boot or reboot
if(s.serverRunning, {
    "Server already running - rebooting with new settings...".postln;
    s.reboot;
}, {
    "Booting server...".postln;
    s.boot;
});
)

/*
After server boots, run main.scd
*/
