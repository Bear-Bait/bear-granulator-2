# S-4 Rival: SuperCollider Granular Sculpting Sampler

**Version:** 0.4.001 (Phase 4 Complete)
**Date:** 2025-12-31
**Status:** Production-Ready 4-Track Workstation

A comprehensive granular synthesis workstation built in SuperCollider to rival the Torso Electronics S-4 ($1000 hardware). This project creates a 4-track granular sculpting sampler with live processing, morphing resonators, extensive modulation, and professional effects.

## Current Status

- ✅ **Phase 1 COMPLETE:** Core Granular Engine (128 grains, 4-second buffer)
- ✅ **Phase 2 COMPLETE:** 48-Band Morphing Resonator (LP/BP/HP morphing, animation)
- ✅ **Phase 3 COMPLETE:** Effects Chain (Color: distortion/crush/comp/noise, Space: reverb/delay/shimmer)
- ✅ **Phase 4 COMPLETE:** 4-Track Architecture (4 independent tracks, master bus, tabbed GUI)
- ⏸️ **Phase 5-10:** Planned (modulation, material modes, MIDI, advanced GUI, recording, optimization)

**See [PHASE4-COMPLETE.md](PHASE4-COMPLETE.md) for Phase 4 implementation details.**

## Project Goals

Build a production-ready granular synthesis instrument with:
- 4 parallel stereo tracks (24-bit/48kHz)
- Up to 128 grains per track
- 4-second live recording buffer per track
- 48-band morphing resonator filterbank
- Comprehensive modulation system (20 modulators total)
- Professional effects chain per track
- MIDI control and performance features
- Advanced GUI with real-time visualization

## Target Features vs. Torso S-4

### Core Architecture
- [x] 4 parallel stereo tracks
- [x] Signal chain: Material → Granular → Filter → Color → Space
- [x] 24-bit/48kHz audio quality

### Granular Engine
- [x] Up to 128 grains per track
- [x] 4-second rolling buffer for live input
- [x] Grain size: 10ms-500ms
- [x] Density: 1-200 grains/second
- [x] Time-warping & pitch-shifting (independent)
- [x] Multiple grain shapes/envelopes
- [x] Position scrubbing
- [x] Stereo spread control

### Morphing Resonator
- [x] 48-band tuned filter bank
- [x] LP/BP/HP morphing
- [x] Harmonic/inharmonic tuning
- [x] Resonance/decay control
- [x] Animation (modulated band gains)

### Modulation System (Phase 5 - COMPLETE ✅)
- [x] 4 modulators per track (16 total)
- [x] Types: LFO, Envelope Follower, Random, Envelope
- [x] 6 LFO waveforms (Sine, Triangle, Saw, Square, Smooth/Stepped Random)
- [x] Route to any parameter (grain, filter, FX)
- [x] Modulation depth control (0-1)
- [x] Rate control (0.01-20 Hz)
- [x] Min/Max range mapping
- [x] Dedicated modulation window per track
- [x] Real-time parameter modulation via control busses

### Effects Chain

**Color Section:**
- [x] Dual-band distortion
- [x] Bit crusher
- [x] Compression/dynamics
- [x] Noise generator

**Space Section:**
- [x] Reverb with freeze function
- [x] Multiple delay types
- [x] Pitch-shifting delay (shimmer)
- [x] Wet/dry mix controls

### Material Modes (Phase 6 - NOT YET IMPLEMENTED)
- [ ] Tape mode (looping with overdub)
- [ ] Poly mode (8-voice MIDI sampler)
- [x] Live input processing (basic recording only)
- [ ] Sample playback from disk

### Performance Features (Phases 7-9 - NOT YET IMPLEMENTED)
- [ ] Scene/preset system
- [ ] Macro controls
- [ ] MIDI learn system
- [ ] Multi-track recording
- [ ] Real-time visualization (planned for Phase 8)

## Technical Specifications

### System Requirements
- SuperCollider 3.13 or higher
- macOS (primary target)
- 8GB RAM minimum
- Audio interface recommended for low latency

### Audio Specifications
- Sample rate: 48kHz
- Bit depth: 24-bit
- Buffer size: 4 seconds @ 48kHz = ~192,000 frames per track
- Max grains: 128 per track (512 total system)
- Latency target: <10ms

