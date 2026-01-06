# Testing Notes - Week of 2026-01-05

## Issues Found

### 1. Direct Mode Breaking Main Window Params

**Symptom:** Setting the engine to "direct" mode appears to break parameter controls on the main window.

**Context:**
- Engine mode is controlled via `\engineMode` parameter (0=GRANULAR, 1=DIRECT, 2=MIX)
- Direct playback uses the `\s4DirectPlayback` SynthDef (core/direct-playback.scd)
- Main window sliders call `trackManager.setParam(trackNum, param, value)`

**Affected files:**
- `gui/four-track-view.scd` - Main window UI and parameter controls
- `core/track-manager.scd` - Track management and parameter routing
- `core/direct-playback.scd` - Direct playback engine

**Hypothesis:** The direct playback synth may not be responding to parameter changes, or the parameter routing in track manager may not properly handle direct mode synths.

**Next steps:**
- [ ] Check which parameters are broken (all or specific ones?)
- [ ] Review track-manager.scd's setParam function for engine mode handling
- [ ] Verify direct playback synth is receiving parameter updates
- [ ] Test if issue occurs in GRANULAR mode vs DIRECT mode vs MIX mode

---

### 2. Track Filter Popping When Enabled

**Symptom:** Audible pop/click when turning on the per-track filter.

**Context:**
- Per-track filter controls in gui/four-track-view.scd:494
- Filter button at line 494 calls `trackManager.setParam(trackNum, \filterOn, btn.value)`
- Filter implementation likely in effects chain

**Affected files:**
- Filter SynthDef (needs investigation)
- Track manager parameter routing

**Hypothesis:** Filter is being hard-switched on/off without fade-in/crossfade, causing discontinuity in audio signal.

**Next steps:**
- [ ] Locate filter SynthDef implementation
- [ ] Add envelope/crossfade when enabling filter
- [ ] Test with different filter settings to isolate issue

---

### 3. Modulation Window Missing Granular Parameters

**Symptom:** Modulation window should allow modulating all individual grain parameters, but some may be missing.

**Context:**
- Modulation window opened via MOD button (gui/four-track-view.scd:201-205)
- Uses `~s4ModulationWindow.value(trackManager, server, trackNum).create`
- Should provide access to all grain parameters for LFO/envelope modulation

**Affected files:**
- Modulation window implementation (needs to be located)
- Parameter routing system

**Required parameters for modulation:**
- Grain size
- Grain density
- Position
- Pitch
- Jitter
- Overlap
- All effect parameters
- Filter parameters

**Next steps:**
- [ ] Find modulation window implementation file
- [ ] Review which parameters are currently available
- [ ] Add missing grain parameters to modulation targets
- [ ] Test modulation routing for each parameter

---

### 4. Volume Control Desync Between Track Tab and Master Tab

**Symptom:** Volume slider on individual track tab is not synced with the volume slider for that track on the master tab. They should control the same parameter and stay synchronized.

**Context:**
- Track tab volume slider: gui/four-track-view.scd:164-168
- Master tab volume slider for each track: gui/four-track-view.scd:889-893
- Both call `trackManager.setVolume(trackNum, value)` but UI values don't sync

**Affected files:**
- `gui/four-track-view.scd` - Both volume slider implementations
- Need bidirectional UI updates

**Hypothesis:** Sliders update the backend value but don't have listeners to update each other when one changes.

**Solution approaches:**
1. Add shared state/controller that updates both sliders when either changes
2. Implement observer pattern for volume changes
3. Store slider references and update both when trackManager.setVolume is called

**Next steps:**
- [ ] Store references to both volume sliders for each track
- [ ] Add callback system to update both UI elements when volume changes
- [ ] Extend to pan controls if same issue exists there

---

### 5. Play/Stop/Record Button Layout Conflicts - NEEDS REDESIGN

**Symptom:** Play/Stop/Record buttons are messy and conflicting with granular/direct mode switching. Current layout is confusing and needs to be completely redone.

**Current Problems:**

1. **PLAY/STOP button** (gui/four-track-view.scd:367-415)
   - Located on main track tab
   - Has complex logic to check `track.params[\engineMode]` and start appropriate synths
   - Conflicts with engine mode switching

2. **RECORD button** (gui/four-track-view.scd:431-452)
   - Also on main track tab
   - Uses "STOP" label which conflicts with PLAY/STOP button
   - No clear visual separation

3. **GRANULAR/DIRECT mode button**
   - Located in LOOP VIEW window (gui/viewfinder.scd:993-1004)
   - Should be more prominent and accessible
   - Mode switching affects which synths the PLAY button activates

**Why This is Confusing:**

- Two different "STOP" buttons (one for playback, one for recording)
- Engine mode selector hidden in separate window
- Play button behavior changes based on mode, but mode not visible
- Recording vs playback transport controls mixed together
- No clear workflow for: Load → Select Mode → Record/Play → Stop

**Proposed Solution:**

**Move ALL transport controls to individual track tabs** with clear sections:

```
TRACK 1 TAB LAYOUT (Redesigned):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
┌─ AUDIO SOURCE ─────────────────────────────────┐
│ [Load Audio File]  [Input: In 3 ▼]            │
│ [● REC]  [■ STOP REC]                          │
└────────────────────────────────────────────────┘

┌─ ENGINE MODE ──────────────────────────────────┐
│ [ GRANULAR ] [ DIRECT ] [ MIX ]                │
│ (Radio buttons - mutually exclusive)           │
└────────────────────────────────────────────────┘

┌─ PLAYBACK ─────────────────────────────────────┐
│ [▶ PLAY]  [■ STOP]                            │
│ Volume: [======·····]  Pan: [····=·····]      │
│ [MUTE] [SOLO]                                  │
└────────────────────────────────────────────────┘

┌─ PARAMETERS ───────────────────────────────────┐
│ (Grain controls / Direct controls / Effects)   │
└────────────────────────────────────────────────┘
```

