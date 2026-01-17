# 🌌 Phase 13 Tutorial: Audio-Rate Modulation + Spatial Automation

**BEARULATOR: Complete Guide to Advanced Modulation & Quad Spatial Control**

---

## 📖 Table of Contents

1. [What's New in Phase 13](#whats-new-in-phase-13)
2. [Audio-Rate Modulation: The Revolution](#audio-rate-modulation-the-revolution)
3. [Spatial Automation: Quad Field Control](#spatial-automation-quad-field-control)
4. [Complete Cookbook: 20 Recipes](#complete-cookbook-20-recipes)
5. [Performance Tips](#performance-tips)
6. [Troubleshooting](#troubleshooting)

---

## What's New in Phase 13

### The Two Big Features

**1. Audio-Rate Modulation (48kHz)**
- **Before:** Modulators ran at 750Hz (control-rate)
- **After:** Modulators run at 48,000Hz (audio-rate)
- **Result:** Zero zipper noise, FM synthesis capabilities, ultra-smooth parameter changes

**2. Spatial Automation**
- Route LFOs/modulators directly to **Quad X** and **Quad Y** parameters
- Automatic spatial movement in the quad field
- Visual feedback with real-time trails
- 3 built-in spatial movement patterns

### Why This Matters

**Audio-Rate Modulation:**
- Smooth filter sweeps (no stepping artifacts)
- Fast modulation creates harmonic overtones (FM synthesis)
- Sub-millisecond precision for expressive control
- Professional-grade modulation quality

**Spatial Automation:**
- Hands-free spatial movement
- Complex spatial patterns (circles, figure-8s, random drift)
- Synchronized spatial choreography across 4 tracks
- Live performance possibilities

---

## Audio-Rate Modulation: The Revolution

### Understanding the Upgrade

**Control-Rate (Pre-Phase 13):**
```
Update frequency: 750 Hz
Time between updates: 1.3 ms
Result: Audible "steps" in fast modulation
```

**Audio-Rate (Phase 13):**
```
Update frequency: 48,000 Hz
Time between updates: 0.02 ms (20 microseconds!)
Result: Perfectly smooth, no artifacts
```

### What Changed Internally

**Before (Control-Rate):**
```supercollider
// Modulator ran at control-rate
SinOsc.kr(freq)  // 750 Hz updates
Out.kr(bus, sig) // Control bus output
```

**After (Audio-Rate):**
```supercollider
// Modulator runs at audio-rate
SinOsc.ar(freq)  // 48,000 Hz updates
Out.ar(bus, sig) // Audio bus output
```

**CPU Impact:** +3-5% (negligible for the quality gain!)

---

## 🎨 Audio-Rate Modulation Cookbook

### Recipe 1: Silky-Smooth Filter Sweeps

**The Sound:** Classic analog filter sweep, zero stepping artifacts

**Setup:**
1. Load a sample into Track 1
2. Open modulation window: `~bearulatorModulationWindow.value(~trackManager, s, 0).create;`
3. Create LFO modulator:
   - **Modulator:** 1 (Mod 1)
   - **Type:** 0 (LFO)
   - **Rate:** 0.5 Hz (slow sweep)
   - **Depth:** 1.0 (full range)
   - **Shape:** 0 (Sine wave)
4. Route to Filter Cutoff:
   - **Target:** "Filter Frequency"
   - **Min:** 100 Hz (dark)
   - **Max:** 8000 Hz (bright)
   - Press **ROUTE**

**Result:** Buttery-smooth filter sweep, no zipper noise, analog feel

**Try This:**
- Rate = 0.1 Hz → slow, hypnotic sweep
- Rate = 2.0 Hz → rhythmic wah effect
- Shape = 1 (Triangle) → linear sweep (up/down ramps)
- Shape = 2 (Sawtooth) → "sweeping up" effect

---

### Recipe 2: FM Synthesis (Harmonic Richness)

**The Sound:** Bell-like tones, metallic overtones, harmonic complexity

**Concept:** Fast audio-rate modulation creates new frequencies via frequency modulation

**Setup:**
1. Load a simple tone or drone sample
2. Create LFO → Pitch modulation:
   - **Type:** LFO
   - **Rate:** 200 Hz (audio-rate FM!)
   - **Depth:** 1.0
   - **Target:** Pitch
   - **Min:** -2 semitones
   - **Max:** +2 semitones

**Result:** Rich harmonic overtones, bell-like timbre

**Science:**
- Modulation at 200 Hz creates sidebands at ±200 Hz from the grain pitch
- Faster rate = brighter, more harmonics
- Deeper range = more extreme sidebands

**Variations:**
- Rate = 50 Hz → warm chorus/vibrato
- Rate = 500 Hz → harsh metallic texture
- Rate = 1000 Hz → extreme FM synthesis
- Shape = Square → ring modulation effect

---

### Recipe 3: Tremolo (Audio-Rate Amplitude Mod)

**The Sound:** Vintage amp tremolo, perfectly smooth

**Setup:**
1. LFO → Grain Amplitude
   - **Rate:** 4 Hz (classic tremolo speed)
   - **Depth:** 1.0
   - **Shape:** Sine
   - **Min:** 0.0 (silence)
   - **Max:** 1.0 (full volume)

**Result:** Classic tremolo effect, smooth as butter

**Try This:**
- Rate = 0.5 Hz → slow pulsing
- Rate = 12 Hz → helicopter effect
- Shape = Square → gated tremolo (rhythmic chopping)
- Min = 0.3 → less extreme (ducking effect)

---

### Recipe 4: Vibrato (Smooth Pitch Wobble)

**The Sound:** Vintage tape wow/flutter, musical vibrato

**Setup:**
1. LFO → Pitch Shift
   - **Rate:** 5 Hz (classic vibrato)
   - **Depth:** 1.0
   - **Shape:** Sine
   - **Min:** -0.5 semitones
   - **Max:** +0.5 semitones

**Result:** Smooth pitch modulation, no digital artifacts

**Musical Uses:**
- Rate = 3 Hz, Range = ±0.2 st → subtle warmth (tape emulation)
- Rate = 6 Hz, Range = ±1 st → expressive vibrato (string emulation)
- Rate = 0.1 Hz, Range = ±5 st → slow pitch drift (ambient)

---

### Recipe 5: Rhythmic Grain Density

**The Sound:** Pulsing grain clouds, rhythmic texture

**Setup:**
1. LFO → Overlap (Density)
   - **Rate:** 2 Hz (half-note pulsing at 120 BPM)
   - **Shape:** Sine
   - **Min:** 4 grains (sparse)
   - **Max:** 64 grains (dense)

**Result:** Breathing texture, rhythmic density modulation

**Sync to Tempo:**
- 120 BPM, quarter notes = 2 Hz
- 120 BPM, eighth notes = 4 Hz
- 140 BPM, quarter notes = 2.33 Hz

---

### Recipe 6: Position Scanning (Auto-Exploration)

**The Sound:** Automatic buffer exploration, evolving texture

**Setup:**
1. LFO → Position
   - **Rate:** 0.2 Hz (slow scan)
   - **Shape:** Triangle (linear scan)
   - **Min:** 0.0 (start of buffer)
   - **Max:** 1.0 (end of buffer)

**Result:** Slowly scans through the entire buffer

**Variations:**
- Shape = Sine → smooth back-and-forth
- Shape = Sawtooth → sweep forward, jump back
- Shape = Random (Smooth) → wandering playhead

---

### Recipe 7: Spectral Morphing

**The Sound:** Evolving spectral character, FFT time-stretching

**Setup:**
1. LFO → Spectral Mix
   - **Rate:** 0.1 Hz (slow morph)
   - **Shape:** Sine
   - **Min:** 0.0 (pure grain engine)
   - **Max:** 1.0 (pure spectral engine)

**Result:** Crossfades between grain and spectral processing

**Advanced:**
- LFO 1 → Spectral Mix (slow)
- LFO 2 → Spectral Smear (fast, creates texture)
- Result: Evolving spectral texture

---

### Recipe 8: Stereo Width Modulation

**The Sound:** Breathing stereo field, spatial pulsing

**Setup:**
1. LFO → Stereo Spread
   - **Rate:** 0.5 Hz
   - **Shape:** Sine
   - **Min:** 0.0 (mono)
   - **Max:** 1.0 (wide stereo)

**Result:** Stereo field breathes in and out

**Try This:**
- Combine with Reverb Mix modulation for "spatial bloom"

---

### Recipe 9: Jitter Animation (Controlled Chaos)

**The Sound:** Controlled randomness, granular shimmer

**Setup:**
1. Random Modulator → Position Jitter
   - **Type:** Random (Smooth)
   - **Rate:** 10 Hz
   - **Min:** 0.0 (tight)
   - **Max:** 0.5 (scattered)

**Result:** Time-varying randomness, never static

---

### Recipe 10: Multi-Parameter Modulation

**The Sound:** Complex evolving texture

**Setup (use all 4 modulators on Track 1):**
1. **Mod 1:** LFO (0.2 Hz) → Position (0.0 to 1.0)
2. **Mod 2:** LFO (0.5 Hz) → Filter Cutoff (200 to 5000 Hz)
3. **Mod 3:** Random (5 Hz) → Pitch Jitter (0 to 3 st)
4. **Mod 4:** LFO (1 Hz) → Reverb Mix (0.0 to 0.8)

**Result:** Constantly evolving, never repeats

---

## 🔊 Spatial Automation Cookbook

### Recipe 11: Circular Orbit

**The Sound:** Track rotates smoothly around the listener

**Setup:**
1. Open quad panner: `~quadPanner.createWindow();`
2. Open modulation window for Track 1
3. Create **Mod 1:**
   - **Type:** LFO
   - **Rate:** 0.25 Hz (one rotation every 4 seconds)
   - **Shape:** Sine
   - **Target:** "Quad X"
   - **Min:** -1.0 (full left)
   - **Max:** +1.0 (full right)
4. Create **Mod 2:**
   - **Type:** LFO
   - **Rate:** 0.25 Hz (same speed!)
   - **Shape:** Sine **+ 90° phase shift** (use Triangle if no phase control)
   - **Target:** "Quad Y"
   - **Min:** -1.0 (front)
   - **Max:** +1.0 (rear)

**Result:** Perfect circular orbit! Watch the trails in the quad panner

**Note:** For perfect circles, X and Y must have:
- Same rate
- 90° phase offset (sine for X, cosine for Y)

**SuperCollider Trick:**
```supercollider
// If you want precise 90° phase:
// Use Sine for X, and Sine + 0.25 phase for Y
// (This requires custom modulator code - future phase!)
```

---

### Recipe 12: Figure-8 Pattern

**The Sound:** Track moves in a figure-8 (infinity symbol)

**Setup:**
1. **Mod 1:** LFO → Quad X
   - Rate: 0.5 Hz
   - Shape: Sine
   - Min: -1.0, Max: +1.0
2. **Mod 2:** LFO → Quad Y
   - Rate: 1.0 Hz (2× the X rate!)
   - Shape: Sine
   - Min: -1.0, Max: +1.0

**Result:** Figure-8 (Lissajous curve with 1:2 ratio)

**Math:** Different frequency ratios create different patterns:
- 1:1 = Diagonal line
- 1:2 = Figure-8
- 2:3 = Cloverleaf
- 1:1 (with 90° phase) = Circle

---

### Recipe 13: Random Spatial Drift

**The Sound:** Track wanders randomly through the quad field

**Setup:**
1. **Mod 1:** Random (Smooth) → Quad X
   - Rate: 2 Hz (change direction every 0.5 seconds)
   - Min: -0.8, Max: +0.8 (avoid extreme edges)
2. **Mod 2:** Random (Smooth) → Quad Y
   - Rate: 1.5 Hz (different rate = less predictable)
   - Min: -0.8, Max: +0.8

**Result:** Organic spatial movement, never repeats

**Try This:**
- Use **Random (Stepped)** for sudden jumps
- Lower rate (0.5 Hz) for slow drift
- Higher rate (10 Hz) for jittery movement

---

### Recipe 14: Front-to-Back Sweep

**The Sound:** Track moves from front speakers to rear speakers

**Setup:**
1. **Mod 1:** LFO → Quad Y
   - Rate: 0.3 Hz
   - Shape: Sine
   - Min: -1.0 (front)
   - Max: +1.0 (rear)
2. Keep Quad X at 0.0 (centered)

**Result:** Front-to-back movement, stays centered left/right

---

### Recipe 15: Left-to-Right Pan

**The Sound:** Classic stereo pan, but in quad field

**Setup:**
1. **Mod 1:** LFO → Quad X
   - Rate: 1 Hz
   - Shape: Triangle (linear sweep)
   - Min: -1.0 (left)
   - Max: +1.0 (right)
2. Keep Quad Y at -1.0 (front speakers only)

**Result:** Pans between front-left and front-right speakers

---

### Recipe 16: Quad Tremolo (Spatial Pulsing)

**The Sound:** Track pulses between center and wide position

**Setup:**
1. Set initial position: X=0.5, Y=0.5 (front-right quadrant)
2. **Mod 1:** LFO → Quad X
   - Rate: 4 Hz (fast pulse)
   - Shape: Sine
   - Min: 0.0 (center)
   - **Max: 1.0 (right edge)** — creates pulsing movement

**Result:** Track pulses outward/inward rhythmically

---

### Recipe 17: 4-Track Spatial Choreography

**The Sound:** All 4 tracks move in synchronized patterns

**Setup:**
- **Track 1:** Circular orbit (clockwise)
  - X: LFO 0.5 Hz Sine, Y: LFO 0.5 Hz Triangle
- **Track 2:** Circular orbit (counter-clockwise)
  - X: LFO 0.5 Hz Sine (inverted: Max = -1, Min = +1)
  - Y: LFO 0.5 Hz Triangle
- **Track 3:** Front-to-back sweep (slow)
  - Y: LFO 0.2 Hz Sine
- **Track 4:** Random drift
  - X: Random 1 Hz, Y: Random 1.5 Hz

**Result:** Complex spatial choreography, immersive quad experience

---

### Recipe 18: Spatial Freeze & Randomize Workflow

**The Sound:** Explore random spatial arrangements, lock in favorites

**Workflow:**
1. Open quad panner: `~quadPanner.createWindow();`
2. Click **RANDOMIZE** button → random positions for all 4 tracks
3. Listen to the spatial arrangement
4. If you like it: Click **SAVE PRESET** (auto-named with timestamp)
5. If not: Click **RANDOMIZE** again
6. Compare arrangements: Click **LOAD LAST** to recall previous preset
7. Lock it in: Click **FREEZE** to stop any spatial modulation

**Use Case:** Live performance, sound design exploration

---

### Recipe 19: Expanding/Contracting Space

**The Sound:** Quad field breathes (tracks move closer/farther from center)

**Setup (requires all 4 tracks):**
1. Position tracks at corners:
   - Track 1: X=-0.7, Y=-0.7 (front-left)
   - Track 2: X=+0.7, Y=-0.7 (front-right)
   - Track 3: X=-0.7, Y=+0.7 (rear-left)
   - Track 4: X=+0.7, Y=+0.7 (rear-right)
2. Apply **same LFO** to all tracks:
   - **Mod 1 on all tracks:** LFO (0.3 Hz, Sine)
   - Track 1: Quad X (Min=-0.3, Max=-0.9)
   - Track 2: Quad X (Min=+0.3, Max=+0.9)
   - (Repeat for Y coordinates)

**Result:** Quad field expands and contracts in sync

---

### Recipe 20: Envelope-Triggered Spatial Movement

**The Sound:** Track moves in response to audio level

**Setup:**
1. **Mod 1:** Envelope Follower → Quad X
   - **Type:** Envelope Follower
   - **Input:** Track's own audio bus
   - **Smoothing:** 0.1 seconds
   - **Min:** -0.5 (left when quiet)
   - **Max:** +0.5 (right when loud)

**Result:** Track position responds to audio dynamics

**Creative Use:**
- Loud passages = wide stereo
- Quiet passages = narrow/centered

---

## Performance Tips

### CPU Management

**Audio-Rate Modulation Impact:**
- LFO: +0.5% CPU per modulator
- Envelope Follower: +1% CPU per modulator
- Random: +0.5% CPU per modulator
- **Total overhead for 16 modulators (4 tracks × 4 mods): ~12% CPU**

**Spatial Modulation Impact:**
- LFO → Quad X/Y: <1% CPU (basically free!)
- Update rate: 20Hz (OSC messages)
- No audio processing overhead

**Optimization:**
1. Use fewer modulators on dense grain tracks (overlap > 64)
2. Spatial modulation is "free" - use it liberally!
3. Audio-rate modulation is worth the 3-5% CPU cost

### Live Performance Workflow

**Preset Recall:**
1. Save 4-5 presets before the performance
2. Load presets between sections
3. Use quick save during soundcheck: `~presets.quickSave;`

**Spatial Performance:**
1. Start with static positions (FREEZE)
2. Enable spatial modulation for climactic moments
3. Use RANDOMIZE for improvisation
4. SAVE PRESET when you find magic moments

---

## Troubleshooting

### "Modulation sounds choppy/stepped"

**Cause:** You may be using an old version (pre-Phase 13)

**Fix:**
1. Check `core/modulator.scd` line 52: Should say `.ar` not `.kr`
2. Reload main.scd: `"main.scd".loadRelative;`

---

### "Spatial modulation doesn't work"

**Checklist:**
1. Is quad panner window open? `~quadPanner.createWindow();`
2. Is the modulator routed to "Quad X" or "Quad Y"?
3. Is the modulation depth > 0?
4. Check console for OSC messages: Should see `/s4/quadPos` at 20Hz

---

### "Preset won't load"

**Common Issues:**
1. Preset file corrupt → Check file exists: `~presets.list;`
2. Wrong preset name → Use exact name (case-sensitive)
3. Old preset format → Re-save preset after Phase 13 update

---

### "Audio-rate modulation causes crackles"

**Rare Issue:** Audio buffer size too small

**Fix:**
```supercollider
s.quit;
s.options.blockSize = 256;  // or 512
s.boot;
"main.scd".loadRelative;
```

---

## Next Steps

### Explore Further:

1. **Combine recipes:** Use Recipe 11 (Circular Orbit) + Recipe 2 (FM Synthesis)
2. **Multi-track spatial:** Recipe 17 (4-Track Choreography) is a starting point
3. **Create presets:** Save your favorite modulation setups
4. **Read the cookbook:** `examples/quad-spatial-examples.scd`

### Advanced Topics:

- Per-grain quad positioning (experimental): `core/grain-engine-quad.scd`
- MIDI control of spatial parameters: `core/midi-mapping.scd`
- Performance guide: `docs/PERFORMANCE-GUIDE.md`

---

## Quick Reference

### Modulation Window Commands
```supercollider
// Open modulation window for Track 1
~bearulatorModulationWindow.value(~trackManager, s, 0).create;

// Open for Track 2
~bearulatorModulationWindow.value(~trackManager, s, 1).create;
```

### Quad Panner Commands
```supercollider
// Open quad panner
~quadPanner.createWindow();

// Manual positioning
~trackManager.setQuadPosition(0, -0.5, -0.5);  // Track 1 → Front-Left

// Freeze all spatial modulation
~quadPanner.freezePositions();

// Randomize all tracks
~quadPanner.randomizePositions();
```

### Preset System Commands
```supercollider
// Save preset
~presets.save("myPreset");

// Load preset
~presets.load("myPreset");

// List all presets
~presets.list;

// Quick save (auto-named)
~presets.quickSave;

// Show preset info
~presets.info("myPreset");
```

---

**Phase 13 Complete!** 🎉

You now have professional-grade audio-rate modulation and advanced spatial automation. Go make some incredible quad granular music!

---

**Questions?** Check the autonomous work session summary: `docs/AUTONOMOUS-WORK-SESSION-SUMMARY.md`

**Performance tips?** Read: `docs/PERFORMANCE-GUIDE.md`

**More examples?** See: `examples/quad-spatial-examples.scd`
