# Viewfinder Quick Start Guide

**5-Minute Tutorial** for the S-4 Rival Waveform Viewfinder

---

## What is the Viewfinder?

The viewfinder lets you **visually select** which part of your audio buffer the grains read from, just like setting loop points in a sampler or DAW.

**Key Feature:** Changes update the engine **in real-time** as you drag - no "apply" button needed!

---

## Opening the Viewfinder

### Method 1: GUI Button
1. Load an audio file on any track
2. Click the **"LOOP VIEW"** button (blue, top-right of track tab)
3. Viewfinder window opens showing your waveform

### Method 2: Code
```supercollider
~viewfinder.createWindow(0);  // Track 1
~viewfinder.createWindow(1);  // Track 2
~viewfinder.createWindow(2);  // Track 3
~viewfinder.createWindow(3);  // Track 4
```

---

## Basic Usage

### Selecting a Loop Region
1. **Click and drag** across the waveform
2. Release mouse
3. Loop boundaries update immediately
4. Status bar shows: `Loop: 0.52s - 1.84s (1.32s) | 21.4% - 75.6%`

### Resetting the Loop
- Click **"Reset Loop"** button (bottom-right)
- Resets to full buffer (0% - 100%)

### Select All
- Click **"Select All"** button
- Visual convenience (same as Reset Loop)

### Refresh Waveform
- Click **"Refresh"** button
- Useful after loading a new file

---

## Understanding Material Modes

The loop window works differently depending on which Material Mode you're in:

### TAPE Mode (Loop)
```supercollider
~trackManager.setMode(0, 0);  // TAPE
```
- **Behavior:** Grains loop continuously within the selected region
- **Position slider:** Scans through the loop window (0.0 = start, 1.0 = end)
- **Use case:** Isolate and loop a specific word, phrase, or texture

**Example:**
- Load vocal: "columbia this houston over"
- Select only "houston"
- Result: Only "houston" loops endlessly

---

### POLY Mode (Sample Playback)
```supercollider
~trackManager.setMode(0, 1);  // POLY
```
- **Behavior:** Grains trigger from a fixed position within the window
- **Position slider:** Sets trigger point within window
- **Use case:** Sample triggering, like an MPC or sampler

**Example:**
- Load drum loop
- Select just the kick transient (first 50ms)
- Grain Size = 200ms
- Result: Each grain plays the kick drum from the beginning

---

### LIVE Mode (Lookback)
```supercollider
~trackManager.setMode(0, 2);  // LIVE
```
- **Behavior:** Grains read backward in time from window end
- **Position slider:** How far back in time (0.0 = recent, 1.0 = window start)
- **Use case:** Live input delay, granular echo effects

**Example:**
- Select last 2 seconds of buffer
- Position = 0.3 (30% back)
- Result: Grains read from 600ms ago

---

## Practical Examples

### Example 1: Stutter Effect (TAPE)
```
Goal: Create rhythmic stutter on a word

Setup:
1. Load vocal file
2. Select one syllable (e.g., "hous" from "houston")
3. Material Mode: TAPE
4. Grain Size: 40ms
5. Overlap: 8
6. Position: 0.5 (middle of syllable)

Result: Rapid granular stutter of that syllable
```

---

### Example 2: Granular Pad (TAPE)
```
Goal: Create ambient pad from field recording

Setup:
1. Load nature sounds or synth pad
2. Select interesting 2-second section
3. Material Mode: TAPE
4. Grain Size: 120ms
5. Overlap: 16 (very dense)
6. Pitch: -12 (octave down)
7. Add LFO to Position

Result: Evolving ambient texture that morphs through the selected region
```

---

### Example 3: Kick Drum Trigger (POLY)
```
Goal: Extract kick drum from full loop

Setup:
1. Load drum loop
2. Zoom into kick transient
3. Select just the attack (30-50ms)
4. Material Mode: POLY
5. Grain Size: 300ms (longer than window)
6. Overlap: 1
7. Position: 0.0 (trigger from start)

Result: Clean kick drum sample trigger
```

---

