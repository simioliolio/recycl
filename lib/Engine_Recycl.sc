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

			var aOrB,startA,endA,startB,endB,crossfade;
			var snd,sndA,sndB,posA,posB,frames,duration,env,posA_kr,posB_kr;

			// latch to change trigger between the two
			aOrB=ToggleFF.kr(t_trig);
			startA=Latch.kr(start,aOrB);
			endA=Latch.kr(end,aOrB);
			startB=Latch.kr(start,1-aOrB);
			endB=Latch.kr(end,1-aOrB);
			crossfade=Lag.ar(K2A.ar(aOrB),0.001);

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
			);

			// If gate is on when we reach the endpoint, playback will continue in reverse.
			// To achieve this, phasor is folded to become a retriggerable triangle ugen.
			posA=Phasor.ar(
				trig:aOrB,
				rate:rate,
				start:start*frames,
				end:end*frames + (end-start)*frames, // add arbitrary length to the phasor
				resetPos:start*frames,               // so it continues to rise beyond the endpoint
			).fold(start*frames, end*frames);

			posA_kr = A2K.kr(posA / context.server.sampleRate);

			sndA=BufRd.ar(
				numChannels:2,
				bufnum:bufnum,
				phase:posA,
				interpolation:4,
			);

			posB=Phasor.ar(
				trig:1-aOrB,
				rate:rate,
				start:start*frames,
				end:end*frames + (end-start)*frames, // add arbitrary length to the phasor
				resetPos:start*frames,               // so it continues to rise beyond the endpoint
			).fold(start*frames, end*frames);

			posB_kr = A2K.kr(posB / context.server.sampleRate);

			sndB=BufRd.ar(
				numChannels:2,
				bufnum:bufnum,
				phase:posB,
				interpolation:4,
			);

			snd = ((crossfade * sndA) + ((1 - crossfade) * sndB)) * env;
			Out.ar(out,snd);
			Out.kr(pos_out, (aOrB * posA_kr) + ((1 - aOrB) * posB_kr));

		}).add;

		posControl = Bus.control(context.server);

		context.server.sync;

		this.addCommand("load_audio_file", "s", { arg msg;
			if (gatedPlayer.notNil, { gatedPlayer.free; });
			~buffer = Buffer.read(context.server, msg[1], action: {
				switch (~buffer.numChannels, 1, {
					// Make split-mono two-channel buffer from mono audio file
					~buffer = Buffer.readChannel(context.server, msg[1], channels: [0, 0], action: {
						// TODO: try to refactor
						gatedPlayer = Synth("GatedPlayer",
							[\out, context.out_b, \bufnum, ~buffer, \pos_out, posControl.index],
							context.xg);
					});
				}, 2, {
					// Proceed with stereo audio file as normal
					// TODO: try to refactor
					gatedPlayer = Synth("GatedPlayer",
						[\out, context.out_b, \bufnum, ~buffer, \pos_out, posControl.index],
						context.xg);
				}, {
					"Unsupported number of channels in audio file".postln;
				});
			});
		});

		// `/play [start](0.0->1.0) [end](0.0->1.0)`
		this.addCommand("play", "f", { arg msg;
			var start, end;
			start = 0.0;
			end = 1.0;
			if (msg[1].notNil) {
				start = msg[1].clip(0.0, 1.0);
				if (msg[2].notNil) {
					end = msg[2].clip(0.0, 1.0);
				}
			};
			gatedPlayer.set(\t_trig, 1, \gate, 1, \start, start, \end, end);
		});

		this.addCommand("stop", "", { arg msg;
			gatedPlayer.set(\gate, 0)
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