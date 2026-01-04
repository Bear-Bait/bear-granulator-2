# S-4 RIVAL: Granular Synthesis Workstation

```
      Hey Jim, come take a ride on the grape leaf raft!

                    ___
                  _/   \_
                 |  o_o  |
                 |   ^   |
                  \_____/
                    | |
               _____|_|_____
              /             \
         ~~~~|  GRAPE LEAF   |~~~~
          ~~~|     RAFT      |~~~
           ~~\_______________/~~
             ~~~~~~~~~~~~~~~
```

This is a 4-track granular synthesis sampler!

## 🎯 Active TODOs

### Completed ✅
- [x] Remove loop buttons from viewfinder (Reset Loop, Select All)
- [x] Add Play/Stop transport buttons to viewfinder
- [x] Add spectral amplitude slider to viewfinder
- [x] Fix volume issues (grain boost at 2.0x, soft limiter using tanh)
- [x] Move all spectral engine sliders to viewfinder (Mix, Amp, Window Size, Overlaps, Rate, Pitch, Smear, Freeze)

### Planned 📋
- [ ] Create recording viewfinder for live audio scrubbing/selection
- [ ] Send recorded regions to granulator viewfinder

---

## 🚀 THE M4 ULTIMATE SPEC (Phase 9+)

### 🌌 Visual Flash (Doom Material Enhanced)
- [x] **FFT Spectrogram Overlay:** Real-time frequency heatmap behind the waveform **(Phase 11 ✅)**
- [x] **Grain Pulse Animation:** Visual "pings" on the viewfinder where grains are triggered **(Phase 11 ✅)**
- [ ] **Neon Glow Rendering:** Hardware-accelerated "glow" effects for the playhead and loop regions

### 🔊 Overlooked Audio Components
- [x] **Dual-Topology Analog-Modeled Filter (Per Track):** **(Phase 10 ✅)**
  - ZDF (Zero-Delay Feedback) Ladder Filter - Liquid resonance with self-oscillation
  - State Variable Filter (SVF) - LP/HP/BP morph capability
  - Pre-Filter Drive Stage - Nonlinear saturation (.tanh) for filter "grit"
  - Bass Loss Compensation - Maintains low-end at high resonance
- [ ] **Audio-Rate Modulation:** Upgrade from 750Hz control-rate to 48kHz audio-rate
- [ ] **Transient Bypass Logic:** Keeps drum transients sharp during heavy spectral stretching
- [x] **Phase-Aligned Granulation:** Prevents phase-cancellation in low-frequency textures **(Phase 9 ✅)**
- [x] **Master Bus "Glue" Compressor:** Final stage compressor to bond the 4 tracks together **(Phase 9 ✅)**

---

## 💻 **HARDWARE PLATFORM**

**Target:** Mac Mini M4
**RAM:** 24 GB
**CPU Usage:** ~25% at full capacity (75% headroom available!)
**Architecture:** Optimized for M4 single-core performance & high memory bandwidth

**Future Targets:**
- Headless Linux build (server deployment)
- Raspberry Pi stripped version (portable/embedded)

**Development Status:** ⚠️ Active development - Documentation evolving rapidly

**📖 For complete feature list, see [FEATURES.md](FEATURES.md)**

---

## QUICK START

### Step 1: Boot the SuperCollider Server

**IMPORTANT**: Before running `main.scd`, you need to boot the audio server. Different systems require different setups:

#### Mac (Built-in Audio)
```supercollider
// Default Mac audio - just boot it
s.boot;
```

####  Mac with Audio Interface (MOTU, Focusrite, etc.)
```supercollider
// Option 1: Use your interface as default
s.boot;

// Option 2: Explicitly select your interface
(
Server.default = Server.local;
s.options.device = "MOTU UltraLite mk4";  // <- Change to YOUR interface name
s.boot;
)

// To see all available devices:
ServerOptions.devices;
```

#### 🐧 Linux (JACK or ALSA)
```supercollider
// JACK (recommended for low latency)
(
Server.default = Server.local;
s.options.device = "JackRouter";
s.boot;
)

// ALSA (simpler setup)
s.boot;  // Uses default ALSA device
```

