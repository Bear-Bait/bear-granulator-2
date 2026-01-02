# Quick Start - Phase 7 Viewfinder

**30-Second Guide to Loop Window Selection**

---

## Step 1: Boot
```supercollider
main.scd  // Boot the system
```

## Step 2: Load Audio
- Click "Load Audio File" button
- Or use: `/Users/forrestmuelrath/Documents/supercollider/sounds/a11wlk01-44_1.aiff`

## Step 3: Open Viewfinder
- Click blue **"LOOP VIEW"** button (top-right of Track 1)
- Or run: `~viewfinder.createWindow(0)`

## Step 4: Select Loop Region
- **Drag** across the waveform
- Selection updates engine **instantly**
- Status bar shows: "Loop: 0.52s - 1.84s (1.32s)"

## Step 5: Listen
- Grains now only read from selected region
- Try different Material Modes:
  - **TAPE** (0): Loops within window
  - **POLY** (1): Triggers from window start
  - **LIVE** (2): Lookback delay

---

## Quick Commands

```supercollider
// Open viewfinder
~viewfinder.createWindow(0);  // Track 1

// Change material mode
~trackManager.setMode(0, 0);  // TAPE (loop)
~trackManager.setMode(0, 1);  // POLY (trigger)
~trackManager.setMode(0, 2);  // LIVE (delay)

// Close viewfinder
~viewfinder.closeAll;
```

---

## Buttons in Viewfinder

- **Reset Loop** - Back to full buffer
- **Select All** - Visual select all
- **Refresh** - Reload waveform

---

## Material Mode Cheat Sheet

| Mode | Behavior | Use Case |
|------|----------|----------|
| TAPE | Loops within window | Isolate a word/phrase |
| POLY | Triggers from start | Sample playback |
| LIVE | Reads backward | Granular delay |

---

**That's it! You now have professional loop windowing! 🎛️**

See `docs/VIEWFINDER-QUICKSTART.md` for detailed examples.
