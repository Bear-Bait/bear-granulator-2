# Phase 18: Dream-Tier Rhythmic Locking - Implementation Guide

**Date:** 2026-01-27  
**Status:** ✅ **IMPLEMENTED**  
**Version:** BEARULATOR v2.5

---

## Overview

Phase 18 upgrades the Sync Manager from "legacy density mode" to **Overlap Math**, enabling perfect rhythmic locking while preserving the lush 64-128 grain textures that define BEARULATOR's sound.

### The Problem (Before Phase 18)

Old sync system forced `useOverlap = 0` (density mode), which:
- ❌ Destroyed the lush multi-grain texture
- ❌ Made grains sound sparse and thin
- ❌ Couldn't sync without compromising sound quality

### The Solution (Phase 18)

**Overlap Math** calculates `grainSize` dynamically:
- ✅ Keeps `useOverlap = 1` (maintain texture)
- ✅ Calculates exact grain size to hit grid divisions
- ✅ Preserves 64-128 grain density while syncing

---

## Three Core Upgrades

### 1. ✅ Sequencer Reset Trigger (`t_reset`)

**What It Does:**  
Adds a trigger input to the grain engine that resets the 64-step sequencer to step 0.

**Why It Matters:**  
Without this, quantized starts would be rhythmically correct but melodically offset (sequencer might be at step 37 when playback starts).

**Implementation:**
```supercollider
// In grain-engine.scd SynthDef args:
t_reset = 0,  // Phase 18: Sequencer reset trigger

// In Demand UGens:
musicalPosJitter = Demand.ar(trig, t_reset, posPattern) * posJitter;
musicalPitchJitter = Demand.ar(trig, t_reset, pitchPattern);
```

**Usage:**
```supercollider
// Manually fire reset:
~trackManager.getTracks[0].grainSynth.set(\t_reset, 1);

// Automatically fired by playQuantized():
~syncManager.playQuantized(0);  // Triggers t_reset internally
```

---

### 2. ✅ Overlap Math (Preserve Texture)

**The Formula:**
```supercollider
densityHz = (bpm / 60) * (subdivision / 4)
grainSize = overlap / densityHz
```

**Example Calculation:**
```
Scenario: 120 BPM, 1/16th notes, overlap = 64 grains

Step 1: Calculate density (how many grains per second)
  beatsPerSecond = 120 / 60 = 2 beats/sec
  notesPerBeat = 16 / 4 = 4 notes/beat
  densityHz = 2 * 4 = 8 Hz (8 grains per second)

Step 2: Calculate grain size to maintain 64-grain texture
  grainSize = 64 / 8 = 8 seconds

Result: 64 overlapping grains, each 8 seconds long, 
        triggered 8 times per second = perfect 1/16th sync!
```

**Why It Works:**
- **Old way:** Set density to 8 Hz, grains barely overlap → thin sound
- **New way:** Keep 64 grains, stretch them to 8 sec → lush texture, perfect sync

**Implementation:**
```supercollider
setRhythmicDensity: { arg self, trackNum, subdivision = 16;
    var currentOverlap = track.params[\overlap] ? 64;
    var bpm = self.getBPM;
    var requiredGrainSize = calculateGrainSize.(bpm, subdivision, currentOverlap);
    
    // ✓ Keep overlap mode (preserves texture)
    trackManager.setParam(trackNum, \useOverlap, 1);
    
    // ✓ Set calculated grain size
    trackManager.setParam(trackNum, \grainSize, requiredGrainSize);
};
```

---

### 3. ✅ Phase-Aligned Quantized Playback

**What It Does:**  
Combines position reset + sequencer reset in a single TempoClock callback.

**The Magic:**
```supercollider
playQuantized: { arg self, trackNum, bars = 1;
    clock.schedAbs(clock.nextBar(bars), {
        // 1. Reset playback position
        trackManager.setParam(trackNum, \position, loopStart);
        
        // 2. Reset sequencer to step 0 (THE KEY!)
        track.grainSynth.set(\t_reset, 1);
        
        // 3. Start playback
        track.grainSynth.run(true);
        
        nil;  // Don't reschedule
    });
};
```

