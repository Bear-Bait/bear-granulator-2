/*
S-4 RIVAL: Quad Spatial Audio Examples
Phase 12 - Spatial Movement & Automation

These examples show how to use the quad speaker system
to create immersive spatial effects with your granular textures.

PREREQUISITE: Run main.scd first!
*/

// ============================================
// EXAMPLE 1: Manual Positioning
// ============================================

// Position tracks in quad corners
~trackManager.setQuadPosition(0, -0.7, -0.7);  // Track 1: Front-Left
~trackManager.setQuadPosition(1,  0.7, -0.7);  // Track 2: Front-Right
~trackManager.setQuadPosition(2, -0.7,  0.7);  // Track 3: Rear-Left
~trackManager.setQuadPosition(3,  0.7,  0.7);  // Track 4: Rear-Right

// Center all tracks
~trackManager.setQuadPosition(0, 0, 0);
~trackManager.setQuadPosition(1, 0, 0);
~trackManager.setQuadPosition(2, 0, 0);
~trackManager.setQuadPosition(3, 0, 0);

// Front stereo pair (good for performance)
~trackManager.setQuadPosition(0, -0.5, -0.8);  // Track 1: Front-Left
~trackManager.setQuadPosition(1,  0.5, -0.8);  // Track 2: Front-Right
~trackManager.setQuadPosition(2, -0.5, -0.8);  // Track 3: Front-Left (doubled)
~trackManager.setQuadPosition(3,  0.5, -0.8);  // Track 4: Front-Right (doubled)

// ============================================
// EXAMPLE 2: Rotating Spatial Movement
// ============================================

// Slowly rotate Track 1 around the quad field
(
~spatialRotation = Task({
	var angle = 0;
	loop {
		var x = angle.cos;
		var y = angle.sin;
		~trackManager.setQuadPosition(0, x, y);
		angle = angle + 0.05;  // Speed of rotation
		0.1.wait;  // Update rate (10Hz)
	}
}).play;
)

  // Slowly rotate Track 2 around the quad field
  (
  ~spatialRotation2 = Task({
      var angle = 0;
      loop {
          var x = angle.cos;
          var y = angle.sin;
          ~trackManager.setQuadPosition(1, x, y);  // Track 2 is index 1
          angle = angle + 0.05;  // Speed of rotation
          0.1.wait; // Update rate (10Hz)
      }
  }).play;
  )



  // Slowly rotate Track 3 around the quad field
  (
  ~spatialRotation2 = Task({
      var angle = 0;
      loop {
          var x = angle.cos;
          var y = angle.sin;
          ~trackManager.setQuadPosition(2, x, y);  // Track 2 is index 1
          angle = angle + 0.05;  // Speed of rotation
          0.1.wait; // Update rate (10Hz)
      }
  }).play;
  )

  // Slowly rotate Track 4 around the quad field
  (
  ~spatialRotation2 = Task({
      var angle = 0;
      loop {
          var x = angle.cos;
          var y = angle.sin;
          ~trackManager.setQuadPosition(3, x, y);  // Track 2 is index 1
          angle = angle + 0.05;  // Speed of rotation
          0.1.wait; // Update rate (10Hz)
      }
  }).play;
  )


  // Rotate Track 1 clockwise, Track 2 counter-clockwise
  (
  ~spatialRotation = Task({
      var angle = 0;
      loop {
          // Track 1: clockwise
          ~trackManager.setQuadPosition(0, angle.cos, angle.sin);
          // Track 2: counter-clockwise (negative angle)
          ~trackManager.setQuadPosition(1, angle.neg.cos, angle.neg.sin);
          angle = angle + 0.05;
          0.1.wait;
      }
  }).play;
  )

  Or rotate all 4 tracks with 90° offsets (like a windmill):

  // All 4 tracks rotating together, 90° apart
  (
  ~spatialRotation = Task({
      var angle = 0;
      loop {
          ~trackManager.setQuadPosition(0, angle.cos, angle.sin);
          ~trackManager.setQuadPosition(1, (angle + 1.5pi).cos, (angle + 1.5pi).sin);
          ~trackManager.setQuadPosition(2, (angle + pi).cos, (angle + pi).sin);
          ~trackManager.setQuadPosition(3, (angle + 0.5pi).cos, (angle + 0.5pi).sin);
          angle = angle + 0.05;
          0.1.wait;
      }
  }).play;
  )

