# Phase 7: Dynamic Windowing Sampler (Waveform Viewfinder)

**Version:** v0.7.001
**Date:** 2026-01-01
**Status:** ✅ Implementation Complete - Ready for Testing

---

## Overview

Phase 7 implements a **real-time non-destructive loop window selection** system using SuperCollider's SoundFileView. This allows you to visually select which portion of your audio buffer the grains read from, without destroying the original audio.

### Inspiration

This feature is inspired by:
- **Torso Electronics BEARULATOR** - Encoder-based loop start/end control
- **Monome Norns "Crone" engine** - Window size + position parameters

### Key Features

✅ **Visual waveform display** with SoundFileView
✅ **Drag-to-select** interface for loop boundaries
✅ **Real-time engine updates** - no need to press "apply"
✅ **Per-track viewfinders** - independent loop windows for all 4 tracks
✅ **Non-destructive** - original buffer remains untouched
✅ **Integrated with Material Modes** - works with TAPE/POLY/LIVE

---

## How It Works

### The Bridge Architecture

```
┌─────────────────┐
│  SoundFileView  │  ← User drags to select region
│   (GUI Layer)   │
└────────┬────────┘
         │ mouseUpAction / mouseMoveAction
         ↓
┌─────────────────┐
│ TrackManager    │  ← Normalizes selection to 0-1
│  .setParam()    │     Validates minimum window size
└────────┬────────┘
         │ \loopStart, \loopEnd
         ↓
┌─────────────────┐
│ s4GrainEngine   │  ← Grains read within loop window
│  (Audio Layer)  │     position.linlin(0, 1, loopStart, loopEnd)
└─────────────────┘
```

### Selection-to-Parameter Mapping

**GUI → Normalized Values:**
```supercollider
var startFrame = view.selection(0)[0];
var duration = view.selection(0)[1];
var endFrame = startFrame + duration;
var numFrames = buffer.numFrames;

var loopStart = (startFrame / numFrames).clip(0.0, 1.0);
var loopEnd = (endFrame / numFrames).clip(0.0, 1.0);
```

**Engine → Buffer Playback:**
```supercollider
// In TAPE mode (mode 0):
bufPos = position.linlin(0, 1, loopStart, loopEnd)
         .wrap(loopStart, loopEnd);
```

---

## Usage

### Opening Viewfinders

**From GUI:**
- Click the **"LOOP VIEW"** button (blue) on any track tab
- Or click the **"VIEW"** button in the mixer overview

**From Code:**
```supercollider
// Open viewfinder for Track 1
~viewfinder.createWindow(0);

// Open viewfinder for Track 2
~viewfinder.createWindow(1);

// Open all 4 viewfinders at once
~viewfinder.createAll;
```

### Selecting Loop Regions

1. **Drag across the waveform** to highlight a region
2. **Release mouse** - loop boundaries update immediately
3. **Post window shows feedback:**
   ```
   Track 1: Loop Window Set
     Start: 0.523s (21.4%)
     End: 1.847s (75.6%)
     Duration: 1.324s
   ```

### Updating Waveform Display

If you load a new audio file:
```supercollider
~viewfinder.updateWaveform(0); // Update Track 1 viewfinder
```

### Closing Viewfinders

```supercollider
~viewfinder.closeAll;  // Close all viewfinder windows
```

Or just close the window manually (X button).

---

## Integration with Material Modes

### TAPE Mode (Looping Sampler)

**How it works:**
- Grains loop continuously within the loop window
- Position slider scans through the window (0.0 = loop start, 1.0 = loop end)
- Perfect for creating evolving textures from short segments

**Example:**
```supercollider
~trackManager.setMode(0, 0);  // TAPE mode
// Select middle 30% of buffer in viewfinder
// Result: Grains loop only that 30% section
```

**Use Cases:**
- Isolate a word/syllable and loop it
- Create rhythmic stutters from short segments
- Scan through a specific phrase with Position slider

---

### POLY Mode (Sample Playback)