**Implementation Plan:**

1. **Refactor track tab layout** (gui/four-track-view.scd)
   - Move engine mode selector from viewfinder to main track tab
   - Separate recording controls into distinct section
   - Clear visual hierarchy: Source → Mode → Playback → Parameters

2. **Update button logic**
   - Single PLAY button that checks current engine mode
   - Separate REC/STOP REC buttons with clear labels
   - Remove duplicate STOP button confusion

3. **Visual improvements**
   - Use StaticText section headers
   - Group related controls with borders/spacing
   - Color-code: Recording (red), Playback (green), Mode (blue)

4. **Sync with viewfinder**
   - Keep mode button in viewfinder but make it sync with main tab
   - Both buttons should update each other when clicked

**Affected Files:**
- `gui/four-track-view.scd` - Main track tab layout (lines 240-460)
- `gui/viewfinder.scd` - Engine mode button (lines 993-1004)
- `core/track-manager.scd` - Engine mode switching logic

**Next Steps:**
- [ ] Design new track tab layout mockup
- [ ] Refactor four-track-view.scd with new button arrangement
- [ ] Add section headers and visual grouping
- [ ] Implement mode button syncing between main tab and viewfinder
- [ ] Test workflow: Load → Mode → Record → Play → Stop
- [ ] Update user documentation with new layout

**Priority:** HIGH - This affects core workflow and user experience

---

### 6. Master Volume Control Missing

**Symptom:** No master volume control to turn all tracks down at once.

**Current State:**
- Individual track volumes exist on both track tabs and master tab
- Master bus has individual effect controls but no global volume fader
- Master tab has `\masterVol` control (gui/four-track-view.scd:926) but only for final output

**Needed:**
- Prominent master volume fader on master tab
- Should affect all 4 tracks simultaneously
- Should be separate from individual track volumes (pre-master effects)
- Allow quick "dim all" or "fade all" control

**Implementation:**
- Add master volume bus control on master tab
- Consider adding master "panic" button to instantly mute all tracks
- VU meter for master output level

**Priority:** MEDIUM

---

### 7. Parameter Enhancement for Microtonal Detail & Time-Stretching

**Symptom:** Current grain parameters don't provide enough surgical control for deep time-stretching and microtonal manipulation. Need professional-grade granulator features.

**Core Issues:**

#### A. Grain Size Range Too Limited
- **Current:** grainSize defaults to 0.1s (100ms), range unclear
- **Needed:** Allow sub-millisecond control down to 0.005s (5ms)
- **Why:** Very small grains + high density = frozen microtonal textures
- **Impact:** Essential for "microscopic detail" and microtonal work

#### B. Scan Speed Control Missing
- **Current:** scanSpeed parameter exists but not exposed properly
- **Needed:** Very slow modulation capability (near-static playhead)
- **Why:** scanSpeed = 0 creates static position; slow scan reveals microtones
- **Implementation:** Route to modulation window for slow LFO control

#### C. Interpolation Quality
- **Current:** Spectral engine uses interp:4 (cubic)
- **Needed:** Ensure grain engine ALSO uses cubic interpolation
- **Why:** Prevents digital artifacts during extreme time-stretch at sub-sample positions
- **Check:** Verify s4GrainEngine interpolation setting

#### D. Missing Professional Parameters

Add these to defaultParams dictionary:

| Parameter | Function | Why It Matters |
|-----------|----------|----------------|
| **Grain Masking** | Skip certain grains randomly | Creates rhythmic breaks and air in dense textures |
| **Position Warp** | Non-linear playhead movement | Allows playhead to "linger" on microtonal transients |
| **Soft-Sync** | Align grain triggers to sub-harmonic | Creates tonal, pitched buzz from noise samples |
| **Distance/Diffusion** | Randomize grain pan and delay | Moves beyond basic stereo into immersive 3D space |

#### E. Improve Existing Parameters

1. **Position Jitter**
   - Increase range significantly
   - High jitter + small grains = clouds
   - Low jitter + large grains = loops

2. **Overlap**
   - Current: Modest values
   - M4 can handle: 256-512 grains for "super-smooth wall of sound"
   - Exceeds what hardware S-4 units can achieve

**Affected Files:**
- `core/track-manager.scd` - defaultParams dictionary
- `core/grain-engine.scd` - Grain synthesis implementation
- `gui/viewfinder.scd` - Grain control sliders
- `gui/modulation-window.scd` - Modulation routing

**Implementation Priority:**
1. Grain size range (0.005s - 5.0s) - HIGH
2. Verify/fix interpolation quality - HIGH
3. Expose scan speed control - MEDIUM
4. Add grain masking parameter - MEDIUM
5. Add position warp - LOW
6. Add soft-sync - LOW
7. Add distance/diffusion - LOW

---

### 8. GUI Control Improvements - Replace Sliders with High-Resolution Controls

**Symptom:** Standard sliders are notoriously difficult for micro-manipulation required in granular synthesis. Can't find microtonal sweet spots or make precise adjustments.

**Problems with Current Sliders:**

1. **Linear scaling on exponential parameters**
   - grainSize 0.1→0.2 is huge sonic jump
   - Frequency/time parameters feel "jumpy"
   - Hard to find precise values

2. **Low resolution for fine control**
   - Mouse movement too coarse
   - Can't "zoom in" on parameter ranges
   - Difficult for microtonal work

3. **Absolute positioning**
   - MIDI controller jumps when slider position ≠ code value
   - No smooth catch-up behavior

**Proposed Solutions:**

#### A. Two-Dimensional XY Pads (The "Orbital" Approach)

