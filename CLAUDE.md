# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**S-4 RIVAL** (nicknamed "Bearulator") is a professional 4-track granular synthesis workstation built in SuperCollider, designed to rival the Torso S-4 hardware sampler. It's optimized for Mac Mini M4 (24GB RAM) with ~25% CPU usage at full capacity, leaving substantial headroom for expansion.

**Language**: SuperCollider (.scd files)
**Platform**: macOS (primary), with planned Linux/Raspberry Pi ports
**Audio Interface**: MOTU UltraLite Mk5 (8 inputs, 4 outputs for quad spatial audio)

**Current Version:** v2.2 (deployed 2026-01-09)
- Probability masking (Bernoulli gate for rhythmic fracturing)
- Click-free effect switching (SelectX + lag)
- Decoupled time/pitch (scanRate vs grainRate)
- 64-step sequencer arrays (KeyStep Pro/Digitone standard)
- Parameter collision fixed (mode → grainMode)

## Essential Commands

### Starting the System
```supercollider
// 1. Boot the SuperCollider server first
s.boot;

// 2. Wait for boot confirmation, then run main
"main.scd".loadRelative;
// OR for initial testing:
"START-HERE.scd".loadRelative;
```

### Development Workflow
```supercollider
// Emergency stop all audio (critical!)
Cmd-.    // Mac - kills all synths immediately

// Server management
s.reboot;        // Restart server (clean slate)
s.freeAll;       // Kill all synths but keep server running
s.quit;          // Shut down server

// Monitoring
s.meter;         // Audio level meters
s.scope;         // Oscilloscope
s.plotTree;      // See all running synths
s.avgCPU;        // Check CPU usage

// Testing
"tests/grain-engine-test.scd".loadRelative;  // Test grain engine
"tests/filterbank-test.scd".loadRelative;    // Test filters
"tests/quad-speaker-test.scd".loadRelative;  // Test quad output
```

### Preset System
```supercollider
// Save/load presets (Phase 14)
~presets.save("mySound");
~presets.load("mySound");
~presets.quickSave;  // Auto-named with timestamp
~presets.list;       // List all presets
~presets.info("mySound");

// Load example presets
"examples/preset-examples.scd".loadRelative;
```

### KeyStep Pro MIDI Control
```supercollider
// MIDI is auto-initialized when main.scd loads

// Smart remapping (on-the-fly, no audio interruption)
~mapKnob.(74, \spectralMix, 0, 1);        // Knob 1 → Spectral Mix
~mapKnob.(76, \filterFreq, 0, 1, \exp);  // Knob 3 → Filter (exponential)
~mapKnob.(77, \reverbMix, 0, 1, \lin, 1); // Knob 4 → Track 2 Reverb

// Load performance patch
"examples/keystep-performance-patches.scd".loadRelative;

// Test MIDI connection
"tests/keystep-pro-test.scd".loadRelative;

// Restore default mappings
~keyStepProMapping.loadDefaultMappings;

// Panic/Reset: Press Note 84 on keyboard
// Or manually: ~trackManager.resetParams(trackNum);
```


## Architecture Overview

### Signal Flow
```
Input/File → Buffer → [Grain Engine OR Spectral Engine OR Direct Playback]
                              ↓
                     Per-Track Filter (Ladder/SVF)
                              ↓
                     Color FX (Distortion, Crusher, Compression)
                              ↓
                     Space FX (Reverb, Delay, Shimmer)
                              ↓
                     Quad Panner (4-speaker spatial audio)
                              ↓
                     Mix Bus → Glue Compressor → Limiter → Output
```

### Core Components

**Track Manager** (`core/track-manager.scd`)
- Manages 4 independent tracks
- Each track has: grain synth, spectral synth, direct playback synth, buffer recorder, audio bus, modulation system (4 modulators/track)
- Handles parameter routing and state management
- **CRITICAL**: All tracks use execution order groups (modGroup → instrumentGroup) to ensure modulators run before instruments

**Grain Engine** (`core/grain-engine.scd`)
- Up to 256 grains using TGrains UGen
- Three material modes:
  - TAPE (0): Looping granular synthesis
  - POLY (1): One-shot sample playback per grain
  - LIVE (2): Real-time input granulation with lookback