**How it works:**
- Grains trigger from a **fixed position** within the loop window
- Position slider sets the trigger point (0.0 = window start, 1.0 = window end)
- No looping - grains read forward from trigger point

**Example:**
```supercollider
~trackManager.setMode(0, 1);  // POLY mode
// Select "houston" word in viewfinder
// Set Position to 0.0
// Result: Every grain starts at "hou" syllable
```

**Use Cases:**
- Sample triggering (like an MPC/sampler)
- Transient shaping (select attack portion only)
- Layered sample playback

---

### LIVE Mode (Lookback Buffer)

**How it works:**
- Grains read **backward in time** from the loop window end
- Position slider = "how far back" (0.0 = most recent, 1.0 = window start)
- Simulates "live input" delay/looping

**Example:**
```supercollider
~trackManager.setMode(0, 2);  // LIVE mode
// Select last 2 seconds of buffer in viewfinder
// Set Position to 0.3 (30% back in time)
// Result: Grains read from 600ms ago
```

**Use Cases:**
- Live input processing with delay
- Echoes and feedback effects
- Time-stretching recent audio

---

## Practical Examples

### Example 1: Isolate a Word (TAPE Mode)

**Scenario:** You have a vocal phrase "columbia this houston over" and want to loop only "houston".

**Steps:**
1. Load the audio file on Track 1
2. Click **"LOOP VIEW"** button
3. Drag across the "houston" waveform (middle section)
4. Set Material Mode to **TAPE** (if not already)
5. Adjust grain parameters:
   - Grain Size: 80ms
   - Overlap: 4
   - Position: 0.5 (middle of loop window)

**Result:** You hear only "houston" looping continuously. Move the Position slider to scan through different parts of the word.

---

### Example 2: Sample Trigger (POLY Mode)

**Scenario:** Create a kick drum from a full drum loop by isolating just the kick transient.

**Steps:**
1. Load drum loop on Track 2
2. Open viewfinder: `~viewfinder.createWindow(1)`
3. Zoom in and select **just the kick transient** (first 50ms)
4. Set Material Mode to **POLY**
5. Set grain parameters:
   - Grain Size: 200ms (longer than window = full kick decay)
   - Overlap: 1
   - Position: 0.0 (trigger from start)

**Result:** Each grain plays the entire kick drum sample from the beginning. Vary overlap to create kick "rolls".

---

### Example 3: Live Delay Effect (LIVE Mode)

**Scenario:** Create a granular delay effect on live input.

**Steps:**
1. Track 3: Record 4 seconds of live input
2. Open viewfinder: `~viewfinder.createWindow(2)`
3. Select the **entire buffer** (full 4 seconds)
4. Set Material Mode to **LIVE**
5. Set grain parameters:
   - Grain Size: 100ms
   - Overlap: 8 (dense)
   - Position: Modulate with LFO (0.0 to 0.5)

**Result:** Grains read from 0-2 seconds ago, creating a granular delay that sweeps through time.

---

### Example 4: Evolving Texture (TAPE Mode + Modulation)

**Scenario:** Create an evolving pad sound that morphs through different sections of audio.

**Steps:**
1. Load textural audio (field recording, synth pad) on Track 4
2. Open viewfinder
3. Select **middle 50%** of buffer
4. Set Material Mode to **TAPE**
5. Set grain parameters:
   - Grain Size: 150ms
   - Overlap: 12 (very dense)
   - Position: 0.5
   - Pitch: -12 (octave down)
6. **Add modulation:**
   - Open MOD window
   - LFO 1 → Position (rate: 0.1 Hz, depth: 0.5)

**Result:** Dense grain cloud that slowly scans through the loop window, creating ambient textures.

---

## Technical Details

### Validation

**Minimum Window Size:**
- Loop window must be at least **1% of buffer length**
- Prevents accidentally selecting empty regions
- Warning posted if window too small

**Boundary Clamping:**
```supercollider
loopStart = loopStart.clip(0.0, 1.0);
loopEnd = loopEnd.clip(0.0, 1.0);
```

