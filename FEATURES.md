# S-4 RIVAL: Complete Feature List

**Current Version:** v2.2 (deployed 2026-01-09)

## 🎵 CORE AUDIO ENGINES

### Granular Engine (GrainBuf) - v2.2 Enhanced
- **Grain Size:** 0.001s - 60s (exponential scaling)
- **Overlap:** 1-128 grains (massive density for M4)
- **Probability:** ✨ v2.2 - 0.0-1.0 (Bernoulli gate for rhythmic fracturing)
- **Position:** 0-1 (playback position in buffer)
- **Scan Speed:** -4 to +4 (continuous scanning, bidirectional)
- **Time Stretch:** ✨ v2.1 - 0.25x-4x (independent tempo scaling, pitch preserved)
- **Position Jitter:** 0-1 (amplitude of position sequence)
- **64-Step Position Sequence:** ✨ v2.1 - Sequenced position modulation (KeyStep Pro/Digitone standard)
- **Pitch Shift:** -24 to +24 semitones (formant-preserving)
- **Pitch Jitter:** 0-12 semitones (amplitude of pitch sequence)
- **64-Step Pitch Sequence:** ✨ v2.1 - Musical arpeggiator/sequencer (replaces random LFNoise)
- **Amplitude:** 0-1
- **Stereo Spread:** 0-1 (independent L/R grain timing)
- **Loop System:** Non-destructive loop windows with visual selection
- **Phase-Aligned Mode:** Zero-crossing aligned grains (prevents phase cancellation in bass)
- **Material Modes:** TAPE (loop), POLY (one-shot), LIVE (input granulation)

### Spectral Engine (Warp1) - M4 Extreme
- **Spectral Mix:** 0-1 (wet/dry blend with grain engine)
- **Spectral Amp:** 0-1 (independent amplitude)
- **Window Size:** 0.05-1.0s (FFT window, exponential)
- **Overlaps:** 1-8 (M4 handles 8 for buttery smooth spectral processing)
- **Rate:** -2 to +2 (playback rate, 0=freeze)
- **Pitch:** -24 to +24 semitones (spectral pitch shift)
- **Smear:** 0-1 (spectral smearing/blurring effect)
- **Freeze:** ON/OFF (spectral freeze toggle)

---

## 🎨 EFFECTS CHAINS

### Color FX Section (Nonlinear Processing)
- **Distortion:** 0-1 (soft saturation)
- **Bit Crusher:** 1-16 bits (sample rate reduction)
- **Compression:** 0-1 (dynamics control)
- **Noise Mix:** 0-1 (additive noise texture)
- **Global ON/OFF** toggle

### Space FX Section (Time-Based Effects)
**Reverb:**
- Mix: 0-1
- Room Size: 0-1
- Damping: 0-1
- Freeze: ON/OFF (infinite reverb tail)

**Delay:**
- Time: 0.01-2.0s
- Feedback: 0-1
- Mix: 0-1

**Shimmer:**
- Pitch: -12 to +24 semitones
- Window Size: 0.05-0.5s
- Mix: 0-1

**Global ON/OFF** toggle

---

## 🎚️ MODULATION SYSTEM

### 4 Modulators Per Track:
1. **LFO** - Sine/Square/Saw/Triangle waveforms
2. **Envelope Follower** - Amplitude tracking
3. **Random** - Sample & hold randomization
4. **Manual** - Direct parameter control

### Modulation Targets:
- Any grain parameter
- Any effect parameter
- Spectral engine parameters
- Real-time visual routing interface

---

## 📊 BUFFER & RECORDING SYSTEM

### 4-Track Architecture:
- Independent buffers per track
- 4-second default (expandable)
- ~2GB total synth memory allocation

### Material Modes:
1. **TAPE (Loop)** - Classic looping granular synthesis
2. **POLY (Sample)** - One-shot sample playback
3. **LIVE (Input)** - Real-time input granulation

### Input System:
- 8 input channels (MOTU Mk5 support)
- Input selector per track (In 1-8)
- 3x automatic input gain boost
- Real-time recording with visual feedback

### File Loading:
- WAV/AIFF support
- Drag-and-drop or file dialog
- Automatic buffer allocation
- Waveform visualization

---

## 🖥️ USER INTERFACE