**Why better:**
- Diagonal movement for finding harmonics
- Higher resolution (2D surface area > 1D line)
- More intuitive for related parameters

**Suggested mappings:**
- X: Position, Y: Grain Jitter (scrub + blur control)
- X: Position, Y: Pitch (sample scrubbing with pitch)
- X: Grain Size, Y: Density (texture morphing)

**Implementation:**
- Add Slider2D widgets to viewfinder
- Link to paired parameters
- Visual feedback of current position

#### B. "Infinity" Rotary Encoders (Relative Control)

**For MIDI controllers (KeyStep Pro integration):**

**Current problem:**
- Absolute mapping causes parameter jumps
- Slider at 0.2, code at 0.8 → moving slider jumps to 0.2

**Fix:**
- Use relative (encoder) mode: sends +1/-1 increments
- Scale increments: one full turn = 1% of buffer (microscopic precision)
- No jumps, infinite resolution

**Implementation:**
- Update track-manager.scd to handle relative MIDI
- Add increment scaling per parameter
- Store "last encoder position" to calculate deltas

#### C. Logarithmic/Exponential Scaling

**Current issue:**
- Linear sliders on exponential values (time, frequency)
- Equal slider movement ≠ equal perceptual change

**Fix:**
- Use `.linexp()` or `.lincurve()` instead of `.linlin()`
- Make slider "heavier" at microtonal sweet spots
- Example: grainSize feels more controllable with log scaling

**Implementation:**
```supercollider
// Replace linear mapping:
slider.value.linlin(0, 1, 0.005, 5.0)

// With logarithmic:
slider.value.linexp(0.01, 1, 0.005, 5.0)
```

**Affected parameters:**
- grainSize (0.005s - 5.0s) - LOG
- Frequency controls - EXP
- Time-based effects - LOG
- Filter resonance - CURVE

#### D. Code Improvements for Smoothness

**Add Internal Parameter Smoothing:**

**Current:**
- Raw `.set(param, value)` causes instant jumps
- GUI jitter translates directly to audio glitches

**Fix:**
- Decouple GUI value from engine value using Lag
- Add global 'lag' parameter to synths (20-50ms glide)
- Smooth scrubbing even with jumpy mouse input

**Implementation in track-manager.scd:**
```supercollider
setParam: { arg self, trackNum, param, value;
    var track = tracks[trackNum];
    track.params[param] = value;

    // Add lag to prevent audio glitches
    track.grainSynth.set(param, value);
    // Synth should have internal .lag() on critical params
}
```

**Synth-side:**
- Add `.lag(0.05)` to grainSize, position, pitch in grain engine
- Prevents zipper noise and glitches
- Creates "expensive" smooth feel

#### E. Multi-Touch "Fine Tune" Modifier

**For mouse/trackpad users:**

**Normal Drag:**
- Full 0.0 to 1.0 range
- Coarse adjustment

**Shift + Drag:**
- Divide mouse movement by 10 or 100
- "Zoom in" on parameter value
- Microtonal precision

**Implementation:**
- Detect modifier keys in slider action
- Scale value change based on modifier
- Visual feedback (highlight slider differently)

**Affected Files:**
- `gui/four-track-view.scd` - All parameter sliders
- `gui/viewfinder.scd` - Grain parameter controls
- `core/grain-engine.scd` - Add .lag() smoothing to parameters
- `core/track-manager.scd` - Update setParam logic

**Priority:** HIGH - Core usability for granular synthesis work

---

### 9. Resource Optimization - Parallel Synth Waste

**Symptom:** Creating all three engine types (grain, spectral, direct) simultaneously for every track wastes resources even when paused.

**Current Implementation:**

Each track creates:
1. `grainSynth` - Always allocated
2. `spectralSynth` - Always allocated
3. `directPlaybackSynth` - Always allocated

**The Waste:**

- All synths created at track initialization
- Use `.run(false)` to pause, but still occupy:
  - Node IDs in server
  - Control busses
  - Memory allocation
- Inactive synths can cause "ghost glitches"
- Cluttered node tree (visible in s.plotTree)

**Problems:**

1. **SendReply Waste:**
   - Direct playback fires SendReply at 60Hz even when silent
   - Wastes language-side CPU for inactive tracks

2. **Modulator Mapping:**
   - `routeModulator` creates new mapper synth every time
   - For extreme performance: Single "Modulation Matrix" synth
   - Handle all 16 modulations (4 modulators × 4 tracks) in one UGen block

**Proposed Solution: Dynamic Swapper**

**Instead of parallel allocation:**
- FREE old synth completely
- CREATE new synth only when engineMode changes
- Only allocate what's currently needed

**Benefits:**
- Clean node tree
- No ghost glitches
- Lower memory footprint
- Reduced CPU for inactive engines

**Implementation:**
```supercollider
setParam: { arg self, trackNum, param, value;
    if(param == \engineMode, {
        var track = tracks[trackNum];

        // FREE old synth completely
        case
            { value == 0 } {  // GRANULAR
                track.directPlaybackSynth.free;
                // Create grain synth if needed
            }
            { value == 1 } {  // DIRECT
                track.grainSynth.free;
                track.spectralSynth.free;
                // Create direct synth if needed
            };
    });
}
```

**Considerations:**
- Synth creation latency during mode switch
- Need to preserve parameter state across switches
- Buffer management during transitions

**Affected Files:**
- `core/track-manager.scd` - Synth lifecycle management
- `core/grain-engine.scd` - Resource allocation
- `core/spectral-engine.scd` - Resource allocation
- `core/direct-playback.scd` - Resource allocation, SendReply optimization

**Priority:** MEDIUM - Optimization for M4 performance, reduces waste

---

### 10. Rhythmic and Melodic Quantization Between Engines

