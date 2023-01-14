(
~crone = NetAddr("localhost", 57120);
~crone.sendMsg("/engine/load/name", "Recycl");
// OSCFunc.new({|msg, time, addr, recvPort| postln(msg) });
)
~crone.sendMsg("/command/load_audio_file", thisProcess.nowExecutingPath.dirname++"/samples/11thhouse.wav");
~crone.sendMsg("/command/load_audio_file", thisProcess.nowExecutingPath.dirname++"/samples/James Brown - Funky Drummer (2).wav");

~crone.sendMsg("/command/play", 0.2, 0.4);
~crone.sendMsg("/command/play", 0.4, 0.6);
~crone.sendMsg("/command/play", 0.0, 0.8);
~crone.sendMsg("/command/stop");


