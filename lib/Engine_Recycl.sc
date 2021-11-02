// An engine for playing slices of audio
Engine_Recycl : CroneEngine {

	var <gatedPlayer;

	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {

		// Based on @inifinitedigits' `slicePlayer4`
		SynthDef("GatedPlayer", {
			arg out=0, bufnum=0, rate=1, start=0, end=1, gate=0, t_trig=1;
			var snd,pos,frames,duration,env;

			rate = rate*BufRateScale.kr(bufnum);
			frames = BufFrames.kr(bufnum);
			duration = frames*(end-start)/rate/context.server.sampleRate; // redundant, but useful for an auto-gated slice player!

			// envelope to clamp looping
			env=EnvGen.ar(
				Env.new(
					levels: [0,1,0],
					times: [0.0,0.0], // attack and release
					curve:\sine,
					releaseNode: 1,
				),
				gate:gate,
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

			snd=BufRd.ar(
				numChannels:2,
				bufnum:bufnum,
				phase:pos,
				interpolation:4,
			);

			snd = snd * env;

			Out.ar(out,snd)
		}).add;

		Server.default.sync;

		gatedPlayer = Synth("GatedPlayer", [\out, context.out_b], context.xg);

		this.addCommand("load_audio_file", "s", {arg msg;
			~buffer = Buffer.read(context.server, msg[1]);
			gatedPlayer.set(\bufnum, ~buffer);
		});

		// `/play [start](0.0->1.0) [end](0.0->1.0)`
		this.addCommand("play", "f", { arg msg;
			var start, end;
			start = 0.0;
			end = 1.0;
			if (msg[1].notNil) {
				start = msg[1];
				if (msg[2].notNil) {
					end = msg[2];
				}
			};
			gatedPlayer.set(\t_trig, 1, \gate, 1, \start, start, \end, end);
		});

		this.addCommand("stop", "", { arg msg;
			gatedPlayer.set(\gate, 0)
		});
	}

	// define a function that is called when the synth is shut down
	free {
		gatedPlayer.free;
	}
}