**Symptom:** Switching between Direct, Granular, and Spectral engines feels "floaty" and un-synced. Need rhythmic hits and melodic locked-in tones when switching or modulating between engines.

**Root Cause:**
- All three engines run independently with separate playhead positions
- No shared clock synchronization
- Engine switching is immediate rather than quantized to tempo
- No pitch quantization to musical scales

**Four-Part Solution:**

#### A. Rhythmic Quantization: Phase-Lock Method

**Goal:** Synchronize playhead position across all engines to a master clock for rhythmic coherence.

**Implementation Components:**

1. **Shared Phase Bus**
   - Create one global control bus per track for playhead position (0-1 range)
   - All three engines (Direct, Granular, Spectral) read from same phase bus
   - Ensures synchronized playback position across engine switches

2. **Triggered Switching**
   - Replace immediate `.run(false)` switching
   - Use `Select.ar` or gated crossfader inside SynthDefs
   - Allows seamless blending without playhead discontinuities

3. **Snap to Grid**
   - Use `Demand.kr` or `StepNoise.kr` to step playback position
   - Jump playhead by rhythmic increments (e.g., 1/16th of buffer)
   - Creates "rhythmic hits" effect when switching modes

**Example Implementation:**
```supercollider
// In track-manager.scd - create shared phase bus
track.phaseBus = Bus.control(server, 1);

// In grain-engine.scd / direct-playback.scd / spectral-engine.scd
// Read shared phase instead of independent position
var sharedPhase = In.kr(phaseBus, 1);
```

#### B. Melodic Quantization: Scale Snapping

**Goal:** Snap pitch values to musical scales for intentional melodic content, while allowing microtonal divisions for "microscopic" detail.

**Implementation:**

1. **Add Scale Parameter**
   - New parameter in defaultParams: `scale` (array of scale degrees)
   - Presets: Major, Minor, Chromatic, 24-tone microtonal, etc.
   - Custom scale input support

2. **Pitch Quantization Logic**
   - In `track-manager.scd` setParam function
   - Snap incoming pitch values to nearest scale degree
   - Apply to both `pitch` and `spectralPitch` parameters

**Example Implementation:**
```supercollider
// In track-manager.scd setParam:
if(param == \pitch or: { param == \spectralPitch }, {
    var scale = track.params[\scale] ? [0, 2, 4, 5, 7, 9, 11]; // Major
    var snappedPitch = value.round.asInteger;

    // Snap to nearest scale degree
    var nearestDegree = scale.minItem({ |deg|
        (snappedPitch - deg).abs
    });

    value = nearestDegree; // Use quantized pitch
});
```

3. **Microtonal Scale Support**
   - Use 24-tone, 31-tone, or 53-tone equal temperament
   - Snap to microtonal degrees for "intentional" microtonality
   - Avoids out-of-tune randomness while preserving microtonal detail

#### C. Engine "Hits" - The Gate Effect

**Goal:** Create rhythmic "hits" by modulating engine mode in sync with tempo.

**Implementation:**

1. **Pulse Wave Modulation**
   - Route square-wave LFO from s4Modulator to new `engineMorph` parameter
   - Hard-switch between Direct (solid) and Granular (textured) in perfect time
   - Creates rhythmic "chop" effect

2. **Spectral Bursts**
   - Use "Random" modulator shape to trigger spectral engine
   - Bursts last a few milliseconds
   - Creates melodic, shimmering highlights on top of direct loop

3. **New Parameter: engineMorph**
   - Float 0-2 range: 0=Direct, 1=Granular, 2=Spectral
   - Can be modulated smoothly for crossfades
   - Or stepped for hard rhythmic switching

**Example Implementation:**
```supercollider
// In grain-engine.scd (or combined multi-engine synth):
var engineMorph = \engineMorph.kr(0).lag(0.05);

// Three parallel engines
var directSig = /* direct playback */;
var grainSig = /* granular */;
var spectralSig = /* spectral */;

// Crossfade between them based on engineMorph
var sig = SelectX.ar(engineMorph.clip(0, 2), [
    directSig,
    grainSig,
    spectralSig
]);
```

#### D. Code Cleanup: Dynamic Modulator Allocation

**Current Waste:**
- 4 modulators × 4 tracks = 16 modulators initialized immediately
- 16 control busses allocated even if unused
- Unnecessary memory overhead on M4

**Solution:**
- Move to **dynamic allocation**
- Only create `modBus` and `modMapper` when `routeModulator` is actually called
- Free unused modulators to keep Node Tree clean

**Implementation in track-manager.scd:**
```supercollider
routeModulator: { arg self, trackNum, modNum, targetParam, minVal, maxVal;
    var track = tracks[trackNum];

    // Only create bus if it doesn't exist yet
    if(track.modBusses[modNum].isNil, {
        track.modBusses[modNum] = Bus.control(server, 1);
    });

    // Only create mapper if it doesn't exist yet
    if(track.modMappers[modNum].isNil, {
        // Create mapper synth
    });

    // Rest of routing logic...
}
```

**Affected Files:**
- `core/track-manager.scd` - Add phase bus, scale parameter, dynamic modulator allocation
- `core/grain-engine.scd` - Read shared phase, add scale quantization
- `core/direct-playback.scd` - Read shared phase
- `core/spectral-engine.scd` - Read shared phase, add scale quantization
- `gui/viewfinder.scd` - Add scale selector UI
- `gui/modulation-window.scd` - Add engineMorph as modulation target

**Implementation Priority:**
1. Shared phase bus for rhythmic sync - HIGH
2. Pitch quantization to scales - HIGH
3. Engine morph parameter for smooth switching - MEDIUM
4. Snap-to-grid rhythmic quantization - MEDIUM
5. Dynamic modulator allocation - MEDIUM
6. Spectral burst modulation - LOW