### Main Window (Four-Track View)
- **Track Tabs (1-4):** Individual track controls
- **Master Tab:** Global controls, mix, CPU monitor
- **Play/Stop** per track
- **Material Mode Selector** (Tape/Poly/Live)
- **Input Channel Selector** (1-8)
- **Load Audio File** button
- **Record** button with visual feedback
- **VU Meters** per track
- **CPU Usage** monitor

### Viewfinder Window (Per Track) ⭐ ENHANCED
**Waveform Visualization:**
- Full waveform display with zoom/pan
- Loop boundary visualization (green start, red end)
- Grain size overlay (yellow box showing grain window)
- Position playhead (red line - parameter value)
- Real-time playhead @ 60Hz (cyan "Live" line when scanning)
- 5 visual layers with smooth overlay rendering

**Navigation:**
- **Arrow Keys:** Zoom in/out, Pan left/right
- **Mouse Wheel:** Zoom to cursor position
- **Shift+Right-Click:** Native SuperCollider zoom
- **G Key:** Zoom to grain level (3x grain size visible)
- **L Key:** Toggle loop boundaries
- **Drag Selection:** Set loop regions visually

**Transport:**
- **Play Button:** Start track playback
- **Stop Button:** Stop track playback
- **Refresh Button:** Reload waveform

**Complete Control Surface:**
- **Grain Controls (9 sliders):** All grain parameters with number boxes
- **Spectral Controls (8 sliders + freeze):** Full spectral engine access
- **Loop Display:** Real-time loop start/end values
- **Dual-mode controls:** Sliders + number boxes (type values, scroll, clip to range)

### Visual Layers (Viewfinder):
1. **Base:** Waveform (SoundFileView)
2. **Layer 1:** Loop boundaries (green/red fade zones)
3. **Layer 2:** Grain size window (yellow overlay)
4. **Layer 3:** Position parameter (red line)
5. **Layer 4:** Real-time playhead (cyan line, 60Hz updates via OSC)

---

## 🔊 MASTER BUS & MIXING

### Master Mix Bus:
- Individual track volume controls
- **Glue Compressor:** ✨ NEW - 2:1 soft-knee (bonds 4 tracks together)
  - Threshold: 0.6
  - Attack: 10ms
  - Release: 100ms
- **Soft Limiter:** tanh saturation (prevents clipping)
- **DC Offset Protection:** LeakDC (protects speakers)
- **Volume Boost:** 2x grain engine compensation
- Stereo output

### Signal Flow:
```
Input → Buffer → Grain Engine ↘
                               → Track Bus → Space FX → Mix Bus → Glue Compressor → Limiter → Master Out
      → Buffer → Spectral Engine ↗
```

---

## 🧮 PERFORMANCE (M4 Specific)

### Current State:
- **CPU Usage:** ~25% @ full capacity
- **RAM:** 24GB supported
- **Headroom:** 75% available for future expansion
- **Modulation Rate:** Control-rate @ ~750Hz
- **Update Rates:**
  - Grain overlay: 30fps
  - Real-time playhead: 60Hz
  - Visual refresh: Smooth, hardware-accelerated

### Quality Settings:
- **Max Grains:** 128 per track (64 per channel)
- **Spectral Interpolation:** Quality 4 (best for M4)
- **Spectral Overlaps:** Up to 8 (buttery smooth)
- **Buffer Allocation:** 1024×16 buffers
- **Memory:** ~2GB total synth memory

---

## 🎨 VISUAL THEME

**Doom Material Color Palette:**
- Background: `#262938` (dark blue-gray)
- Foreground: `#EEFFFF` (light cyan-white)
- Accent Cyan: `#89DDFF`
- Warning Red: `#ff5370`
- Success Green: `#c3e88d`
- Highlight Yellow: `#ffcb6b`
- Orange: `#f78c6c`
- Selection: `#cc7000`

**Typography:**
- Primary: DejaVu Sans Mono
- Fallback: Monaco
- Number boxes: Cyan on dark gray for visibility

---

## ✅ RECENTLY COMPLETED (Latest Session)

