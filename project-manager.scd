/*
BEARULATOR: Project Manager
- Saves "Scenes" (Audio Buffers + Parameters) to user recordings folder
*/

~bearulatorProjectManager = { arg trackManager, masterBus;
    // TARGET PATH: ~/Documents/supercollider/granular/samples/recordings/
    var projectsDir = Platform.userHomeDir +/+ "Documents/supercollider/granular/samples/recordings";
    var publicAPI;

    // Ensure directory exists (creates the path if it's missing)
    if(File.exists(projectsDir).not, { 
        "Creating directory: %".format(projectsDir).postln;
        File.mkdir(projectsDir); 
    });

    publicAPI = (
        // --- API: Save Full Project ---
        saveProject: { arg self, projectName;
            var projPath = projectsDir +/+ projectName;
            var samplesPath = projPath +/+ "samples";
            var statePath = projPath +/+ "state.scd";
            var projectData = Dictionary.new;
            
            "Saving Project to: %...".format(projPath).postln;

            // 1. Create Folder Structure
            if(File.exists(projPath).not, { File.mkdir(projPath) });
            if(File.exists(samplesPath).not, { File.mkdir(samplesPath) });

            // 2. Export Audio Buffers & Capture Params
            projectData["tracks"] = 4.collect({ |i|
                var track = trackManager.getTrack(i);
                var bufPath = samplesPath +/+ "track_%.wav".format(i+1);
                
                // A. Write Buffer to Disk
                if(track.recorder.buffer.notNil, {
                    track.recorder.buffer.write(bufPath, "wav", "int16");
                    "   Exported loop: track_%.wav".format(i+1).postln;
                });

                // B. Capture Parameters
                Dictionary[
                    "params" -> track.params,
                    "relPath" -> ("samples" +/+ "track_%.wav".format(i+1))
                ]
            });

            // 3. Save State Manifest
            projectData.writeArchive(statePath);
            "   State saved.".postln;
            "Project '%' saved successfully.".format(projectName).postln;
        },

        // --- API: Load Project ---
        loadProject: { arg self, projectName;
            var projPath = projectsDir +/+ projectName;
            var statePath = projPath +/+ "state.scd";
            var projectData;
            
            if(File.exists(statePath), {
                "Loading Project: %...".format(projectName).postln;
                projectData = Object.readArchive(statePath);
                
                // Restore Tracks
                projectData["tracks"].do({ |tData, i|
                    var fullSamplePath = projPath +/+ tData["relPath"];
                    
                    if(File.exists(fullSamplePath), {
                        trackManager.loadSample(i, fullSamplePath);
                        "   Loaded loop: %".format(tData["relPath"]).postln;
                    });

                    {
                        tData["params"].keysValuesDo({ |k, v|
                            trackManager.setParam(i, k, v);
                        });
                    }.defer(0.2);
                });
                
                "Project Loaded.".postln;
            }, {
                "Project not found at: %".format(projPath).warn;
            });
        },
        
        // --- API: List Projects ---
        listProjects: {
            var folders = (projectsDir +/+ "*").pathMatch;
            folders.collect({ |p| PathName(p).folderName }).postln;
        },
        
        // --- API: Open Folder ---
        openFolder: {
            projectsDir.openOS;
        }
    );
    
    "Bearulator Project Manager Initialized (Custom Path)".postln;
    publicAPI;
};