### Key SuperCollider UGens
- `GrainBuf` - Core granular synthesis
- `RecordBuf` - Live recording buffer
- `BPF`/`Resonz` - Filter bank
- `PitchShift` - Time/pitch manipulation
- `Compander` - Dynamics processing
- `FreeVerb`/`JPverb` - Reverb
- `CombC`/`AllpassC` - Delays
- `MIDIIn`/`MIDIdef` - MIDI handling

## Development Phases

### Phase 1: Core Granular Engine (Week 1-2)
**Objective:** Build single-track granular synth with live buffer

**Deliverables:**
- `core/grain-engine.scd` - Main SynthDef with GrainBuf
- `core/buffer-recorder.scd` - 4-second rolling buffer
- `gui/basic-controls.scd` - Simple GUI with essential controls

**Key Features:**
- 128 max grains
- 4-second live recording buffer
- Grain size control (10ms-500ms)
- Density control (1-200 grains/sec)
- Position control (scrub through buffer)
- Pitch control (-2 to +2 octaves)
- Grain envelope shapes (4 types minimum)
- Random jitter (position & pitch)
- Stereo spread

**Testing Criteria:**
- CPU usage <15% for single track
- No audio dropouts at 128 grains
- Smooth grain triggering
- Clean buffer recording

---

### Phase 2: Morphing Resonator (Week 3)
**Objective:** Implement 48-band tuned filterbank

**Deliverables:**
- `core/filterbank.scd` - Resonator implementation
- `core/filter-shapes.scd` - LP/BP/HP morphing logic

**Key Features:**
- 48 parallel bandpass filters
- Harmonic series tuning (default)
- Custom scale support
- Filter type morphing (LP→BP→HP)
- Resonance/Q control per band
- Decay time (resonance tail)
- Animation (LFO on band gains)
- Master cutoff/frequency control

**Algorithm:**
```supercollider
// Pseudo-code structure
48.collect({ |i|
    freq = fundamental * (i+1); // harmonic series
    BPF.ar(input, freq, rq) * gain;
}).sum;
```

**Testing Criteria:**
- No aliasing or artifacts
- Smooth filter morphing
- CPU <10% additional load
- Resonance stable at high Q values

---

### Phase 3: Effects Chain (Week 4)
**Objective:** Complete Color and Space effects sections

**Deliverables:**
- `core/effects-color.scd` - Distortion, compression, bit crusher
- `core/effects-space.scd` - Reverb, delay, shimmer

**Color Section:**
- Dual-band distortion (separate lo/hi freq)
- Drive amount per band
- Crossover frequency
- Bit crusher (sample rate reduction)
- Bit depth reduction
- Compressor/limiter
- Noise generator with mix control

**Space Section:**
- Reverb (FreeVerb or JPverb)
  - Size/room size
  - Damping
  - Mix
  - Freeze function (hold tail)
- Delay
  - Time (sync to tempo optional)
  - Feedback
  - Ping-pong stereo
  - Filtered feedback
- Shimmer (pitch-shifted delay)
  - Pitch interval (+12, +7, etc.)
  - Shimmer mix

**Testing Criteria:**
- Effects don't clip
- Freeze function stable
- Shimmer pitch accurate
- CPU <15% for full chain

---

### Phase 4: Four-Track Architecture (Week 5) ✅ COMPLETE
**Objective:** Expand to 4 independent parallel tracks

**Status:** ✅ **COMPLETE** (v0.4.001, 2025-12-31)

**Deliverables:**
- ✅ `core/track-manager.scd` - Track instantiation & routing (330 lines)
- ✅ `core/mix-bus.scd` - Master mixing system (195 lines)
- ✅ `gui/four-track-view.scd` - Multi-track tabbed GUI (670 lines)

**Key Features:**
- 4 independent instances of grain engine
- Per-track audio buses
- Individual track volume/pan
- Track mute/solo
- Master mix bus
- Track routing options
- Inter-track send/return (optional)

**File Structure:**
```
Track 1 → [Grain→Filter→Color→Space] → Bus 1 ↘
Track 2 → [Grain→Filter→Color→Space] → Bus 2 → Master → Output
Track 3 → [Grain→Filter→Color→Space] → Bus 3 ↗
Track 4 → [Grain→Filter→Color→Space] → Bus 4 ↗
```

**Testing Criteria:**
- All 4 tracks run simultaneously
- No crosstalk between tracks
- CPU <50% for 4 full tracks
- Independent control of each track

