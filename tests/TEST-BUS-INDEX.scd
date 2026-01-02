/*
CHECK BUS INDICES
See what bus indices are allocated
*/

(
var track = ~trackManager.getTrack(0);

"=== BUS ALLOCATION ===".postln;
"Modulator bus 1: index %".format(track.modBusses[0].index).postln;
"Modulator bus 1 object: %".format(track.modBusses[0]).postln;
"".postln;
"Mapper bus object: %".format(track.modMappers[0]).postln;
"Mapper bus index: %".format(track.modMappers[0].index).postln;
"".postln;
"Server's first private control bus: %".format(s.options.numAudioBusChannels).postln;
)
