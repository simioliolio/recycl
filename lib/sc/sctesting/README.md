# Supercollider testing

Testing changes to SuperCollider engines is a little slow when developing for norns. It sometimes needs restarting when you make a change to a SuperCollider script. Therefore it is advantageous to be able to develop norns-bound SuperCollider scripts in isolation from the norns environment.

For macOS:

- In `~/Library/Application Support/SuperCollider/Extensions/sc/core`, add the contents of [this folder](https://github.com/monome/norns/tree/main/sc/core). Now when you start SuperCollider / reboot SuperCollider server, you should hear the same sound your norns makes when it restarts.
- Add your engine .sc file to `~/Library/Application Support/SuperCollider/Extensions/`.
- Run a test SuperCollider script from any directory (similar to [Engine_Recycl_test.scd](https://github.com/simioliolio/recycl/blob/master/sctesting/Engine_Recycle_test.scd)), and send OSC messages to your engine. Because your engine is loaded when SC server loads / reboots, it should work straight away.

The SuperCollider extensions folder should look a bit like this:
<img width="732" alt="Screenshot 2022-03-23 at 12 29 22" src="https://user-images.githubusercontent.com/22215429/159689862-60cce0d7-29b7-4a30-a754-6047507e9a60.png">
