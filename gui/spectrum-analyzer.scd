/*
S-4 Rival: Spectrum Analyzer (FabFilter-Style)
Phase 15 - Professional spectral visualization

Features:
- Real-time FFT spectrum (glowing filled area)
- 128-band resonator response curve overlay
- Logarithmic frequency axis
- 30fps smooth animation
- FabFilter Pro-Q aesthetic

Usage:
~spectrumAnalyzer = ~s4SpectrumAnalyzer.value(server, masterBus, trackManager);
~spectrumAnalyzer.createWindow();
*/

~s4SpectrumAnalyzer = { arg server, masterBus, trackManager;
	var window, userView, fftBuf, fftSynth, updateTask;
	var fftData, responseCurve;
	var width = 800, height = 400;
	var numBands = 128;

	// Initialize data arrays
	fftData = Array.fill(numBands, { 0.0 });
	responseCurve = Array.fill(numBands, { 0.5 });

	(
		createWindow: {
			// Create analyzer window
			window = Window("S-4 Spectral Resonator", Rect(100, 100, width, height))
				.background_(Color.gray(0.05))
				.onClose_({
					if(updateTask.notNil, { updateTask.stop });
					if(fftSynth.notNil, { fftSynth.free });
					if(fftBuf.notNil, { fftBuf.free });
				});

			// Allocate FFT buffer (128 bins)
			fftBuf = Buffer.alloc(server, 128);

			// Create FFT analysis synth on master output
			fftSynth = {
				var sig = In.ar(0, 2).sum; // Read master output (stereo sum)
				var chain = FFT(fftBuf, sig);
				// No output - just analysis
				0.0;
			}.play(addAction: \addToTail);

			// Create UserView for drawing
			userView = UserView(window, Rect(0, 0, width, height))
				.background_(Color.gray(0.05))
				.resize_(5);

			// Drawing function
			userView.drawFunc = {
				var xScale, yScale;
				var filterFreq, filterMorph, filterRes, filterDecay;

				// Get current filter parameters from master bus
				if(trackManager.notNil, {
					var master = trackManager.getMasterBus;
					if(master.notNil, {
						// Read filter params (would need to expose these)
						filterFreq = 200;   // Default values for now
						filterMorph = 0.5;
						filterRes = 0.5;
						filterDecay = 0.5;
					});
				});

				// === LAYER 1: FFT SPECTRUM (The "Glow") ===
				// Filled area showing actual audio spectrum
				Pen.fillColor = Color.cyan(0.8, 0.3); // Glowing cyan
				Pen.moveTo(0 @ height);

				fftData.do { arg magnitude, i;
					// Logarithmic X-axis mapping
					var logPos = (i / (numBands - 1)).explin(0.001, 1, 0, width);
					var yPos = height - (magnitude.clip(0, 1) * (height - 20));
					Pen.lineTo(logPos @ yPos);
				};

				Pen.lineTo(width @ height);
				Pen.fill;

				// === LAYER 2: RESONATOR RESPONSE CURVE (The "Target") ===
				// Bright line showing theoretical filter response
				Pen.strokeColor = Color.cyan(1.0, 1.0); // Bright cyan
				Pen.width = 2;

				responseCurve.do { arg gain, i;
					var logPos = (i / (numBands - 1)).explin(0.001, 1, 0, width);
					var yPos = height - (gain.clip(0, 1) * (height - 20));

					if(i == 0, {
						Pen.moveTo(logPos @ yPos);
					}, {
						Pen.lineTo(logPos @ yPos);
					});
				};
				Pen.stroke;

				// === FREQUENCY LABELS ===
				// Draw frequency markers (log scale)
				[20, 50, 100, 200, 500, 1000, 2000, 5000, 10000, 20000].do { arg freq;
					var normPos = freq.explin(20, 20000, 0, 1);
					var xPos = normPos * width;
					var label = if(freq >= 1000, {
						(freq / 1000).asString ++ "k"
					}, {
						freq.asString
					});

					// Grid line
					Pen.strokeColor = Color.gray(0.2);
					Pen.width = 1;
					Pen.line(xPos @ 0, xPos @ height);
					Pen.stroke;

					// Label
					Pen.stringAtPoint(
						label,
						(xPos - 15) @ (height - 15),
						Font("DejaVu Sans Mono", 9),
						Color.gray(0.6)
					);
				};

				// === dB SCALE ===
				// Draw amplitude markers
				[-60, -40, -20, 0].do { arg db;
					var normGain = db.dbamp;
					var yPos = height - (normGain.clip(0, 1) * (height - 20));

					// Grid line
					Pen.strokeColor = Color.gray(0.2);
					Pen.width = 1;
					Pen.line(0 @ yPos, width @ yPos);
					Pen.stroke;

					// Label
					Pen.stringAtPoint(
						db.asString ++ "dB",
						5 @ (yPos - 10),
						Font("DejaVu Sans Mono", 9),
						Color.gray(0.6)
					);
				};
			};

			// Update task - 30fps
			updateTask = Task({
				loop {
					// Get FFT data from buffer
					fftBuf.getn(0, numBands, { arg values;
						{
							// Convert complex FFT to magnitude
							fftData = values.clump(2).collect({ arg pair;
								var real = pair[0];
								var imag = pair[1];
								(real.squared + imag.squared).sqrt.ampdb.linlin(-60, 0, 0, 1);
							});

							// Calculate theoretical resonator response
							responseCurve = numBands.collect({ arg i;
								var harmonic = i + 1;
								var freq = 200 * harmonic; // Use actual filterFreq here
								var bandGain = 1.0 - ((i / numBands) * (1.0 - 0.5)); // Use actual filterDecay
								bandGain.clip(0, 1);
							});

							// Refresh display
							userView.refresh;
						}.defer;
					});

					(1/30).wait; // 30fps
				};
			}, AppClock).start;

			window.front;
		},

		close: {
			if(window.notNil, { window.close });
		}
	);
};

"✓ Spectrum analyzer module loaded (FabFilter-style)".postln;