**Benefits:**
- Rhythmic coherence when switching engines
- Melodic control over pitch instead of random microtonality
- "Hits" and rhythmic effects via modulation
- Cleaner resource usage
- Professional granulator feel

**Priority:** HIGH - Core feature for musical control and rhythmic effects

---

### 11. Quad Spatial Presets and GUI Buttons

**Symptom:** Quad spatial panner exists but lacks easy-access preset buttons. Need to integrate spatial presets from `quad-spatial-examples.scd` into the main GUI for quick spatial arrangement changes.

**Current State:**

**Existing Quad Panner GUI:**
- Visual 2D panner with drag-and-drop track positioning (`gui/quad-panner.scd`)
- Manual positioning via mouse
- Color-coded tracks (cyan, yellow, green, orange)
- Currently accessed only from Track 1 tab (gui/four-track-view.scd:220-231)

**Existing Spatial Presets** (in examples file):
1. **Corners** - All tracks in quad corners
2. **Front Row** - Front stereo pair arrangement
3. **Circle** - Tracks positioned in circle around listener
4. **Mono** - All tracks centered
5. **Distant** - All tracks rear (creates "far away" effect)

**Existing Spatial Automation** (code-based):
- Rotating movement (single, dual, quad windmill)
- Ping-pong between speakers
- Random spatial drift
- Orbital movement with different speeds
- Depth oscillation (front/back)
- Spectral spatial spread

**Proposed Solution:**

#### A. Add Preset Buttons to Quad Panner GUI

**Add button row to quad panner window:**

```supercollider
// In gui/quad-panner.scd - add after canvas, before close button

// Spatial Presets Section
StaticText(window, Rect(10, canvasHeight + 70, canvasWidth - 20, 20))
    .string_("SPATIAL PRESETS")
    .font_(Font("DejaVu Sans Mono", 11, true))
    .stringColor_(colors.cyan);

// First row of preset buttons
Button(window, Rect(10, canvasHeight + 90, 75, 25))
    .states_([["CORNERS", colors.fg, colors.blue]])
    .action_({ self.applyPreset(\corners) });

Button(window, Rect(90, canvasHeight + 90, 75, 25))
    .states_([["FRONT", colors.fg, colors.green]])
    .action_({ self.applyPreset(\frontRow) });

Button(window, Rect(170, canvasHeight + 90, 75, 25))
    .states_([["CIRCLE", colors.fg, colors.yellow]])
    .action_({ self.applyPreset(\circle) });

Button(window, Rect(250, canvasHeight + 90, 75, 25))
    .states_([["MONO", colors.fg, colors.orange]])
    .action_({ self.applyPreset(\mono) });

Button(window, Rect(330, canvasHeight + 90, 70, 25))
    .states_([["DISTANT", colors.fg, colors.magenta]])
    .action_({ self.applyPreset(\distant) });
```

#### B. Add Preset Implementation Method

**Add to quad-panner publicAPI:**

```supercollider
applyPreset: { arg self, presetName;
    case
        { presetName == \corners } {
            trackPositions[0] = [-0.7, -0.7];
            trackPositions[1] = [ 0.7, -0.7];
            trackPositions[2] = [-0.7,  0.7];
            trackPositions[3] = [ 0.7,  0.7];
        }
        { presetName == \frontRow } {
            trackPositions[0] = [-0.7, -0.5];
            trackPositions[1] = [ 0.7, -0.5];
            trackPositions[2] = [-0.3, -0.5];
            trackPositions[3] = [ 0.3, -0.5];
        }
        { presetName == \circle } {
            trackPositions[0] = [ 0.0, -0.7];  // Front
            trackPositions[1] = [ 0.7,  0.0];  // Right
            trackPositions[2] = [ 0.0,  0.7];  // Rear
            trackPositions[3] = [-0.7,  0.0];  // Left
        }
        { presetName == \mono } {
            4.do({ arg i;
                trackPositions[i] = [0, 0];
            });
        }
        { presetName == \distant } {
            trackPositions[0] = [-0.3,  0.8];
            trackPositions[1] = [ 0.3,  0.8];
            trackPositions[2] = [-0.5,  0.9];
            trackPositions[3] = [ 0.5,  0.9];
        };

    // Apply positions to track manager
    4.do({ arg i;
        trackManager.setQuadPosition(i,
            trackPositions[i][0],
            trackPositions[i][1]
        );
    });

    // Refresh canvas
    canvas.refresh;
},
```

#### C. Add Automation Control Buttons (Optional)

**Add second row for spatial automation:**

```supercollider
// Automation Controls Section
StaticText(window, Rect(10, canvasHeight + 120, canvasWidth - 20, 20))
    .string_("AUTOMATION")
    .font_(Font("DejaVu Sans Mono", 11, true))
    .stringColor_(colors.orange);

Button(window, Rect(10, canvasHeight + 140, 90, 25))
    .states_([
        ["ROTATE ▶", colors.fg, colors.green],
        ["STOP ■", colors.black, colors.red]
    ])
    .action_({ arg btn;
        if(btn.value == 1, {
            self.startRotation;
        }, {
            self.stopRotation;
        });
    });

Button(window, Rect(105, canvasHeight + 140, 90, 25))
    .states_([
        ["PING-PONG ▶", colors.fg, colors.green],
        ["STOP ■", colors.black, colors.red]
    ])
    .action_({ arg btn;
        if(btn.value == 1, {
            self.startPingPong;
        }, {
            self.stopPingPong;
        });
    });

Button(window, Rect(200, canvasHeight + 140, 90, 25))
    .states_([
        ["DRIFT ▶", colors.fg, colors.green],
        ["STOP ■", colors.black, colors.red]
    ])
    .action_({ arg btn;
        if(btn.value == 1, {
            self.startDrift;
        }, {
            self.stopDrift;
        });
    });

Button(window, Rect(295, canvasHeight + 140, 90, 25))
    .states_([
        ["ORBIT ▶", colors.fg, colors.green],
        ["STOP ■", colors.black, colors.red]
    ])
    .action_({ arg btn;
        if(btn.value == 1, {
            self.startOrbit;
        }, {
            self.stopOrbit;
        });
    });
```

