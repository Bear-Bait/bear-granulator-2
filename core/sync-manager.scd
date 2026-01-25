/*
BEARULATOR: Sync Manager
- TempoClock Management
- Rhythmic Grain Density Calculation
- Quantized Triggering
*/

~bearulatorSyncManager = { arg trackManager;
    var clock = TempoClock.default;
    var publicAPI;

    publicAPI = (
        // --- API: Set Global Tempo ---
        setBPM: { arg self, bpm;
            clock.tempo = bpm / 60;
            "✓ Global Tempo set to: % BPM".format(bpm).postln;
        },

        // --- API: Snap Track to Grid (Subdivision) ---
        setRhythmicDensity: { arg self, trackNum, div;
            var densityHz = clock.tempo * (div / 1); 
            
            // 1. Force Density Mode
            trackManager.setParam(trackNum, \useOverlap, 0); 
            
            // 2. Set Density (Hz)
            trackManager.setParam(trackNum, \density, densityHz);
            
            // 3. Set Grain Size to fill the gap (100% duty cycle)
            trackManager.setParam(trackNum, \grainSize, 1 / densityHz);
            
            "✓ Track % Locked to 1/% notes (% Hz)".format(trackNum+1, div, densityHz.round(0.01)).postln;
        },

        // --- API: Quantized Play ---
        playQuantized: { arg self, trackNum;
            var track = trackManager.getTrack(trackNum);
            "Quantizing Start...".postln;
            clock.playNextBar({
                trackManager.setParam(trackNum, \position, track.params[\loopStart]);
                if(track.grainSynth.notNil) { track.grainSynth.run(true) };
                if(track.directPlaybackSynth.notNil) { track.directPlaybackSynth.run(true) };
                "▶ Track % Playing (On Grid)".format(trackNum+1).postln;
            });
        },
        
        // --- GUI: Sync Tools Window ---
        createSyncWindow: { arg self;
            var win = Window("SYNC MANAGER", Rect(100, 350, 320, 150)).front;
            var bpmBox;
            
            win.view.background_(Color.fromHexString("#262938"));
            
            // BPM Control
            StaticText(win, Rect(10, 10, 50, 20)).string_("BPM").stringColor_(Color.white);
            bpmBox = NumberBox(win, Rect(50, 10, 50, 20))
                .value_(clock.tempo * 60)
                .action_({ |nb| self.setBPM(nb.value) });
                
            // Rhythmic Grain Snapping buttons
            StaticText(win, Rect(10, 50, 100, 20)).string_("SNAP ALL:").stringColor_(Color.white);
            
            Button(win, Rect(10, 75, 60, 30))
                .states_([["1/4", Color.black, Color.cyan]])
                .action_({ [0,1,2,3].do({|i| self.setRhythmicDensity(i, 4)}) });
                
            Button(win, Rect(80, 75, 60, 30))
                .states_([["1/8", Color.black, Color.cyan]])
                .action_({ [0,1,2,3].do({|i| self.setRhythmicDensity(i, 8)}) });
                
            Button(win, Rect(150, 75, 60, 30))
                .states_([["1/16", Color.black, Color.cyan]])
                .action_({ [0,1,2,3].do({|i| self.setRhythmicDensity(i, 16)}) });
        }
    );

    "✓ Bearulator Sync Manager Defined".postln;
    publicAPI;
};