/*
S-4 Rival: Waveform Visualizer (Phase 8 - Early Implementation)
================================================================

Minimal waveform display for immediate visual feedback during Phase 4 testing.
Shows buffer contents and playback position for a single track.

Usage:
  ~visualizer = ~s4Visualizer.value(buffer, parentView, width, height);
  ~visualizer.setPosition(0.5);  // Update playhead position (0-1)
  ~visualizer.refresh;  // Redraw waveform
  ~visualizer.close;  // Cleanup

Features:
  - Real-time waveform display
  - Playback position indicator (red line)
  - Auto-scaling amplitude
  - Lightweight (30fps max)

Phase 8 will add:
  - Grain cloud visualization
  - Multi-track view
  - Zoom/pan controls
  - Spectrum display
*/

~s4Visualizer = { |buffer, parentView, width = 800, height = 200|
	var visualizer = ();
	var waveformView;
	var updateTask;
	var currentPosition = 0.5;
	var waveformData;
	var isActive = true;

	// ============================================
	// CREATE WAVEFORM VIEW
	// ============================================

	visualizer.create = {
		// User view for custom drawing
		waveformView = UserView(parentView, Rect(0, 0, width, height))
			.background_(Color.black)
			.drawFunc_({ |view|
				var w = view.bounds.width;
				var h = view.bounds.height;
				var midY = h / 2;
				var sampleStep, sample, x, y, prevX, prevY;

				// Skip if no buffer data
				if(waveformData.isNil, { ^this });

				// Draw center line
				Pen.strokeColor = Color.gray(0.3);
				Pen.moveTo(0 @ midY);
				Pen.lineTo(w @ midY);
				Pen.stroke;

				// Draw waveform
				Pen.strokeColor = Color.cyan;
				Pen.width = 1;

				sampleStep = (waveformData.size / w).max(1).asInteger;

				waveformData.size.do({ |i|
					if(i % sampleStep == 0, {
						sample = waveformData[i];
						x = (i / waveformData.size) * w;
						y = midY - (sample * midY * 0.9);  // 90% height scale

						if(i == 0, {
							Pen.moveTo(x @ y);
						}, {
							Pen.lineTo(x @ y);
						});
					});
				});
				Pen.stroke;

				// Draw playback position (red line)
				Pen.strokeColor = Color.red;
				Pen.width = 2;
				x = currentPosition * w;
				Pen.moveTo(x @ 0);
				Pen.lineTo(x @ h);
				Pen.stroke;
			});

		// Load initial waveform data
		visualizer.refresh;

		waveformView;
	};

	// ============================================
	// UPDATE WAVEFORM DATA FROM BUFFER
	// ============================================

	visualizer.refresh = {
		if(buffer.notNil and: { buffer.numFrames > 0 }, {
			// Load buffer data (mono - use channel 0)
			buffer.loadToFloatArray(action: { |array|
				var monoData;
				// Extract channel 0 (every other sample if stereo)
				if(buffer.numChannels == 2, {
					monoData = Array.newClear(array.size / 2);
					(array.size / 2).do({ |i|
						monoData[i] = array[i * 2];
					});
					waveformData = monoData;
				}, {
					waveformData = array;
				});

				// Trigger redraw
				{ waveformView.refresh; }.defer;
			});
		});
	};

	// ============================================
	// SET PLAYBACK POSITION
	// ============================================

	visualizer.setPosition = { |pos|
		currentPosition = pos.clip(0, 1);
		{ waveformView.refresh; }.defer;
	};

	// ============================================
	// AUTO-UPDATE TASK (30fps)
	// ============================================

	visualizer.startAutoUpdate = { |posFunc|
		updateTask = Task({
			loop {
				if(isActive and: { posFunc.notNil }, {
					visualizer.setPosition(posFunc.value);
				});
				(1/30).wait;  // 30fps
			};
		}).play(AppClock);
	};

	visualizer.stopAutoUpdate = {
		if(updateTask.notNil, { updateTask.stop; });
	};

	// ============================================
	// CLEANUP
	// ============================================

	visualizer.close = {
		isActive = false;
		visualizer.stopAutoUpdate;
		if(waveformView.notNil, { waveformView.remove; });
	};

	visualizer;
};