#### D. Implement Automation Methods

**Add automation Task management to publicAPI:**

```supercollider
// Automation tasks
spatialRotation: nil,
spatialPingPong: nil,
spatialDrift: nil,
spatialOrbit: nil,

startRotation: { arg self;
    self.stopRotation; // Stop if already running
    spatialRotation = Task({
        var angle = 0;
        loop {
            4.do({ arg i;
                var offset = i * 0.5pi; // 90° apart
                var x = (angle + offset).cos;
                var y = (angle + offset).sin;
                trackManager.setQuadPosition(i, x, y);
                trackPositions[i] = [x, y];
            });
            angle = angle + 0.01; // Rotation speed
            0.05.wait;
            { canvas.refresh }.defer; // Update GUI
        }
    }).play;
},

stopRotation: { arg self;
    if(spatialRotation.notNil, { spatialRotation.stop });
},

// Similar methods for startPingPong, startDrift, startOrbit...
```

#### E. Add Quick-Access Buttons to Main GUI

**Option 1: Add to Master Tab**

Add spatial preset buttons to the master tab alongside master controls:

```supercollider
// In gui/four-track-view.scd - makeMasterTab function
// Add after Quad Panner button (line ~823)

StaticText(parent, Rect(430, yPos, 150, 20))
    .string_("Quad Presets:")
    .font_(Font("DejaVu Sans Mono", 9));

Button(parent, Rect(540, yPos, 60, 25))
    .states_([["CORNERS", colors.fg, colors.blue]])
    .action_({ ~quadPanner.applyPreset(\corners) });

Button(parent, Rect(605, yPos, 60, 25))
    .states_([["CIRCLE", colors.fg, colors.yellow]])
    .action_({ ~quadPanner.applyPreset(\circle) });

Button(parent, Rect(670, yPos, 60, 25))
    .states_([["MONO", colors.fg, colors.orange]])
    .action_({ ~quadPanner.applyPreset(\mono) });
```

**Option 2: Add to Individual Track Tabs**

Add small spatial preset dropdown to each track tab for per-track positioning.

**Proposed Presets to Implement:**

**Essential (High Priority):**
1. **Corners** - Classic quad setup
2. **Front Row** - Performance/stereo fallback
3. **Circle** - Equal spacing around listener
4. **Mono** - Center all (compatibility)
5. **Distant** - Ambient/reverberant effect

**Automation (Medium Priority):**
6. **Rotate** - Windmill effect (all 4 tracks)
7. **Ping-Pong** - Bounce between corners
8. **Drift** - Random spatial movement
9. **Orbit** - Multiple orbital speeds

**Advanced (Low Priority):**
10. **Spectral Spread** - Low front, high rear
11. **Depth Oscillate** - Front/back movement
12. **Custom** - Save current positions as preset

**Affected Files:**
- `gui/quad-panner.scd` - Add preset buttons and automation controls
- `examples/quad-spatial-examples.scd` - Migrate preset code to panner
- `gui/four-track-view.scd` - Add quick-access buttons to master tab
- `core/track-manager.scd` - Ensure setQuadPosition is working properly

**Implementation Priority:**
1. Add 5 essential preset buttons to quad panner GUI - HIGH
2. Implement applyPreset method - HIGH
3. Add quick-access buttons to master tab - MEDIUM
4. Add 4 automation toggle buttons - MEDIUM
5. Implement automation Task methods - MEDIUM
6. Add custom preset save/recall - LOW

**Benefits:**
- One-click spatial arrangement changes
- Easy access to proven spatial configurations
- Automated spatial movement for live performance
- Visual feedback of preset positions
- Integration with existing quad panner workflow

**Priority:** MEDIUM - Quality of life improvement for quad users

---

### 12. Track 1 Waveform Lost After Extended Looping

**Symptom:** Track 1 lost its waveform display in the track window (viewfinder) after looping for hours.

**Context:**
- Waveform display likely uses buffer data for visualization
- Extended looping session caused waveform to disappear
- May be memory issue, buffer corruption, or display refresh problem

**Possible Causes:**
1. **Buffer Management Issue:**
   - Buffer may have been freed or corrupted during long session
   - Temp file path lost or file deleted by OS
   - Buffer reference became nil

2. **Display Refresh Issue:**
   - Waveform drawing stopped updating
   - Canvas refresh task died or stopped
   - UserView drawFunc no longer being called

3. **Memory Leak:**
   - Extended session caused memory pressure
   - Buffer or waveform data deallocated by garbage collector
   - File handle closed by OS after hours of activity

**Affected Files:**
- `gui/viewfinder.scd` - Waveform display and refresh logic
- `core/track-manager.scd` - Buffer management and file path storage
- `core/buffer-recorder.scd` - Temporary file management

**Next Steps:**
- [ ] Check if buffer is still valid after extended session
- [ ] Verify temp file still exists on disk
- [ ] Add buffer validity checks before drawing waveform
- [ ] Implement waveform refresh/reload button
- [ ] Add error handling for missing buffer/file
- [ ] Test extended looping session (4+ hours) to reproduce

**Priority:** MEDIUM - Stability issue for long sessions

---

### 13. Window Management Issues - Viewfinder and Modulation Windows