### Real-Time Updates

**mouseMoveAction** (during drag):
- Updates engine continuously as you drag
- Allows you to "audition" different loop regions
- Instant feedback

**mouseUpAction** (on release):
- Finalizes selection
- Posts detailed feedback to post window
- Validates minimum window size

### Performance

- No CPU overhead when viewfinder is closed
- Minimal impact when open (just GUI rendering)
- Waveform caching handled by SoundFileView
- Independent of grain engine (no audio processing in GUI)

---

## API Reference

### ~bearulatorViewfinder Methods

```supercollider
// Create viewfinder for specific track
~viewfinder.createWindow(trackNum)
// trackNum: 0-3 (Track 1-4)

// Update waveform after loading new buffer
~viewfinder.updateWaveform(trackNum)

// Open all viewfinders at once
~viewfinder.createAll

// Close all viewfinder windows
~viewfinder.closeAll

// Cleanup
~viewfinder.free
```

### Related TrackManager Methods

```supercollider
// Set loop boundaries manually (if needed)
~trackManager.setParam(trackNum, \loopStart, 0.2);  // 20% into buffer
~trackManager.setParam(trackNum, \loopEnd, 0.8);    // 80% into buffer

// Get current loop boundaries
~trackManager.getTrack(trackNum).grainSynth.get(\loopStart, { |val| val.postln });
```

---

## Workflow Tips

### Tip 1: Start with Full Buffer
When loading new audio:
1. First, listen to the **full buffer** (loopStart: 0.0, loopEnd: 1.0)
2. Then open viewfinder and narrow down to interesting sections
3. This helps you understand the full context before zooming in

### Tip 2: Use Grid for Timing
The viewfinder has a **grid overlay** (100ms divisions):
- Helps align loop boundaries to transients
- Useful for rhythmic material
- Can visually estimate grain size vs. loop size

### Tip 3: A/B Compare Loop Regions
To compare two loop regions:
1. Select region A, listen
2. Select region B, listen
3. The engine updates immediately - no need to "store" presets
4. For permanent storage, save loop boundaries in a preset file (future feature)

### Tip 4: Combine with Position Modulation
**Best workflow:**
1. Set loop window via viewfinder (defines the "space")
2. Use Position slider or LFO modulation to scan through that space
3. This gives you both **macro control** (window size/location) and **micro control** (position within window)

### Tip 5: Use POLY Mode for Percussive Material
For drums, transients, clicks:
- Use viewfinder to isolate the transient
- POLY mode triggers from loop start
- Grain Size controls decay length
- Overlap controls density/rolls

---

## Troubleshooting

### Viewfinder Won't Open

**Symptom:** Clicking "LOOP VIEW" button does nothing

**Solutions:**
1. Check post window for error messages
2. Ensure `main.scd` was run successfully
3. Verify `~viewfinder` is not nil: `~viewfinder.postln`
4. Try creating manually: `~viewfinder.createWindow(0)`

### No Waveform Displayed

**Symptom:** Viewfinder opens but shows empty/black

**Solutions:**
1. Ensure audio file is loaded on that track
2. Check buffer: `~trackManager.getTrack(0).recorder.buffer.postln`
3. Try updating waveform: `~viewfinder.updateWaveform(0)`
4. Check file path is correct (SoundFileView requires valid path)

### Loop Selection Not Working

**Symptom:** Can't drag to select region

**Solutions:**
1. Ensure waveform has loaded (wait ~1 second after opening)
2. Try closing and reopening viewfinder
3. Check `.setSelectable(0, true)` is enabled (it should be by default)

### Loop Changes Not Audible

**Symptom:** Loop window changes but sound stays the same

**Solutions:**
1. Verify synth is running: `~trackManager.getTrack(0).grainSynth.postln`
2. Check amp is not zero
3. Ensure Position slider is within 0.0-1.0 range
4. Try different Material Mode (TAPE vs POLY vs LIVE)
5. Check grain size isn't way longer than loop window

