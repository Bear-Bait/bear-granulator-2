# Sigur Rós Preset - Quick Start Guide

## 🎵 What Is This?

A generative ambient preset inspired by:
- **Sigur Rós** - "Hoppípolla" (glacial beauty, slow builds)
- **Brian Eno** - "1/1" (infinite sustain, harmonic shimmer)  
- **Hiroshi Yoshimura** - "Creek" (pentatonic drift, wide intervals)

Creates ultra-slow, evolving ambient textures that rival professional ambient records.

---

## 🚀 Quick Start (3 Steps)

### 1. Boot BEARULATOR
```supercollider
s.boot;
"main.scd".loadRelative;
```

### 2. Load a Sample
Best samples:
- **Rhodes piano** (sustained notes)
- **Female vocal** ("ah" or "ooh")
- **Bell/Chime** (clean, tonal)

Load into Track 1 via GUI or:
```supercollider
~trackManager.getTracks[0].recorder.loadSample("/path/to/sample.wav");
```

### 3. Run the Preset
```supercollider
"tests/sigur-ros-test.scd".loadRelative;
```

This runs a **step-by-step test** that builds the preset gradually so you can hear each layer.

---

## 📋 Alternative Methods

### Method A: Step-by-Step Test (Recommended)
```supercollider
"tests/sigur-ros-test.scd".loadRelative;
```
- Builds preset gradually over ~25 seconds
- Shows what each component does
- Good for learning

### Method B: Full Preset (Instant)
```supercollider
"presets/sigur_ros_generative.scd".loadRelative;
```
- Applies all settings instantly
- Good once you know what it does

### Method C: Load Saved Preset
```supercollider
// After running Method A or B once, the preset is saved:
~presets.load("sigur_ros_generative");
```

### Method D: Easy Loader
```supercollider
"LOAD-SIGUR-ROS.scd".loadRelative;
```
- Simplest option (just wraps Method B)

---

## 🎛️ Key Parameters

| Parameter | Value | Effect |
|-----------|-------|--------|
| `timeStretch` | 0.1 | 10x slower playback |
| `overlap` | 64 | Dense grain cloud |
| `grainSize` | 0.3 | Long grains (smooth) |
| `pitchJitter` | 1.0 | Pentatonic melody |
| `spectralMix` | 0.3 | Infinite sustain layer |
| `reverbMix` | 0.7 | 70% cathedral reverb |
| `shimmerMix` | 0.5 | 50% octave shimmer |

---

## 🎚️ Adjustments (While Playing)

### Make it Slower
```supercollider
~trackManager.setParam(0, \timeStretch, 0.05);  // 20x slower (!)
```

### More Shimmer
```supercollider
~trackManager.setParam(0, \shimmerMix, 0.8);
```

### Bigger Space
```supercollider
~trackManager.setParam(0, \reverbMix, 0.9);
~trackManager.setParam(0, \reverbSize, 1.0);
```

### More Infinite Sustain
```supercollider
~trackManager.setParam(0, \spectralMix, 0.5);
~trackManager.setParam(0, \spectralFreeze, 0.8);
```

---

## 🎼 What You'll Hear

**First 30 seconds:**
- Dense grain texture begins
- Time slows to glacial pace
- Pentatonic melody emerges

**1-3 minutes:**
- Spectral freeze creates infinite sustain
- Cathedral reverb fills space
- Octave shimmer adds angelic quality

**5-10 minutes:**
- Melody drifts through pentatonic scale
- Wide interval leaps (Yoshimura style)
- Evolving harmonic texture

---

## ⚠️ Troubleshooting

### "Variable not defined" error
Make sure you have the **opening quote**:
```supercollider
// CORRECT:
"tests/sigur-ros-test.scd".loadRelative;

// WRONG (missing opening quote):
tests/sigur-ros-test.scd".loadRelative;
```

### No sound
1. Make sure a sample is loaded in Track 1
2. Check Track 1 volume: `~trackManager.setVolume(0, 0.8);`
3. Press PLAY button in GUI

### Sounds wrong
Best samples are **sustained tones**:
- ✅ Rhodes piano, vocal "ah", bells
- ❌ Drums, bass, percussive sounds

### CPU too high
Reduce overlap:
```supercollider
~trackManager.setParam(0, \overlap, 32);  // Was 64
```

---

## 💾 Saving Your Version

After tweaking:
```supercollider
~presets.save("my_sigur_ros_variation");
```

---

## 🎹 Sample Suggestions

### Free Samples
- **Philharmonia Orchestra** - Free sample library (sustained strings)
- **Freesound.org** - Search "rhodes sustained", "vocal ah", "bell"
- **VCSL** (Versilian Community Sample Library) - Free, high quality

### In BEARULATOR
If you have samples in `samples/` directory:
```supercollider
~trackManager.getTracks[0].recorder.loadSample(
    basePath +/+ "samples/drones/your_sample.wav"
);
```

---

## 🎵 Musical Context

This preset recreates the aesthetic of:

**Sigur Rós - "Hoppípolla" (2005)**
- Ultra-slow builds over 3-5 minutes
- Bowed guitar with octave effects
- Glacial patience, huge reverb

**Brian Eno - "1/1" (Ambient 1, 1978)**
- Infinite sustain via tape loops
- Overlapping melodic fragments
- Harmonic shimmer, no rhythm

**Hiroshi Yoshimura - "Creek" (Green, 1986)**
- Pentatonic melodies with wide interval leaps
- Minimalist, patient, water-like movement
- Inspired by nature sounds

---

## 📊 Technical Details

**Grain Engine:**
- 64 overlapping grains (dense cloud)
- 0.3s grain size (smooth, not glitchy)
- 0.1 timeStretch = 10x slower

**Pitch Sequencer:**
- 64-step pentatonic pattern
- Wide leaps every 8 steps (Yoshimura style)
- Smooth stepwise motion otherwise

**Spectral Engine:**
- 30% blend with grain engine
- Partial freeze (0.5) for sustain
- 0.2 rate (almost frozen)

**Space FX:**
- 90% reverb size (cathedral)
- 70% reverb mix (very wet)
- 50% shimmer mix (+1 octave)
- 0.7 shimmer feedback (long tail)

**CPU Usage:** ~20-25% on M4 Mac Mini

---

## 🚀 Next Steps

1. Try with different samples (vocal vs Rhodes vs bells)
2. Adjust `timeStretch` (0.05-0.3) for different tempos
3. Add more tracks with complementary settings
4. Record 10-minute evolving pieces

---

**Created:** 2026-01-27  
**Requires:** BEARULATOR v2.4 (shimmer effects)  
**Difficulty:** Beginner (just run the test file!)
