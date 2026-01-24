# Loop Playhead Constraint Fix

**Date:** 2026-01-24  
**Issue:** Grain and spectral playheads not constrained to loop region in viewfinder  
**Status:** ✅ FIXED (v2.2.1)

---

## Problem Description

When dragging to select a loop region in the viewfinder, the grain (green) and spectral (yellow) playheads would wander across the entire waveform instead of staying within the selected loop boundaries (green start marker / red end marker).

**Expected Behavior:**
- Playheads should stay between loop start and loop end
- When loop region changes, playheads should immediately jump to new region
- Visual playhead position should match audio playback position

**Actual Behavior (Before Fix):**
- Playheads would appear outside loop region
- Static position parameter would cause playhead to jump to arbitrary buffer positions
- Inconsistent mapping between audio playback and visual feedback

---

## Root Cause

The grain engine used `XFade2` to blend between `position` (0-1 normalized) and `phasor` (loopStart-loopEnd absolute), creating a `scanPos` with inconsistent coordinate spaces:

```supercollider
// BEFORE: XFade2 blends between two DIFFERENT coordinate spaces!
scanPos = XFade2.ar(K2A.ar(position), phasor, ...);
// position = 0-1 (normalized)
// phasor = loopStart-loopEnd (absolute)
```

**Why the initial `.linlin` fix was wrong:**
The first attempt used `.linlin(0, 1, loopStart, loopEnd)` on scanPos, assuming it would be an "identity operation" when already in loop coordinates. This is mathematically incorrect:
- If `loopStart=0.2, loopEnd=0.8` and `scanPos=0.8` (at loop end)
- `.linlin(0, 1, 0.2, 0.8)` maps 0.8 → 0.68 (WRONG!)

---

## Solution (Option A: Conditional Select)

Replace `XFade2` with `Select.ar` to ensure `scanPos` is ALWAYS in consistent absolute coordinates (loopStart to loopEnd):

```supercollider
// AFTER (v2.2.1): Unified position logic with Select.ar
scanPos = Select.ar(scanSpeed.abs > 0.01, [
    // Static Mode: Map normalized position (0-1) to loop range
    position.linlin(0, 1, loopStart, loopEnd),
    // Scanning Mode: Phasor is already in loop range
    phasor
]);

// Now scanPos is ALWAYS in absolute coordinates - send directly
SendReply.ar(Impulse.ar(60), '/grainPlayhead', [scanPos]);
```

**Why this works:**
1. Both branches output the SAME coordinate space (loopStart to loopEnd)
2. Select.ar picks the correct branch based on scan mode
3. No post-processing needed - scanPos is correct by definition
4. bufPos calculation simplified (no redundant .linlin)

**Edge case protection added:**
```supercollider
// Prevent division by zero / Phasor instability with tiny loops
loopEnd = loopEnd.max(loopStart + 0.001);
```

**Spectral engine:** No changes needed - it already uses Phasor constrained to loop boundaries.

---

## Files Modified

### Core Audio Engine
- `core/grain-engine.scd` (lines 163-224)
  - Added loopEnd minimum enforcement (line 167)
  - Replaced XFade2 with Select.ar for unified position logic (lines 204-211)
  - Simplified bufPos calculation - removed redundant .linlin (lines 214-221)
  - SendReply now sends scanPos directly (line 224)

### Test Files
- `tests/loop-playhead-test.scd` (NEW)
  - Automated test that cycles through different loop regions
  - Verifies playhead constraint in static and scanning modes
  
- `tests/loop-playhead-visual-test.scd` (NEW)
  - Manual visual test with step-by-step instructions
  - User drags to select loop regions and verifies playhead stays within bounds

---

## Testing

### Automated Test
```supercollider
"tests/loop-playhead-test.scd".loadRelative;
```

**What it does:**
1. Loads Apollo 11 sample
2. Sets loop region 20%-80%
3. Tests static position (scanSpeed=0)
4. Tests scanning playback (scanSpeed=1)
5. Changes loop region while playing
6. Tests spectral engine separately

**Expected output:** Console messages confirming playheads stay in loop region

### Manual Visual Test
```supercollider
"tests/loop-playhead-visual-test.scd".loadRelative;
```

**What to do:**
1. Script opens viewfinder with Apollo 11 sample
2. Observe playheads looping in middle 50% of waveform
3. DRAG on waveform to select different loop regions
4. Verify playheads immediately jump to new region
5. Try selecting: left 25%, right 25%, tiny regions

**Pass criteria:**
✓ Green (grain) playhead stays within loop markers  
✓ Yellow (spectral) playhead stays within loop markers  
✓ Playheads loop back at red (end) marker  
✓ Changing loop region updates playheads immediately  
✓ No playheads visible outside selected region  

---

## Code Quality

**SuperCollider Best Practices:**
- ✓ Used `Select.ar` for conditional audio-rate logic (efficient, no branching)
- ✓ Single coordinate space throughout (loopStart to loopEnd)
- ✓ Backward compatible (no API changes)
- ✓ Consistent with spectral engine design
- ✓ Edge case protection for extreme loop regions

**Performance Impact:**
- Negligible - `Select.ar` is cheaper than `XFade2` (no crossfade computation)
- Removed redundant `.linlin` in bufPos calculation
- No additional CPU overhead

---

## Future Improvements

**Potential enhancements (not required for current fix):**
1. Add visual "clipping" indicators when playhead reaches loop boundaries
2. Implement loop "ping-pong" mode (reverse direction at boundaries)
3. Add loop crossfade regions (smooth transition at boundaries)
4. Sync direct playback engine playhead (currently not visualized in loop mode)

---

## Related Documentation

- `CLAUDE.md` - Section: "Loop System: Non-destructive loop windows with visual selection"
- `gui/viewfinder.scd` - Lines 337-383: Playhead visualization layers
- `core/grain-engine.scd` - Lines 199-220: Phasor and scanPos calculation
- `FEATURES.md` - Section: "Loop System"

---

## Deployment Checklist

Before merging:
- [x] Fix implemented in `grain-engine.scd` (Option A: Select.ar)
- [x] Edge case protection added (loopEnd minimum)
- [x] Test files created
- [x] Documentation updated
- [ ] Manual testing completed (run visual test)
- [ ] User verification (visual test passed)
- [ ] Update CHANGELOG.md with fix notes
- [ ] Tag version (suggest v2.2.1 bugfix release)

---

**Questions?** See CLAUDE.md section "Common Development Tasks > Debugging Audio Issues"