- Overlap control (1-128 grains) replaces old density parameter
- Time stretch (0.25x-4x) independent of pitch
- Phase-aligned mode for bass-heavy material (prevents phase cancellation)

**Spectral Engine** (`core/spectral-engine.scd`)
- Warp1 UGen for spectral time-stretching
- FFT-based pitch shifting and spectral freezing
- Runs in parallel with grain engine (can blend both)
- 1-8 overlaps for buttery smooth spectral processing on M4

**Direct Playback** (`core/direct-playback.scd`)
- PlayBuf-based clean sample playback (no granulation)
- Phase 15 feature for traditional sampler behavior
- Can crossfade with grain/spectral engines via engineMorph parameter

**Per-Track Filter** (`core/per-track-effects.scd`)
- Dual topology: Moog Ladder (0.0-0.33) vs SVF (0.33-1.0)
- SVF morphs between LP/BP/HP
- Pre-filter drive stage for saturation
- Bass compensation at high resonance

**Modulation System** (`core/modulator.scd`)
- **4 modulators per track** (Phase 5/13)
- Types: LFO, Envelope Follower, Random, Manual
- **Audio-rate modulation @ 48kHz** (not control-rate) - eliminates zipper noise
- 13 modulation targets including quadX/quadY for spatial automation
- Visual feedback in viewfinder (green pulses for notes, cyan overlays for CC)

**MIDI Integration** (`core/keystep-pro-mapping.scd`)
- **KeyStep Pro smart mapper** - One-line remapping: `~mapKnob.(cc, param, min, max, warp)`
- **6 default mappings** - 5 knobs + mod strip → Track 1 parameters
- **Polyphonic keyboard** - Notes 48-83 control pitch, root at C3 (Note 60)
- **Panic/Reset** - Note 84 resets all tracks to factory defaults
- **Visual feedback** - Cyan overlays for CC, green pulses for notes
- **10 performance patches** - Pre-configured mappings for different styles
- **Multi-track support** - Control any track from any knob
- **Exponential/Linear warping** - Musical scaling for time/frequency parameters
- See: `KEYSTEP-PRO-QUICKSTART.md`, `KEYSTEP-QUICK-REF.md`, `examples/keystep-performance-patches.scd`

### GUI Components

**Main Window** (`gui/four-track-view.scd`)
- 4 track tabs + master tab
- Per-track controls: grain parameters, effects, material mode selector
- Master: global transport, track overview, CPU monitor

**Viewfinder** (`gui/viewfinder.scd`)
- Advanced waveform editor with 6 visual layers:
  1. FFT Spectrogram (frequency heatmap, Phase 11)
  2. Loop boundaries (green start, red end)
  3. Grain size window (yellow box)
  4. Position parameter (red line)
  5. Real-time playhead (cyan "Live" line @ 60Hz)
  6. Grain pulse animation (expanding rings)
- Navigation: Arrow keys (zoom/pan), G key (zoom to grain), L key (toggle loops)
- Transport controls: Play/Stop buttons control track directly
- **All grain + spectral controls** in one window (Phase 7+)

**Recording Viewfinder** (`gui/recording-viewfinder.scd`)
- Live audio capture with region selection (Phase 12)
- Send selected regions to any of 4 tracks
- 8-channel input support

**Quad Panner** (`gui/quad-panner.scd`)
- 2D spatial positioning GUI (Phase 12)
- Drag-and-drop track positioning in quad field
- Preset layouts: Corners, Front Row, Circle, Center

**Modulation Window** (`gui/modulation-window.scd`)
- Visual routing interface for modulation system
- Create/edit modulators, route to targets with min/max ranges
- Separate popup window (not integrated into main GUI)

## Critical SuperCollider Gotchas

### Variable Declaration Order
**CRITICAL**: SuperCollider requires ALL `var` declarations at the TOP of a code block, before any other statements. See `COMMON-BUGS.md` for details.

```supercollider
// BAD - will fail to compile
if(condition, {
    Pen.fillRect(rect);  // Statement first
    var myVar = 10;      // ERROR! Variable after statement
});

// GOOD
if(condition, {
    var myVar = 10;      // ALL vars first

    Pen.fillRect(rect);  // Statements after
});
```

