# S-4 RIVAL: Complete Feature List

## 🎵 CORE AUDIO ENGINES

### Granular Engine (GrainBuf)
- **Grain Size:** 0.001s - 60s (exponential scaling)
- **Overlap:** 1-128 grains (massive density for M4)
- **Position:** 0-1 (playback position in buffer)
- **Scan Speed:** -4 to +4 (continuous scanning, bidirectional)
- **Position Jitter:** 0-1 (stochastic grain distribution)
- **Pitch Shift:** -24 to +24 semitones (formant-preserving)
- **Pitch Jitter:** 0-12 semitones (grain pitch randomization)
- **Amplitude:** 0-1
- **Stereo Spread:** 0-1 (independent L/R grain timing)
- **Loop System:** Non-destructive loop windows with visual selection
- **Phase-Aligned Mode:** ✨ NEW - Zero-crossing aligned grains (prevents phase cancellation in bass)

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

### Session Highlights:
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

## 🚀 PHASE 12+ ROADMAP

### Visual Flash (Doom Material Enhanced)
- [x] FFT Spectrogram Overlay (real-time frequency heatmap) - **Phase 11**
- [x] Grain Pulse Animation (visual "pings" where grains trigger) - **Phase 11**
- [ ] Neon Glow Rendering (hardware-accelerated glow effects)

### Audio Components
- [x] **Dual-Topology Analog-Modeled Filter** (per track) - **Phase 10**
  - ZDF Ladder Filter (liquid resonance, self-oscillation)
  - State Variable Filter (LP/HP/BP morph)
  - Pre-Filter Drive Stage (nonlinear saturation for "grit")
  - Bass Loss Compensation (maintains low-end at high resonance)
- [ ] Audio-Rate Modulation (48kHz vs 750Hz control-rate)
- [ ] Transient Bypass Logic (keeps drum transients sharp)
- [ ] 4× Oversampled Color Section (anti-aliased saturation)
- [ ] 128-Band Resonator (DynKlank upgrade)

### Future Features:
- [ ] Recording viewfinder for live audio scrubbing
- [ ] Preset save/load system
- [ ] Track naming
- [ ] MIDI control integration
- [ ] Headless Linux build
- [ ] Raspberry Pi stripped version

---

**Last Updated:** January 3, 2026
**Version:** Phase 11 (Dual-Topology Filter + Visual Feedback)
