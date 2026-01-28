# Master Tab: Tempo & Sync Controls

**Added:** Phase 18  
**Location:** Master Tab → Top section (after Transport)

---

## Visual Layout

```
┌─────────────────────────────────────────────────────────────┐
│ MASTER CONTROLS                                             │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│ TRANSPORT                                                    │
│ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│ │ PLAY ALL │ │ STOP ALL │ │MIDI PATCH│ │ SYNC MGR │       │
│ └──────────┘ └──────────┘ └──────────┘ └──────────┘       │
│                                                              │
│ TEMPO & SYNC                                                 │
│ BPM: ┌─────┐ ┌───────────┐ ┌──────────┐ ┌───┐ ┌────┐     │
│      │ 120 │ │ TAP TEMPO │ │SYNC: OFF │ │60 │ │120 │     │
│      └─────┘ └───────────┘ └──────────┘ └───┘ └────┘     │
│       ↑          ↑              ↑          ↑      ↑         │
│    Number    Tap 4x to    Toggle DAW   Quick presets       │
│     Box      set tempo      sync ON                         │
│                                                              │
│ KEYSTEP MIDI:                                                │
│ ...                                                          │
└─────────────────────────────────────────────────────────────┘
```

---

## Controls Breakdown

### 1. BPM Number Box
- **Type:** Editable number field
- **Range:** 20-300 BPM
- **Default:** 120 BPM
- **Color:** Cyan (normal), Yellow (typing)
- **Action:** Click to type new BPM, press Enter
- **Updates:** Immediately changes ~syncManager.setBPM()

**Usage:**
```
Click → Type "90" → Press Enter → Tempo set to 90 BPM
```

---

### 2. TAP TEMPO Button
- **Type:** Momentary button
- **Color:** Gray background
- **Action:** Click 4 times at desired tempo
- **Feedback:** Post window shows:
  ```
  Tap 1/4
  Tap 2/4: ~120 BPM
  Tap 3/4: ~118 BPM
  ✓ Tap tempo: 119 BPM (4 taps)
  ```

**Usage:**
```
Click-Click-Click-Click (in rhythm)
→ Tempo automatically calculated and applied
```

---

### 3. SYNC TO DAW Button (Toggle)
- **Type:** Toggle button (2 states)
- **State 1:** "SYNC: OFF" (Gray) - Manual BPM control
- **State 2:** "SYNC: DAW" (Green) - Following external MIDI clock
- **Default:** OFF
- **Status:** Phase 19 (placeholder for now)

**Current Behavior:**
```
Click → Shows warning: "DAW sync not yet implemented (Phase 19)"
       → Button resets to OFF
```

**Future Behavior (Phase 19):**
```
Click → State: "SYNC: DAW" (Green)
       → BPM box becomes read-only
       → Tempo follows DAW MIDI clock
       → Transport follows DAW start/stop

Click again → State: "SYNC: OFF" (Gray)
             → BPM box editable again
             → Manual tempo control
```

---

### 4. Quick BPM Presets (60, 120)
- **Type:** Momentary buttons
- **Color:** Gray background
- **Action:** Instantly set tempo to preset value
- **Updates:** BPM box updates automatically

**Usage:**
```
Click "60" → Tempo set to 60 BPM (slow ambient)
Click "120" → Tempo set to 120 BPM (standard house)
```

**Why These Values:**
- **60 BPM** - Common for ambient/drone/Sigur Rós presets
- **120 BPM** - Standard dance music tempo

---

## Interaction Flow

### Scenario 1: Manual Tempo Entry
```
1. User clicks BPM box
2. Types "95"
3. Presses Enter
4. ~syncManager.setBPM(95) called
5. All rhythmically-locked tracks adjust
```

### Scenario 2: Tap Tempo
```
1. User clicks TAP TEMPO 4 times in rhythm
2. Each click shows estimated BPM in post window
3. After 4th tap, tempo locks
4. BPM box updates to show new value
```

### Scenario 3: Quick Preset
```
1. User clicks "120" button
2. Tempo immediately set to 120 BPM
3. BPM box shows 120
```

### Scenario 4: DAW Sync (Future - Phase 19)
```
1. User clicks "SYNC: OFF" button
2. State changes to "SYNC: DAW" (Green)
3. BPM box becomes gray (read-only)
4. Tempo now controlled by DAW
5. Click again to return to manual control
```

---

## Integration with Sync Manager