---

## Future Enhancements (Phase 8+)

### Planned Features:

1. **Multiple Loop Regions**
   - Store A/B/C/D loop presets per track
   - Quick switching between loop windows
   - Morph between regions with crossfade

2. **Visual Grain Position Indicator**
   - Show current grain read position on waveform
   - Animated playhead overlay
   - Density visualization (how many grains active)

3. **Zoom/Scroll**
   - Zoom in for precise selection
   - Scroll through long audio files
   - Minimap overview

4. **Snap to Transients**
   - Auto-detect transients/zero-crossings
   - Snap loop boundaries to nearest transient
   - Beat detection for rhythmic material

5. **Loop Region Presets**
   - Save/load loop window positions
   - Per-track preset storage
   - Global preset library

---

## Keyboard Shortcuts

*(Not yet implemented - placeholder for future)*

- `Cmd+A` - Select all
- `Cmd+L` - Select loop region
- `Space` - Play/pause (toggles synth on/off)
- `←/→` - Nudge loop start/end by 10ms
- `Shift+←/→` - Nudge by 100ms

---

## Technical Implementation Notes

### SoundFileView Configuration

```supercollider
sfv = SoundFileView(win, bounds)
    .background_(Color.black)
    .waveColors_([Color.cyan.alpha_(0.8)])  // Cyan waveform
    .gridOn_(true)                          // Show time grid
    .gridColor_(Color.gray(0.3))            // Dark grid lines
    .timeCursorOn_(true)                    // Show cursor
    .timeCursorColor_(Color.yellow.alpha_(0.6))
    .drawsWaveForm_(true)                   // Render waveform
    .elasticMode_(1)                        // Elastic resize
    .gridResolution_(0.1)                   // 100ms grid
    .setSelectable(0, true);                // Enable user selection
```

### Mouse Event Handlers

**mouseMoveAction** - Real-time updates during drag:
```supercollider
sfv.mouseMoveAction = { arg view;
    var sel = view.selection(0);
    var loopStart = (sel[0] / buffer.numFrames).clip(0, 1);
    var loopEnd = ((sel[0] + sel[1]) / buffer.numFrames).clip(0, 1);

    trackManager.setParam(trackNum, \loopStart, loopStart);
    trackManager.setParam(trackNum, \loopEnd, loopEnd);
};
```

**mouseUpAction** - Finalize + validate on release:
```supercollider
sfv.mouseUpAction = { arg view;
    // Same as mouseMoveAction, but with:
    // - Minimum window size validation
    // - Post window feedback
    // - Error handling
};
```

---

## Files Modified/Created

### New Files (Phase 7):
- `gui/viewfinder.scd` - Viewfinder module implementation
- `TEST-VIEWFINDER.scd` - Test script with examples
- `docs/phase-7-viewfinder.md` - This documentation

### Modified Files:
- `main.scd` - Added viewfinder initialization
- `gui/four-track-view.scd` - Added "LOOP VIEW" and "VIEW" buttons

### Unchanged (Already Had Support):
- `core/grain-engine.scd` - Already had loopStart/loopEnd parameters
- `core/track-manager.scd` - Already had setParam() for loop boundaries

---

## Summary

Phase 7 brings **professional-grade loop windowing** to the BEARULATOR granular sampler. By combining visual waveform editing with real-time audio parameter mapping, you can:

✅ **Visually select** which part of your audio to granulate
✅ **Instantly audition** different loop regions
✅ **Precisely control** grain source material
✅ **Integrate seamlessly** with Material Modes (TAPE/POLY/LIVE)

This feature elevates the BEARULATOR from a basic granular synth to a **dynamic windowing sampler** comparable to commercial hardware units.

**Next:** Phase 8 will add preset management, visual grain position indicators, and advanced modulation routing.

---

**Version:** v0.7.001
**Implementation Status:** ✅ COMPLETE
**Ready for User Testing:** YES
