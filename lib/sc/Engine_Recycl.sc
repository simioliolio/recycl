// An engine for playing slices of audio
Engine_Recycl : CroneEngine {

	var <gatedPlayer;
	var <posControl;

	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {

		// Based on @inifinitedigits' `slicePlayer6`
		SynthDef("GatedPlayer", {
			arg out=0,       // *Must* be a two channel bus...
			bufnum=0,        // ...and two channel buffer
			rate=1,
			start=0, end=1,  // 0.0 -> 1.0 ('percentage' of buffer) // TODO: Use seconds here?
			gate=0,          // starts and stops envelope
			t_trig=1,        // resets playback to 'start'
			pos_out;         // allows for pos polling, in seconds

			var snd,pos,frames,duration,env,pos_kr;

			rate = rate*BufRateScale.kr(bufnum);
			frames = BufFrames.kr(bufnum);

			// envelope to clamp looping
			env=EnvGen.ar(
				Env.new(
					levels: [0,1,0],
					times: [0.0001,0.0001], // attack and release
					curve:\linear,
					releaseNode: 1,
				),
				gate:gate,
				doneAction:Done.freeSelf,
			);

			// If gate is on when we reach the endpoint, playback will continue in reverse.
			// To achieve this, phasor is folded to become a retriggerable triangle ugen.
			pos=Phasor.ar(
				trig:t_trig,
				rate:rate,
				start:start*frames,
				end:end*frames + (end-start)*frames, // add arbitrary length to the phasor
				resetPos:start*frames,               // so it continues to rise beyond the endpoint
			).fold(start*frames, end*frames);

			pos_kr = A2K.kr(pos / context.server.sampleRate);

			snd=BufRd.ar(
				numChannels:2,
				bufnum:bufnum,
				phase:pos,
				interpolation:4,
			);

			snd = snd * env;
			Out.ar(out,snd);
			Out.kr(pos_out, pos_kr);

		}).add;

		posControl = Bus.control(context.server);

		context.server.sync;

		this.addCommand("load_audio_file", "s", { arg msg;
			if (gatedPlayer.notNil, { gatedPlayer.free; });
			~buffer = Buffer.read(context.server, msg[1], action: {
				switch (~buffer.numChannels, 1, {
					// Make split-mono two-channel buffer from mono audio file
					~buffer = Buffer.readChannel(context.server, msg[1], channels: [0, 0], action: {
						// Done. Wait for play command.
					});
				}, 2, {
					// Done. Wait for play command.
				}, {
					"Unsupported number of channels in audio file".postln;
				});
			});
		});

		// `/play [start](0.0->1.0) [end](0.0->1.0)`
		this.addCommand("play", "ff", { arg msg;
			var start, end;
			start = 0.0;
			end = 1.0;
			if (msg[1].notNil) {
				start = msg[1].clip(0.0, 1.0);
				if (msg[2].notNil) {
					end = msg[2].clip(0.0, 1.0);
				}
			};
			if (gatedPlayer.notNil) {
				gatedPlayer.set(\gate, 0)
			};
			gatedPlayer = Synth("GatedPlayer",
							[\out, context.out_b, \bufnum, ~buffer, \pos_out, posControl.index],
							context.xg);
			gatedPlayer.set(\t_trig, 1, \gate, 1, \start, start, \end, end);
		});

		this.addCommand("stop", "", { arg msg;
			if (gatedPlayer.notNil) {
				gatedPlayer.set(\gate, 0)
			}
		});

		this.addPoll("playhead".asSymbol, {
			var val = posControl.getSynchronous;
			val
		});
	}

	// define a function that is called when the synth is shut down
	free {
		gatedPlayer.free;
		posControl.free;
	}
}