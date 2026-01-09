 (
  // Visual Pitch Monitor (Guitar Tuner Style)
  var win, pitchText, noteText, centsText, canvas;
  var pitchSynth, oscListener;
  var currentFreq = 440, currentNote = "A", currentCents = 0;
  var noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];

  // Create window
  win = Window("Pitch Monitor", Rect(100, 100, 400, 300))
      .background_(Color.black)
      .front;

  // Frequency display (big number)
  pitchText = StaticText(win, Rect(10, 10, 380, 60))
      .string_("--- Hz")
      .align_(\center)
      .font_(Font("Monaco", 48, true))
      .stringColor_(Color.fromHexString("#89DDFF"));

  // Note name display
  noteText = StaticText(win, Rect(10, 80, 380, 50))
      .string_("--")
      .align_(\center)
      .font_(Font("Monaco", 36, true))
      .stringColor_(Color.fromHexString("#C3E88D"));

  // Cents deviation display
  centsText = StaticText(win, Rect(10, 140, 380, 30))
      .string_("0 cents")
      .align_(\center)
      .font_(Font("Monaco", 18))
      .stringColor_(Color.white);

  // Visual tuner needle
  canvas = UserView(win, Rect(50, 180, 300, 100))
      .background_(Color.gray(0.1))
      .drawFunc_({
          var centerX = 150, centerY = 80;
          var angle, needleLength = 60;
          var centsNormalized = currentCents.clip(-50, 50) / 50.0;  // -1 to 1

          // Draw scale marks
          Pen.strokeColor = Color.gray(0.3);
          Pen.width = 1;
          11.do({ |i|
              var x = i.linlin(0, 10, 20, 280);
              Pen.line(x @ 10, x @ 20);
          });
          Pen.stroke;

          // Center line (in-tune)
          Pen.strokeColor = Color.fromHexString("#C3E88D");
          Pen.width = 2;
          Pen.line(centerX @ 10, centerX @ 30);
          Pen.stroke;

          // Needle
          angle = centsNormalized * 0.7;  // ±0.7 radians
          Pen.strokeColor = if(currentCents.abs < 5, {
              Color.fromHexString("#C3E88D")  // Green if in tune
          }, {
              Color.fromHexString("#FF5370")  // Red if out of tune
          });
          Pen.width = 3;
          Pen.line(
              centerX @ centerY,
              (centerX + (needleLength * sin(angle))) @ (centerY - (needleLength * cos(angle)))
          );
          Pen.stroke;

          // Dot at pivot
          Pen.fillColor = Color.white;
          Pen.addArc(centerX @ centerY, 5, 0, 2pi);
          Pen.fill;
      });

  // Pitch detection synth
  pitchSynth = {
      var in, freq, hasFreq;

      // Get audio from Track 1 output bus
      in = Mix.ar(InFeedback.ar(~trackManager.getTrack(0).audioBus, 2));

      // Pitch detection
      # freq, hasFreq = Pitch.kr(in,
          initFreq: 440,
          minFreq: 60,    // C2
          maxFreq: 4000,  // ~B7
          execFreq: 30,   // Update 30 times per second
          ampThreshold: 0.02,
          median: 7
      );

      // Send pitch via OSC
      SendReply.kr(Impulse.kr(30), '/pitch', [freq, hasFreq]);

      Silent.ar;
  }.play;

  // OSC listener for pitch updates
  oscListener = OSCFunc({ arg msg;
      var freq = msg[3];
      var hasFreq = msg[4];
      var midiNote, noteName, octave, cents;

      if(hasFreq > 0, {
          currentFreq = freq;

          // Convert to MIDI note number
          midiNote = freq.cpsmidi;

          // Get note name and octave
          noteName = noteNames[midiNote.round % 12];
          octave = (midiNote / 12).floor - 1;
          currentNote = noteName ++ octave.asString;

          // Calculate cents deviation
          currentCents = (midiNote - midiNote.round) * 100;

          // Update GUI
          {
              pitchText.string_(freq.round(0.1).asString ++ " Hz");
              noteText.string_(currentNote);
              centsText.string_(currentCents.round(1).asString ++ " cents");
              canvas.refresh;
          }.defer;
      }, {
          // No pitch detected
          {
              pitchText.string_("--- Hz");
              noteText.string_("--");
              centsText.string_("0 cents");
          }.defer;
      });
  }, '/pitch');

  // Cleanup on window close
  win.onClose_({
      pitchSynth.free;
      oscListener.free;
      "Pitch monitor closed".postln;
  });

  "✅ Pitch Monitor opened - monitors Track 1 output".postln;
)