---

### Phase 5: Modulation System (Week 6)
**Objective:** 4 modulators per track with routing matrix

**Deliverables:**
- `core/modulation.scd` - Modulator engine
- `core/mod-routing.scd` - Routing matrix logic
- `gui/mod-matrix.scd` - GUI for mod routing

**Modulator Types:**

**LFO:**
- Waveforms: Sine, Saw, Triangle, Square, Random (smooth), Random (stepped)
- Rate: 0.01Hz to 100Hz
- Sync to tempo (optional)
- Phase offset
- Bipolar/unipolar output

**Envelope:**
- ADSR
- Looping option
- Trigger source selection

**Random:**
- Sample & hold
- Smooth random (LFNoise1)
- Rate control

**Envelope Follower:**
- Track input amplitude
- Attack/release time
- Threshold

**Routing Matrix:**
- Each modulator → multiple destinations
- Depth control per routing
- Polarity (+ or -)
- Source selection GUI

**Example Routings:**
- LFO1 → Grain Size (depth 0.5)
- LFO1 → Filter Cutoff (depth 0.3)
- Envelope1 → Grain Density
- Random1 → Grain Position

**Testing Criteria:**
- Smooth modulation (no zipper noise)
- All 20 modulators stable
- No CPU spikes from modulation
- Visual feedback in GUI

---

### Phase 6: Material Modes (Week 7)
**Objective:** Multiple source modes per track

**Deliverables:**
- `material/tape-mode.scd` - Tape looping
- `material/poly-mode.scd` - MIDI sampler
- `material/live-input.scd` - Live processing

**Tape Mode:**
- Continuous recording to 4-second buffer
- Overdub capability
- Loop start/end points
- Playback modes:
  - Sync (tempo-locked)
  - Free (seconds-based)
  - Stretch (time/pitch independent)
- Varispeed control
- Reverse playback

**Poly Mode:**
- 8-voice polyphonic allocation
- MIDI note-on/off handling
- Velocity → amplitude mapping
- Note-per-grain or note-per-cloud
- Sample selection per note
- Root note tuning

**Live Input Mode:**
- Direct audio passthrough
- Pre/post grain selection
- Input monitoring
- HPF/LPF on input

**Testing Criteria:**
- Clean overdubs in tape mode
- Accurate MIDI tracking in poly mode
- Low latency in live mode
- Smooth mode switching

---

### Phase 7: MIDI & Sync (Week 8)
**Objective:** Full MIDI integration and tempo sync

**Deliverables:**
- `io/midi-handler.scd` - MIDI note & CC handling
- `io/midi-learn.scd` - MIDI learn system
- `io/sync-engine.scd` - Tempo sync

**MIDI Features:**

**Note Input:**
- Polyphonic MIDI in Poly mode
- Note → pitch mapping
- Velocity sensitivity
- Sustain pedal support
- All notes off (panic)

**CC Control:**
- MIDI learn for any parameter
- Store CC mappings
- 14-bit CC support (optional)
- MIDI feedback (if controller supports)

**Sync:**
- MIDI clock input
- Internal TempoClock
- Ableton Link (via OSC if possible)
- Beat/bar display
- Sync grain triggers to beat/bar

**Testing Criteria:**
- <5ms MIDI latency
- Stable tempo sync
- No stuck notes
- MIDI learn works for all params

---

### Phase 8: Advanced GUI (Week 9-10)
**Objective:** Professional multi-track interface

**Deliverables:**
- `gui/main-window.scd` - Master window layout
- `gui/track-view.scd` - Per-track interface
- `gui/visualizer.scd` - Waveform & grain display
- `gui/meters.scd` - Level meters

**GUI Sections:**

**Track View (per track):**
- Waveform display with playhead
- Grain cloud visualization (optional)
- Material mode selector
- Grain controls (size, density, position, pitch)
- Filter controls (cutoff, resonance, morph)
- Effects controls (color & space)
- Modulation assignment buttons
- Level meter
- Mute/Solo buttons

**Master Section:**
- Master fader
- Master meters (L/R)
- BPM/tempo display
- Transport controls
- Scene selector
- Preset browser

**Modulation Matrix:**
- Visual routing display
- Drag-to-assign interface
- Depth sliders
- Modulator waveform display

**Performance View:**
- Macro knobs (8-16)
- Scene triggers
- Simplified interface for live use

