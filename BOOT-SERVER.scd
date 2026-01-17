(
// --- 1. SERVER CONFIGURATION ---
"Setting server options...".postln;
s.options.numInputBusChannels = 8;
s.options.numOutputBusChannels = 4;
s.options.sampleRate = 48000; // Matches MOTU/Digitone
s.options.memSize = 8192 * 256; 
s.options.numBuffers = 1024 * 16;
"Options set.".postln;

// --- 2. BOOT / REBOOT ---
if(s.serverRunning, {
    "Server running - rebooting...".postln;
    s.reboot;
}, {
    "Booting server...".postln;
    s.boot;
});

// --- 3. AUTOMATIC MIDI & SYNC SETUP ---
s.doWhenBooted({
    "Server is LIVE. Initializing Studio MIDI...".postln;
    
    // Reset any old MIDI connections to prevent duplicates
    MIDIdef.freeAll;
    
    MIDIClient.init;
    MIDIIn.connectAll; // Crucial: Connects KeyStep Input to SC

    // A. FIND DESTINATION (Digitone)
    // Search Order: Digitone -> KeyStep -> Default
    m = MIDIOut.newByName("Elektron Digitone", "Elektron Digitone");
    
    if(m.isNil, {
        "Digitone USB not found. Checking KeyStep Pro...".postln;
        m = MIDIOut.newByName("KeyStep Pro", "KeyStep Pro");
    });
    
    if(m.isNil, {
        "Target devices not found. Using default MIDI Out.".postln;        m = MIDIOut(0);
    });

    m.latency = 0; // Essential for tight clocking

    // B. CREATE BRIDGES (KeyStep -> Digitone)
    // Only create bridges if we successfully found a target 'm'
    if(m.notNil, {
        
        // 1. Note Bridge (Keys)
        MIDIdef.noteOn(\bridgeOn, { |vel, num, chan| 
            m.noteOn(chan, num, vel); 
        });
        MIDIdef.noteOff(\bridgeOff, { |vel, num, chan| 
            m.noteOff(chan, num, vel); 
        });

        // 2. Clock/Transport Bridge (Heartbeat & Start/Stop)
        // Forwards: 248(Clock), 250(Start), 251(Continue), 252(Stop)
        MIDIdef.sysrt(\bridgeClock, { |val, index|
            if ((index == 248) or: { (250..252).includes(index) }) {
                m.write(index);
            };
        });

        // 3. Program Change Bridge (Pattern Switching)
        MIDIdef.program(\bridgeProg, { |val, chan|
            m.program(chan, val);
            ("Switched Pattern: " ++ val).postln;
        });
        
        "   > Hardware Bridge Active: KeyStep -> Destination".postln;
    });

    // C. SYNC SUPERCOLLIDER INTERNAL CLOCK
    // Makes SC patterns follow KeyStep tempo
    MIDIdef.sysrt(\scInternalSync, { |val, index|
        case
        { index == 250 } { 
            "   > KeyStep STARTED -> SC Internal Clock Playing".postln;
            TempoClock.default.beats = 0; 
            TempoClock.default.play;
        }
        { index == 252 } { 
            "   > KeyStep STOPPED".postln;
            // Optional: TempoClock.default.stop;
        };
    });

    "-----------------------------------------------------".postln;
    ("MIDI SUCCESS: Global variable 'm' is ready. (UID: " ++ m.uid ++ ")").postln;
    "CLOCK STATUS: Listening for KeyStep Pro...".postln;
    "-----------------------------------------------------".postln;
});
)