/*
═══════════════════════════════════════════════════════════════════
PATTERN LIBRARY - Core System
═══════════════════════════════════════════════════════════════════

30 built-in sequencer patterns organized by category.
Includes tributes to Hiroshi Yoshimura and Brian Eno.

Categories:
- Yoshimura (5 patterns inspired by "Green" album)
- Eno (3 patterns inspired by "Music for Airports")
- Terrestrial (8 world music scales)
- Microtonal (5 xenharmonic systems)
- Rhythmic (4 polyrhythmic patterns)
- Mathematical (5 algorithmic generators)

*/

~patternLibrary = (
	patterns: Dictionary.new,

	// Initialize library with 30 built-in patterns
	init: { arg self;
		"Initializing pattern library...".postln;

		// ═════════════════════════════════════════════════════
		// YOSHIMURA CATEGORY (5 patterns)
		// ═════════════════════════════════════════════════════

		// 1. CREEK (The Archetype)
		// Pentatonic with wide jumps, odd phrase length (7 notes) over 64 steps
		self.register(
			name: \yoshimuraCreek,
			category: \yoshimura,
			type: \pitch,
			generator: {
				var pentatonic = [0, 2, 4, 7, 9];  // F Major Pentatonic
				var intervals = [9, -5, 10, -7, 12, -9, 7];  // Wide jumps (6ths, 10ths)
				var pattern = Array.newClear(64);
				var pitch = pentatonic.choose;

				64.do({ |i|
					var interval = intervals[i % 7];  // 7-note phrase
					pitch = (pitch + interval).clip(-12, 24);
					// Snap to pentatonic scale
					pitch = pentatonic.minItem({ |deg| (pitch - deg).abs });
					pattern[i] = pitch;
				});
				pattern;
			},
			description: "Creek - Pentatonic with wide interval jumps (6ths, 10ths), 7-note phrase creates phasing effect"
		);

		// 2. FEEL (Quartal Voicings)
		// Stacked fourths (D-G-C-F) played as broken chord
		self.register(
			name: \yoshimuraFeel,
			category: \yoshimura,
			type: \pitch,
			generator: {
				var quartalChord = [0, 5, 10, 15];  // Stacked perfect fourths
				var pattern = Array.newClear(64);

				// Play chord tones in upward/random order with spaces
				64.do({ |i|
					if(i % 3 == 0, {
						pattern[i] = quartalChord[i % quartalChord.size];
					}, {
						pattern[i] = 0;  // Rest
					});
				});
				pattern;
			},
			description: "Feel - Quartal harmony (stacked fourths), sparse broken chord with silence"
		);

		// 3. GREEN (Hocketing Ostinato)
		// Call-and-response between bass pulse and decorative trill
		self.register(
			name: \yoshimuraGreen,
			category: \yoshimura,
			type: \pitch,
			generator: {
				var pattern = Array.fill(64, 0);

				// Bass pulse: Root - Fifth (every 8 steps)
				(0, 8..63).do({ |i|
					pattern[i] = 0;  // Root
				});
				(4, 12..63).do({ |i|
					pattern[i] = 7;  // Fifth
				});

				// Upper trill: 5-6-5-3 (fills between bass notes)
				(2, 10..63).do({ |i|
					pattern[i] = 9;  // 6th
				});
				(6, 14..63).do({ |i|
					pattern[i] = 4;  // 3rd
				});

				pattern;
			},
			description: "Green - Hocketing (call-and-response) between bass pulse and melodic trill"
		);

		// 4. WIND CHIMES (Non-directional)
		// Pentatonic without tension notes, no melodic resolution
		self.register(
			name: \yoshimuraWindChimes,
			category: \yoshimura,
			type: \pitch,
			generator: {
				var pentatonic = [0, 2, 4, 7, 9];  // No 4th or 7th (no tension)
				var pattern = Array.fill(64, { |i|
					// Slight bias toward middle register
					var weights = [1, 2, 3, 2, 1];
					pentatonic.wchoose(weights.normalizeSum);
				});
				pattern;
			},
			description: "Wind Chimes - Pentatonic without tension notes, weighted toward middle register"
		);

		// 5. WATER (Flowing Pentatonic Walk)
		// Stepwise motion through pentatonic scale, always moving
		self.register(
			name: \yoshimuraWater,
			category: \yoshimura,
			type: \pitch,
			generator: {
				var pentatonic = [0, 2, 4, 7, 9, 12, 14, 16];  // Two octaves
				var pattern = Array.newClear(64);
				var currentIndex = 3;  // Start mid-scale

				64.do({ |i|
					pattern[i] = pentatonic[currentIndex];
					// Random walk: up, down, or stay (weighted toward motion)
					currentIndex = (currentIndex + [-1, 0, 1].wchoose([0.4, 0.2, 0.4]))
						.clip(0, pentatonic.size - 1);
				});
				pattern;
			},
			description: "Water - Flowing stepwise motion through pentatonic scale, liquid movement"
		);

		// ═════════════════════════════════════════════════════
		// ENO CATEGORY (3 patterns)
		// ═════════════════════════════════════════════════════

		// 6. AIRPORTS (16-note melodic sequence)
		// From Ambient 1 - C minor, stepwise motion
		self.register(
			name: \enoAirports,
			category: \eno,
			type: \pitch,
			generator: {
				var sequence = [0, 3, 7, 3, 12, 10, 7, 5, 3, 7, 10, 12, 15, 12, 7, 3];
				var pattern = Array.fill(64, { |i|
					sequence[i % sequence.size];
				});
				pattern;
			},
			description: "Airports - 16-note C minor sequence with stepwise motion (Music for Airports)"
		);

		// 7. AMBIENT CHORDS (Polyrhythmic durations)
		// Chord tones with irregular durations (4, 6, 5, 3 pattern)
		self.register(
			name: \enoPolyChords,
			category: \eno,
			type: \pitch,
			generator: {
				var chords = [
					[0, 3, 7],    // C minor
					[5, 10, 12],  // F, Bb, C
					[3, 7, 10],   // Eb, G, Bb
					[-2, 3, 7]    // Bb, Eb, G
				];
				var durations = [4, 6, 5, 3];  // Polyrhythm
				var pattern = Array.newClear(64);
				var pos = 0;
				var chordIndex = 0;

				while { pos < 64 } {
					var dur = durations[chordIndex % durations.size];
					var chord = chords[chordIndex % chords.size];

					dur.do({ |i|
						if(pos + i < 64, {
							pattern[pos + i] = chord[i % chord.size];
						});
					});

					pos = pos + dur;
					chordIndex = chordIndex + 1;
				};
				pattern;
			},
			description: "Ambient Chords - Polyrhythmic chord tones (4-6-5-3 pattern) in C minor"
		);

		// 8. DISCREET MUSIC (Overlapping loops)
		// Different loop lengths create phase relationships
		self.register(
			name: \enoDiscreet,
			category: \eno,
			type: \pitch,
			generator: {
				var loop1 = [0, 4, 7, 11];    // 4-note loop
				var loop2 = [0, 3, 7, 10, 14]; // 5-note loop
				var pattern = Array.fill(64, { |i|
					// Combine two loops of different lengths
					(loop1[i % loop1.size] + loop2[i % loop2.size]) / 2;
				});
				pattern;
			},
			description: "Discreet Music - Overlapping loops of different lengths create phase patterns"
		);

		// ═════════════════════════════════════════════════════
		// TERRESTRIAL CATEGORY (8 patterns)
		// ═════════════════════════════════════════════════════

		// 9. Pentatonic Major
		self.register(
			name: \pentatonicMajor,
			category: \terrestrial,
			type: \pitch,
			generator: {
				var scale = [0, 2, 4, 7, 9];
				Array.fill(64, { scale.choose });
			},
			description: "Major Pentatonic - Universal melodic scale (Chinese, African, blues)"
		);

		// 10. Pentatonic Minor
		self.register(
			name: \pentatonicMinor,
			category: \terrestrial,
			type: \pitch,
			generator: {
				var scale = [0, 3, 5, 7, 10];
				Array.fill(64, { scale.choose });
			},
			description: "Minor Pentatonic - Blues/rock foundation"
		);

		// 11. Japanese Hirajoshi
		self.register(
			name: \hirajoshi,
			category: \terrestrial,
			type: \pitch,
			generator: {
				var scale = [0, 2, 3, 7, 8];
				Array.fill(64, { scale.choose });
			},
			description: "Hirajoshi - Japanese traditional scale, distinctive semitone intervals"
		);

		// 12. Maqam Hijaz (Middle Eastern)
		self.register(
			name: \hijaz,
			category: \terrestrial,
			type: \pitch,
			generator: {
				var scale = [0, 1, 4, 5, 7, 8, 11];
				Array.fill(64, { scale.choose });
			},
			description: "Maqam Hijaz - Middle Eastern, augmented 2nd interval"
		);

		// 13. Raga Bhairav (Indian)
		self.register(
			name: \bhairav,
			category: \terrestrial,
			type: \pitch,
			generator: {
				var scale = [0, 1, 4, 5, 7, 8, 11];
				Array.fill(64, { scale.choose });
			},
			description: "Raga Bhairav - Indian classical, morning raga"
		);

		// 14. Dorian Mode
		self.register(
			name: \dorian,
			category: \terrestrial,
			type: \pitch,
			generator: {
				var scale = [0, 2, 3, 5, 7, 9, 10];
				Array.fill(64, { scale.choose });
			},
			description: "Dorian - Minor with raised 6th, jazz/funk feel"
		);

		// 15. Phrygian Mode
		self.register(
			name: \phrygian,
			category: \terrestrial,
			type: \pitch,
			generator: {
				var scale = [0, 1, 3, 5, 7, 8, 10];
				Array.fill(64, { scale.choose });
			},
			description: "Phrygian - Spanish/flamenco character, flat 2nd"
		);

		// 16. Whole Tone
		self.register(
			name: \wholeTone,
			category: \terrestrial,
			type: \pitch,
			generator: {
				var scale = [0, 2, 4, 6, 8, 10];
				Array.fill(64, { scale.choose });
			},
			description: "Whole Tone - Debussy's dreamlike scale, all whole steps"
		);

		// ═════════════════════════════════════════════════════
		// MICROTONAL CATEGORY (5 patterns)
		// ═════════════════════════════════════════════════════

		// 17. 24-TET (Quarter-tones)
		self.register(
			name: \quarterTone,
			category: \microtonal,
			type: \pitch,
			generator: {
				var scale = Array.series(24, 0, 0.5);
				Array.fill(64, { scale.choose });
			},
			description: "24-TET - Quarter-tone equal temperament, Middle Eastern microtones"
		);

		// 18. 31-TET (Meantone approximation)
		self.register(
			name: \meantone31,
			category: \microtonal,
			type: \pitch,
			generator: {
				var scale = Array.series(31, 0, 12/31);
				Array.fill(64, { scale.choose });
			},
			description: "31-TET - Approximates 1/4-comma meantone, Renaissance tuning"
		);

		// 19. Just Intonation (5-limit)
		self.register(
			name: \justIntonation,
			category: \microtonal,
			type: \pitch,
			generator: {
				var scale = [0, 2.04, 3.86, 4.98, 7.02, 8.84, 10.88];  // Pure ratios
				Array.fill(64, { scale.choose });
			},
			description: "Just Intonation - Pure harmonic ratios (5-limit), no beating"
		);

		// 20. Bohlen-Pierce (13-step tritave)
		self.register(
			name: \bohlenPierce,
			category: \microtonal,
			type: \pitch,
			generator: {
				var scale = [0, 1.87, 3.37, 4.98, 6.38, 7.82, 9.24, 10.67, 11.95, 13.36, 14.68, 16.04, 17.28];
				Array.fill(64, { scale.choose });
			},
			description: "Bohlen-Pierce - 13-step tritave scale, 'extraterrestrial' harmony"
		);

		// 21. Carlos Alpha (78 cents)
		self.register(
			name: \carlosAlpha,
			category: \microtonal,
			type: \pitch,
			generator: {
				var scale = Array.series(16, 0, 0.65);  // 78 cent steps
				Array.fill(64, { scale.choose });
			},
			description: "Carlos Alpha - Wendy Carlos's 78-cent scale, xenharmonic"
		);

		// ═════════════════════════════════════════════════════
		// RHYTHMIC CATEGORY (4 patterns)
		// ═════════════════════════════════════════════════════

		// 22. Euclidean 7/64
		self.register(
			name: \euclidean7,
			category: \rhythmic,
			type: \position,
			generator: {
				var hits = 7;
				var steps = 64;
				var pattern = Array.fill(steps, 0);
				var stepSize = steps / hits;

				hits.do({ |i|
					var index = (i * stepSize).round.asInteger;
					pattern[index] = 0.5;  // Position jump
				});
				pattern;
			},
			description: "Euclidean 7/64 - 7 evenly-spaced hits, West African rhythm"
		);

		// 23. Fibonacci Rhythm
		self.register(
			name: \fibonacci,
			category: \rhythmic,
			type: \position,
			generator: {
				var fib = [1, 1, 2, 3, 5, 8, 13, 21];
				var pattern = Array.fill(64, 0);
				var pos = 0;

				fib.do({ |interval|
					pos = (pos + interval) % 64;
					pattern[pos] = 0.3;
				});
				pattern;
			},
			description: "Fibonacci - Hit points based on Fibonacci sequence"
		);

		// 24. Golden Ratio Rhythm
		self.register(
			name: \goldenRatio,
			category: \rhythmic,
			type: \position,
			generator: {
				var phi = (1 + 5.sqrt) / 2;
				var pattern = Array.fill(64, 0);
				var pos = 0;

				16.do({ |i|
					pos = (pos + (phi * 4)) % 64;
					pattern[pos.round.asInteger] = 0.3;
				});
				pattern;
			},
			description: "Golden Ratio - Spacing based on φ (1.618...)"
		);

		// 25. Prime Numbers
		self.register(
			name: \primeNumbers,
			category: \rhythmic,
			type: \position,
			generator: {
				var primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61];
				var pattern = Array.fill(64, 0);

				primes.do({ |p|
					if(p < 64, { pattern[p] = 0.4 });
				});
				pattern;
			},
			description: "Prime Numbers - Hits on prime-numbered steps (2, 3, 5, 7, 11...)"
		);

		// ═════════════════════════════════════════════════════
		// MATHEMATICAL CATEGORY (5 patterns)
		// ═════════════════════════════════════════════════════

		// 26. Sine Wave Contour
		self.register(
			name: \sineWave,
			category: \mathematical,
			type: \pitch,
			generator: {
				Array.fill(64, { |i|
					((i / 64 * 2pi).sin * 12).round;
				});
			},
			description: "Sine Wave - Smooth melodic contour, ±12 semitones"
		);

		// 27. Sawtooth Wave
		self.register(
			name: \sawtoothWave,
			category: \mathematical,
			type: \pitch,
			generator: {
				Array.fill(64, { |i|
					((i % 16) - 8);
				});
			},
			description: "Sawtooth - Repeating ascending ramp, -8 to +7"
		);

		// 28. Random Walk
		self.register(
			name: \randomWalk,
			category: \mathematical,
			type: \pitch,
			generator: {
				var pattern = Array.newClear(64);
				pattern[0] = 0;

				(1..63).do({ |i|
					pattern[i] = (pattern[i-1] + [0, 1, -1].choose).clip(-12, 12);
				});
				pattern;
			},
			description: "Random Walk - Markov chain, single-step motion"
		);

		// 29. Exponential Curve
		self.register(
			name: \exponential,
			category: \mathematical,
			type: \pitch,
			generator: {
				Array.fill(64, { |i|
					((i / 64).pow(2) * 24).round;
				});
			},
			description: "Exponential - Accelerating ascent, 0 to 24 semitones"
		);

		// 30. Accelerando
		self.register(
			name: \accelerando,
			category: \mathematical,
			type: \position,
			generator: {
				Array.fill(64, { |i|
					if((i.pow(1.5) % 8) < 1, { 0.2 }, { 0 });
				});
			},
			description: "Accelerando - Increasing density over time, position jumps"
		);

		// ═════════════════════════════════════════════════════
		// ARPEGGIO CATEGORY (24 patterns)
		// ═════════════════════════════════════════════════════

		// MAJOR TRIADS (3 patterns - 1, 2, 3 octaves)
		// 31. Major Triad - 1 octave
		self.register(
			name: \arpMajor1Oct,
			category: \arpeggio,
			type: \pitch,
			generator: {
				var chord = [0, 4, 7];  // C Major
				Array.fill(64, { |i| chord.wrapAt(i) });
			},
			description: "Major triad arpeggio - 1 octave (C-E-G)"
		);

		// 32. Major Triad - 2 octaves
		self.register(
			name: \arpMajor2Oct,
			category: \arpeggio,
			type: \pitch,
			generator: {
				var chord = [0, 4, 7, 12, 16, 19];  // C Major 2 octaves
				Array.fill(64, { |i| chord.wrapAt(i) });
			},
			description: "Major triad arpeggio - 2 octaves"
		);

		// 33. Major Triad - 3 octaves
		self.register(
			name: \arpMajor3Oct,
			category: \arpeggio,
			type: \pitch,
			generator: {
				var chord = [0, 4, 7, 12, 16, 19, 24, 28, 31];  // 3 octaves
				Array.fill(64, { |i| chord.wrapAt(i) });
			},
			description: "Major triad arpeggio - 3 octaves"
		);

		// MINOR TRIADS (3 patterns)
		// 34. Minor Triad - 1 octave
		self.register(
			name: \arpMinor1Oct,
			category: \arpeggio,
			type: \pitch,
			generator: {
				var chord = [0, 3, 7];  // C Minor
				Array.fill(64, { |i| chord.wrapAt(i) });
			},
			description: "Minor triad arpeggio - 1 octave (C-Eb-G)"
		);

		// 35. Minor Triad - 2 octaves
		self.register(
			name: \arpMinor2Oct,
			category: \arpeggio,
			type: \pitch,
			generator: {
				var chord = [0, 3, 7, 12, 15, 19];
				Array.fill(64, { |i| chord.wrapAt(i) });
			},
			description: "Minor triad arpeggio - 2 octaves"
		);

		// 36. Minor Triad - 3 octaves
		self.register(
			name: \arpMinor3Oct,
			category: \arpeggio,
			type: \pitch,
			generator: {
				var chord = [0, 3, 7, 12, 15, 19, 24, 27, 31];
				Array.fill(64, { |i| chord.wrapAt(i) });
			},
			description: "Minor triad arpeggio - 3 octaves"
		);

		// MAJOR 7TH (3 patterns) - Your original liveStranger pattern
		// 37. Major 7th - 1 octave
		self.register(
			name: \arpMaj71Oct,
			category: \arpeggio,
			type: \pitch,
			generator: {
				var chord = [0, 4, 7, 11];  // Cmaj7
				Array.fill(64, { |i| chord.wrapAt(i) });
			},
			description: "Major 7th arpeggio - 1 octave (Cmaj7)"
		);

		// 38. Major 7th - 2 octaves (LIVE STRANGER)
		self.register(
			name: \liveStranger,
			category: \arpeggio,
			type: \pitch,
			generator: {
				var chord = [0, 4, 7, 11, 14, 11, 7, 4];  // Synthwave classic
				Array.fill(64, { |i| chord.wrapAt(i) });
			},
			description: "Live Stranger - Classic synthwave arpeggio (Cmaj7, 2 oct)"
		);

		// 39. Major 7th - 3 octaves
		self.register(
			name: \arpMaj73Oct,
			category: \arpeggio,
			type: \pitch,
			generator: {
				var chord = [0, 4, 7, 11, 12, 16, 19, 23, 24, 28, 31, 35];
				Array.fill(64, { |i| chord.wrapAt(i) });
			},
			description: "Major 7th arpeggio - 3 octaves"
		);

		// MINOR 7TH (3 patterns)
		// 40. Minor 7th - 1 octave
		self.register(
			name: \arpMin71Oct,
			category: \arpeggio,
			type: \pitch,
			generator: {
				var chord = [0, 3, 7, 10];  // Cm7
				Array.fill(64, { |i| chord.wrapAt(i) });
			},
			description: "Minor 7th arpeggio - 1 octave (Cm7)"
		);

		// 41. Minor 7th - 2 octaves
		self.register(
			name: \arpMin72Oct,
			category: \arpeggio,
			type: \pitch,
			generator: {
				var chord = [0, 3, 7, 10, 12, 15, 19, 22];
				Array.fill(64, { |i| chord.wrapAt(i) });
			},
			description: "Minor 7th arpeggio - 2 octaves"
		);

		// 42. Minor 7th - 3 octaves
		self.register(
			name: \arpMin73Oct,
			category: \arpeggio,
			type: \pitch,
			generator: {
				var chord = [0, 3, 7, 10, 12, 15, 19, 22, 24, 27, 31, 34];
				Array.fill(64, { |i| chord.wrapAt(i) });
			},
			description: "Minor 7th arpeggio - 3 octaves"
		);

		// DOMINANT 7TH (3 patterns)
		// 43. Dominant 7th - 1 octave
		self.register(
			name: \arpDom71Oct,
			category: \arpeggio,
			type: \pitch,
			generator: {
				var chord = [0, 4, 7, 10];  // C7
				Array.fill(64, { |i| chord.wrapAt(i) });
			},
			description: "Dominant 7th arpeggio - 1 octave (C7) - blues/jazz"
		);

		// 44. Dominant 7th - 2 octaves
		self.register(
			name: \arpDom72Oct,
			category: \arpeggio,
			type: \pitch,
			generator: {
				var chord = [0, 4, 7, 10, 12, 16, 19, 22];
				Array.fill(64, { |i| chord.wrapAt(i) });
			},
			description: "Dominant 7th arpeggio - 2 octaves"
		);

		// 45. Dominant 7th - 3 octaves
		self.register(
			name: \arpDom73Oct,
			category: \arpeggio,
			type: \pitch,
			generator: {
				var chord = [0, 4, 7, 10, 12, 16, 19, 22, 24, 28, 31, 34];
				Array.fill(64, { |i| chord.wrapAt(i) });
			},
			description: "Dominant 7th arpeggio - 3 octaves"
		);

		// DIMINISHED (3 patterns)
		// 46. Diminished - 1 octave
		self.register(
			name: \arpDim1Oct,
			category: \arpeggio,
			type: \pitch,
			generator: {
				var chord = [0, 3, 6, 9];  // C diminished (symmetrical)
				Array.fill(64, { |i| chord.wrapAt(i) });
			},
			description: "Diminished arpeggio - 1 octave (symmetrical, tense)"
		);

		// 47. Diminished - 2 octaves
		self.register(
			name: \arpDim2Oct,
			category: \arpeggio,
			type: \pitch,
			generator: {
				var chord = [0, 3, 6, 9, 12, 15, 18, 21];
				Array.fill(64, { |i| chord.wrapAt(i) });
			},
			description: "Diminished arpeggio - 2 octaves"
		);

		// 48. Diminished - 3 octaves
		self.register(
			name: \arpDim3Oct,
			category: \arpeggio,
			type: \pitch,
			generator: {
				var chord = [0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30, 33];
				Array.fill(64, { |i| chord.wrapAt(i) });
			},
			description: "Diminished arpeggio - 3 octaves"
		);

		// AUGMENTED (3 patterns)
		// 49. Augmented - 1 octave
		self.register(
			name: \arpAug1Oct,
			category: \arpeggio,
			type: \pitch,
			generator: {
				var chord = [0, 4, 8];  // C augmented (symmetrical)
				Array.fill(64, { |i| chord.wrapAt(i) });
			},
			description: "Augmented arpeggio - 1 octave (symmetrical, dreamy)"
		);

		// 50. Augmented - 2 octaves
		self.register(
			name: \arpAug2Oct,
			category: \arpeggio,
			type: \pitch,
			generator: {
				var chord = [0, 4, 8, 12, 16, 20];
				Array.fill(64, { |i| chord.wrapAt(i) });
			},
			description: "Augmented arpeggio - 2 octaves"
		);

		// 51. Augmented - 3 octaves
		self.register(
			name: \arpAug3Oct,
			category: \arpeggio,
			type: \pitch,
			generator: {
				var chord = [0, 4, 8, 12, 16, 20, 24, 28, 32];
				Array.fill(64, { |i| chord.wrapAt(i) });
			},
			description: "Augmented arpeggio - 3 octaves"
		);

		// SUS CHORDS (3 patterns)
		// 52. Sus2 - 1 octave
		self.register(
			name: \arpSus21Oct,
			category: \arpeggio,
			type: \pitch,
			generator: {
				var chord = [0, 2, 7];  // Csus2
				Array.fill(64, { |i| chord.wrapAt(i) });
			},
			description: "Sus2 arpeggio - 1 octave (open, ambiguous)"
		);

		// 53. Sus2 - 2 octaves
		self.register(
			name: \arpSus22Oct,
			category: \arpeggio,
			type: \pitch,
			generator: {
				var chord = [0, 2, 7, 12, 14, 19];
				Array.fill(64, { |i| chord.wrapAt(i) });
			},
			description: "Sus2 arpeggio - 2 octaves"
		);

		// 54. Sus4 - 1 octave
		self.register(
			name: \arpSus41Oct,
			category: \arpeggio,
			type: \pitch,
			generator: {
				var chord = [0, 5, 7];  // Csus4
				Array.fill(64, { |i| chord.wrapAt(i) });
			},
			description: "Sus4 arpeggio - 1 octave (tension, wants resolution)"
		);

		"Pattern library initialized: % patterns".format(self.patterns.size).postln;
		self;
	},

	// Register a pattern
	register: { arg self, name, category, type, generator, description;
		self.patterns[name] = (
			name: name,
			category: category,
			type: type,  // \pitch or \position
			generator: generator,
			description: description
		);
	},

	// Get pattern by name
	get: { arg self, name;
		self.patterns[name];
	},

	// Get all patterns in category
	getByCategory: { arg self, category;
		self.patterns.values.select({ |p| p.category == category });
	},

	// Get all category names
	getCategories: { arg self;
		[\yoshimura, \eno, \terrestrial, \microtonal, \rhythmic, \mathematical, \arpeggio];
	},

	// Generate pattern array from pattern name
	generate: { arg self, name;
		var pattern = self.patterns[name];
		if(pattern.notNil, {
			pattern.generator.value;
		}, {
			"Pattern not found: %".format(name).warn;
			Array.fill(64, 0);  // Return zeros if not found
		});
	},

	// List all pattern names
	listNames: { arg self;
		self.patterns.keys.asArray.sort;
	},

	// Search patterns by keyword
	search: { arg self, keyword;
		self.patterns.select({ |p|
			p.name.asString.containsi(keyword) or: {
				p.description.containsi(keyword)
			};
		});
	}
);

// Initialize on load
~patternLibrary = ~patternLibrary.init;

"✓ Pattern library loaded - 54 patterns available".postln;
"  Categories: Yoshimura (5), Eno (3), Terrestrial (8), Microtonal (5), Rhythmic (4), Mathematical (5), Arpeggio (24)".postln;
"  Access via: ~patternLibrary.generate(\\liveStranger)".postln;

/*
Usage Examples:

// Generate a pattern
var pattern = ~patternLibrary.generate(\yoshimuraCreek);

// Apply to track
~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);

// List all patterns
~patternLibrary.listNames;

// Get patterns by category
~patternLibrary.getByCategory(\yoshimura);

// Search
~patternLibrary.search("pentatonic");
*/