**Symptom:** Clicking "LOOP VIEW" or "MOD" buttons creates new window every time instead of focusing existing window. Multiple duplicate windows can be opened.

**Current Problems:**

**A. Viewfinder Button Issues:**
1. **Button Label:** Says "LOOP VIEW" but should be "TRACK VIEW" or "WAVEFORM VIEW"
   - Location: gui/four-track-view.scd:208-217
   - Misleading name - not just for loops, shows full waveform

2. **Creates Duplicate Windows:**
   - Each button press opens new viewfinder window
   - Should check if window already exists for that track
   - Should bring existing window to front or do nothing

**B. Modulation Window Issues:**
1. **Same Duplicate Problem:**
   - MOD button (gui/four-track-view.scd:201-205)
   - Creates new modulation window every press
   - Should reuse existing window

**Proposed Solution:**

#### A. Window Instance Tracking

**Store window references in track manager or GUI:**

```supercollider
// In gui/four-track-view.scd or track-manager
var viewfinderWindows = Array.newClear(4);  // One per track
var modulationWindows = Array.newClear(4);  // One per track
```

#### B. Update Button Actions with Window Checks

**Viewfinder Button (rename to "TRACK VIEW"):**

```supercollider
// Replace LOOP VIEW button (line 208-217)
Button(parent, Rect(675, 10, 70, 40))
    .states_([["TRACK\nVIEW", colors.fg, colors.blue]])  // Renamed
    .font_(Font("DejaVu Sans Mono", 9, true))
    .action_({
        // Check if window already exists
        if(viewfinderWindows[trackNum].notNil and: {
            viewfinderWindows[trackNum].window.notNil and: {
                viewfinderWindows[trackNum].window.isClosed.not
            }
        }, {
            // Window exists - bring to front
            viewfinderWindows[trackNum].window.front;
        }, {
            // Window doesn't exist - create new one
            if(~viewfinder.notNil, {
                viewfinderWindows[trackNum] = ~viewfinder.createWindow(trackNum);
            }, {
                "Viewfinder not initialized. Run main.scd first.".warn;
            });
        });
    });
```

**Modulation Button:**

```supercollider
// Replace MOD button (line 201-205)
Button(parent, Rect(610, 10, 60, 40))
    .states_([["MOD", colors.black, colors.cyan]])
    .action_({
        // Check if window already exists
        if(modulationWindows[trackNum].notNil and: {
            modulationWindows[trackNum].window.notNil and: {
                modulationWindows[trackNum].window.isClosed.not
            }
        }, {
            // Window exists - bring to front
            modulationWindows[trackNum].window.front;
        }, {
            // Window doesn't exist - create new one
            modulationWindows[trackNum] = ~s4ModulationWindow.value(
                trackManager, server, trackNum
            ).create;
        });
    });
```

#### C. Update Viewfinder/Modulation to Return Window Reference

**Ensure createWindow returns publicAPI with window reference:**

```supercollider
// In viewfinder.scd and modulation-window.scd
publicAPI = (
    window: nil,
    createWindow: { arg self, trackNum;
        // ... existing code ...
        window = Window(...).front;
        self;  // Return publicAPI so caller can store reference
    }
);
```

**Affected Files:**
- `gui/four-track-view.scd` - Update button labels and actions
- `gui/viewfinder.scd` - Ensure window reference is returned
- `gui/modulation-window.scd` - Ensure window reference is returned

**Priority:** MEDIUM - Quality of life, prevents window clutter

---

### 14. Move MOD Buttons to Main Track Tabs

**Symptom:** MOD buttons currently on individual track tabs (lines 201-205) but should be moved to main tab next to VIEW buttons for better organization.

**Current Layout:**
- MOD button on each individual track tab (Track 1, Track 2, Track 3, Track 4)
- Located at coordinates (610, 10, 60, 40)

**Proposed Layout:**
- Move MOD buttons to top of each track tab alongside other utility buttons
- Place next to "TRACK VIEW" button for logical grouping
- Or add to master tab for centralized access

**Option 1: Keep on Individual Track Tabs (Reorganize)**
```supercollider
// On each track tab, group utility buttons together
[TRACK VIEW] [MOD] [QUAD PANNER]
```

**Option 2: Add to Master Tab (Centralized)**
```supercollider
// On master tab, add MOD buttons for all tracks
Track 1: [VIEW] [MOD]
Track 2: [VIEW] [MOD]
Track 3: [VIEW] [MOD]
Track 4: [VIEW] [MOD]
```

**Recommendation:** Keep on individual track tabs but group with VIEW button as "utility row"

**Affected Files:**
- `gui/four-track-view.scd` - Reposition MOD buttons

**Priority:** LOW - Organizational improvement

---

### 15. Master Tab Redesign - Digitone-Style Layout with Master EQ/Effects

**Symptom:** Master tab needs complete redesign to follow Digitone workflow: individual track overviews + master effects section that affects all tracks.

**Current Master Tab Issues:**
- Has individual track controls (volume, pan, mute, solo)
- Has 128-band resonator filter
- Missing comprehensive master EQ
- Missing master effects chain (separate from per-track effects)
- No clear visual hierarchy between track section and master section

**Proposed Layout (Digitone-Inspired):**

