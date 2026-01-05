/*
Stereo Balance Monitor - Auto-stops after N readings
Monitors left/right channel balance for debugging stereo issues
*/

(
var trackNum = 0;  // Which track to monitor (0-3)
var numReadings = 25;  // How many readings before auto-stop
var rate = 5;  // Readings per second
var count = 0;

// Clean up any existing monitors
if(~stereoTest.notNil, { ~stereoTest.free });
if(~stereoResponder.notNil, { ~stereoResponder.free });

"=== Starting Stereo Balance Monitor ===".postln;
"Track: %, Readings: %, Rate: % Hz".format(trackNum + 1, numReadings, rate).postln;
"".postln;

~stereoTest = {
    var sig = In.ar(~trackManager.getTracks[trackNum].audioBus.index, 2);
    SendReply.kr(Impulse.kr(rate), '/stereoBalance', [
        Amplitude.ar(sig[0]),  // Left
        Amplitude.ar(sig[1])   // Right
    ]);
}.play(target: ~trackManager.getTracks[trackNum].instrumentGroup, addAction: \addAfter);

~stereoResponder = OSCFunc({ arg msg;
    "L: % (% dB) | R: % (% dB)".format(
        msg[3].round(0.001), msg[3].ampdb.round(0.1),
        msg[4].round(0.001), msg[4].ampdb.round(0.1)
    ).postln;

    count = count + 1;
    if(count >= numReadings, {
        "".postln;
        "=== Stopped after % readings ===".format(numReadings).postln;
        ~stereoTest.free;
        ~stereoResponder.free;
    });
}, '/stereoBalance');

"Monitor running... will auto-stop after % readings".format(numReadings).postln;
)