### Event Callbacks
Functions stored in Events receive the Event itself as first argument, not passed arguments. Access Event fields directly or use external functions.

### GUI Thread Safety
Always use `.defer` when updating GUI from non-GUI threads (forks, OSC responders).

### Buffer Allocation
Always use `server.sync` in a fork when allocating buffers before using them.

### OSC Address Conflicts
Use unique OSC addresses for each synth (e.g., `/grainPlayhead` vs `/spectralPlayhead`).

## File Organization

```
granular/
├── main.scd                  # Main boot script - loads all modules
├── START-HERE.scd            # Quick start script for first-time users
├── core/                     # Audio engine modules
│   ├── grain-engine.scd      # TGrains-based granular synthesis
│   ├── spectral-engine.scd   # Warp1-based spectral processing
│   ├── direct-playback.scd   # PlayBuf-based clean playback
│   ├── track-manager.scd     # 4-track orchestration + modulation
│   ├── buffer-recorder.scd   # Live audio recording per track
│   ├── per-track-effects.scd # Dual-topology filter (Ladder/SVF)
│   ├── effects-color.scd     # Distortion, crusher, compression
│   ├── effects-space.scd     # Reverb, delay, shimmer
│   ├── mix-bus.scd           # Stereo master bus
│   ├── mix-bus-quad.scd      # Quad (4-channel) master bus
│   ├── modulator.scd         # Audio-rate modulation system
│   ├── midi-mapping.scd      # KeyStep Pro integration
│   └── preset-system.scd     # Save/load complete state
├── gui/                      # Visual interface modules
│   ├── four-track-view.scd   # Main window (tabbed interface)
│   ├── viewfinder.scd        # Advanced waveform editor
│   ├── recording-viewfinder.scd  # Live recording GUI
│   ├── modulation-window.scd # Modulation routing interface
│   └── quad-panner.scd       # 2D spatial positioning
├── tests/                    # Test scripts
├── examples/                 # Example presets
├── presets/                  # User preset storage (auto-created)
├── samples/                  # Audio samples
│   ├── stock/               # Included samples (Apollo 11)
│   ├── drones/
│   ├── percussion/
│   └── field-recordings/
└── docs/                     # Development documentation
```

## Key Implementation Details

### Material Modes (Phase 6)
- **TAPE (0)**: `position` parameter controls playback location, loops between `loopStart` and `loopEnd`
- **POLY (1)**: Each grain reads from fixed `position`, no scanning
- **LIVE (2)**: Grains read from current record position minus `position` offset (lookback buffer)

### Overlap vs Density (Phase 6b)
- **Overlap** (recommended): Specifies number of simultaneous grains (1-128), grain rate auto-calculated
- **Density** (legacy): Specifies grains/second, may cause gaps or excessive overlap
- Parameter `useOverlap` (default 1) controls which mode is active

### Time Stretch vs Pitch (Phase 15)
- **timeStretch**: Scales grain rate AND grain size together (0.25x-4x), pitch unchanged
- **pitch**: Legacy parameter, changes playback rate (affects both speed and pitch)
- **pitchShift**: True pitch shifting using PitchShift UGen (preserves speed)

### Audio-Rate Modulation (Phase 13)
All modulation runs at **48kHz** (not 750Hz control-rate). This eliminates zipper noise and enables FM-style effects with fast modulation. Modulators use audio buses and run in `modGroup` before instrument synths in `instrumentGroup`.

### Quad Spatial Audio (Phase 12)
- 4-speaker layout: FL (Out 0), FR (Out 1), RL (Out 2), RR (Out 3)
- Equal-power quad panning based on X/Y coordinates
- Per-grain spatial positioning available via `core/grain-engine-quad.scd` (experimental)
- Master 48-band resonator processes all 4 channels

### Preset System (Phase 14)
Saves 80+ parameters per track to `.scd` files in `presets/` directory. Includes grain settings, spectral state, filters, effects, mix controls, spatial positions, and material modes. Modulation routings saved for reference but NOT auto-restored (prevents accidental synth creation).