//Slower 4x rotate
(
~spatialRotation = Task({
    var angle = 0;
    loop {
        // Track 1
        ~trackManager.setQuadPosition(0, angle.cos, angle.sin);
        // Track 2 (90 deg offset)
        ~trackManager.setQuadPosition(1, (angle + 1.5pi).cos, (angle + 1.5pi).sin);
        // Track 3 (180 deg offset)
        ~trackManager.setQuadPosition(2, (angle + pi).cos, (angle + pi).sin);
        // Track 4 (270 deg offset)
        ~trackManager.setQuadPosition(3, (angle + 0.5pi).cos, (angle + 0.5pi).sin);

        // --- THE SPEED CONTROL ---
        // Decrease this number to slow down the rotation
        // 0.01 is 5x slower than your original 0.05
        angle = angle + 0.01;

        // Keep this at 0.05 or 0.1 for smooth movement
        0.1.wait;
    }
}).play;
)

// Stop rotation
~spatialRotation.stop;
 ~spatialRotation2.stop;
// ============================================
// EXAMPLE 3: Ping-Pong Between Speakers
// ============================================

// Bounce Track 2 between the 4 corners
(
~pingPong = Task({
	var positions = [
		[-0.8, -0.8],  // Front-Left
		[ 0.8, -0.8],  // Front-Right
		[ 0.8,  0.8],  // Rear-Right
		[-0.8,  0.8]   // Rear-Left
	];
	var idx = 0;

	loop {
		~trackManager.setQuadPosition(1, positions[idx][0], positions[idx][1]);
		idx = (idx + 1) % 4;
		1.0.wait;  // Dwell time at each corner
	}
}).play;
)

// Stop ping-pong
~pingPong.stop;

// ============================================
// EXAMPLE 4: Random Spatial Drift
// ============================================

// Track 3 slowly drifts to random positions
(
~spatialDrift = Task({
	loop {
		var targetX = rrand(-0.8, 0.8);
		var targetY = rrand(-0.8, 0.8);

		// Smoothly move to new position
		100.do({ arg i;
			var progress = i / 100;
			var currentX = progress.blend(
				~trackManager.getTracks[2].quadX ? 0,
				targetX
			);
			var currentY = progress.blend(
				~trackManager.getTracks[2].quadY ? 0,
				targetY
			);
			~trackManager.setQuadPosition(2, currentX, currentY);
			0.05.wait;
		});

		// Hold position for a moment
		rrand(2.0, 5.0).wait;
	}
}).play;
)

// Stop drift
~spatialDrift.stop;

// ============================================
// EXAMPLE 5: Orbit Around Center
// ============================================

// Multiple tracks orbiting at different speeds
(
~spatialOrbit = Task({
	var angles = [0, pi/2, pi, 3*pi/2];  // Start positions
	var speeds = [0.03, 0.05, 0.04, 0.06];  // Different speeds
	var radii = [0.6, 0.7, 0.5, 0.8];  // Different orbit sizes

	loop {
		4.do({ arg i;
			var x = angles[i].cos * radii[i];
			var y = angles[i].sin * radii[i];
			~trackManager.setQuadPosition(i, x, y);
			angles[i] = angles[i] + speeds[i];
		});
		0.05.wait;  // 20Hz update rate
	}
}).play;
)

// Stop orbit
~spatialOrbit.stop;

// ============================================
// EXAMPLE 6: Depth Modulation (Front/Back)
// ============================================

// Oscillate Track 1 between front and back
(
~depthOscillator = Task({
	var phase = 0;
	loop {
		var y = sin(phase) * 0.8;  // -0.8 (front) to +0.8 (rear)
		~trackManager.setQuadPosition(0, 0, y);  // Keep centered horizontally
		phase = phase + 0.05;
		0.05.wait;
	}
}).play;
)

