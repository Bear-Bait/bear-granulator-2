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

This moving quickly so the instructions might be wrong! I will ask the AI to rewrite them after I can afford more AI credits!! !! !

I'm running on mac mini with 24 GB of ran. Full blast, 25% cpu. Will be taking advatage of that head room. I think it could run better on headless linux and eventually I will make a stripped version for rasipi.

Given the exceptional single-core performance and memory bandwidth of the **Mac Mini M4**, the previous constraints—designed for standard hardware—are no longer applicable. We are shifting the "S-4 RIVAL" from a "mobile-optimized" architecture to a 


Rewrite the above

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

## Overview

A 4-track granular synthesis sampler built for high-performance hardware.

## Current Platform

**Mac Mini M4** with 24GB RAM, running at ~25% CPU utilization at full capacity. Excellent headroom for feature expansion and real-time processing.

## Architecture Notes

- **Primary target**: macOS (current development)
- **Planned variants**: 
  - Headless Linux (optimized performance)
  - Raspberry Pi version (resource-constrained port)

## Status


# S-4 RIVAL: Feature Roadmap (M4 Optimized)

## 1. Audio-Rate LFO Modulation
**Priority:** HIGH | **Status:** Recommended for M4

**Current:** LFOs run at control-rate (.kr) — 750Hz update rate, causes zipper noise on resonant filters.

**Upgrade:** Move all LFO modulation to audio-rate (.ar) at 48kHz native.

**Benefits:**
- Eliminates zipper artifacts
- Enables FM synthesis with metallic textures
- Sub-millisecond modulation precision

**Target File:** `core/track-manager.scd`

---

## 2. 4x Oversampled Saturation
**Priority:** HIGH | **Status:** Recommended for M4

**Current:** Distortion runs at standard sample rate, causing digital aliasing.

**Upgrade:** 4x upsampling chain (192kHz) → non-linear saturation → 4x downsampling with anti-aliasing filter.

**Benefits:**
- Analog-like "creamy" saturation
- No digital harshness or artifacts
- Leverages M4's vectorized math performance

**Target File:** `core/grain-engine.scd` (lines 257–295)

---

## 3. 128-Band Resonator (DynKlank)
**Priority:** MEDIUM | **Status:** Recommended for M4

**Current:** 48-band morphing resonator using parallel filters.

**Upgrade:** Replace with DynKlank UGen for 128-band architecture.

**Benefits:**
- Professional spectral resolution
- Richer harmonic textures
- **CPU target:** <30% per track

**Target File:** Master bus filterbank initialization

---

## 4. Real-Time Playhead Visualization
**Priority:** HIGH | **Status:** Recommended for M4

**Current:** Static waveform display with polling lag.

**Upgrade:** Hardware-timed playhead pushed via `SendReply.ar` at 60–120Hz to GPU-rendered UserView.

**Benefits:**
- Sample-locked visual tracking
- Zero UI latency
- Real-time recording visualization

**Target File:** `\s4SpectralEngine` and `\s4GrainEngine` SynthDefs

### 

**High-Resolution Desktop Architecture**.

This plan prioritizes **Signal Purity**, **Sample-Accurate Modulation**, and **Spectral Density** over CPU conservation.

---

# S-4 RIVAL: M4 Extreme Performance Plan (Phase 5+)

## 1. Global Audio-Rate (`.ar`) Signal Path

**Status:** Recommended for M4 | **Priority:** High

* **The Upgrade:** Eliminate `.kr` (Control Rate) for all internal modulation. Migrate every instance of `Bus.control` to `Bus.audio`.
* **The Rationale:** On the M4, the overhead of calculating modulators at 48kHz instead of 750Hz is negligible. Native `.ar` modulation eliminates "zipper noise" on high-resonance filters and enables "Audio-Rate FM" where LFOs can reach audible frequencies for metallic textures.
* **Action Item:** Update `modulator.scd` to use `.ar` for all LFO and Random UGens.

---

## 2. 4x Oversampled "Color" Section

**Status:** Recommended for M4 | **Priority:** High (Sonic Fidelity)

* **The Upgrade:** Wrap nonlinear modules (Distortion, Bit-Crusher, Saturation) in oversampling blocks.
* **The Rationale:** Digital distortion at standard sample rates creates "aliasing"—unwanted frequencies that fold back into the audible range, making high-end textures sound "brittle."
* **Implementation:**
* Upsample the signal 4x (to 192kHz).
* Apply `.tanh` or `SoftClipAmp8`.
* Downsample with an anti-aliasing filter.


* **Result:** A "warm," analog-modeled saturation that rivals boutique hardware.

---

## 3. Concurrent Engine: `GrainBuf` + `Warp1`

**Status:** Recommended for M4 | **Priority:** Medium (Versatility)

* **The Upgrade:** Run both the Granular Engine (`GrainBuf`) and the Spectral Engine (`Warp1`) simultaneously per track, rather than as a toggle.
* **The Rationale:** With 24GB of RAM and M4 bandwidth, you can manage dual high-resolution buffer readers without dropouts.
* **Benefit:** This allows for **Layered Sculpting**. You can use `Warp1` to create a "frozen spectral bed" while `GrainBuf` adds rhythmic "shards" or "sculpted pulses" on top of the same audio material.

---

## 4. Ultra-Density 96-Band Resonator

**Status:** Recommended for M4 | **Priority:** High

* **The Upgrade:** Increase the resonator density from 48 bands to **96 or 128 bands** per track.
* **The Rationale:** The M4's ability to handle vectorized math allows for massive parallel filter banks.
* **Implementation:** Replace individual filter objects with `DynKlank.ar` or `Klank.ar`, driven by a `Buffer` containing 128 precise frequency ratios.
* **Result:** The resonator shifts from sounding like "a group of filters" to "a physical resonant object," providing a much smoother morphing experience across the frequency spectrum.

---

## 5. System-Wide DC Safety & Headroom

**Status:** Mandatory for High-Power Use | **Priority:** Critical

* **The Upgrade:** Integrate `LeakDC.ar` and `Limiter.ar` as permanent fixtures on the `s4MasterBus`.
* **The Rationale:** High-resonance, oversampled filters can easily create massive energy peaks and DC offset (silent speaker-damaging voltage).
* **Benefit:** Allows the user to push the "sculpting" controls to extreme limits without fear of digital clipping or hardware damage.

---

## Technical Summary for Mac Mini M4

| Component | Standard Plan (Subpar) | M4 Extreme Plan (Target) |
| --- | --- | --- |
| **Modulation** | `.kr` (Control Rate) | **`.ar` (Audio Rate)** |
| **Granulation** | Single-Engine Mode | **Parallel Multi-Engine** |
| **Filter Density** | 48 Bands | **96 - 128 Bands** |
| **Distortion** | Standard `.tanh` | **4x Oversampled Saturation** |
| **CPU Target** | < 50% | **Unlimited (Single-Core Max)** |

---

### Implementation Note

To implement the 128-band resonator effectively on your M4, I recommend using the **`DynKlank`** UGen. It is significantly more efficient for large banks and allows you to update the frequencies, amplitudes, and ring times (decay) of all 128 bands simultaneously via `ControlBus` arrays.

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
<!-- gptel--bounds: ((response (1121 2042) (2043 3816))) -->
<!-- End: -->