### v2.1 Engine Deployment (January 8, 2026) - MAJOR UPDATE
- ✅ **Click-Free Effect Switching** - SelectX with 50ms lag crossfading (fixes Issue #2: Filter Popping)
- ✅ **Parameter Collision Fix** - Renamed `mode` → `grainMode` (fixes Issue #5: Mode Collision)
- ✅ **Decoupled Time/Pitch** - Independent scanRate (time) and grainRate (pitch) for tape stop/freeze effects
- ✅ **64-Step Sequencer** - posSeq/pitchSeq arrays (KeyStep Pro/Digitone standard)
- ✅ **Musical Jitter** - Demand UGens replace LFNoise for repeatable, rhythmic modulation
- ✅ **Smooth Playhead Export** - Fixed "quantum jitter" bug in GUI visualization
- ✅ **Comprehensive Deployment Test** - Automated test suite verifying all v2.1 features

### Previous Session Highlights:
- ✅ Fixed shift+right-click zoom in viewfinder
- ✅ Fixed number box visibility (cyan text on dark gray background)
- ✅ Fixed number box functionality (scroll, keyboard input, range clipping)
- ✅ Added Play/Stop transport buttons to viewfinder
- ✅ Moved all spectral controls to viewfinder (cleaner main window)
- ✅ Added spectral amplitude control
- ✅ Fixed volume levels (2x boost, soft limiter)
- ✅ Added buffer nil-check protection in overlays
- ✅ **Master Bus Glue Compressor** - 2:1 soft-knee compressor for track cohesion
- ✅ **Phase-Aligned Granulation** - Zero-crossing aligned grains (prevents bass phase cancellation)
- ✅ **Dual-Topology Per-Track Filter (Phase 10)** - ZDF Ladder + SVF with drive stage
- ✅ **FFT Spectrogram Overlay (Phase 11)** - Real-time frequency visualization in viewfinder
- ✅ **Grain Pulse Animation (Phase 11)** - Visual feedback for grain density

---

## 🎛️ PHASE 10: PER-TRACK FILTER SYSTEM

### Dual-Topology Filter
Professional-grade filtering with two distinct topologies per track:

**ZDF Ladder Filter (0.0 - 0.33 on Topology slider):**
- Moog-style lowpass with resonance
- Liquid, musical resonance character
- Bass compensation at high resonance (prevents bass loss)
- Self-oscillation capability (up to 3.5 gain)

**State Variable Filter (0.33 - 1.0 on Topology slider):**
- Morph between LP/BP/HP (lowpass, bandpass, highpass)
- 0.33 = Pure Lowpass
- 0.66 = Pure Bandpass
- 1.0 = Pure Highpass
- Equal-power crossfading between types

### Filter Parameters (per track):
- **Cutoff:** 20Hz - 18kHz (exponential mapping)
- **Topology/Type:** 0-0.33 = Ladder, 0.33-1.0 = SVF morph
- **Resonance:** 0-1 (Q factor for SVF, gain for Ladder)
- **Drive:** Pre-filter saturation stage (0 = clean, 1 = saturated grit)
- **Filter Mix:** Dry/wet blend (0 = bypass, 1 = full wet)

### Signal Flow:
```
Grains → PitchShift → Filter (optional) → Color FX → Space FX → Output
                        ↓
                   Drive → [Ladder OR SVF] → Mix
```

---

## 🌈 PHASE 11: VISUAL FEEDBACK ENHANCEMENTS

### FFT Spectrogram Overlay
Real-time frequency visualization displayed behind the waveform:

**Technical Specs:**
- 10 frequency bands (40Hz - 16kHz, log-spaced)
- 60 time slices (2-second scrolling window)
- 30fps update rate (minimal CPU overhead)
- Cyan color-mapped heatmap (darker = quieter, brighter = louder)

**Implementation:**
- Server-side: 10× BPF analyzers with amplitude tracking
- OSC broadcast: `/s4_fft` @ 30Hz (10 values per message)
- Client-side: Scrolling buffer + Pen-based rendering

### Grain Pulse Animation
Visual feedback for grain density and playback activity:

**Features:**
- Expanding ring animation at playhead position
- Pulse rate tied to grain overlap parameter (higher overlap = faster pulses)
- Yellow color with alpha fade (0.4 max opacity)
- 5-25 pixel radius expansion
- Continuous animation during playback

**Purpose:**
- Immediate visual confirmation of grain activity
- Density visualization (overlap parameter feedback)
- Playback monitoring without audio

### Enhanced Viewfinder Layers:
1. **Layer 0:** FFT Spectrogram (frequency heatmap)
2. **Layer 1:** Loop boundaries (green start, red end)
3. **Layer 2:** Grain size window (yellow box)
4. **Layer 3:** Position parameter (red line)
5. **Layer 4:** Real-time playhead (cyan "Live" line)
6. **Layer 5:** Grain pulse animation (expanding rings)

---

## 🎛️ PHASE 12: MIDI, RECORDING, AND QUAD OUTPUT

### MIDI Control System
**KeyStep Pro Integration (Arturia):**
- 5 rotary encoder CC mappings (customizable)
- Polyphonic note triggering (4 MIDI channels → 4 tracks)
- Velocity-sensitive grain density boost
- Note number → playback rate via `.midiratio`
- Visual feedback in viewfinder:
  - Green pulses on note events
  - Cyan overlays on CC parameter changes

**Implementation:**
- File: `core/midi-mapping.scd`
- Visual feedback: `gui/viewfinder.scd` (lines 634-672)
- Default CC assignments:
  - CC 74 → Filter Cutoff (Track 1)
  - CC 71 → Grain Size (Track 1)
  - CC 76 → Overlap/Density (Track 1)
  - CC 77 → Spectral Mix (Track 1)
  - CC 78 → Filter Drive (Track 1)

### Recording Viewfinder
**Live Audio Capture with Region Selection:**
- Separate window for recording live input
- Real-time waveform visualization (SoundFileView)
- Region selection via mouse drag
- Send selected regions to any of 4 granulator tracks
- 8-channel input support (MOTU Mk5 compatible)
- Transport controls (Record/Stop/Play)
- 3x automatic input gain boost

**Workflow:**
1. Select input channel (In 1-8)
2. Press REC to start recording (up to 10 seconds default)
3. Press STOP to finish
4. Drag on waveform to select region
5. Choose target track (1-4)
6. Press "Send to Track" to transfer audio to granulator

**Implementation:**
- File: `gui/recording-viewfinder.scd`
- Uses `Buffer.copyData` for region extraction
- Non-destructive workflow (original recording preserved)

### Quad Speaker Output
**4-Channel Spatial Audio System:**
- 2D spatial positioning (X/Y coordinates)
- Equal-power quad panning
- Per-track spatial control
- 4-speaker layout: FL, FR, RL, RR (MOTU outputs 0-3)

**Features:**
- Interactive spatial GUI with drag-and-drop positioning
- Preset spatial layouts (Corners, Front Row, Circle, Center)
- Real-time spatial movement
- Master 48-band resonator processes all 4 channels
- Glue compressor on quad mix

**Implementation:**
- SynthDef: `core/mix-bus-quad.scd` (\s4MasterBusQuad)
- GUI: `gui/quad-panner.scd`
- Track manager method: `setQuadPosition(trackNum, x, y)`
- Test file: `tests/quad-speaker-test.scd`

**Quad Panning Formula:**
```supercollider
// Equal-power quad panning (X/Y → 4 speakers)
FL = sqrt((1 - X) * (1 - Y) * 0.5) * signal
FR = sqrt((1 + X) * (1 - Y) * 0.5) * signal
RL = sqrt((1 - X) * (1 + Y) * 0.5) * signal
RR = sqrt((1 + X) * (1 + Y) * 0.5) * signal
```

### Modulation Enhancements
**New Modulation Targets Added:**
- Shimmer Mix (spectral shimmer effect wet/dry)
- Filter Cutoff (already existed, now documented)

**Updated Modulation Targets (13 total):**
1. Grain Size
2. Density (Overlap)
3. Position
4. Pitch
5. Position Jitter
6. Pitch Jitter
7. Stereo Spread
8. Filter Frequency (Cutoff)
9. Filter Morph (Topology)
10. Reverb Mix
11. Delay Mix
12. **Shimmer Mix** ✨ NEW
13. (Filter Cutoff = Filter Frequency)

### Bug Fixes
- ✅ Fixed Play/Stop buttons in viewfinder (now use `\amp` parameter)
- ✅ Improved number box visibility (cyan text on dark gray)

---

## ⚡ PHASE 13: AUDIO-RATE MODULATION + SPATIAL AUTOMATION

### Audio-Rate Modulation (48kHz)
**Revolutionary Sound Quality Upgrade:**
- All modulators now run at **48,000 Hz** instead of 750 Hz control-rate
- **Zero zipper noise** - buttery smooth parameter changes
- **FM synthesis capabilities** - fast modulation creates harmonic overtones
- **Sub-millisecond precision** - ultra-responsive modulation

**Technical Implementation:**
- Changed all LFO oscillators from `.kr` to `.ar`
- Upgraded modulation buses from `Bus.control` to `Bus.audio`
- Updated mapper synths to use `In.ar` / `Out.ar`
- Minimal CPU increase (<5%) for massive quality improvement

**Files Modified:**
- `core/modulator.scd` - Audio-rate oscillators (lines 46-90)
- `core/track-manager.scd` - Audio bus allocation (line 425)

**Benefits:**
- Silky-smooth filter sweeps (no stepping artifacts)
- Audio-rate pitch modulation enables FM/ring mod effects
- Professional-grade modulation quality
- Future-proof for advanced synthesis techniques

### Spatial Modulation
**LFO → Quad Position Routing:**
- Route modulators directly to **quadX** and **quadY** parameters
- Automatic spatial movement controlled by LFOs
- 3 spatial movement patterns built-in

**Implementation:**
- Added `quadX` and `quadY` to modulation targets (gui/modulation-window.scd)
- Special routing via OSC for spatial parameter updates (track-manager.scd:475-513)
- 20Hz update rate to avoid OSC flooding

**Usage:**
```supercollider
// Open modulation window
~s4ModulationWindow.value(~trackManager, s, 0).create;

// Create LFO modulator
// Mod 1, Type 0 (LFO), Rate 0.5 Hz, Depth 1.0, Shape 0 (Sine)

// Route to Quad X
// Select "Quad X" from target menu
// Set Min: -1.0, Max: 1.0
// Press ROUTE

// Result: Track slowly oscillates left/right in quad field
```

**Creative Applications:**
- Circular orbits (Sine LFO → X, Cosine LFO → Y)
- Figure-8 patterns (different LFO rates on X/Y)
- Random spatial drift (Random modulator)
- Envelope-triggered spatial movement

### Per-Grain Quad Positioning
**Most Advanced Feature:**
- Each individual grain positioned independently in quad space
- 256 grains (64 per speaker) with spatial distribution
- 3 spatial modes: Random, Rotating, Expanding

**New SynthDef:** `\s4grainQuad`
**File:** `core/grain-engine-quad.scd`

**Parameters:**
- `spatialSpread` (0-1): Spatial field size (0=mono, 1=full quad)
- `spatialMode` (0-2): Movement pattern
  - 0 = Random positioning (each grain at random location)
  - 1 = Rotating (grains spiral around listener)
  - 2 = Expanding/Contracting (breathes in/out)
- `spatialRate` (Hz): Speed of spatial movement

**How It Works:**
1. Generates X/Y coordinates using LFNoise/SinOsc
2. Creates 4 independent grain clouds (FL, FR, RL, RR)
3. Applies equal-power panning per grain
4. Each speaker receives spatially-weighted grains

**Example:**
```supercollider
// Load quad grain engine
"core/grain-engine-quad.scd".loadRelative;

// Create quad grain synth (experimental)
~quadGrain = Synth(\s4grainQuad, [
    \bufnum, ~trackManager.getTracks[0].recorder.buffer,
    \grainSize, 0.1,
    \overlap, 16,
    \spatialSpread, 0.8,  // Wide field
    \spatialMode, 0,      // Random
    \spatialRate, 2.0,    // Movement speed
    \out, 0  // Channels 0-3
]);

// Try different modes
~quadGrain.set(\spatialMode, 1);  // Rotating cloud
~quadGrain.set(\spatialMode, 2);  // Breathing cloud
```

**Performance Notes:**
- Uses 256 grains total (same as stereo engine)
- Outputs 4 channels instead of 2
- Slightly higher CPU (~10-15%) due to quad panning math
- Best with overlap 8-32 for balanced spatial density

**Sound Design Ideas:**
- **Spatial Clouds:** Random mode + high overlap = diffuse atmosphere
- **Orbital Textures:** Rotating mode + medium grains = swirling motion
- **Breathing Pads:** Expanding mode + slow rate = organic movement
- **Quad Percussion:** Short grains + random mode = spatial hits

---

## 💾 PHASE 14: PRESET SYSTEM

### Complete State Save/Load
**Production-ready preset management for the entire S-4 RIVAL system:**

**What Gets Saved:**
- All 4 track parameters (80+ parameters per track)
- Grain engine settings (size, overlap, position, pitch, jitter, etc.)
- Spectral engine state (mix, rate, freeze, smear, pitch, etc.)
- Filter settings (frequency, resonance, morph, drive, mix)
- Effects chains (Color FX: distortion, crusher, compression, noise)
- Space FX (reverb, delay, shimmer with all parameters)
- Mix controls (volume, pan, mute, solo per track)
- Spatial positions (quad X/Y coordinates for all tracks)
- Material modes (TAPE/POLY/LIVE)
- Modulation targets (reference only - not auto-restored)

**File Format:**
- `.scd` files (SuperCollider dictionary format)
- Human-readable and version-safe
- Stored in `presets/` directory (auto-created)

**Public API:**
```supercollider
// Save current state
~presets.save("myPreset");

// Load preset
~presets.load("myPreset");

// Quick save (auto-named with timestamp)
~presets.quickSave;

// List all presets
~presets.list;

// Show preset details
~presets.info("myPreset");

// Delete preset
~presets.delete("myPreset");
```

**Example Presets (10 included):**
1. **ambient_pad** - Dense grain cloud, shimmer reverb
2. **rhythmic_glitch** - Sparse grains, spectral freeze
3. **drone_machine** - Low pitch, infinite sustain
4. **vocal_granulator** - Speech-optimized settings
5. **percussion_mangler** - Short grains, high density
6. **tape_delay** - Vintage tape emulation
7. **shimmer_heaven** - Spectral shimmer + reverb
8. **filter_sweep** - Ready for filter automation
9. **quad_spatial** - 4-track spatial preset (all corners)
10. **live_input** - LIVE mode processing setup

**Create Example Presets:**
```supercollider
"examples/preset-examples.scd".loadRelative;
// Creates all 10 example presets in one run
```

**Workflow:**
1. Design a sound with the GUI
2. Save it: `~presets.save("magicTexture");`
3. Later: Load it instantly: `~presets.load("magicTexture");`
4. Share presets: Copy `.scd` files from `presets/` directory

**Performance Use:**
- Save multiple presets before a show
- Recall instantly during performance
- No manual parameter tweaking needed
- Complete state restoration in <200ms

**Implementation:**
- File: `core/preset-system.scd`
- Test suite: `tests/preset-system-test.scd`
- Examples: `examples/preset-examples.scd`
- Auto-loads with `main.scd`

**Note:** Modulation routings are saved for reference but NOT automatically restored on preset load (prevents accidental synth creation). Manually re-route modulators if needed.

---

## 🚀 PHASE 15+ ROADMAP

### Visual Flash (Doom Material Enhanced)
- [x] FFT Spectrogram Overlay (real-time frequency heatmap) - **Phase 11**
- [x] Grain Pulse Animation (visual "pings" where grains trigger) - **Phase 11**
- [ ] Neon Glow Rendering (hardware-accelerated glow effects)
- [ ] 3D Spatial Visualization (quad field with height axis)

### Audio Components
- [x] **Dual-Topology Analog-Modeled Filter** (per track) - **Phase 10**
- [x] **MIDI Control Integration** - **Phase 12**
- [x] **Quad Spatial Audio** - **Phase 12**
- [x] **Recording Viewfinder** - **Phase 12**
- [x] **Audio-Rate Modulation** (48kHz vs 750Hz control-rate) - **Phase 13**
- [x] **Per-grain spatial positioning** (quad granulation) - **Phase 13**
- [x] **Spatial modulation** (LFO → X/Y position) - **Phase 13**
- [ ] Transient Bypass Logic (keeps drum transients sharp)
- [ ] 4× Oversampled Color Section (anti-aliased saturation)
- [ ] 128-Band Resonator (DynKlank upgrade)

### Future Features:
- [x] **Preset save/load system** - **Phase 14 ✅**
- [ ] Preset management GUI (visual preset browser)
- [ ] Track naming
- [ ] Surround sound export (5.1/7.1)
- [ ] Headless Linux build
- [ ] Raspberry Pi stripped version

---

**Last Updated:** January 8, 2026
**Version:** v2.1 (Click-Free Switching + 64-Step Sequencer + Decoupled Time/Pitch)