## Common Development Tasks

### Adding a New Parameter
1. Add to SynthDef arg list in `core/grain-engine.scd` (or relevant engine)
2. Add to default params in `track-manager.scd` createTrack method
3. Add GUI control in `gui/four-track-view.scd` or `gui/viewfinder.scd`
4. Wire GUI control to call `~trackManager.setParam(trackNum, \paramName, value)`
5. If modulation target: add to modulation window target menu and routing logic

### Testing Audio Changes
1. Make changes to relevant `.scd` file
2. Run `s.freeAll` to kill existing synths
3. Reload the modified file with `"core/filename.scd".loadRelative`
4. Reload main if needed: `"main.scd".loadRelative`
5. Test with dedicated test script if available

### Debugging Audio Issues
- Use `s.plotTree` to see all running synths and their groups
- Check `s.avgCPU` and `s.peakCPU` for performance issues
- Use `s.scope` to visualize audio output
- Check Post window for error messages
- Verify buffer allocation with `buffer.plot`

### Adding Modulation Targets
1. Ensure parameter exists in SynthDef and track-manager defaults
2. Add to modulation targets list in `gui/modulation-window.scd` (popup menu)
3. For spatial params (quadX/quadY): use special OSC routing (see track-manager.scd:475-513)
4. For standard params: mapper synths use `Out.ar` to audio bus

## Known Issues & Workarounds

### Waveform Display for Recorded Buffers
Uses temporary WAV files written to disk. Not ideal but functional. Refresh button in viewfinder reloads waveform after recording.

### Modulation Window
Separate popup window, not integrated into main tabbed interface. Plan to integrate in future phase.

### Recording Playhead
May not advance during live recording (visual only - audio works correctly).

### Crop Mode Validation
When in crop mode, skip the 1% minimum selection check (see viewfinder.scd crop logic).

## Performance Guidelines

### CPU Budget
- Target: <50% average CPU usage on M4
- Current: ~25% at full capacity (4 tracks, all effects)
- Each track with all features: ~6% CPU
- Headroom: 75% available for expansion

### Memory Management
- Total synth memory: ~2GB (configured in main.scd)
- Buffer allocation: 1024×16 buffers
- Each track: 4-second default buffer (expandable)
- Spectral engine uses Quality 4 interpolation (best for M4)

### Optimization Tips
- Reduce overlap count if CPU spikes (128 → 64 or 32)
- Disable unused effects chains (set colorOn/spaceOn to 0)
- Use DIRECT playback mode instead of GRANULAR when granulation not needed
- Lower spectral overlaps (8 → 4) if running multiple spectral tracks

## References

