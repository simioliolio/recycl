# Supercollider testing

Testing changes to SuperCollider engines is a little slow when developing for norns. It sometimes needs restarting when you make a change to a SuperCollider script. Therefore it is advantageous to be able to develop norns-bound SuperCollider scripts in isolation from the norns environment.

For macOS:

- In `~/Library/Application Support/SuperCollider/Extensions/sc`, add the contents of [this folder](https://github.com/monome/norns/tree/main/sc). Now when you start SuperCollider / reboot SuperCollider server, you should hear the same sound your norns makes when it starts up.
- Add your engine .sc file to `~/Library/Application Support/SuperCollider/Extensions/`.
- Run a test SuperCollider script (similar to [Engine_Recycl_test.scd](https://github.com/simioliolio/recycl/blob/master/sctesting/Engine_Recycle_test.scd)), and send OSC messages to your engine (because your engine is loaded when SC server loads / reboots, it should work straight away).
