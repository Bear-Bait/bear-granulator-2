# Phase 6: Material Modes
**Version: 0.6.0**
**Status: Planning**

## Overview
Add different buffer playback modes to give the granular engine distinct sonic characters and workflows.

## Three Material Modes

### 1. TAPE Mode (Current Default)
**Character:** Continuous tape loop
**Playback:** Grains read from a continuously looping buffer
**Use Case:** Texture generation, ambient soundscapes, continuous evolution

**Features:**
- Rolling 4-second buffer (already implemented)
- Live input recording
- Position playback head moves through buffer
- Natural for ambient/drone/texture work

### 2. POLY Mode
**Character:** Polyphonic sample playback
**Playback:** Multiple independent grain voices, each with their own position
**Use Case:** Melodic sequences, polyrhythms, granular synthesis as an instrument

**Features:**
- Fixed buffer (no rolling/overwriting)
- Each grain can have independent:
  - Start position
  - Pitch
  - Envelope
- MIDI input triggering (optional)
- Voices can stack/overlap
- More "playable" than TAPE mode

### 3. LIVE Mode
**Character:** Real-time input processing
**Playback:** Grains process live audio with minimal latency
**Use Case:** Live performance, real-time effects, instrument processing

**Features:**
- Very short buffer (100-500ms)
- Grains read from "recent past" of live input
- Lower latency than TAPE mode
- Position parameter becomes "lookback time"
- Ideal for processing voice, guitar, synth in real-time

## Implementation Plan

### Step 1: Architecture Changes
**File:** `core/grain-engine.scd`

Add mode parameter to SynthDef:
```supercollider
arg mode = 0,  // 0=TAPE, 1=POLY, 2=LIVE
```

Modify buffer position logic:
- TAPE: Current looping behavior
- POLY: Fixed position per grain trigger
- LIVE: Position = "time ago" from write head

### Step 2: Buffer Management
**File:** `core/track-manager.scd`

- TAPE mode: Use existing 4-second rolling buffer
- POLY mode: Load fixed audio file, no rolling
- LIVE mode: Allocate 500ms circular buffer

### Step 3: GUI Updates
**File:** `gui/four-track-view.scd`

Add mode selector per track:
- Dropdown or button group: [TAPE | POLY | LIVE]
- Update parameter labels based on mode:
  - TAPE: "Position" (0-1 in loop)
  - POLY: "Start Point" (0-1 in sample)
  - LIVE: "Lookback" (ms in past)

### Step 4: Per-Mode Features

**POLY Mode Specific:**
- File browser for loading samples
- Voice stealing algorithm (if >128 grains)
- Optional MIDI note input
- Pitch quantization option

**LIVE Mode Specific:**
- Auto-detect input (always recording)
- Latency compensation
- Freeze button (stop updating buffer)

## Technical Considerations

### Buffer Allocation
- TAPE: 192000 frames (4 sec @ 48kHz) - existing
- POLY: Variable size based on loaded file
- LIVE: 24000 frames (500ms @ 48kHz) - new

### CPU Impact
- POLY mode may use more CPU (fixed buffer = less cache-friendly)
- LIVE mode should be most efficient (smallest buffer)

### Backward Compatibility
- Default to TAPE mode (mode=0)
- Existing projects continue working
- Mode saved in presets (Phase 7)

## Testing Criteria

### TAPE Mode
- ✓ Already working (existing behavior)
- Verify mode switching doesn't break it

### POLY Mode
- [ ] Load various audio files (wav, aiff, flac)
- [ ] Verify grain start positions are accurate
- [ ] Test voice count under load (128 grains)
- [ ] Check memory usage with large files

### LIVE Mode
- [ ] Verify low latency (<50ms perceptual)
- [ ] Test freeze functionality
- [ ] Ensure no buffer overflow/underflow
- [ ] Check with various input sources

## Open Questions

1. **POLY Mode:** Should we support multi-sample per track (e.g., chromatic sampling)?
2. **LIVE Mode:** Include a record-to-TAPE button to capture processed audio?
3. **GUI:** Per-mode color coding for quick visual identification?
4. **Presets:** Should mode be saved per-track or globally?

## Success Criteria

Phase 6 is complete when:
1. All three modes work reliably
2. Mode switching is glitch-free (no audio pops)
3. Each mode has its distinct sonic character
4. GUI clearly indicates current mode
5. Documentation includes use cases for each mode

## Timeline Estimate

- **Step 1 (Architecture):** ~2 hours - Modify grain engine for mode switching
- **Step 2 (Buffer):** ~1 hour - Add buffer management logic
- **Step 3 (GUI):** ~2 hours - Mode selector and dynamic UI
- **Step 4 (Features):** ~3 hours - Per-mode specific features
- **Testing:** ~2 hours - Verify all modes work correctly

**Total:** ~10 hours development + testing

## Next Phase Preview

**Phase 7:** Preset System
- Save/recall all track parameters
- Include modulation routing
- Per-track and global presets
- Preset browser/manager
