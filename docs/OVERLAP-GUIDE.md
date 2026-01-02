# Overlap Mode Guide (Phase 6b)

## The Problem with Density

In traditional granular synthesizers, you control:
- **Grain Size**: How long each grain lasts
- **Density**: How many grains per second are triggered

This creates a problem: **simultaneous grains = grain size × density**

### Example: Your "Houston" audio file (2.44 seconds)

**OLD WAY (Density Mode):**
```
Grain Size: 2.7 seconds
Density: 20 grains/second
Simultaneous grains: 2.7 × 20 = 54 grains overlapping!
Result: FEEDBACK, artifacts, chaos
```

When you set grain size to match your buffer length (to hear the full audio), the density stays high, causing massive overlap. This leads to:
- Feedback loops
- Hitting maxGrains limit (grain dropout)
- Unpredictable behavior
- Can't hear the full audio cleanly

## The Solution: Overlap Control

**NEW WAY (Overlap Mode - DEFAULT):**

Instead of setting density directly, you set the **number of simultaneous grains** you want. The synth automatically calculates the correct density.

```
Formula: density = overlap / grainSize
```

### Same Example with Overlap Mode:

```
Grain Size: 2.7 seconds
Overlap: 1 grain
Auto-calculated density: 1 / 2.7 = 0.37 grains/second
Simultaneous grains: exactly 1
Result: CLEAN playback of full audio file ✓
```

## How to Use Overlap Mode

### Use Case 1: Full-Length Sample Playback
**Goal:** Hear the entire audio file, no granular effect

```supercollider
Grain Size: >= buffer length (e.g., 2.7s for a 2.44s file)
Overlap: 1
Material Mode: TAPE (loop)
```

Result: The full audio plays and loops smoothly, like a sample player.

### Use Case 2: Smooth Looping with Crossfades
**Goal:** Full audio with smooth grain crossfades

```supercollider
Grain Size: >= buffer length
Overlap: 2-4
Material Mode: TAPE
```

Result: Multiple grains overlap slightly, creating smooth crossfades.

### Use Case 3: Classic Granular Texture
**Goal:** Granular "shimmer" or "cloud" effect

```supercollider
Grain Size: 10-100ms (small grains)
Overlap: 4-8
Material Mode: TAPE
```

Result: Classic granular synthesis texture.

### Use Case 4: Dense Granular Clouds
**Goal:** Thick, evolving textures

```supercollider
Grain Size: 50-200ms
Overlap: 16-64
Material Mode: TAPE or POLY
```

Result: Dense, evolving grain clouds. Watch CPU usage!

### Use Case 5: Triggered Samples (No Granular Effect)
**Goal:** Use grains like sample triggers

```supercollider
Grain Size: >= buffer length
Overlap: 1
Material Mode: POLY (sample mode)
Position: Trigger point (0-1)
```

Result: Each grain is a sample trigger from a fixed position.

## GUI Changes

**Before (Phase 6):**
```
Grain Size: [slider]
Density:    [slider]  ← Could cause problems with long grains
```

**After (Phase 6b):**
```
Grain Size: [slider]
Overlap:    [slider]  ← Musical control, auto-adjusts
```

The help text now reads:
```
(Overlap = simultaneous grains, auto-adjusts for grain size)
```

## Legacy Compatibility

The old `density` parameter still exists for backwards compatibility:

```supercollider
// Old way (still works)
~trackManager.setParam(0, \density, 20);
~trackManager.setParam(0, \useOverlap, 0);  // Switch to density mode

// New way (default)
~trackManager.setParam(0, \overlap, 4);
~trackManager.setParam(0, \useOverlap, 1);  // Overlap mode (default)
```

## Technical Details

### Automatic Density Calculation

Inside the grain engine:

```supercollider
actualDensity = Select.kr(useOverlap, [
    density,                    // Legacy mode
    (overlap / grainDur).max(0.1)  // Overlap mode (auto-calculated)
]);
```

### Dynamic maxGrains Allocation

maxGrains is now based on overlap:

```supercollider
maxGrains = (overlap * 0.5).max(4).min(128).asInteger;
```

Since we have 2 GrainBuf UGens (L/R stereo), each gets half the overlap count.

**Example:**
- Overlap = 8 → maxGrains = 4 per channel (8 total)
- Overlap = 64 → maxGrains = 32 per channel (64 total)
- Overlap = 128 → maxGrains = 64 per channel (128 total)

This ensures grains are never dropped due to hitting the maxGrains limit.

## Common Overlap Values

| Overlap | Use Case | CPU Usage |
|---------|----------|-----------|
| 1 | Full sample playback, no granular effect | Very Low |
| 2-4 | Light granular texture, smooth crossfades | Low |
| 8-16 | Classic granular synthesis | Medium |
| 32-64 | Dense grain clouds, evolving textures | High |
| 128 | Extreme density (may cause CPU issues) | Very High |

## Tips

1. **Start with Overlap = 1** when loading a new file to hear it cleanly
2. **Increase overlap slowly** to add granular texture
3. **Lower amp when increasing overlap** to prevent clipping
4. **Watch CPU** with overlap > 32 on all 4 tracks simultaneously
5. **Use TAPE mode** for looping, **POLY mode** for sample triggers
6. **Combine with Position** to scan through the buffer

## Example Patches

### Patch 1: Clean Voice Sample Player
```supercollider
Grain Size: 3.0s
Overlap: 1
Position: 0.5
Amp: 0.5
Material Mode: TAPE
```

### Patch 2: Granular Pad
```supercollider
Grain Size: 80ms
Overlap: 8
Position: 0.5 (modulate with LFO)
Pitch: -12 (octave down)
Stereo Spread: 0.7
Material Mode: TAPE
```

### Patch 3: Glitch Stutter
```supercollider
Grain Size: 20ms
Overlap: 16
Position: 0.2 (fixed)
Pos Jitter: 0.1
Pitch Jitter: 7
Material Mode: POLY
```

---

**Phase 6b Complete!** You now have musical, intuitive control over grain density.