#### Windows (ASIO or MME)
```supercollider
// ASIO (recommended - low latency)
(
Server.default = Server.local;
s.options.device = "ASIO : Your Interface Name";  // e.g., "ASIO : Focusrite USB"
s.boot;
)

// To see all available devices:
ServerOptions.devices;
```

### Step 2: Wait for Boot Confirmation
Look for this in the Post window:
```
*** Welcome to SuperCollider 3.14.1 ***
Server 'localhost' running.
```

### Step 3: Run Main
```supercollider
// Execute this file
"main.scd".loadRelative;
```

The GUI will open automatically!

---

## 🎛️ WHAT YOU'RE LOOKING AT

### 4 Track Tabs
- **TRACK 1-4**: Full granular synthesis controls per track
  - Load audio files or record live input
  - Grain engine (size, overlap, position, pitch)
  - Color FX (distortion, bit crusher, compression, noise)
  - Space FX (reverb, delay, shimmer)
  - Loop window selector (drag waveform to set loop points)

### Master Tab
- **PLAY ALL / STOP ALL**: Global transport
- **GLOBAL SPEED**: Control pitch of all tracks at once
- **TRACK OVERVIEW**: Quick mix controls + VU meters
- **CPU MONITOR**: Keep it green!

---

## 🎵 BASIC WORKFLOW

### 1. Load Audio into Track 1
1. Click **TRACK 1** tab
2. Click **Load Audio File**
3. Navigate to `samples/stock/` and load one of these:
   - **a11wlk01.wav** - "Columbia, this is Houston" (Apollo 11 mission audio) 🚀
   - **a11wlk01-44_1.aiff** - Same audio, different format
   - **SinedPink.aiff** - Synthetic test tone
4. Click **PLAY** to hear grains

**Pro tip**: The Apollo 11 sample is PERFECT for granular processing - try tiny grain sizes (0.01s) for a frozen space transmission texture!

### 2. Sculpt the Grains
- **Grain Size**: How long each grain is (0.001s - 60s)
- **Overlap**: How many grains play at once (1-128)
- **Position**: Where in the buffer to read from (0-1)
- **Pitch**: Transpose in semitones (-24 to +24)

### 3. Set Loop Window
- Drag on the waveform display to select a region
- The grain engine will only play from this region
- Use arrow keys or mouse wheel to zoom

### 4. Add Effects
- **Color FX ON**: Enable distortion/crusher/noise chain
- **Space FX ON**: Enable reverb/delay/shimmer

### 5. Mix & Monitor
- Go to **MASTER** tab
- Adjust track volumes
- Watch VU meters (aim for green/yellow, avoid red)
- Keep CPU below 50% average

---

## ESSENTIAL SC COMMANDS

See `generic-commands.scd` for a full cheat sheet. Here are the must-knows:

### Emergency Stop
```supercollider
Cmd-.    // Mac
Ctrl-.   // Windows/Linux
// Kills all sound immediately!
```

### Server Management
```supercollider
s.boot;          // Start server
s.reboot;        // Restart clean
s.quit;          // Shut down
s.freeAll;       // Kill all synths but keep server running
```

### Monitoring
```supercollider
s.meter;         // Audio level meters
s.scope;         // Oscilloscope
s.plotTree;      // See all running synths
s.avgCPU;        // Check CPU usage
```

### Volume Control
```supercollider
s.volume = -20;  // Set output volume in dB
s.mute;          // Mute all output
s.unmute;        // Unmute
```

---

## 🎨 MATERIAL MODES (Phase 6)

Each track has 3 material modes:

1. **TAPE (Loop)**: Classic looping granular synthesis
   - Good for: Ambient textures, pitch shifting loops

2. **POLY (Sample)**: One-shot sample playback per grain
   - Good for: Rhythmic glitches, stutters

3. **LIVE (Input)**: Real-time granulation of live audio input
   - Good for: Live processing, feedback loops

---

## 🔧 TROUBLESHOOTING

### No Sound?
1. Check server is booted: `s.serverRunning`
2. Check volume isn't muted: `s.volume`
3. Hit **PLAY** button (tracks start STOPPED by default)
4. Check audio interface is selected correctly
5. Verify your interface is powered on and connected