- **README.md**: User-facing quickstart guide
- **FEATURES.md**: Complete feature list with technical specs
- **TESTING-GUIDE.md**: Phase-specific testing procedures
- **COMMON-BUGS.md**: SuperCollider syntax gotchas
- **docs/**: Phase summaries and development notes
- **bearulator_project_state.org**: Comprehensive design document with v2.1 engine code

## Development Philosophy

- **M4-optimized**: Take advantage of headroom - prioritize audio quality over CPU conservation
- **Audio-first**: Preserve reverb tails and smooth parameter changes over minor optimizations
- **No over-engineering**: Keep solutions simple and focused on current requirements
- **Phase-based development**: Each phase builds on previous (currently Phase 15)
- **SuperCollider idioms**: Respect SC's event-based architecture and server/client separation

## Autonomous Work Practices

### User Preferences
- **Work autonomously when possible** - The user values efficiency and prefers you to make reasonable decisions without constant check-ins
- **Make small, focused changes** - Don't refactor surrounding code unless explicitly asked
- **Test thoroughly** - Verify changes work before presenting them as complete
- **Be proactive with research** - Use the Explore agent when you need to understand unfamiliar parts of the codebase
- **Document as you go** - Update this CLAUDE.md file when you discover new patterns or important information

### When to Work Autonomously

**GO AHEAD without asking:**
- Fixing bugs with clear root causes
- Adding parameters following established patterns
- Writing test scripts to verify functionality
- Implementing features with clear specifications
- Refactoring code that's clearly broken or inefficient
- Updating documentation to match code changes
- Following up on compiler errors or warnings

**ASK FIRST for:**
- Architectural changes affecting multiple modules
- Changes to public API or parameter ranges
- Performance optimizations that trade quality for speed
- GUI layout changes (user has specific aesthetic preferences)
- Removing features or deprecating functionality
- Changing audio behavior in subjective ways (filter character, reverb sound, etc.)

### Efficient Task Patterns

**For parameter additions:**
1. Read the relevant SynthDef to understand arg structure
2. Add to SynthDef, track-manager defaults, GUI, and modulation targets (if applicable) in one pass
3. Test with a simple command before marking complete

**For bug fixes:**
1. Reproduce the issue if possible (check test files)
2. Use Grep to find all occurrences of problematic code patterns
3. Fix systematically, checking for similar issues elsewhere
4. Verify fix with existing test scripts or create a new one

**For audio engine changes:**
1. Understand signal flow first (see Architecture Overview section)
2. Check execution order (modGroup → instrumentGroup)
3. Verify parameter ranges match GUI controls
4. Test with `s.freeAll` + reload workflow
5. Check CPU usage impact with `s.avgCPU`

### Research Strategy

**Use the Explore agent (Task tool) when:**
- Looking for where a feature is implemented across multiple files
- Understanding how a system works (e.g., "how does modulation routing work?")
- Finding all uses of a particular pattern or API
- You need context before making changes

**Use direct file reading when:**
- You know exactly which file to check
- Reading a specific SynthDef or function
- Checking recent changes or documentation

### Testing Philosophy

**Audio changes require testing:**
- Run `s.freeAll` to kill old synths
- Reload modified files
- Test with both GUI and direct commands
- Check multiple parameter ranges, not just defaults
- Listen for artifacts (clicks, pops, zipper noise)
- Verify CPU usage hasn't spiked

**Don't rely on:**
- "It compiles so it probably works" - SuperCollider is dynamically typed
- Default values only - edge cases often reveal bugs
- Visual confirmation alone - audio glitches may not be visible

**Deployment Tests (IMPORTANT):**
- Create comprehensive deployment tests for every major version/update
- Follow the pattern in `tests/v2.1-deployment-test.scd`
- Test format: automated script that runs through all critical features
- Include: bug fixes, new parameters, effect switching, audio quality checks
- Output: step-by-step progress with PASSED/FAILED status
- User preference: "That test was brilliant" - this is the gold standard

### Common Pitfall Checklist

Before submitting audio engine changes, verify:
- [ ] All `var` declarations at top of code blocks
- [ ] GUI updates wrapped in `.defer` when called from forks/OSC
- [ ] Unique OSC addresses for each synth
- [ ] Parameter ranges match GUI slider ranges
- [ ] `server.sync` after buffer allocation
- [ ] No hardcoded track numbers (use trackNum argument)
- [ ] Modulation targets use audio buses (not control buses)
- [ ] Filter parameters mapped exponentially (20Hz-18kHz)

### Efficiency Tips for This Codebase

1. **Pattern matching**: Many parameters follow identical patterns - copy and adapt rather than reinvent
2. **Test files exist**: Check `tests/` directory before writing new test code
3. **Documentation is accurate**: Unlike many projects, the docs here are up-to-date and trustworthy
4. **bearulator_project_state.org**: Contains v2.1 engine code and design rationale - check for architectural decisions
5. **Phase numbers matter**: Features reference phases (e.g., "Phase 12: MIDI") - use these for context
6. **SC Post window**: The SuperCollider post window is your friend - errors are usually descriptive
7. **Use existing test patterns**: See `tests/grain-engine-test.scd` for command-based testing style

### Communication Style

**The user prefers:**
- Concise summaries over verbose explanations
- "Here's what I did" over "Here's what I'm going to do"
- Results-focused updates ("Fixed X by doing Y") over process descriptions
- Direct questions when you need clarification, not apologetic hedging
- Technical accuracy over politeness

**Avoid:**
- Asking permission for obvious next steps
- Lengthy explanations of basic concepts
- Apologizing for taking time to research properly
- Over-explaining trivial changes
- Hedging with "I think maybe possibly..."
