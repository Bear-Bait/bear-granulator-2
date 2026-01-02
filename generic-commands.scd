s.boot;                    // start the server
s.reboot;                  // restart clean
s.quit;                    // shut down server
s.freeAll;                 // free all synths
s.plotTree;                // view node tree
s.meter;                  // level meters
ServerMeter.new(s);
s.scope;                   // oscilloscope
s.freqscope;              // frequency analyzer
Sound Control
Cmd-.  or  Ctrl-.         // emergency stop (kill all sound)
s.volume = -20;           // set output volume (dB)
s.mute;                   // mute output
s.unmute;                 // unmute
s.record;                 // start recording
s.stopRecording;          // stop recording
GUI Essentials
// Slider
Slider().action_({|sl| sl.value.postln});

// Knob (circular)
Knob().action_({|kn| kn.value.postln});

// Button
Button().states_([["Off"], ["On"]]).action_({|bt| bt.value.postln});

// Number box
NumberBox().value_(440).action_({|nb| nb.value.postln});

// EZSlider (with label)
EZSlider(nil, 300@30, "Freq", \freq, {|ez| ez.value.postln});

// Multi-slider
MultiSliderView().size_(16).elasticMode_(1);
Monitoring
s.dumpOSC(1);             // show OSC messages (0 to disable)
s.queryAllNodes;          // print all running nodes
ServerMeter.new(s);       // persistent meter window
FreqScope.new(400, 200);  // persistent freq scope
Common Patterns
// Set synth parameter
x.set(\freq, 440);

// Free specific synth
x.free;

// Pause/resume synth
x.run(false);  // pause
x.run(true);   // resume

// Map control to bus
x.map(\freq, busNum);

// Get server status
s.avgCPU;                 // CPU usage
s.peakCPU;                // peak CPU
s.numSynths;              // synth count
Post Window
.postln;                  // print to post window
.dump;                    // detailed object info
.plot;                    // plot arrays/signals
thisProcess.platform;     // system info
s.volume.gui;  // volume slider
{ SinOsc.ar(440) * 0.1 }.play;