**Visualization:**
- Real-time waveform of buffer
- Grain positions animated
- Filter frequency response
- Modulation curves

**Testing Criteria:**
- GUI responsive (<16ms frame time)
- No visual artifacts
- Intuitive workflow
- Scalable window size

---

### Phase 9: Recording & I/O (Week 11)
**Objective:** Multi-track recording and sample management

**Deliverables:**
- `io/recorder.scd` - Multi-track recording
- `io/sample-manager.scd` - Sample library
- `io/audio-io.scd` - Input/output routing

**Recording Features:**
- Record individual tracks to disk
- Record master output
- Bounce in place
- Non-destructive recording
- WAV/AIFF format support
- Timestamped file naming
- Recording indicator

**Sample Management:**
- Browse samples on disk
- Preview samples
- Drag & drop loading
- Favorite samples
- Auto-scan sample folders
- Sample info display (length, SR, bit depth)

**Audio I/O:**
- Input channel selection per track
- Output routing options
- Headphone monitoring
- Input gain staging
- Input meter

**Testing Criteria:**
- Clean recordings (no glitches)
- Proper file management
- Fast sample loading
- Accurate input monitoring

---

### Phase 10: Optimization & Polish (Week 12)
**Objective:** Production-ready performance and features

**Deliverables:**
- `docs/user-manual.md` - User documentation
- `presets/factory/` - Factory preset library
- Optimized code throughout

**Optimization Tasks:**
- Profile CPU usage
- Optimize hot paths
- Reduce unnecessary calculations
- Efficient GUI updates
- Memory leak checking
- Buffer management optimization

**Additional Features:**
- Grain formant preservation
- Granular feedback routing
- Advanced freeze functions
- Randomization controls
- Preset morphing/interpolation
- Undo/redo system

**Polish:**
- Error handling
- Graceful degradation
- Help tooltips in GUI
- Keyboard shortcuts
- Save/load project state
- Preference system

**Testing Criteria:**
- CPU <40% average
- No memory leaks
- Stable over long sessions
- Professional UX

---

## File Structure
```
s4-rival/
│
├── README.md                    # This file
├── main.scd                     # Boot script
│
├── core/
│   ├── grain-engine.scd         # Core granular SynthDef
│   ├── buffer-recorder.scd      # Rolling buffer management
│   ├── filterbank.scd           # 48-band resonator
│   ├── filter-shapes.scd        # Filter morphing logic
│   ├── effects-color.scd        # Distortion/compression
│   ├── effects-space.scd        # Reverb/delay
│   ├── track-manager.scd        # 4-track system
│   ├── mix-bus.scd              # Master mixing
│   ├── modulation.scd           # Modulator engine
│   └── mod-routing.scd          # Routing matrix
│
├── material/
│   ├── tape-mode.scd            # Tape looping
│   ├── poly-mode.scd            # MIDI sampler
│   └── live-input.scd           # Live processing
│
├── gui/
│   ├── main-window.scd          # Master layout
│   ├── track-view.scd           # Per-track UI
│   ├── four-track-view.scd      # Multi-track layout
│   ├── mod-matrix.scd           # Modulation GUI
│   ├── visualizer.scd           # Waveform display
│   ├── meters.scd               # Level meters
│   └── basic-controls.scd       # Initial simple GUI
│
├── io/
│   ├── midi-handler.scd         # MIDI input
│   ├── midi-learn.scd           # MIDI learn system
│   ├── sync-engine.scd          # Tempo sync
│   ├── recorder.scd             # Audio recording
│   ├── sample-manager.scd       # Sample browser
│   └── audio-io.scd             # I/O routing
│
├── presets/
│   ├── factory/                 # Factory presets
│   │   ├── ambient-textures.scd
│   │   ├── glitch-rhythms.scd
│   │   └── drone-pads.scd
│   └── user/                    # User presets
│
├── samples/                     # Sample library
│   ├── drones/
│   ├── percussion/
│   └── field-recordings/
│
├── docs/
│   ├── user-manual.md           # End user docs
│   ├── developer-notes.md       # Technical notes
│   └── api-reference.md         # Code reference
│
└── tests/
    ├── grain-engine-test.scd
    ├── filterbank-test.scd
    └── performance-test.scd
```

---

## Development Workflow

