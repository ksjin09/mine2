Engine_Grd : CroneEngine {

	var group,sample,map,d2k;
	var duration, root, mode, mindex;
	var confetti, sound;

	*new { |context, doneCallback| ^super.new(context, doneCallback) }

	alloc {
		var p = thisMethod.filenameSymbol.asString.dirname +/+ "confetti";
		var s, sprkl;
		Server.default = context.server;
		s = Server.default;
		sound = 0;
		confetti = [
			//[Buffer.read(s, p +/+ "gml_32.wav"), 32],
			//[Buffer.read(s, p +/+ "cel_65.wav"), 65],
			//[Buffer.read(s, p +/+ "pf_95.wav"), 95],
			[Buffer.read(s, p +/+ "hrp_59.wav"), 59],
			[Buffer.read(s, p +/+ "kba_58.wav"), 58],
			[Buffer.read(s, p +/+ "mba_59.wav"), 59],
			[Buffer.read(s, p +/+ "pan_74.wav"), 74],
			[Buffer.read(s, p +/+ "gtr_63.wav"), 63],
			[Buffer.read(s, p +/+ "oud_52.wav"), 52],
			[Buffer.read(s, p +/+ "toy_84.wav"), 84],
			[Buffer.read(s, p +/+ "pe_66.wav"), 66],
			[Buffer.read(s, p +/+ "wah_79.wav"), 79],
			[Buffer.read(s, p +/+ "gml_52.wav"), 52],
			//[Buffer.read(s, p +/+ "plt_74.wav"), 74],
		];
		sprkl = Pseries(0,1,confetti.size-1).loop.stutter(3).asStream;
		duration = 1;
		root = 50;
		group  = ParGroup.tail(context.xg);
		sample = Sample.celesta;
		map    = sample.map;
		mode   = [
			[0,2,4,6,7,9,11],
			[0,2,4,5,7,9,11],
			[0,2,4,5,7,9,10],
			[0,2,3,5,7,9,10],
			[0,2,3,5,7,8,10],
			[0,1,3,5,7,8,10],
			[0,1,3,5,6,8,10],
		];
		mindex = 0;
		d2k = { |degree, mode|
			var size = mode.size;
			var deg = degree.round;
			12 * deg.div(size) + mode[deg%size];
		};
		(
			line: { |dur| Env.linen(0.005,0,dur).kr(2) },
			sine: { |dur| Env.sine(dur).kr(2) },
			perc: { |dur| Env.perc(dur,0.01,1,6).kr(2) }
		).keysValuesDo { |n,e|
			SynthDef(n, {
				|buf,rate=1,pos=0,amp=1,dur=1,pan=0, fb= 1, lfo= 1, cutoff= 500, num = 1|
	var insig, insig2, local, sig, ifft, fftA, fftB, fft, env;
				insig = Mix.fill(12, {Decay2.ar(Dust.ar(0.1), 0.1, 2, 0.1) * SinOsc.ar((IRand(36,84).midicps+SinOsc.ar(rate, 0, lfo)), 0, amp).frac});
				insig2 = PlayBuf.ar(
					1, buf,
					rate*BufRateScale.ir(buf)*if(n==\perc,{-1},{1}),
					1,
					pos*BufFrames.ir(buf)
				);
				fft = FFT(LocalBuf(512), insig2);
	fftA = PV_OddBin(fft);
	fftB = PV_RandComb(fft, 0.9, Impulse.kr(XLine.kr(0.1,10, dur)));
	fft = PV_MagMul(fftA,fftB);
	ifft = IFFT(fft);

	insig = insig+ifft; // insig2는 fft를 거쳐서 나감

	4.do{arg i; insig = AllpassN.ar(insig, 0.2, 0.001.rrand(0.2))}; // 음색변화 없는 delay


	local = LocalIn.ar(2)*fb; // localin에서 채널을 2개 만들어준 이유는 feedback시키는 과정의 소리가 2채널이므로, feedback coef에 곱해서 나감
	local = OnePole.ar(local, 0.5); // lowpass filter

    local = AllpassN.ar(local, 0.05, {Rand(0.003,0.05)}!2, 2);

	local = DelayN.ar(HPF.ar(local, cutoff), 1.0,
		Array.fill(2, {arg i;
		LFNoise1.kr(num**i,3.0.rrand(32),4.0.rrand(10.0)*(i+1))*0.001;
	}).abs);  // 계속 변하는 delaytime

	local = AllpassN.ar(local, 0.05, {Rand(0.01,0.05)}!2, 0.2);

	local = local + insig;

	LocalOut.ar(local);
				env = SynthDef.wrap(e,prependArgs:[dur]);
				sig = local * env * amp;
				sig = LinPan2.ar(sig, pan);
				Out.ar(0, Limiter.ar(LeakDC.ar(sig)));;
			}).add;
		};
		this.addCommand(\ping, "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff", { |m|
			var key;
			if(sound == 0, {
			    ([0,12,24]+root).do { |base,i|
					  key = d2k.((m[i*8+1]*8).asInteger, mode[mindex]);
					  Synth.grain([\sine,\line,\perc][((m[i*8+2].abs*6)%3).asInteger], [
						  buf:  map[base+key][0],
						  rate: map[base+key][1],
						  pos:  m[i*8+3].linlin(-1,1,0.1,0.3),
						  amp:  dbamp(m[i*8+4].linlin(-1,1,-12,-3)-(i*1.5)),
					  	dur:  duration*[m[i*8+5].linlin(-1,1,0.05,0.3),2].wchoose([0.9,0.1]),
					  	pan:  m[i*8+6],
					  ], group);
			    };
			 });
			 if(sound > confetti.size, {
			    var index = m[1].linlin(-1,1,0,confetti.size).asInteger;
				  ([0,12,24]+root).do { |base,i|
				  	key = d2k.((m[i*8+1]*8).asInteger, mode[mindex]);
			  		Synth.grain(\line, [
			  			buf:  confetti[index][0],
			  			rate: midiratio(base+key-confetti[index][1]),
		  				pos:  m[i*8+3].linlin(-1,1,0.1,0.3),
		  				amp:  dbamp(m[i*8+4].linlin(-1,1,-12,-3)-(i*1.5)),
		  				dur:  duration*[m[i*8+5].linlin(-1,1,0.05,0.3),2].wchoose([0.9,0.1]),
		  				pan:  m[i*8+6],
		  			], group);
		  		};
		  	});
			if((sound > 0) && (sound <= confetti.size), {
			    ([0,12,24]+root).do { |base,i|
					  key = d2k.((m[i*8+1]*8).asInteger, mode[mindex]);
					  Synth.grain([\sine,\line,\line,\perc][((m[i*8+2].abs*6)%3).asInteger], [
						  buf:  confetti[sound-1][0],
						  rate: midiratio(base+key-confetti[sound-1][1]),
						  pos:  m[i*8+3].linlin(-1,1,0,0.1),
						  amp:  dbamp(m[i*8+4].linlin(-1,1,-12,-3)-(i*1.5)),
					  	dur:  duration*[m[i*8+5].linlin(-1,1,0.05,0.3),2].wchoose([0.9,0.1]),
					  	pan:  m[i*8+6],
					  ], group);
			    };
			 });
		});
		this.addCommand(\pong, "f", { |m|
			duration = m[1]
		});
		this.addCommand(\set_root, "f", { |m|
			root = m[1].asInteger
		});
		this.addCommand(\set_mode, "f", { |m|
			mindex = m[1].asInteger
		});
		this.addCommand(\set_sound, "i", { |m|
			sound = m[1]
		});
	}
	free { sample.free; confetti.do(_.do(_.free)); }
}