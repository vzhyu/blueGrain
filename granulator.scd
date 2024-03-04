(
~currentPath = PathName.new(thisProcess.nowExecutingPath).parentPath;
~bufLoad = {
	s.waitForBoot({
		~path = PathName.new(thisProcess.nowExecutingPath).parentPath ++ "multiphonic#7-Trill-3rd_var_001.aiff";
		~pathSplit = ~path.split();
		~fileName = ~pathSplit[(~pathSplit.size) - 1];
		~buf = Buffer.readChannel(s, ~path, channels:0);
	})
};

~init = {

	~xBus = Bus.control(s, 1);
	~yBus = Bus.control(s, 1);
	~playBus = Bus.control(s, 1);
	~ampBus = Bus.control(s, 1);

	~sigBus = Bus.audio(s, 1);

	~durValue = 0.04;
	~panValue = 0.0;
	~rateValue = 1.0;
	~posValue = 0.0;
	~freqValue = 10.0;
	~pRateValue = 1.0;
	~ampValue = 1.0;
	~ampBoxValue = ~ampValue.ampdb.round(0.1);
	if(~ampBoxValue >= 0, {
		~ampBoxString = "+" ++ ~ampBoxValue.asString;
	}, {
		~ampBoxString = ~ampBoxValue.asString;
	}
	);

	~rateMin = -5;
	~rateMax = 5;
	~panMin = -1;
	~panMax = 1;
	~durMin = 0.01;
	~durMax = 0.4;
	~freqMin = 5;
	~freqMax = 100;
	~posMin = 0;
	// ~posMax = (~buf.numFrames) - 1;
	~posMax = 1;
	~pRateMin = -10;
	~pRateMax = 10;
	~ampMin = -40;
	~ampMax = 9;
	~pan = false;

	~mainFont = Font("Tahoma", 14);
	~boxFont = Font("Courier", 12);

	~buttonColor = Color.fromHexString("#2185b0");

	~sliderWidth = 280;
	~textWidth = 100;
	~boxWidth = 50;

	~xPosWin = 400;
	~yPosWin = 800;
	~xSizeWin = 570;
	~ySizeWin = 100;

	~alertWidth = 300;
	~recordNum = 0;

	~fileNameText = TextField.new(w)
	.fixedWidth_(380)
	.font_(~mainFont)
	.canFocus_(false)
	.value_(~fileName);

	~picker = PopUpMenu.new(w)
	.items_([~fileName, "White Noise", "Pink Noise", "Brown Noise", "Microphone"])
	.allowsReselection_(true)
	.fixedWidth_(380)
	.font_(~mainFont)
	.canFocus_(false)
	.action_({
		arg n;
		if(n.value == 0, {
			~bufMode.();
		});
		if(n.value > 0, {
			~sigMode.();
		});

		// choice.postln;
	});

	~switchOff = Button.new(w)
	.canFocus_(false)
	.font_(~mainFont)
	.fixedWidth_(80)
	.visible_(false)
	.states_([["PLAY", Color.gray(0.8), Color.gray(0.5)]])
	.action_({
		~warningWindow.(message: "Please select a valid file.");
	});

	~recordButtonOff = Button.new(w)
	.canFocus_(false)
	.font_(~mainFont)
	.fixedWidth_(80)
	.visible_(false)
	.states_([["RECORD", Color.gray(0.8), Color.gray(0.5)]])
	.action_({
		~warningWindow.(message: "Please select a valid file.");
	});

	~mouseToggleOff = Button.new(w)
	.canFocus_(false)
	.font_(~mainFont)
	.fixedWidth_(150)
	.visible_(false)
	.states_([["Mouse Control", Color.gray(0.8), Color.gray(0.5)]])
	.action_({
		~warningWindow.(message: "Please select a valid file.");
	});

	~playToggleOff = Button.new(w)
	.canFocus_(false)
	.font_(~mainFont)
	.fixedWidth_(100)
	.visible_(false)
	.states_([["Autoplay", Color.gray(0.8), Color.gray(0.5)]])
	.action_({
		~warningWindow.(message: "Please select a valid file.");
	});
	~recordButton = Button.new(w)
	.canFocus_(false)
	.font_(~mainFont)
	.fixedWidth_(80)
	// .states_([["⏺", Color.red, Color.fromHexString("#2185b0")], ["⏹", Color.yellow, Color.fromHexString("#2185b0")]])
	.states_([["RECORD", Color.gray(0.8), ~buttonColor], ["RECORD", Color.red, ~buttonColor]])
	.action_({
		~recordButtonAction = {
			if(~recordButton.value == (1), {
				// s.record((~currentPath ++ Date.getDate ++ ".wav"));
				s.record();
			});
			if(~recordButton.value == (0), {
				s.stopRecording;
			});
		};
		~recordButtonAction.();

	});
	~pressRecord = {
		~recordButton.value_((~recordButton.value+1)%2);
		~recordButtonAction.();
	};

	~recordButtonControls = [~recordButton, ~pressRecord];

	~fileButton = Button.new(w)
	.canFocus_(false)
	.font_(~mainFont)
	.fixedWidth_(60)
	.states_([["OPEN", Color.yellow, ~buttonColor]])
	.action_({
		FileDialog({
			arg path;
			var mouseTrue = false, playTrue = false;
			// path[0].postln;
			~path = path[0];
			~pathSplit = ~path.split();
			~fileName = ~pathSplit[(~pathSplit.size) - 1];
			if (~mouseToggle.value == 0, {
				// ~mouseRead.stop;
				~pressMouseToggle.();
				mouseTrue = true;
			});
			if (~playToggle.value == 0, {
				~pressPlayToggle.();
				playTrue = true;
				// ~autoPlay.stop;
			});
			~bufGrain.free;
			AppClock.play(Routine.new({
				~buf = Buffer.readChannel(s, ~path, channels:0);
				0.1.wait;
				if(~buf.numFrames == nil, {
					// ~buf.postln;
					~buttonsDeactivate.();
					~warningWindow.(message: "Please select a valid file.");
				});
				if(~buf.numFrames != nil, {
					// ~buf.postln;
					~buttonsActivate.();
					~bufGrain = Synth(\bufGrain, [\buf, ~buf, \rate, ~rateValue, \pan, ~panValue, \dur, ~durValue, \freq, ~freqValue], ~grainGroup);
					0.1.wait;
					if (mouseTrue == true, {
						// ~mouseRead.reset;
						// AppClock.play(~mouseRead);
						~pressMouseToggle.();
					});
					if (playTrue == true, {
						// ~autoPlay.reset;
						// AppClock.play(~autoPlay);
						~pressPlayToggle.();
					});
				});
				// 0.3.wait;
				// ~posMax = (~buf.numFrames - 1);
				// 0.3.wait;
				~fileNameText.value_(~fileName);
				if(~picker.value != 0, {
					~picker.value_(0);
					~bufMode.();
				});
				~picker.items_([~fileName, "White Noise", "Pink Noise", "Brown Noise", "Microphone"]);
			}));
		}, path:~currentPath)
	});

	~switch = Button.new(w)
	.font_(~mainFont)
	.canFocus_(false)
	// .focusColor_(Color.gray)
	.fixedWidth_(80)
	.value_(1)
	// .states_([["⏻", Color.green, Color.fromHexString("#2185b0")], ["⏻", Color.gray(0.8), Color.fromHexString("#2185b0")]])
	.states_([["PLAY", Color.green, ~buttonColor], ["PLAY", Color.gray(0.8), ~buttonColor]])
	.action_({
		~switchAction = {
			if (~switch.value == 0, {
				~grainGroup.set(\amp, ~ampValue);
				if (~picker.value > 0, {
					~inputSwitch.(input: \sig);
					// "sig".postln;
				});
				if (~picker.value == 0, {
					~inputSwitch.(input: \buf);
					// "buf".postln;
				});
			});
			if (~switch.value == 1, {
				~grainGroup.set(\amp, 0);
			});
		};
		~switchAction.();
	});

	~pressSwitchToggle = {
		~switch.value_((~switch.value+1)%2);
		~switchAction.();
	};

	~switchControls = [~switch, ~pressSwitchToggle];


	~mouseToggle = Button.new(w)
	.font_(~mainFont)
	.canFocus_(false)
	.fixedWidth_(150)
	.states_([["Mouse Control", Color.green, ~buttonColor], ["Mouse Control", Color.gray(0.8), ~buttonColor]])
	.action_({
		~mouseToggleAction = {
			if (~mouseToggle.value == 0, {
				~mouseRead.reset;
				AppClock.play(~mouseRead);
				// ~sound.set(\amp, ~ampValue);
				// ~switch.value_(0);
				~setButtonState.(~switchControls, 0);
			});
			if (~mouseToggle.value == 1, {
				~mouseRead.stop;
			})
		};
		~mouseToggleAction.();
	});

	~pressMouseToggle = {
		// if (~mouseToggle.value == 0, {
		// 	~mouseToggle.value_(1);
		// 	}, {
		// 		if (~mouseToggle.value == 1, {
		// 			~mouseToggle.value_(0);
		// 		});
		// });
		~mouseToggle.value_((~mouseToggle.value+1)%2);
		~mouseToggleAction.();
	};


	~mouseToggleControls = [~mouseToggle, ~pressMouseToggle];

	~playToggle = Button.new()
	.font_(~mainFont)
	.canFocus_(false)
	.fixedWidth_(100)
	.states_([["Autoplay", Color.green, ~buttonColor], ["Autoplay", Color.gray(0.8), ~buttonColor]])
	.action_({
		~playToggleAction = {
			if (~playToggle.value == 0, {
				// ~posBox.value.postln;
				~startAutoPlay = {
					if(~pRateValue >= 0, {
						~play.free;
						// "posRate".postln;
						~play = Synth(\autoPlay, [\phase, 1 + (abs(~posBox.value.asFloat)*2), \mul, ~pRateValue, \numFrames, ~buf.numFrames]);
					});
					if(~pRateValue < 0, {
						~play.free;
						// "negRate".postln;
						~play = Synth(\autoPlay, [\phase, -1 - (abs(~posBox.value.asFloat)*(-2)), \mul, ~pRateValue, \numFrames, ~buf.numFrames]);
					});
				};
				~startAutoPlay.();
				~autoPlay.reset;
				AppClock.play(~autoPlay);
				// ~sound.set(\amp, 1);
				// ~switch.value_(0);
				~setButtonState.(~switchControls, 0);
			});
			if (~playToggle.value == 1, {
				~autoPlay.stop;
			});
		};
		~playToggleAction.();
	});

	~onButtons = [~switch, ~recordButton, ~mouseToggle, ~playToggle];
	~offButtons = [~switchOff, ~recordButtonOff, ~mouseToggleOff, ~playToggleOff];

	~pressPlayToggle = {
		// if (~playToggle.value == 0, {
		// 	~playToggle.value_(1);
		// 	}, {
		// 		if (~playToggle.value == 1, {
		// 			~playToggle.value_(0);
		// 		});
		// });
		// if (~playToggle.value == 1, {
		// 	~playToggle.value_(0);
		// 	}, {
		// 		if (~playToggle.value == 0, {
		// 			~playToggle.value_(1);
		// 		});
		// });
		~playToggle.value_((~playToggle.value+1)%2);
		~playToggleAction.();
	};


	~playToggleControls = [~playToggle, ~pressPlayToggle];

	~setButtonState = {
		arg controls, state = 0;
		var button, toggle;
		button = controls[0];
		toggle = controls[1];
		while({button.value != state}, {
			toggle.();
		});
	};

	~cleanBoxInput = {
		arg input = "nil";
		var array = [$0, $1, $2, $3, $4, $5, $6, $7, $8, $9, $., $-, $+], isNumber = true;
		input.do({
			arg i, j;
			if(array.includes(i) == false, {
				isNumber = false;
			});
		});
		isNumber;
	};

	~inputSwitch = {
		arg input;
		if(input == \buf, {
			// "buf".postln;
			~bufGrain.set(\amp, ~ampValue);
			~sigGrain.set(\amp, 0);
			~setButtonState.(~switchControls, 0);
		});
		if(input == \sig, {
			// "sig".postln;
			~bufGrain.set(\amp, 0);
			~sigGrain.set(\amp, ~ampValue);
			~setButtonState.(~switchControls, 0);
		});
	};

	~durLabel = StaticText(w)
	.font_(~mainFont)
	.string_("duration")
	.fixedWidth_(~textWidth);
	~durSlider = Slider.new(w)
	.background_(Color.gray(0.8, 0.1))
	.fixedWidth_(~sliderWidth)
	.action_({
		var val;
		//set slider value to freq
		~durValue = ~durSlider.value.linlin(0, 1, ~durMin, ~durMax);
		~grainGroup.set(\dur, ~durValue);
		~durBox.value_(~durValue.round(0.01));
		val = ~durBox.value.asFloat;
		if(val > ~durMax, {
			~durSlider.knobColor_(Color.red);
		});
		if(val < ~durMin, {
			~durSlider.knobColor_(Color.red);
		});
		if(val >= ~durMin, {
			if(val <= ~durMax, {
				~durSlider.knobColor_(Color.black);
			});
		});
	})
	.orientation_(\horizontal)
	.value_(~durValue.linlin(~durMin, ~durMax, 0, 1));
	~durBox = TextField(w)
	.mouseDownAction_({
		~durBox.value = ("");
	})
	.value_(~durValue)
	.action_({
		var val;
		if(~durBox.value == "", {
			~durBox.value_(~durValue.round(0.01));
		});
		if(~cleanBoxInput.(~durBox.value) == false, {
			~durBox.value_(~durValue.round(0.01));
		});
		val = ~durBox.value.asFloat;
		~durSlider.value = val.linlin(~durMin, ~durMax, 0, 1);
		~durValue = val;
		~grainGroup.set(\dur, ~durValue);
		if(val > ~durMax, {
			~durSlider.knobColor_(Color.red);
		});
		if(val < ~durMin, {
			~durSlider.knobColor_(Color.red);
		});
		if(val >= ~durMin, {
			if(val <= ~durMax, {
				~durSlider.knobColor_(Color.black);
			});
		});
		~durBox.value_(val.asFloat);
		w.focus;
	})
	.font_(~boxFont)
	.fixedWidth_(~boxWidth);

	~panLabel = StaticText(w)
	.font_(~mainFont)
	.string_("panning")
	.fixedWidth_(~textWidth);
	~panSlider = Slider.new(w)
	.background_(Color.gray(0.8, 0.1))
	.fixedWidth_(~sliderWidth)
	.action_({
		var val;
		~panValue = ~panSlider.value.linlin(0, 1, ~panMin, ~panMax);
		~grainGroup.set(\pan, ~panValue);
		~panBox.value_(~panValue.round(0.01));
		val = ~panBox.value.asFloat;
		if(val > ~panMax, {
			~panSlider.knobColor_(Color.red);
		});
		if(val < ~panMin, {
			~panSlider.knobColor_(Color.red);
		});
		if(val >= ~panMin, {
			if(val <= ~panMax, {
				~panSlider.knobColor_(Color.black);
			});
		});
	})
	.orientation_(\horizontal)
	.value_(~panValue.linlin(~panMin, ~panMax, 0, 1));
	~panBox = TextField(w)
	.mouseDownAction_({
		~panBox.value_("");
	})
	.value_(~panValue)
	.action_({
		var val;
		if(~panBox.value == "", {
			~panBox.value_(~panValue.round(0.01));
		});
		if(~cleanBoxInput.(~panBox.value) == false, {
			~panBox.value_(~panValue.round(0.01));
		});
		val = ~panBox.value.asFloat;
		~panSlider.value = val.linlin(~panMin, ~panMax, 0, 1);
		val = val.clip(~panMin, ~panMax);
		~panValue = val;
		~grainGroup.set(\pan, ~panValue);
		if(val > ~panMax, {
			~panSlider.knobColor_(Color.red);
		});
		if(val < ~panMin, {
			~panSlider.knobColor_(Color.red);
		});
		if(val >= ~panMin, {
			if(val <= ~panMax, {
				~panSlider.knobColor_(Color.black);
			});
		});
		~panBox.value_(val.asFloat);
		w.focus;

	})
	.font_(~boxFont)
	.fixedWidth_(~boxWidth);

	~rateLabel = StaticText(w)
	.font_(~mainFont)
	.string_("rate (grain)")
	.fixedWidth_(~textWidth);
	~rateSlider = Slider.new(w)
	.background_(Color.gray(0.8, 0.1))
	.fixedWidth_(~sliderWidth)
	.action_({
		var val;
		if(~picker.value == 0, {
			~rateValue = ~rateSlider.value.linlin(0, 1, ~rateMin, ~rateMax);
			~grainGroup.set(\rate, ~rateValue);
			~rateBox.value_(~rateValue.round(0.01));
			val = ~rateBox.value.asFloat;
			if(val > ~rateMax, {
				~rateSlider.knobColor_(Color.red);
			});
			if(val < ~rateMin, {
				~rateSlider.knobColor_(Color.red);
			});
			if(val >= ~rateMin, {
				if(val <= ~rateMax, {
					~rateSlider.knobColor_(Color.black);
				});
			});
		});
		if(~picker.value > 0, {
			~rateSlider.value_(0.5);
		});
	})
	.orientation_(\horizontal)
	.value_(~rateValue.linlin(~rateMin, ~rateMax, 0, 1));
	~rateBox = TextField(w)
	.mouseDownAction_({
		if(~picker.value == 0, {
			~rateBox.value_("");
		});
	})
	.value_(~rateValue)
	.action_({
		var val;
		if(~picker.value == 0, {
			if(~rateBox.value == "", {
				~rateBox.value_(~rateValue.round(0.01));
			});
			if(~cleanBoxInput.(~rateBox.value) == false, {
				~rateBox.value_(~rateValue.round(0.01));
			});
			val = ~rateBox.value.asFloat;
			~rateSlider.value = val.linlin(~rateMin, ~rateMax, 0, 1);
			~rateValue = val;
			~grainGroup.set(\rate, ~rateValue);
			if(val > ~rateMax, {
				~rateSlider.knobColor_(Color.red);
			});
			if(val < ~rateMin, {
				~rateSlider.knobColor_(Color.red);
			});
			if(val >= ~rateMin, {
				if(val <= ~rateMax, {
					~rateSlider.knobColor_(Color.black);
				});
			});
			~rateBox.value_(val.asFloat);
		});
		if(~picker.value > 0 , {
			~rateBox.value_("--");
		});
		w.focus;
	})
	.font_(~boxFont)
	.fixedWidth_(~boxWidth);

	~pRateLabel = StaticText(w)
	.font_(~mainFont)
	.string_("rate (autoplay)")
	.fixedWidth_(~textWidth);
	~pRateSlider = Slider.new(w)
	.background_(Color.gray(0.8, 0.1))
	.fixedWidth_(~sliderWidth)
	.action_({
		var val;
		if(~picker.value == 0, {
			~pRateValue = ~pRateSlider.value.linlin(0, 1, ~pRateMin, ~pRateMax);
			// ~sound.set(\pRate, ~pRateValue);
			~pRateBox.value_(~pRateValue.round(0.01));
			// ~pRateValue.postln;
			~startAutoPlay.();
			// if (~play != nil, {
			// 	~play.free;
			// 	// "playExist".postln;
			// 	if(~pRateValue >= 0, {
			// 		~play = Synth(\autoPlay, [\phase, 1 + (abs(~posBox.value)*2), \mul, ~pRateValue]);
			// 	});
			// 	if(~pRateValue < 0, {
			// 		~play = Synth(\autoPlay, [\phase, -1 - (abs(~posBox.value)*(-2)), \mul, ~pRateValue]);
			// 	});
			// });
			// if (~play == nil, {
			// 	// "playNil".postln;
			// });
			val = ~pRateBox.value.asFloat;
			if(val > ~pRateMax, {
				~pRateSlider.knobColor_(Color.red);
			});
			if(val < ~pRateMin, {
				~pRateSlider.knobColor_(Color.red);
			});
			if(val >= ~pRateMin, {
				if(val <= ~pRateMax, {
					~pRateSlider.knobColor_(Color.black);
				});
			});
		});
		if(~picker.value > 0, {
			~pRateSlider.value_(0.5);
		});
	})
	.orientation_(\horizontal)
	.value_(~pRateValue.linlin(~pRateMin, ~pRateMax, 0, 1));
	~pRateBox = TextField(w)
	.mouseDownAction_({
		if(~picker.value == 0, {
			~pRateBox.value_("");
		});
	})
	.value_(~pRateValue)
	.action_({
		var val;
		if(~picker.value == 0, {
			if(~pRateBox.value == "", {
				~pRateBox.value_(~pRateValue.round(0.01));
			});
			if(~cleanBoxInput.(~pRateBox.value) == false, {
				~pRateBox.value_(~pRateValue.round(0.01));
			});
			val = ~pRateBox.value.asFloat;
			~pRateSlider.value = val.linlin(~pRateMin, ~pRateMax, 0, 1);
			~pRateValue = val;
			~startAutoPlay.();
			if(val > ~pRateMax, {
				~pRateSlider.knobColor_(Color.red);
			});
			if(val < ~pRateMin, {
				~pRateSlider.knobColor_(Color.red);
			});
			if(val >= ~pRateMin, {
				if(val <= ~pRateMax, {
					~pRateSlider.knobColor_(Color.black);
				});
			});
			~pRateBox.value_(val.asFloat.round(0.01));
		});
		if(~picker.value > 0, {
			~pRateBox.value_("--");
		});
		// ~setButtonState.(~playToggleControls, 0);
		// ~sound.set(\pRate, ~pRateValue);
		w.focus;
	})
	.font_(~boxFont)
	.fixedWidth_(~boxWidth);

	~posLabel = StaticText(w)
	.font_(~mainFont)
	.string_("position")
	.fixedWidth_(~textWidth);
	~posSlider = Slider.new(w)
	.background_(Color.gray(0.8, 0.1))
	.fixedWidth_(~sliderWidth)
	.action_({
		var val;
		if(~picker.value == 0, {
			~posValue = ~posSlider.value.linlin(0, 1, ~posMin, ~posMax);
			~grainGroup.set(\pos, ~posValue);
			~posBox.value_(~posValue.round(0.001));
			if(~playToggle.value == 0, {
				~startAutoPlay.();
			});
			val = ~posBox.value.asFloat;
			if(val > ~posMax, {
				~posSlider.knobColor_(Color.red);
			});
			if(val < ~posMin, {
				~posSlider.knobColor_(Color.red);
			});
			if(val >= ~posMin, {
				if(val <= ~posMax, {
					~posSlider.knobColor_(Color.black);
				});
			});
		});
		if(~picker.value > 0, {
			~posSlider.value_(0.5);
		});
	})
	.orientation_(\horizontal)
	.value_(~posValue.linlin(~posMin, ~posMax, 0, 1));
	~posBox = TextField(w)
	.mouseDownAction_({
		if(~picker.value == 0, {
			~posBox.value_("");
		});
	})
	.value_(~posValue)
	.action_({
		var val;
		if(~picker.value == 0, {
			if(~posBox.value == "", {
				~posBox.value_(~posValue.round(0.001));
			});
			if(~cleanBoxInput.(~posBox.value) == false, {
				~posBox.value_(~posValue.round(0.001));
			});
			val = ~posBox.value.asFloat.clip(0, 1);
			~posSlider.value = val.linlin(~posMin, ~posMax, 0, 1);
			val = val.clip(~posMin, ~posMax);
			~posValue = val;
			~grainGroup.set(\pos, ~posValue);
			if(val > ~posMax, {
				~posSlider.knobColor_(Color.red);
			});
			if(val < ~posMin, {
				~posSlider.knobColor_(Color.red);
			});
			if(val >= ~posMin, {
				if(val <= ~posMax, {
					~posSlider.knobColor_(Color.black);
				});
			});
			~posBox.value_(val);
		});
		if(~picker.value > 0, {
			~posBox.value_("--");
		});
		w.focus;
	})
	.font_(~boxFont)
	.fixedWidth_(~boxWidth);

	~freqLabel = StaticText(w)
	.font_(~mainFont)
	.string_("density")
	.fixedWidth_(~textWidth);
	~freqSlider = Slider.new(w)
	.background_(Color.gray(0.8, 0.1))
	.fixedWidth_(~sliderWidth)
	.action_({
		var val;
		~freqValue = ~freqSlider.value.linlin(0, 1, ~freqMin, ~freqMax);
		~grainGroup.set(\freq, ~freqValue);
		~freqBox.value_(~freqValue.round(0.01));
		val = ~freqBox.value.asFloat;
		if(val > ~freqMax, {
			~freqSlider.knobColor_(Color.red);
		});
		if(val < ~freqMin, {
			~freqSlider.knobColor_(Color.red);
		});
		if(val > ~freqMin, {
			if(val < ~freqMax, {
				~freqSlider.knobColor_(Color.black);
			});
		});
	})
	.orientation_(\horizontal)
	.value_(~freqValue.linlin(~freqMin, ~freqMax, 0, 1));
	~freqBox = TextField(w)
	.mouseDownAction_({
		~freqBox.value_("");
	})
	.value_(~freqValue)
	.action_({
		var val;
		if(~freqBox.value == "", {
			~freqBox.value_(~freqValue.round(0.01));
		});
		if(~cleanBoxInput.(~freqBox.value) == false, {
			~freqBox.value_(~freqValue.round(0.01));
		});
		val = ~freqBox.value.asFloat;
		~freqSlider.value = val.linlin(~freqMin, ~freqMax, 0, 1);
		~freqValue = val;
		~grainGroup.set(\freq, ~freqValue);
		if(val > ~freqMax, {
			~freqSlider.knobColor_(Color.red);
		});
		if(val < ~freqMin, {
			~freqSlider.knobColor_(Color.red);
		});
		if(val > ~freqMin, {
			if(val < ~freqMax, {
				~freqSlider.knobColor_(Color.black);
			});
		});
		~freqBox.value_(val.round(0.01));
		w.focus;
	})
	.font_(~boxFont)
	.fixedWidth_(~boxWidth);

	~ampSlider = Slider.new(w)
	.background_(Color.gray(0.8, 0.1))
	.value_(1.dbamp.explin(~ampMin.dbamp, ~ampMax.dbamp, 0, 1))
	.action_({
		~ampValue = ~ampSlider.value.linexp(0, 1, ~ampMin.dbamp, ~ampMax.dbamp);
		~ampBoxValue = ~ampValue.ampdb.round(0.1);
		if(~ampBoxValue >= 0, {
			~ampBoxString = "+" ++ ~ampBoxValue.asString;
		}, {
			~ampBoxString = ~ampBoxValue.asString;
		}
		);
		// ~ampValue.postln;
		if(~switch.value == 0, {
			// ~sound.set(\amp, ~ampValue, \ampLag, 0.2);
			~grainGroup.set(\amp, ~ampValue);
			if (~picker.value > 0, {
				~inputSwitch.(input: \sig);
				// "sig".postln;
			});
			if (~picker.value == 0, {
				~inputSwitch.(input: \buf);
				// "buf".postln;
			});
		});
		~ampBox.value_(~ampBoxString + "dB");
	})
	.orientation_(\vertical);
	~ampBox = TextField(w)
	.mouseDownAction_({
		~ampBox.value_("");
	})
	.value_(~ampBoxString + "dB")
	.action_({
		// ~ampBoxValue = ~ampValue.ampdb.round(0.1);
		var input, outString, diff, lag;
		if(~ampBox.value == "", {
			~ampBox.value_(~ampValue.round(0.1));
		});
		if(~cleanBoxInput.(~ampBox.value) == false, {
			~ampBox.value_(~ampValue.round(0.1));
		});
		input = ~ampBox.value.asFloat;
		input = input.clip(-40, 15);
		// lag = input.dbamp.expexp(0.01, 100, 0.2, 200);
		// diff = input-~ampValue.ampdb;
		// if (diff > 0, {
		// 	lag = diff.linexp(0, 40, 0.2, 100);
		// });
		// if (diff <= 0, {
		// 	lag = 0.2;
		// });
		// lag = diff.expexp(0.2, 10, 0.
		// input = input.clip(-40, 18);
		// input.postln;
		~ampSlider.value = input.dbamp.explin(~ampMin.dbamp, ~ampMax.dbamp, 0, 1);
		~ampValue = input.dbamp;
		if (input >= 0, {
			outString = "+" ++ input.round(0.1).asString + "dB";
		}, {
			outString = input.round(0.1).asString + "db";
		}
		);
		~ampBox.value_(outString);
		// lag.postln;
		// ~ampValue.postln;
		if(~switch.value == 0, {
			~grainGroup.set(\amp, ~ampValue);
			if (~picker.value > 0, {
				~inputSwitch.(input: \sig);
				// "sig".postln;
			});
			if (~picker.value == 0, {
				~inputSwitch.(input: \buf);
				// "buf".postln;
			});
		});
		w.focus;
	})
	.font_(~boxFont)
	.fixedWidth_(70);


	~rateControl = [~rateSlider, ~rateBox, ~rateMin, ~rateMax];
	~panControl = [~panSlider, ~panBox, ~panMin, ~panMax];
	~durControl = [~durSlider, ~durBox, ~durMin, ~durMax];
	~freqControl = [~freqSlider, ~freqBox, ~freqMin, ~freqMax];
	~posControl = [~posSlider, ~posBox, ~posMin, ~posMax];
	~pRateControl = [~pRateSlider, ~pRateBox, ~pRateMin, ~pRateMax];
	~ampControl = [~ampSlider, ~ampBox, ~ampMin, ~ampMax];

	SynthDef.new(\bufGrain, {
		arg buf, rate, pan, dur, freq, pos, amp = 1, ampLag = 0.2,
		out = 0;
		var sig, env, ampCheck;
		amp = amp.lag(ampLag);
		sig = GrainBuf.ar(2,
			Impulse.ar(freq),
			dur:dur,
			rate:rate,
			sndbuf:buf,
			pan: pan,
			pos: pos
		);
		sig = sig * amp;
		ampCheck = Amplitude.ar(sig);
		Out.kr(~ampBus, ampCheck);
		Out.ar(out, sig);
	}).add;

	SynthDef.new(\sigGrain, {
		arg in, out = 0,
		pan, dur, freq, pos, amp = 1, ampLag = 0.2;
		var inSig, sig, env, ampCheck;
		amp = amp.lag(ampLag);
		inSig = In.ar(in, 1);
		sig = GrainIn.ar(2,
			Impulse.ar(freq),
			dur: dur,
			in: inSig,
			pan: pan,
		);
		sig = sig * amp;
		ampCheck = Amplitude.ar(sig);
		Out.kr(~ampBus, ampCheck);
		Out.ar(out, sig);
	}).add;

	SynthDef.new(\wNoise, {
		arg out;
		var sig;
		sig = WhiteNoise.ar(mul:0.2);
		Out.ar(out, sig);
	}).add;

	SynthDef.new(\pNoise, {
		arg out;
		var sig;
		sig = PinkNoise.ar(mul:0.2);
		Out.ar(out, sig);
	}).add;

	SynthDef.new(\bNoise, {
		arg out;
		var sig;
		sig = BrownNoise.ar(mul:0.2);
		Out.ar(out, sig);
	}).add;

	SynthDef.new(\sine, {
	});

	SynthDef.new(\sq, {
	});

	SynthDef.new(\tri, {
	});

	SynthDef.new(\saw, {
	});

	SynthDef.new(\mic, {
		arg in = 0, out;
		var sig;
		sig = SoundIn.ar(in);
		Out.ar(out, sig);
	}).add;

	SynthDef.new(\mouseTrack, {
		var mouseX, mouseY, outX, outY;
		mouseX = MouseX.kr();
		mouseY = MouseY.kr();
		Out.kr(~xBus, mouseX);
		Out.kr(~yBus, mouseY);
	}).add;

	SynthDef.new(\autoPlay, {
		arg phase = 1, mul = 1, numFrames;
		var pos;
		// pos = EnvGen.ar(Env.new([~posBox.value, ~posBox.value, 1, 0, 1, 1], [0, (~buf.numFrames)/s.sampleRate*~pRateValue], releaseNode:5, loopNode:4));
		pos = LFSaw.ar(mul/(numFrames/(s.sampleRate)), phase).range(0, 1);
		Out.kr(~playBus, pos);
	}).add;


	~mouseRead = Routine.new({
		{
			var xRead, yRead;
			xRead = ~xBus.getSynchronous;
			yRead = ~yBus.getSynchronous;
			~controlSet.(~freqControl, xRead, \slider);
			~grainGroup.set(\freq, xRead.linlin(0, 1, ~freqMin, ~freqMax));
			if (~playToggle.value == 1, {
				if(~picker.value == 0, {
					~controlSet.(~posControl, yRead, \slider);
					~grainGroup.set(\pos, yRead.linlin(0, 1, ~posMin, ~posMax));
				});
			});
			0.01.wait;
		}.loop;
	});

	~panRead = Routine.new({
		{
			var xRead;
			xRead = ~xBus.getSynchronous;
			~controlSet.(~panControl, xRead, \slider);
			~grainGroup.set(\pan, xRead.linlin(0, 1, ~panMin, ~panMax));
			0.01.wait;
		}.loop;
	});

	~autoPlay = Routine.new({
		{
			var pos;
			pos = ~playBus.getSynchronous;
			~controlSet.(~posControl, pos.round(0.001), \box);
			// pos.postln;
			~posValue = pos;
			~grainGroup.set(\pos, pos);
			0.01.wait;
		}.loop;
	});

	~controlSet = {
		arg control, value, target;
		var slider, box, min, max;
		slider = control[0];
		box = control[1];
		min = control[2];
		max = control[3];
		if (target == \slider, {
			slider.value_(value);
			box.value_(value.linlin(0, 1, min, max).round(0.01));
		});
		if (target == \box, {
			box.value_(value);
			slider.value_(value.linlin(min, max, 0, 1));
		});
	};

	~ampCheck = Routine.new({
		{
			arg amp;
			amp = ~ampBus.getSynchronous;
			if(amp >= 0.25, {
				~ampSlider.knobColor_(Color.yellow);
				if(amp >= 0.5, {
					~ampSlider.knobColor_(Color.red);
					if(amp >= 1, {
						~grainGroup.set(\ampLag, 0);
						~setButtonState.(~switchControls, 1);
						~setButtonState.(~playToggleControls, 1);
						~setButtonState.(~mouseToggleControls, 1);
						~setButtonState.(~recordButtonControls, 0);
						~warningWindow.(message: "Volume too high!", func:{
							~warning.close;
							~ampSlider.value_(1.dbamp.explin(~ampMin.dbamp, ~ampMax.dbamp, 0, 1));
							~ampBox.value_("+0.0 dB");
							~ampValue = 1;
							~grainGroup.set(\ampLag, 0.2);
							w.focus;
							~ampCheck.reset;
							AppClock.play(~ampCheck);
						});
						// ~alert = Window("Warning!", Rect(~xPosWin + ((~xSizeWin - ~alertWidth)/2), 700, ~alertWidth, 100))
						// // .fixedWidth_(400)
						// .alwaysOnTop_(true)
						// .layout_(
						// 	VLayout(
						// 		StaticText.new(~alert)
						// 		.align_(\center)
						// 		.string_("Volume too high!")
						// 		.font_(~mainFont),
						// 		HLayout(
						// 			Button.new(~alert)
						// 			.fixedWidth_(50)
						// 			.states_([["OK"]])
						// 			.action_({
						// 				~alert.close;
						// 				~ampSlider.value_(1.dbamp.explin(~ampMin.dbamp, ~ampMax.dbamp, 0, 1));
						// 				~ampBox.value_("+0.0 dB");
						// 				~ampValue = 1;
						// 				~grainGroup.set(\ampLag, 0.2);
						// 				w.focus;
						// 				~ampCheck.reset;
						// 				AppClock.play(~ampCheck);
						// 			})
						// 		)
						// 	)
						// );
						// ~alert.front;
						~ampCheck.stop;
					});
				});
			});
			if(amp < 0.25, {
				~ampSlider.knobColor_(Color.black);
			});
			// amp.postln;
			0.01.wait;
		}.loop;
	});

	~bufMode = {
		var sliders, boxes;
		~sourceSig.free;

		sliders = [~rateSlider, ~pRateSlider, ~posSlider];
		boxes = [~rateBox, ~pRateBox, ~posBox];
		sliders.do({
			arg i;
			i.background_(Color.gray(0.8, 0.1));
		});
		boxes.do({
			arg i;
			i.canFocus_(true);
		});
		~controlSet.(~rateControl, ~rateValue.round(0.01), \box);
		~controlSet.(~pRateControl, ~pRateValue.round(0.01), \box);
		~controlSet.(~posControl, ~posValue.round(0.001), \box);
		~playToggle.visible_(true);
		~playToggleOff.visible_(false)
		.action({
			~warningWindow.(message: "Please select a valid file.");
		});
		~sourceSig = Synth(\wNoise, [\out, ~sigBus], ~sourceGroup);
		~inputSwitch.(input: \buf);
	};

	~sigMode = {
		var sliders, boxes;
		~sourceSig.free;

		sliders = [~rateSlider, ~pRateSlider, ~posSlider];
		boxes = [~rateBox, ~pRateBox, ~posBox];
		~inputSwitch.(input: \sig);
		sliders.do({
			arg i;
			i.background_(Color.gray(0.5, 0.4));
			i.value_(0.5);
		});
		boxes.do({
			arg i;
			i.canFocus_(false);
			i.value_("--");
		});
		~setButtonState.(~playToggleControls, 1);
		~playToggle.visible_(false);
		~playToggleOff.visible_(true)
		.action_({
			~warningWindow.(message: "Autoplay unavailable in current mode.");
		});
		if(~picker.value == 1, {
			~sourceSig = Synth(\wNoise, [\out, ~sigBus], ~sourceGroup);
		});
		if(~picker.value == 2, {
			~sourceSig = Synth(\pNoise, [\out, ~sigBus], ~sourceGroup);
		});
		if(~picker.value == 3, {
			~sourceSig = Synth(\bNoise, [\out, ~sigBus], ~sourceGroup);
		});
		if(~picker.value == 4, {
			~sourceSig = Synth(\mic, [\out, ~sigBus], ~sourceGroup);
		});
	};

	~warningWindow = {
		arg message, title = "Error", func = {~warning.close};
		~warning = Window(title, Rect(~xPosWin + ((~xSizeWin - ~alertWidth)/2), 700, ~alertWidth, 100))
		.alwaysOnTop_(true)
		.layout_(
			VLayout(
				StaticText.new(~warning)
				.align_(\center)
				.string_(message)
				.font_(~mainFont),
				HLayout(
					Button.new(~warning)
					.fixedWidth_(50)
					.states_([["OK"]])
					.action_({
						func.();
					})
				)
			)
		);
		~warning.front;

	};

	// ~invalidFileAlert = {
	// 	~invalidFile = Window("Invalid File", Rect(~xPosWin + ((~xSizeWin - ~alertWidth)/2), 700, ~alertWidth, 100))
	// 	.alwaysOnTop_(true)
	// 	.layout_(
	// 		VLayout(
	// 			StaticText.new(~invalidFile)
	// 			.align_(\center)
	// 			.string_("Please select a valid file.")
	// 			.font_(~mainFont),
	// 			HLayout(
	// 				Button.new(~invalidFile)
	// 				.fixedWidth_(50)
	// 				.states_([["OK"]])
	// 				.action_({
	// 					~invalidFile.close;
	// 				})
	// 			)
	// 		)
	// 	);
	// 	~invalidFile.front;
	// };
	//
	// ~autoPlayAlert = {
	// 	~autoPlayUnavailable = Window("Unavailable", Rect(~xPosWin + ((~xSizeWin - ~alertWidth)/2), 700, ~alertWidth, 100))
	// 	.alwaysOnTop_(true)
	// 	.layout_(
	// 		VLayout(
	// 			StaticText.new(~autoPlayUnavailable)
	// 			.align_(\center)
	// 			.string_("Autoplay unavailable in current mode.")
	// 			.font_(~mainFont),
	// 			HLayout(
	// 				Button.new(~autoPlayUnavailable)
	// 				.fixedWidth_(50)
	// 				.states_([["OK"]])
	// 				.action_({
	// 					~autoPlayUnavailable.close;
	// 				})
	// 			)
	// 		)
	// 	);
	// 	~autoPlayUnavailable.front;
	// };

	~buttonsActivate = {
		~onButtons.do({
			arg i;
			i.visible_(true);
		});
		~offButtons.do({
			arg i;
			i.visible_(false);
		});
	};

	~buttonsDeactivate = {
		~onButtons.do({
			arg i;
			i.visible_(false);
		});
		~offButtons.do({
			arg i;
			i.visible_(true);
			i.action_({
				~warningWindow.(message: "Please select a valid file.");
			});
		});
		~setButtonState.(~switchControls, 1);
	};
};

~winLoad = {
	w = Window("granulator", Rect(~xPosWin, ~yPosWin, ~xSizeWin, ~ySizeWin))
	.asView.fixedWidth_(570)
	.background_(Color.fromHexString("#84acbd"))
	.alwaysOnTop_(true)
	.mouseDownAction_({
		w.focus;
	})
	.onClose_({
		~sourceGroup.free;
		~grainGroup.free;
		~mouse.free;
		~play.free;
		AppClock.clear;
	})
	.asView.keyDownAction_({
		arg i, char;
		// char.postln;
		if (char == $z, {
			~panRead.reset;
			AppClock.play(~panRead);
		});
		if (char == $p, {
			~pressPlayToggle.();
		});
		if (char == $m, {
			~pressMouseToggle.();
		});
		if (char == $r, {
			~pressRecord.();
		});
		if (char == $ , {
			~pressSwitchToggle.();
		});

	})
	.asView.keyUpAction_({
		arg i, char;
		if (char == $z, {
			~panRead.stop;
		});
	})

	.layout_(
		HLayout(
			VLayout(
				HLayout(
					~fileButton,
					// ~fileNameText,
					~picker,
				),
				HLayout(
					~switch,
					~switchOff,
					~recordButton,
					~recordButtonOff,
					~mouseToggle,
					~mouseToggleOff,
					~playToggle,
					~playToggleOff
				),
				HLayout(
					~durLabel,
					~durSlider,
					~durBox,
				),
				HLayout(
					~panLabel,
					~panSlider,
					~panBox,
				),
				HLayout(
					~rateLabel,
					~rateSlider,
					~rateBox,
				),
				HLayout(
					~pRateLabel,
					~pRateSlider,
					~pRateBox,
				),

				HLayout(
					~posLabel,
					~posSlider,
					~posBox,
				),
				HLayout(
					~freqLabel,
					~freqSlider,
					~freqBox,
				),
			),
			VLayout(
				StaticText(w)
				.align_(\center)
				.font_(~mainFont)
				.string_("Volume"),
				~ampSlider,
				HLayout(
					~ampBox,
				)
			)

		)
	);


	~sourceGroup = Group.new(addAction:'addToHead');
	~grainGroup = Group.new(addAction:'addToTail');


	~mouse = Synth(\mouseTrack);
	~bufGrain = Synth(\bufGrain, [\buf, ~buf, \rate, ~rateValue, \pan, ~panValue, \dur, ~durValue, \freq, ~freqValue], ~grainGroup);
	~sigGrain = Synth(\sigGrain, [\in, ~sigBus, \rate, ~rateValue, \pan, ~panValue, \dur, ~durValue, \freq, ~freqValue, \amp, 0], ~grainGroup);
	~play = Synth(\autoPlay, [\phase, 1 + (abs(~posBox.value.asFloat)*2), \mul, ~pRateValue]);
	~sourceSig = Synth(\wNoise, [\out, ~sigBus], ~sourceGroup);
	AppClock.play(~ampCheck);
	~setButtonState.(~switchControls, 0);
	~setButtonState.(~mouseToggleControls, 1);
	~setButtonState.(~playToggleControls, 1);
	w.front;
	w.focus;
	if(~buf == nil, {
		~buttonsDeactivate.();
	});
};


~startup = Routine.new({
	Window.closeAll;
	// 0.01.wait;
	s.waitForBoot({
		~bufLoad.();
		0.5.wait;
		~init.();
		0.5.wait;
		~winLoad.();
	});
});

AppClock.play(~startup);
)
//Last updated 2024-01-07 22:26:58
//reverted last changes, will fix record function later