### Setup Phase
1. Create project directory structure
2. Initialize git repository
3. Set up SuperCollider startup file
4. Configure audio interface
5. Test basic SC functionality

### Per-Phase Development
1. Read phase requirements
2. Create necessary files
3. Implement core functionality
4. Write basic tests
5. Integrate with existing code
6. Update GUI if needed
7. Performance testing
8. Documentation
9. Git commit

### Daily Practice
- 2-3 hour focused sessions
- Test each module before moving on
- Commit working code frequently
- Document unusual decisions
- Profile performance regularly

---

## Code Style Guidelines

### Naming Conventions
```supercollider
// Variables: camelCase
var grainSize, bufferLength, filterCutoff;

// SynthDefs: lowercase with hyphens
SynthDef(\s4-grain-engine, { ... });

// Global variables: prefixed with ~
~grainBuffer, ~trackManager, ~modMatrix;

// Constants: UPPERCASE
var MAX_GRAINS = 128;
var BUFFER_SIZE = 192000;
```

### Documentation
```supercollider
/*
Function: createGrainSynth
Purpose: Initialize granular synthesis engine
Args:
  - track: Track number (0-3)
  - bufnum: Buffer number for sample
  - grainSize: Grain duration in seconds
Returns: Synth instance
*/
```

### Performance
- Always use `.ar` for audio rate
- Use `.kr` for control rate when possible
- Avoid expensive operations in tight loops
- Pre-calculate values when possible
- Use LocalBuf for temporary buffers

---

## Testing Strategy

### Unit Testing
Test each module independently:
```supercollider
// tests/grain-engine-test.scd
(
// Test 1: Grain engine boots
var synth = Synth(\s4-grain-engine);
3.wait;
synth.free;
"✓ Grain engine boots".postln;

// Test 2: CPU usage acceptable
// ... etc
)
```

### Integration Testing
Test modules working together:
- Grain engine → Filter → Effects chain
- MIDI → Poly mode → Grain engine
- Modulation → Multiple destinations

### Performance Testing
- CPU usage monitoring
- Memory leak detection
- Long-running stability (1+ hour)
- Maximum polyphony tests
- GUI responsiveness under load

### Audio Quality Testing
- No clipping or distortion
- Clean grain triggering
- Smooth parameter changes
- Accurate pitch shifting
- Reverb tail quality

---

## Success Metrics

### Phase Completion Criteria
Each phase must meet:
- ✓ All deliverables created
- ✓ Basic tests passing
- ✓ CPU usage within target
- ✓ Integration with prior phases works
- ✓ Documentation updated

### Project Completion Criteria
- ✓ All 4 tracks functional
- ✓ 128 grains per track stable
- ✓ 48-band resonator working
- ✓ Full modulation system (20 mods)
- ✓ Complete effects chain
- ✓ MIDI control functional
- ✓ Professional GUI complete
- ✓ Recording system working
- ✓ CPU usage <40% average
- ✓ Stable for 1+ hour sessions
- ✓ User manual complete
- ✓ 10+ factory presets

---

## Known Challenges & Solutions

### Challenge: 128 Grains CPU Load
**Solution:** 
- Optimize grain envelope (use Env.perc)
- Limit active grains intelligently
- Use efficient triggering (Impulse vs Dust)

### Challenge: 48-Band Filter CPU
**Solution:**
- Consider FFT-based approach if too heavy
- Reduce to 32 or 24 bands if needed
- Use Resonz instead of BPF for efficiency

### Challenge: GUI Responsiveness
**Solution:**
- Update GUI at 30fps max
- Batch parameter changes
- Use deferred updates
- Separate GUI from audio thread

### Challenge: Buffer Management
**Solution:**
- Pre-allocate all buffers at startup
- Use LocalBuf where possible
- Implement buffer pool
- Monitor buffer memory usage

---

## Stretch Goals (If Time Permits)

### Advanced Features
- [ ] Spectral freezing
- [ ] Convolution reverb
- [ ] Formant preservation in pitch shift
- [ ] Multi-band compression
- [ ] Sidechain compression
- [ ] LFO tempo sync with swing
- [ ] Grain cloud presets
- [ ] Morphing between presets
- [ ] External modulation via OSC

### Experimental Features
- [ ] Machine learning grain selection
- [ ] Pulsar synthesis mode
- [ ] FOF synthesis integration
- [ ] Spectral delay
- [ ] Granular feedback networks
- [ ] Multi-dimensional grain clouds