```
MASTER TAB LAYOUT:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

┌─ TRACK OVERVIEW ──────────────────────────────────────────────┐
│                                                                │
│ Track 1:  [VU Meter]  Vol [===·····]  Pan [··=····]  [M][S]  │
│ Track 2:  [VU Meter]  Vol [===·····]  Pan [··=····]  [M][S]  │
│ Track 3:  [VU Meter]  Vol [===·····]  Pan [··=····]  [M][S]  │
│ Track 4:  [VU Meter]  Vol [===·····]  Pan [··=····]  [M][S]  │
│                                                                │
│ [PLAY ALL] [STOP ALL]    [STEREO/QUAD TOGGLE]                │
└────────────────────────────────────────────────────────────────┘

┌─ MASTER EFFECTS ──────────────────────────────────────────────┐
│                                                                │
│ ┌─ MASTER EQ ───────────────────────────────────────────┐    │
│ │ [ON/OFF]                                               │    │
│ │ Low:    Gain [··=····]  Freq [==·····]  Q [===···]   │    │
│ │ Mid:    Gain [··=····]  Freq [==·····]  Q [===···]   │    │
│ │ High:   Gain [··=····]  Freq [==·····]  Q [===···]   │    │
│ └────────────────────────────────────────────────────────┘    │
│                                                                │
│ ┌─ MASTER COMPRESSOR ──────────────────────────────────┐    │
│ │ [ON/OFF]                                              │    │
│ │ Threshold [===·····]  Ratio [==·····]  Attack [··=·] │    │
│ │ Release [===····]  Makeup [··=····]                   │    │
│ └────────────────────────────────────────────────────────┘    │
│                                                                │
│ ┌─ MASTER REVERB ──────────────────────────────────────┐    │
│ │ [ON/OFF]                                              │    │
│ │ Size [===·····]  Damping [==·····]  Mix [··=·····]   │    │
│ └────────────────────────────────────────────────────────┘    │
│                                                                │
│ ┌─ MASTER LIMITER ─────────────────────────────────────┐    │
│ │ [ON/OFF]                                              │    │
│ │ Ceiling [=========·]  Release [===····]               │    │
│ └────────────────────────────────────────────────────────┘    │
│                                                                │
│ Master Volume: [====================·]  [VU METER]            │
│                                                                │
└────────────────────────────────────────────────────────────────┘

┌─ UTILITIES ───────────────────────────────────────────────────┐
│ [SPECTRUM ANALYZER]  [QUAD PANNER]  [CPU MONITOR]            │
│ Quad Presets: [CORNERS] [CIRCLE] [MONO]                      │
└────────────────────────────────────────────────────────────────┘
```

**Key Differences from Current Layout:**

**1. Clear Visual Separation:**
- Top section: Track overview (simplified controls)
- Middle section: Master effects chain (NEW)
- Bottom section: Utilities and presets

**2. Master Effects Chain (NEW):**
- **Master EQ** - 3-band parametric EQ
  - Each band: Gain, Frequency, Q
  - Affects all tracks after individual processing

- **Master Compressor** - Bus compressor
  - Threshold, Ratio, Attack, Release, Makeup Gain
  - "Glue" compressor for cohesive mix

- **Master Reverb** - Global reverb send
  - Separate from per-track reverbs
  - Adds cohesive space to entire mix

- **Master Limiter** - Output protection
  - Ceiling control (prevent clipping)
  - Fast release for transparent limiting

**3. Simplified Track Overview:**
- Essential controls only (Volume, Pan, Mute, Solo)
- VU meters for visual feedback
- Remove detailed filter controls (move to individual tracks)

**4. Master Volume:**
- Prominent master fader
- Affects final output after all effects
- Accompanied by master VU meter

**Implementation Approach:**

**A. Create Master Effects SynthDefs:**

```supercollider
// New file: core/master-effects.scd

SynthDef(\s4MasterEQ, {
    arg in, out,
        lowGain = 0, lowFreq = 200, lowQ = 1,
        midGain = 0, midFreq = 1000, midQ = 1,
        highGain = 0, highFreq = 5000, highQ = 1,
        mix = 1;

    var sig = In.ar(in, 2);
    var eq;

    // 3-band parametric EQ
    eq = BPeakEQ.ar(sig, lowFreq, lowQ, lowGain);
    eq = BPeakEQ.ar(eq, midFreq, midQ, midGain);
    eq = BPeakEQ.ar(eq, highFreq, highQ, highGain);

    sig = (sig * (1 - mix)) + (eq * mix);
    Out.ar(out, sig);
}).add;

SynthDef(\s4MasterCompressor, {
    // Bus compressor implementation
}).add;

SynthDef(\s4MasterReverb, {
    // Global reverb send
}).add;

SynthDef(\s4MasterLimiter, {
    // Output limiter
}).add;
```

**B. Update Master Bus Chain:**

```supercollider
// In track-manager or main.scd
// Insert master effects between track mix and final output

~masterBus → [Master EQ] → [Master Comp] → [Master Reverb] → [Master Limiter] → Output
```

**C. Redesign Master Tab GUI:**

```supercollider
// In gui/four-track-view.scd - makeMasterTab function
// Complete rewrite following layout above
// Group controls into sections with clear visual hierarchy
```

**Affected Files:**
- `core/master-effects.scd` - NEW FILE - Master effects SynthDefs
- `core/track-manager.scd` - Update master bus chain
- `gui/four-track-view.scd` - Redesign makeMasterTab function
- `main.scd` - Load master effects and initialize chain

**Implementation Priority:**
1. Create master EQ SynthDef - HIGH
2. Create master compressor SynthDef - HIGH
3. Create master limiter SynthDef - HIGH
4. Create master reverb SynthDef - MEDIUM
5. Redesign master tab GUI layout - HIGH
6. Wire master effects into signal chain - HIGH
7. Add master volume control - HIGH
8. Update master bus routing - HIGH

**Benefits:**
- Professional mixing workflow (like Digitone)
- Clear separation between track and master processing
- Master EQ for overall tonal shaping
- Master compressor for "glue"
- Output limiting prevents clipping
- Cohesive master reverb space
- Improved visual hierarchy

**Priority:** HIGH - Critical for professional mixing workflow

---

## Test Notes

*Additional notes will be added here as testing continues...*