**Result:**  
Multiple tracks start **in perfect sync**, both rhythmically AND melodically.

---

## API Reference

### Sync Manager Methods

#### `setBPM(bpm)`
Set global tempo.
```supercollider
~syncManager.setBPM(120);
```

#### `getBPM()`
Get current tempo.
```supercollider
~syncManager.getBPM;  // → 120.0
```

#### `setRhythmicDensity(trackNum, subdivision)`
Lock track to rhythmic grid using Overlap Math.
```supercollider
~syncManager.setRhythmicDensity(0, 16);   // Track 1 → 1/16th notes
~syncManager.setRhythmicDensity(1, 8);    // Track 2 → 1/8th notes
~syncManager.setRhythmicDensity(2, 32);   // Track 3 → 1/32nd notes
```

**Subdivisions:**
- `4` = 1/4 notes (quarter notes)
- `8` = 1/8 notes (eighth notes)
- `16` = 1/16 notes (sixteenth notes)
- `32` = 1/32 notes (thirty-second notes)

#### `setAllRhythmicDensity(subdivision)`
Lock all 4 tracks to same subdivision.
```supercollider
~syncManager.setAllRhythmicDensity(16);  // All tracks → 1/16th
```

#### `playQuantized(trackNum, bars)`
Start track on next bar with phase reset.
```supercollider
~syncManager.playQuantized(0, 1);  // Start Track 1 on next bar
~syncManager.playQuantized(1, 2);  // Start Track 2 in 2 bars
```

#### `stopQuantized(trackNum, bars)`
Stop track on next bar.
```supercollider
~syncManager.stopQuantized(0, 1);  // Stop Track 1 on next bar
```

#### `tapTempo()`
Set tempo by tapping 4 times.
```supercollider
// Tap 4 times at desired tempo:
~syncManager.tapTempo;  // Tap 1
~syncManager.tapTempo;  // Tap 2
~syncManager.tapTempo;  // Tap 3
~syncManager.tapTempo;  // Tap 4 → tempo locked!
```

#### `createSyncWindow()`
Open GUI for tempo/sync control.
```supercollider
~syncManager.createSyncWindow;
```

---

## Usage Examples

### Example 1: Basic Sync Setup

```supercollider
// 1. Set tempo
~syncManager.setBPM(120);

// 2. Lock tracks to different subdivisions
~syncManager.setRhythmicDensity(0, 4);   // Track 1: 1/4 notes
~syncManager.setRhythmicDensity(1, 8);   // Track 2: 1/8 notes
~syncManager.setRhythmicDensity(2, 16);  // Track 3: 1/16 notes

// 3. Start all tracks quantized
~syncManager.playQuantized(0, 1);
~syncManager.playQuantized(1, 1);
~syncManager.playQuantized(2, 1);
```

### Example 2: Polyrhythmic Sequencing

```supercollider
// Set up pitch sequences
~trackManager.setParam(0, \pitchSeq, [0, 2, 4, 7, 9].extend(64));
~trackManager.setParam(0, \pitchJitter, 1.0);

~trackManager.setParam(1, \pitchSeq, [0, 3, 5, 7, 10].extend(64));
~trackManager.setParam(1, \pitchJitter, 1.0);

// Lock to different subdivisions
~syncManager.setBPM(90);
~syncManager.setRhythmicDensity(0, 8);   // Track 1: 1/8 notes
~syncManager.setRhythmicDensity(1, 16);  // Track 2: 1/16 notes (polyrhythm!)

// Start phase-aligned
~syncManager.playQuantized(0, 1);
~syncManager.playQuantized(1, 1);  // Both start from step 0!
```

### Example 3: Live Performance Workflow

```supercollider
// Open GUI
~syncManager.createSyncWindow;

// During performance:
// 1. Tap tempo with foot controller
~syncManager.tapTempo;  // Tap 4x

// 2. Quick subdivision changes via GUI buttons
//    (Click "1/16th" to lock all tracks)

// 3. Quantized track starts
//    (Click "▶ PLAY" next to Track 1)
```