// Stop oscillator
~depthOscillator.stop;

// ============================================
// EXAMPLE 7: Spectral Spatial Spread
// ============================================

// Low frequencies front, high frequencies rear
// (This requires modulating spectral parameters with position)
(
~spectralSpread = Task({
	loop {
		4.do({ arg i;
			var spectralPos = i / 3;  // 0 to 1
			var y = spectralPos.linlin(0, 1, -0.7, 0.7);  // Front to rear
			~trackManager.setQuadPosition(i, (i-1.5)*0.4, y);
		});
		0.1.wait;
	}
}).play;
)

// Stop spread
~spectralSpread.stop;

// ============================================
// EXAMPLE 8: Interactive Spatial Control
// ============================================

// Map MIDI CC to spatial position (requires MIDI setup)
/*
MIDIFunc.cc({ arg val, cc;
	var normalized = val / 127.0;
	var x = normalized.linlin(0, 1, -1, 1);
	~trackManager.setQuadPosition(0, x, 0);
}, 1);  // CC 1 controls X position of Track 1

MIDIFunc.cc({ arg val, cc;
	var normalized = val / 127.0;
	var y = normalized.linlin(0, 1, -1, 1);
	~trackManager.setQuadPosition(0, 0, y);
}, 2);  // CC 2 controls Y position of Track 1
*/

// ============================================
// EXAMPLE 9: Spatial Presets
// ============================================

// Define some useful spatial arrangements
(
~spatialPresets = (
	// All tracks in corners
	corners: {
		~trackManager.setQuadPosition(0, -0.7, -0.7);
		~trackManager.setQuadPosition(1,  0.7, -0.7);
		~trackManager.setQuadPosition(2, -0.7,  0.7);
		~trackManager.setQuadPosition(3,  0.7,  0.7);
	},

	// Front stereo pair
	frontRow: {
		~trackManager.setQuadPosition(0, -0.7, -0.5);
		~trackManager.setQuadPosition(1,  0.7, -0.5);
		~trackManager.setQuadPosition(2, -0.3, -0.5);
		~trackManager.setQuadPosition(3,  0.3, -0.5);
	},

	// Circle around listener
	circle: {
		~trackManager.setQuadPosition(0,  0.0, -0.7);  // Front
		~trackManager.setQuadPosition(1,  0.7,  0.0);  // Right
		~trackManager.setQuadPosition(2,  0.0,  0.7);  // Rear
		~trackManager.setQuadPosition(3, -0.7,  0.0);  // Left
	},

	// Mono (all centered)
	mono: {
		4.do({ arg i;
			~trackManager.setQuadPosition(i, 0, 0);
		});
	},

	// Distant (all rear, creates "far away" effect)
	distant: {
		~trackManager.setQuadPosition(0, -0.3,  0.8);
		~trackManager.setQuadPosition(1,  0.3,  0.8);
		~trackManager.setQuadPosition(2, -0.5,  0.9);
		~trackManager.setQuadPosition(3,  0.5,  0.9);
	}
);
)

// Use presets
~spatialPresets.corners.value;
~spatialPresets.frontRow.value;
~spatialPresets.circle.value;
~spatialPresets.mono.value;
~spatialPresets.distant.value;

// ============================================
// CLEANUP
// ============================================

// Stop all spatial automation
(
[~spatialRotation, ~pingPong, ~spatialDrift, ~spatialOrbit,
 ~depthOscillator, ~spectralSpread].do({ arg task;
	if(task.notNil, { task.stop });
});
"All spatial automation stopped.".postln;
)


// Test on Track 4 (Index 3)
fork {
	"Testing QUANTIZED Pitch (Integers)...".postln;
	[0, 2, 4, 5, 7, 9, 11, 12].do { |note|
		// The .round(1) is technically redundant here since I typed integers,
		// but this is the math your button will do:
		var qVal = note.round(1); 
		
		"Playing Semitone: %".format(qVal).postln;
		~trackManager.setParam(3, \pitch, qVal);
		~trackManager.setParam(3, \spectralPitch, qVal);
		0.4.wait;
	}
};