### Audio Crackling?
1. Check CPU usage (Master tab)
2. Increase server buffer size:
   ```supercollider
   s.quit;
   s.options.blockSize = 256;  // or 512, 1024
   s.boot;
   ```

### GUI Looks Weird?
- Make sure you have **DejaVu Sans Mono** font installed
- Or edit `gui/four-track-view.scd` to use a different monospace font

### Recording Too Quiet?
- Input is boosted 3x automatically
- Check your interface's input gain
- Try the Input selector (In 1-8) to choose the right channel

---

## 📁 PROJECT STRUCTURE

```
granular/
├── main.scd                  # Start here!
├── generic-commands.scd      # SC command reference
├── core/                     # Engine modules
│   ├── grain-engine.scd
│   ├── track-manager.scd
│   ├── buffer-recorder.scd
│   └── ...
├── gui/                      # Visual interface
│   ├── four-track-view.scd
│   ├── viewfinder.scd
│   └── ...
├── samples/                  # Audio samples
│   ├── stock/               # Included samples (Apollo 11, test tones)
│   ├── drones/              # Put your drone samples here
│   ├── percussion/          # Put your percussion here
│   └── field-recordings/    # Put your field recordings here
└── docs/                     # Development notes
```

---

## 🎧 STOCK SAMPLES

The `samples/stock/` folder includes some great starter material:

### Apollo 11 Mission Audio 🚀
- **a11wlk01-44_1k.aiff** - "Columbia, this is Houston..."
- Classic mission control transmission
- Perfect for granular processing - rich textures with voice, static, and space
- Try these settings:
  - Grain Size: 0.01s → frozen space transmission
  - Position: 0.3-0.7 → scan through the transmission
  - Pitch: -12 → deep space drone
  - Reverb Mix: 0.8 + Freeze: 1.0 → infinite space

### Test Tone
- **SinedPink.aiff** - Sine wave + pink noise blend
- Good for testing effects and understanding parameters
- Less exciting than Apollo 11 but useful for calibration

**Want more samples?** Drop any WAV/AIFF files into the samples folders!

---

## LEARNING PATH

1. **Start Simple**: Load one sample, hit play, adjust grain size
2. **Explore Position**: Move the position slider while playing
3. **Try Loop Windows**: Select different regions of your sample
4. **Add Pitch**: Transpose up/down while playing
5. **Layer Tracks**: Load different samples on tracks 2-4
6. **Mix Effects**: Start with reverb mix, then try delay
7. **Get Weird**: Crank the jitter, add noise, freeze the reverb

---

## 🌊 ADVANCED FEATURES

### Modulation System (Phase 5)
- Click **MOD** button in any track
- 4 modulators per track (LFO, Envelope Follower, Random, etc.)
- Route to any parameter (pitch, grain size, position, etc.)

### Viewfinder (Phase 7)
- Click **LOOP VIEW** for popup waveform editor
- Zoom with arrow keys or mouse wheel
- Drag to select precise loop regions
- Works with both loaded files AND recorded buffers

---

## KNOWN ISSUES

- Waveform display uses temp files for recorded buffers
- Modulation window is a separate popup (not integrated)
- Track naming & preset system coming soon™

---

## YES YES YES!

Remember: There's no "right" way to use this. Granular synthesis is all about exploration.

- Try tiny grain sizes (0.001s) for frozen textures
- Try huge grain sizes (10s+) for slow morphing
- Crank overlap to 128 for dense clouds
- Use 1 overlap for clean playback
- Record your output and feed it back in!

Questions? Check `generic-commands.scd` or holler at Forrest.


```
      _____
     /     \
    | ^   ^ |
    |   o   |   
     \_____/
       | |
    ___| |___
   /         \
  |     x     |
   \_________/
```

<!-- Local Variables: -->
<!-- gptel-model: claude-haiku-4-5-20251001 -->
<!-- gptel--backend-name: "Claude-Haiku-4.5" -->
<!-- gptel-max-tokens: 6000 -->
<!-- gptel--bounds: ((response (1140 2102) (2110 7628))) -->
<!-- End: -->
