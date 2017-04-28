(
/*
* multiplicity/multiplicity.scd
*
* multiplicity
* Copyright (C) 2016 - John Burnett
* <http://www.johncburnett.com/>
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

//--------------------------------------------------------------
//_Init

//_Routing
~num_inputs = 2; // 1 or 2

//_Server
s = Server.local;
o = s.options;
o.memSize_(2e6); // 2GB of RAM
o.numInputBusChannels  = 2; // 2 in
o.numOutputBusChannels = 2; // 2 out

//_Globals
~displayGUI = true;

//_Synthesis globals
~dur = 20.0;  // duration of each swell
~space = 5;   // space between swell onsets

//_Debugging
~debugIDE = true;
~debugServer = false;

s.waitForBoot({

	//--------------------------------------------------------------
	//_Buffers

	~cwd = thisProcess.nowExecutingPath.dirname +/+ "samples";
	~b1 = Buffer.read(s, ~cwd +/+ "water.wav");
	~b2 = Buffer.read(s, ~cwd +/+ "park.wav");
	~b3 = Buffer.read(s, ~cwd +/+ "alm.wav");
	s.sync; /* wait for server */

	//--------------------------------------------------------------
	//_Live Input

	// stereo input
	SynthDef(\live_in, { |amp=0.0, send=0.0|
		var in, mix, chain, onsets;
		in = [SoundIn.ar(0), SoundIn.ar(1)];
		mix = in * amp;
		Out.ar(10, in * send); 	// to processing
		Out.ar(20, mix);	    // to mixer
	}).add;

	//--------------------------------------------------------------
	//_Samplers

	SynthDef(\sampler_1ch, { |bufnum=0, rate=1.0, pan=0, amp=0.0, send=0.0|
		var in, mix;
		in = PlayBuf.ar(1, bufnum, rate, doneAction:2);
		mix = Pan2.ar(in, pan) * amp;
		Out.ar(10, in * send); 	// to processing
		Out.ar(20, mix);	    // to mixer
	}).add;


	SynthDef(\sampler_2ch, { |bufnum=0, rate=1.0, amp=0.0, send=0.0|
		var in, mix;
		in = PlayBuf.ar(2, bufnum, rate, doneAction:2);
		mix = in * amp;
		Out.ar(10, in * send); 	// to processing
		Out.ar(20, mix);	    // to mixer
	}).add;

	SynthDef(\looper_1ch, { |bufnum=0, rate=1.0, pan=0, amp=0.0, send=0.0|
		var in, mix;
		in = PlayBuf.ar(1, bufnum, rate, loop:1);
		mix = Pan2.ar(in, pan) * amp;
		Out.ar(10, in * send); 	// to processing
		Out.ar(20, mix);	    // to mixer
	}).add;


	SynthDef(\looper_2ch, { |bufnum=0, rate=1.0, amp=0.0, send=0.0|
		var in, mix;
		in = PlayBuf.ar(2, bufnum, rate, loop:1);
		mix = in * amp;
		Out.ar(10, in * send); 	// to processing
		Out.ar(20, mix);	    // to mixer
	}).add;

	//--------------------------------------------------------------
	//_Processing

	SynthDef(\chorus, { |amp=0.0, predelay=0.08, speed=0.05, depth=0.1, ph_diff=0.5|
		var in1, in2, mod1, mod2, sig1, sig2, mix, numDelays = 12;
		in1 = In.ar(10, 1) * numDelays.reciprocal;
		in2 = In.ar(11, 1) * numDelays.reciprocal;

		mod1 = Array.fill(numDelays, { |i|
			LFPar.kr(speed * rrand(0.94, 1.06), ph_diff * i, depth, predelay);
		});
		mod2 = Array.fill(numDelays, { |i|
			LFPar.kr(speed * rrand(0.94, 1.06), ph_diff * i, depth, predelay);
		});
		sig1 = DelayC.ar(in1, 0.5, mod1);
		sig2 = DelayC.ar(in2, 0.5, mod2);

		mix = [sig1, sig2];
		Out.ar(20, mix);
	}).add;


	SynthDef(\collage,{ |amp=0.0|
		var in, d1, d2, p1, p2, p3, p4, pan, mix;

		in = In.ar(10, 2);

		d1 = Array.fill(6, {
			BPF.ar(
				CombC.ar(in[0], 15.0, rrand(0.5, 10.0), 20),
				rrand(200, 10000),
				0.3)
		} ).sum / 2;

		d2 = Array.fill(6, {
			BPF.ar(
				CombC.ar(in[1], 15.0, rrand(0.5, 10.0), 20),
				rrand(200, 10000),
				0.3)
		} ).sum / 2;

		pan = LinLin.kr(SinOsc.kr(0.25), -1.0, 1.0, -0.6, 0.6);
		d1 = Pan2.ar(d1, pan);
		d2 = Pan2.ar(d2, -1.0*pan);
		mix = [d1, d2] * amp;
		Out.ar(20, mix);
	}).add;


	SynthDef(\melt,{ |amp=0.0, mod_scale=1.0|
		var in, d1, d2, pan, mix;

		in = In.ar(10, 2);

		d1 = Array.fill(6, {
			BPF.ar(
				CombC.ar(
					in[0],
					15.0,
					LinLin.kr(
						SinOsc.kr(rrand(1/16, 1/32) * mod_scale),
						-1.0,
						1.0,
						rrand(4.0, 6.0) * mod_scale,
						rrand(8.0, 12.0) * mod_scale ),
					10) * mod_scale,
				rrand(200, 10000),
				0.3)
		} ).sum / 2;

		d2 = Array.fill(6, {
			BPF.ar(
				CombC.ar(
					in[1],
					15.0,
					LinLin.kr(
						SinOsc.kr(rrand(1/16, 1/32) * mod_scale),
						-1.0,
						1.0,
						rrand(4.0, 6.0) * mod_scale,
						rrand(8.0, 12.0) * mod_scale ),
					10) * mod_scale,
				rrand(200, 10000),
				0.3)
		} ).sum / 2;

		pan = LinLin.kr(SinOsc.kr(0.125), -1.0, 1.0, -0.6, 0.6);
		d1 = Pan2.ar(d1, pan);
		d2 = Pan2.ar(d2, -1.0*pan);
		mix = ([d1, d2]*4) * amp;

		Out.ar(20, mix);	// to mixer
	}).add;

	//--------------------------------------------------------------
	//_Synthesis

	SynthDef(\phaseMod, { |amp=0.0, carrier=1000.0, mod=400.0, pan=0.0|
		var phaseEnv, ampEnv, pmOsc, mix;
		phaseEnv = Line.ar(0.0, 10.0.rand, 8);
		ampEnv   = EnvGen.ar(Env.linen(~dur*0.25, ~dur*0.5, ~dur*0.25), doneAction:2);
		pmOsc    = PMOsc.ar(carrier, mod, phaseEnv, mul:0.1);
		mix      = Pan2.ar(pmOsc * ampEnv, pan) * amp;
		Out.ar(20, mix);
	}).add;

	//--------------------------------------------------------------
	//_Mixer

	SynthDef(\mixer,{ |amp=0.0|
		var in, mix;
		in = In.ar(20, 2);
		mix = Limiter.ar(MidEQ.ar(in, 15000, 0.7, 8)) * amp;
		Out.ar(0, mix);
	}).add;

	/**************************************************************************************************/
	//_Routing

	s.sync; /* wait for server */

	// mixer
	~mix = Synth(\mixer, [\amp, 0.0]);

	// processing
	~collage   = Synth(\collage,   [\amp, 0.0]);
	~melting   = Synth(\melt,      [\amp, 0.0]);

	// samplers
	~water  = Synth(\looper_2ch, [\bufnum, ~b1.bufnum]);
	~park   = Synth(\looper_2ch, [\bufnum, ~b2.bufnum]);
	~alm    = Synth(\looper_2ch, [\bufnum, ~b3.bufnum]);

	// live input
	~live = Synth(\live_in, [\amp, 0.0, \send, 0.0]);

	// synth arrays
	~gens = [~water, ~park, ~alm, ~live]; // generators
	~proc = [~collage, ~melting]; // processing

	/**************************************************************************************************/
	//_Worlds

	/*
	* world0
	*
	* field recording of park fading into granulated layers
	*/
	~world0 = Routine({
		var found = false;

		~reset.(~world1);
		~reset.(~world2);
		~reset.(~world3);
		~reset.(~world4);

		// exits
		if(~activity[1], {
			"exiting world 1".postln;
			~interp.(~alm, \send, 0.4, 0.0, len:15);
		},{ /* else */
			~fadein.(~melting, amp:0.8, len:60.0);
			found = true;
		});
		if(~activity[2], {
			"exiting world 2".postln;
			~fadeout.(~water, amp:0.1, len:15.0);
			~interp.(~water, \send, 0.8, 0.0, len:30);
		},{ /* else */
			~fadein.(~collage, amp:0.8, len:45.0);
		});
		if(~activity[3], {
			"exiting world 3".postln;
		});
		if(~activity[4], {
			"exiting world 4".postln;
			~interp.(~live, \send, 0.8, 0.0, len:30);
		},{ /* else */
			if(not(found), { ~fadein.(~collage, amp:0.8, len:45.0) });
		});

		~activity = false!5;
		~activity[0] = true;

		"entering world 0".postln;

		Routine.run({
			~fadein.(~park, amp:0.8, len:15.0);
			15.wait;
			~fadeout.(~park, amp:0.8, len:30.0);
			30.wait;
			"transform complete".postln;
		});

		~interp.(~park, \send, 0.0, 0.8, len:45.0);
	});


	/*
	* world1
	*
	* almglocken sounds with 'melt' processing
	*/
	~world1 = Routine({
		~reset.(~world0);
		~reset.(~world2);
		~reset.(~world3);
		~reset.(~world4);

		// exits
		if(~activity[0], {
			"exiting world 0".postln;
			~interp.(~park, \send, 0.8, 0.0, len:30.0);
			~fadeout.(~collage, amp:0.8, len:30);
		},{ /* else */
			~fadein.(~melting, amp:0.8, len:60.0);
		});
		if(~activity[2], {
			"exiting world 2".postln;
			~fadeout.(~water, amp:0.1, len:30.0);
			~interp.(~water, \send, 0.8, 0.0, len:30);
		});
		if(~activity[3], {
			"exiting world 3".postln;
		});
		if(~activity[4], {
			"exiting world 4".postln;
			~interp.(~live, \send, 0.8, 0.0, len:30);
			~fadeout.(~collage, amp:0.8, len:30.0);
		});

		~activity = false!5;
		~activity[1] = true;

		"entering world 1".postln;

		~interp.(~alm, \send, 0.0, 0.3, len:30);

		Routine.run({
			~fadein.(~alm, amp:0.05, len:15.0);
			15.wait;
			~fadeout.(~alm, amp:0.05, len:30.0);
			30.wait;
			"transform complete".postln;
		});
	});


	/*
	* world2
	*
	* liquid + collage
	*/
	~world2 = Routine({
		var found = false;

		~reset.(~world0);
		~reset.(~world1);
		~reset.(~world3);
		~reset.(~world4);

		// exits
		if(~activity[0], {
			"exiting world 0".postln;
			~interp.(~park, \send, 0.8, 0.0, len:30.0);
			~fadeout.(~melting, amp:0.8, len:30);
		},{ /* else */
			~fadein.(~collage, amp:0.8, len:45.0);
			found = true;
		});
		if(~activity[1], {
			"exiting world 1".postln;
			~interp.(~alm, \send, 0.4, 0.0, len:30.0);
			~fadeout.(~melting, amp:0.8, len:30.0);
		});
		if(~activity[3], {
			"exiting world 3".postln;
		});
		if(~activity[4], {
			"exiting world 4".postln;
			~interp.(~live, \send, 0.8, 0.0, len:30);
		},{ /* else */
			if(not(found), { ~fadein.(~collage, amp:0.8, len:45.0) });
		});

		~activity = false!5;
		~activity[2] = true;

		"entering world 2".postln;

		~fadein.(~water, amp:0.1, len:30.0);
		~interp.(~water, \send, 0.0, 0.8, len:30);

		Routine.run({ 45.wait; "transform complete".postln; });
	});


	/*
	* world3
	*
	* phase modulation synthesis
	*/
	~world3 = Routine({
		~reset.(~world0);
		~reset.(~world1);
		~reset.(~world2);
		~reset.(~world4);

		// exits
		if(~activity[0], {
			"exiting world 0".postln;
			~interp.(~park, \send, 0.8, 0.0, len:30.0);
			~fadeout.(~collage, amp:0.8, len:30);
			~fadeout.(~melting, amp:0.8, len:30);
		});
		if(~activity[1], {
			"exiting world 1".postln;
			~interp.(~alm, \send, 0.4, 0.0, len:30.0);
			~fadeout.(~melting, amp:0.8, len:30.0);
		});
		if(~activity[2], {
			"exiting world 2".postln;
			~fadeout.(~water, amp:0.1, len:30.0);
			~interp.(~water, \send, 0.8, 0.0, len:30);
			~fadeout.(~collage, \collage, amp:0.8, len:30.0);
		});
		if(~activity[4], {
			"exiting world 4".postln;
			~interp.(~live, \send, 0.8, 0.0, len:30);
			~fadeout.(~collage, amp:0.8, len:30.0);
		});

		~activity = false!5;
		~activity[3] = true;

		"entering world 3".postln;

		// audio
		Routine.run({
			while( {~activity[3]}, {
				Synth(\phaseMod, [
					\carrier,	2000.0.rand,
					\mod, 		800.rand,
					\pan, 		1.0.rand2,
					\amp, 		0.3
				]);
				~space.wait;
			});
		});

		"transform complete".postln;
	});


	/*
	* world4
	*
	* live input
	*/
	~world4 = Routine({
		var found = false;

		~reset.(~world0);
		~reset.(~world1);
		~reset.(~world2);
		~reset.(~world3);

		// exits
		if(~activity[0], {
			"exiting world 0".postln;
			~interp.(~park, \send, 0.8, 0.0, len:30.0);
			~fadeout.(~melting, amp:0.8, len:30);
		},{ /* else */
			~fadein.(~collage, amp:0.8, len:45.0);
			found = true;
		});
		if(~activity[1], {
			"exiting world 1".postln;
			~interp.(~alm, \send, 0.4, 0.0, len:15);
		});
		if(~activity[2], {
			"exiting world 2".postln;
			~fadeout.(~water, amp:0.1, len:15.0);
			~interp.(~water, \send, 0.8, 0.0, len:30);
		},{ /* else */
			if(not(found), { ~fadein.(~collage, amp:0.8, len:45.0) });
		});
		if(~activity[3], {
			"exiting world 3".postln;
		});

		~activity = false!5;
		~activity[4] = true;

		"entering world 4".postln;

		~fadein.(~live, amp:0.8, len:30);
		~interp.(~live, \send, 0.0, 0.8, len:45);

		Routine.run({
			~fadein.(~live, amp:0.8, len:15.0);
			15.wait;
			~fadeout.(~live, amp:0.8, len:30.0);
			30.wait;
			"transform complete".postln;
		});

		Routine.run({
			45.wait;
			"transform complete".postln;
		});
	});

	//--------------------------------------------------------------
	//_Utilities

	~bound = { |x|
		var x1;
		if((x >= 0.4) && (x < 0.6), {
			x1 = x-0.4 * 5;
		},{
			if(x < 0.4, { x1 = 0 }, { x1 = 1 });
		});
		x1;
	};

	~interp = { |x, y|
		var x1, x2, y1, y2, out;
		x1 = ~bound.(1-x);
		x2 = ~bound.(x);
		y1 = ~bound.(1-y);
		y2 = ~bound.(y);
		out = [x1, y1, x2, y2];
	};

	~worlds = [
		~world0, ~world1, ~world2, ~world3, ~world4
	];

	~activity = false!5;

	~reset = { |r| r.stop.reset };

	~resetAll = {
		~world0.stop.reset;
		~world1.stop.reset;
		~world2.stop.reset;
		~world3.stop.reset;
		~world4.stop.reset;

		~activity = false!5;

		for(0, ~gens.size-1, { |i| ~gens[i].set(\amp, 0.0, \send, 0.0) });
		for(0, ~proc.size-1, { |i| ~proc[i].set(\amp, 0.0) });
	};

	~fadein = { |synth, amp=0.8, len=10.0, res=50|
		Routine({
			res.do({ |i|
				synth.set(\amp, i/res*amp);
				(len/res).wait;
			});
		}).play;
	};

	~fadeout = { |synth, amp=0.8, len=10.0, res=50|
		Routine({
			res.do({ |i|
				synth.set(\amp, amp - (i/res*amp));
				(len/res).wait;
			});
		}).play;
	};

	~interp = { |synth, param, start, end, len=10.0, res=100|
		Routine({
			var spec = ControlSpec(start, end, \lin, 0.00001);
			res.do({ |i|
				var v0 = spec.map(i/res);
				synth.set(param, v0);
				(len/res).wait;
			});
		}).play;
	};

	/**************************************************************************************************/
	//_GUI

	// window config
	w = Window("multiplicity", Rect(
		Window.screenBounds.width - 200,
		Window.screenBounds.height,
		200,
		440
	))
	.alwaysOnTop_(true)
	.background_(Color(0.1, 0.1, 0.1));

	// audio controls
	~audioToggle = Button(w, Rect(10, 10, 180, 80))
	.states_([
		["audio off", Color.black, Color.red],
		["audio on", Color.black, Color.green]
	])
	.action_({ |state|
		if(state.value == 0, { ~mix.set(\amp, 0.0) });
		if(state.value == 1, { ~mix.set(\amp, 1.0) });
	});

	~closeButton = Button(w, Rect(10, 110, 180, 80))
	.states_([
		["quit", Color.white, Color.blue]
	])
	.action_({ |state|
		s.quit;
		w.close;
		if(not(~debugIDE), {
			thisProcess.shutdown;
			0.exit;
		});
	});

	// world triggers
	~toggleW0 = Button(w, Rect(10, 220, 180, 40))
	.states_([
		[" world 0: inactive", Color.black, Color.white],
		[" world 0: active  ", Color.black, Color.cyan]
	])
	.action_({ |state|
		if(state.value == 0, { ~resetAll.(); });
		if(state.value == 1, {
			~world0.play;
			~toggleW1.value_(0);
			~toggleW2.value_(0);
			~toggleW3.value_(0);
			~toggleW4.value_(0);
		});
	});

	~toggleW1 = Button(w, Rect(10, 260, 180, 40))
	.states_([
		[" world 1: inactive", Color.black, Color.white],
		[" world 1: active  ", Color.black, Color.cyan]
	])
	.action_({ |state|
		if(state.value == 0, { ~resetAll.(); });
		if(state.value == 1, {
			~world1.play;
			~toggleW0.value_(0);
			~toggleW2.value_(0);
			~toggleW3.value_(0);
			~toggleW4.value_(0);
		});
	});

	~toggleW2 = Button(w, Rect(10, 300, 180, 40))
	.states_([
		[" world 2: inactive", Color.black, Color.white],
		[" world 2: active  ", Color.black, Color.cyan]
	])
	.action_({ |state|
		if(state.value == 0, { ~resetAll.(); });
		if(state.value == 1, {
			~world2.play;
			~toggleW0.value_(0);
			~toggleW1.value_(0);
			~toggleW3.value_(0);
			~toggleW4.value_(0);
		});
	});

	~toggleW3 = Button(w, Rect(10, 340, 180, 40))
	.states_([
		[" world 3: inactive", Color.black, Color.white],
		[" world 3: active  ", Color.black, Color.cyan]
	])
	.action_({ |state|
		if(state.value == 0, { ~resetAll.(); });
		if(state.value == 1, {
			~world3.play;
			~toggleW0.value_(0);
			~toggleW1.value_(0);
			~toggleW2.value_(0);
			~toggleW4.value_(0);
		});
	});

	~toggleW4 = Button(w, Rect(10, 380, 180, 40))
	.states_([
		[" world 4: inactive", Color.black, Color.white],
		[" world 4: active  ", Color.black, Color.cyan]
	])
	.action_({ |state|
		if(state.value == 0, { ~resetAll.(); });
		if(state.value == 1, {
			~world4.play;
			~toggleW0.value_(0);
			~toggleW1.value_(0);
			~toggleW2.value_(0);
			~toggleW3.value_(0);
		});
	});

	// server GUI items
	if(~debugServer, {
		s.meter;
		s.scope;
		s.plotTree;
	});

	// display gui
	if( (~displayGUI), { w.front });
});
)