### Integration
- [ ] Ableton Link (via OSC)
- [ ] OSC control surface support
- [ ] Max/MSP integration
- [ ] Eurorack CV output (via DC-coupled interface)
- [ ] TouchOSC template

### Expansion
- [ ] 8-track version
- [ ] Multi-channel output (8+)
- [ ] Session view (scene matrix)
- [ ] Collaboration features
- [ ] Cloud preset sharing

---

## Resources

### SuperCollider Documentation
- [Official SC Docs](https://doc.sccode.org/)
- [GrainBuf Help](https://doc.sccode.org/Classes/GrainBuf.html)
- [GUI Guide](https://doc.sccode.org/Guides/GUI-Introduction.html)
- [Server Architecture](https://doc.sccode.org/Guides/Server-Architecture.html)

### Granular Synthesis Theory
- Curtis Roads - "Microsound"
- Barry Truax - Granular synthesis papers
- [Granular Synthesis Tutorial](https://thormagnusson.gitbooks.io/scoring/content/PartII/chapter10.html)

### Similar Projects for Reference
- GR-1 Granular Synthesizer
- Tasty Chips GR-Mega
- 4ms Spectral Multiband Resonator
- Mutable Instruments Beads/Clouds

---

## Version History

### v0.3.001 - Current Build (Phase 3 Complete) ✅
**Status:** Fully functional single-track granular workstation

**Features:**
- Core granular engine (128 grains, 4-second buffer)
- 48-band morphing resonator (LP/BP/HP)
- Color effects (distortion, bit crush, compressor, noise)
- Space effects (reverb with freeze, delay, shimmer)
- Wide horizontal GUI (all controls visible, no scrolling)
- MOTU Mk5 8-input support
- Live recording and playback
- Test sound generation

**Known Issues:**
- Waveform display shows harmless Qt threading warnings
- Waveform cursor position update needs optimization

**Files:**
- `main.scd` - Boot script
- `core/grain-engine.scd` - Main SynthDef with inline effects
- `core/buffer-recorder.scd` - 4-second rolling buffer recorder
- `core/effects-color.scd` - Color effects (reference only)
- `core/effects-space.scd` - Space effects (reference only)
- `core/filter-shapes.scd` - Filter morphing functions
- `core/filterbank.scd` - 48-band resonator
- `gui/wide-gui.scd` - Wide horizontal layout (current)
- `gui/basic-controls.scd` - Vertical layout (deprecated)
- `tests/phase3-test.scd` - Automated effects testing
- `tests/quick-sound-test.scd` - Quick sound verification

**Documentation:**
- `GETTING-STARTED.md` - Quick start guide
- `SOUND-TEST-GUIDE.md` - Detailed testing instructions

### v0.1 - Phase 1 Complete
- Basic granular engine
- Simple GUI
- Single track

### v0.2 - Phase 2 Complete
- 48-band resonator
- Filter morphing

### v0.3 - Phase 3 Complete
- Effects chain
- Color & Space modules

### v0.4 - Phase 4 Complete
- 4-track architecture
- Track management

### v0.5 - Phase 5 Complete
- Modulation system
- Routing matrix

### v0.6 - Phase 6 Complete
- Material modes
- Tape/Poly/Live

### v0.7 - Phase 7 Complete
- MIDI integration
- Tempo sync

### v0.8 - Phase 8 Complete
- Advanced GUI
- Visualization

### v0.9 - Phase 9 Complete
- Recording system
- Sample management

### v1.0 - Phase 10 Complete
- Optimization
- Production ready

---

## License

MIT License - Feel free to modify and distribute

---

## Credits

**Inspired by:** Torso Electronics S-4
**Built with:** SuperCollider
**Developer:** [Your Name]
**Project Start:** [Date]

---

## Getting Started

1. Install SuperCollider 3.13+
2. Clone this repository
3. Open `main.scd` in SuperCollider
4. Boot the server: `s.boot;`
5. Run main.scd
6. Start with Phase 1 development

**Happy coding! 🎛️🎵**

<!-- Local Variables: -->
<!-- gptel-model: claude-haiku-4-5-20251001 -->
<!-- gptel--backend-name: "Claude-Haiku-4.5" -->
<!-- gptel-max-tokens: 6000 -->
<!-- gptel--bounds: nil -->
<!-- End: -->