### Example 4: Granular Delay (LIVE)
```
Goal: Time-stretching delay effect

Setup:
1. Record 4 seconds of live input
2. Select entire buffer
3. Material Mode: LIVE
4. Grain Size: 80ms
5. Overlap: 12
6. Position: Modulate 0.0-0.5 with LFO

Result: Grains sweep through 0-2 seconds ago, creating granular delay
```

---

## Tips & Tricks

### Tip 1: Visual Feedback
- The **cyan waveform** shows your audio
- **Selected region** is highlighted
- **Grid lines** help with timing (100ms divisions)

### Tip 2: Start Broad, Then Narrow
1. First, listen to full buffer (click "Reset Loop")
2. Identify interesting sections visually
3. Narrow down to specific region
4. Fine-tune with Position slider

### Tip 3: Combine with Modulation
Best workflow:
1. Set loop window (macro control)
2. Use Position slider or LFO to scan through window (micro control)
3. This gives you both broad and detailed control

### Tip 4: Use POLY for Percussive Material
For drums, clicks, transients:
- Viewfinder: Isolate the transient
- POLY mode: Trigger from start
- Grain Size: Controls decay length
- Perfect for sample-accurate triggering

### Tip 5: Experiment with Window Size
- **Large windows** (80-100%): Subtle variations
- **Medium windows** (20-50%): Focused textures
- **Small windows** (5-10%): Intense repetition
- **Tiny windows** (1-3%): Granular freeze effect

---

## Common Workflows

### Workflow: Isolate a Word
1. Load vocal phrase
2. Open viewfinder
3. Visually locate the word
4. Drag to select it
5. TAPE mode: Word loops
6. Adjust Position to scan through word

### Workflow: Sample Library
1. Load long audio file (e.g., vinyl sample pack)
2. Open viewfinder
3. Scrub through, find interesting sounds
4. Select each sound
5. POLY mode: Trigger like samples
6. Save loop boundaries as presets (future feature)

### Workflow: Evolving Soundscape
1. Load textural audio
2. Select 30-50% of buffer
3. TAPE mode
4. Dense overlap (16-32)
5. Long grains (100-200ms)
6. LFO on Position
7. LFO on Grain Size
8. Result: Constantly evolving ambient texture

---

## Keyboard Shortcuts

**Current:**
- `Cmd+W` - Close viewfinder window

**Planned (Phase 8):**
- `Cmd+A` - Select all
- `Cmd+R` - Reset loop
- `Space` - Play/pause track
- `←/→` - Nudge loop boundaries

---

## Troubleshooting

### Viewfinder won't open
- Check that `main.scd` ran successfully
- Verify `~viewfinder` exists: `~viewfinder.postln`
- Check that track has audio loaded

### Can't select region
- Wait ~1 second for waveform to load
- Try clicking "Refresh" button
- Close and reopen viewfinder

### Selection doesn't update sound
- Verify synth is running
- Check amp slider isn't zero
- Try different Material Mode
- Ensure grain size isn't way longer than loop window

### Status bar shows wrong times
- Check buffer sampleRate matches server
- Try clicking "Refresh"

---

## Advanced: Multiple Tracks

You can open viewfinders for all tracks simultaneously:

```supercollider
~viewfinder.createAll;
```

Each track has:
- Independent loop window
- Independent material mode
- Independent grain parameters

This allows complex multi-layer granular compositions!

---

## Next Steps

Once you're comfortable with the viewfinder:

1. **Explore Material Modes** - Each mode offers unique sonic possibilities
2. **Add Modulation** - LFOs on Position, Grain Size, Overlap
3. **Layer Tracks** - Different loop windows on each track
4. **Use Effects** - Color FX and Space FX for post-processing

**Coming in Phase 8:**
- Loop region presets (A/B/C/D)
- Visual grain position indicator
- Snap to transients
- Zoom/scroll for long files

---

## Summary

The viewfinder turns the S-4 Rival into a **dynamic windowing sampler** where you can:

✅ **Visually select** which part of your audio to granulate
✅ **Instantly hear** the results (real-time updates)
✅ **Precisely control** grain source material
✅ **Work differently** in each material mode (TAPE/POLY/LIVE)

**Remember:** The Position slider and loop window work together:
- **Loop window** = the "space" grains can explore
- **Position** = where within that space to read from

Master this combination and you unlock infinite sonic possibilities!

---

**Happy granulating! 🎛️✨**