### When rhythmic locking is active:
```supercollider
// User sets BPM to 90 via GUI
~syncManager.setBPM(90);  // Called automatically

// If tracks are locked to grid:
~syncManager.setRhythmicDensity(0, 16);  // Track 1 at 1/16 notes

// Changing BPM recalculates grain sizes automatically:
// 90 BPM, 1/16th, overlap=64
// → grainSize = 64 / 6 Hz = 10.67 seconds (auto-adjusted)
```

### BPM change propagation:
1. User changes BPM in GUI
2. ~syncManager.setBPM() called
3. TempoClock.tempo updated
4. All quantized events adjust to new tempo
5. Rhythmically-locked tracks maintain grid alignment

---

## Visual States

### Normal State (Manual Control)
```
BPM: [120] [TAP TEMPO] [SYNC: OFF] [60] [120]
     cyan   gray        gray        gray gray
```

### Typing BPM
```
BPM: [95_] [TAP TEMPO] [SYNC: OFF] [60] [120]
     yellow  gray        gray        gray gray
     ↑ Cursor visible
```

### Tap Tempo Active (Post Window Feedback)
```
Post Window:
  Tap 1/4
  Tap 2/4: ~118 BPM
  Tap 3/4: ~120 BPM
  ✓ Tap tempo: 119 BPM (4 taps)
```

### DAW Sync Active (Phase 19)
```
BPM: [120] [TAP TEMPO] [SYNC: DAW] [60] [120]
     gray   disabled    green      disabled
     (read-only when synced to DAW)
```

---

## Keyboard Shortcuts (Potential)

*Not implemented yet, but could add:*
```
Cmd+T → Focus BPM box for typing
Spacebar (when BPM focused) → Tap tempo
Cmd+D → Toggle DAW sync
```

---

## Error Handling

### If Sync Manager Not Initialized
```
User clicks any tempo control
→ Warning: "Sync Manager not initialized"
→ No action taken
→ Check main.scd loaded correctly
```

### If Invalid BPM Entered
```
User types "999"
→ SuperCollider's NumberBox clamps to valid range (20-300)
→ No error, just uses clamped value
```

### If DAW Sync Clicked (Phase 19 Not Implemented)
```
User clicks "SYNC: OFF"
→ Post window: "⚠ DAW sync not yet implemented (Phase 19)"
→ Button resets to OFF state
→ Manual control remains active
```

---

## Technical Details

### BPM → TempoClock Conversion
```supercollider
// User enters: 120 BPM
clock.tempo = 120 / 60;  // = 2.0 beats per second
```

### Tap Tempo Algorithm
```supercollider
// Stores 4 tap times:
tapTimes = [1.0, 2.1, 3.2, 4.3]

// Calculate average interval:
avgInterval = (4.3 - 1.0) / 3 = 1.1 seconds

// Convert to BPM:
bpm = 60 / 1.1 = 54.5 BPM (rounded to 55)
```

---

## Future Enhancements (Phase 19+)

### DAW Sync Implementation
When "SYNC: DAW" is active:
- Listen to MIDI clock (0xF8 bytes, 24 PPQN)
- Calculate BPM from clock intervals
- Update BPM box in real-time
- Lock transport to DAW start/stop

### Additional Quick Presets
Could add more buttons:
- **80 BPM** - Hip-hop
- **140 BPM** - Jungle/DnB
- **170 BPM** - Footwork

### Tempo Automation
Record BPM changes over time:
- Click "REC" → Changes recorded
- Click "PLAY" → Tempo morphs automatically

---

## User Workflow Example

### Recording Session with DAW
```
1. Open Ableton Live, set to 110 BPM
2. Boot BEARULATOR
3. In Master tab: Type "110" in BPM box
4. Lock tracks to grid:
   ~syncManager.setRhythmicDensity(0, 16);
5. Press Play in Ableton
6. Press PLAY ALL in BEARULATOR
7. Record BEARULATOR output in Ableton

Future (Phase 19):
3. Click "SYNC: OFF" → "SYNC: DAW"
4. BPM auto-matches Ableton (110 BPM)
5. Transport auto-follows Ableton start/stop
```

---

## Testing

### After Update, Test:
```supercollider
s.boot;
"main.scd".loadRelative;

// 1. Open Master tab in GUI

// 2. Click BPM box → Type "90" → Enter
//    Should see: "✓ Global Tempo: 90 BPM (1.5 beats/sec)"

// 3. Click TAP TEMPO 4 times
//    Should calculate tempo from your taps

// 4. Click "120" preset button
//    Should instantly change to 120 BPM

// 5. Click "SYNC: OFF" button
//    Should show warning (Phase 19 not implemented)
```

---

**Last Updated:** 2026-01-27  
**Version:** Phase 18  
**Status:** ✅ Implemented (DAW sync pending Phase 19)