---

## Testing

### Run Phase 18 Test Script

```supercollider
s.boot;
"main.scd".loadRelative;

// Load samples into Track 1 and Track 2

// Run comprehensive test:
"/Users/forrestmuelrath/Documents/supercollider/granular/tests/phase18-sync-test.scd".load;
```

**What It Tests:**
1. ✅ Manual t_reset trigger (sequencer jumps to step 0)
2. ✅ Overlap Math (texture preserved while syncing)
3. ✅ Phase-aligned quantized playback (tracks start in sync)

---

## Troubleshooting

### "Grains sound thin after locking to grid"

**Cause:** You manually set `useOverlap = 0` (density mode).

**Fix:**
```supercollider
// Force back to overlap mode:
~trackManager.setParam(0, \useOverlap, 1);
~trackManager.setParam(0, \overlap, 64);  // Restore lush texture
~syncManager.setRhythmicDensity(0, 16);   // Re-lock to grid
```

### "Sequencer not resetting on quantized start"

**Cause:** Grain engine might not have t_reset parameter (old version).

**Fix:** Make sure you're running Phase 18 grain-engine.scd:
```supercollider
// Check if t_reset exists:
~trackManager.getTracks[0].params[\t_reset].notNil;  // Should be true
```

### "Grain size becomes huge (8+ seconds)"

**This is correct!** With high overlap (64+ grains) and fast subdivisions (1/16th), grain size must be long to maintain texture.

**Math:**
```
120 BPM, 1/16th notes, overlap=64
→ grainSize = 64 / 8 Hz = 8 seconds

This is intentional and sounds correct!
```

If grain size is too long for your sample:
```supercollider
// Option 1: Reduce overlap (less dense texture)
~trackManager.setParam(0, \overlap, 32);  // Half the grain count
~syncManager.setRhythmicDensity(0, 16);   // Recalculate

// Option 2: Use slower subdivision
~syncManager.setRhythmicDensity(0, 4);    // 1/4 notes instead of 1/16
```

---

## Technical Details

### Overlap Math Formula Derivation

**Goal:** Calculate grain size that maintains `N` overlapping grains while hitting rhythmic divisions.

**Given:**
- `bpm` = tempo in beats per minute
- `subdivision` = note value (4, 8, 16, 32)
- `overlap` = desired number of overlapping grains

**Step 1:** Calculate grain trigger rate (densityHz)
```
beatsPerSecond = bpm / 60
notesPerBeat = subdivision / 4
densityHz = beatsPerSecond * notesPerBeat
```

**Step 2:** Calculate grain duration
```
If we trigger 'densityHz' grains per second,
and want 'overlap' grains active simultaneously,
then each grain must last:

grainSize = overlap / densityHz
```

**Proof:**
```
At any moment in time:
  activeGrains = densityHz * grainSize
  
We want: activeGrains = overlap

Therefore:
  overlap = densityHz * grainSize
  grainSize = overlap / densityHz  ✓
```

---

## Performance Impact

**CPU Usage:** No change (same number of grains)  
**Memory:** No change (grain sizes calculated, not stored)  
**Latency:** No change (quantization happens at TempoClock resolution)

**Comparison:**
```
Before Phase 18:
  - Overlap Mode: Beautiful texture, no sync
  - Density Mode: Perfect sync, thin sound
  
After Phase 18:
  - Overlap Math: Beautiful texture AND perfect sync! ✓
```

---

## Future Enhancements

### Phase 19 Ideas:
- MIDI Clock sync (external DAW as master)
- Per-track tempo multipliers (Track 1 at 2x, Track 2 at 0.5x)
- Euclidean rhythm masks (7/16 patterns, etc.)
- Swing/groove quantization

---

## Credits

**Formula:** Based on grain synthesis overlap theory (Roads, 2001)  
**Implementation:** Claude Code + User collaboration  
**Testing:** Phase 18 test script (comprehensive)

---

**Last Updated:** 2026-01-27  
**Version:** BEARULATOR v2.5 (Phase 18)  
**Status:** Production ready ✅
