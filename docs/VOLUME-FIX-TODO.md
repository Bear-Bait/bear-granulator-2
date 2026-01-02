# Volume Fix TODO (For Tomorrow)

**Issue:** Volume was too quiet, but this was caused by a **broken output knob on the computer**, not the synth.

**Current State:**
- grain-engine.scd line 202: `sig = sig * 50.0` (way too loud!)
- mix-bus.scd line 152: `mix = mix.clip(-1.0, 1.0)` (hard limiter, should be soft)

---

## Changes to Make Tomorrow

### 1. Revert Limiter (mix-bus.scd)

**File:** `core/mix-bus.scd`
**Line:** 152

**Change from:**
```supercollider
// Hard limiter to prevent clipping (allows much more level than tanh)
mix = mix.clip(-1.0, 1.0);
```

**Back to:**
```supercollider
// Soft limiter to prevent clipping
mix = mix.tanh;
```

**Why:** Tanh is a proper soft limiter that prevents harsh clipping. Hard clip sounds bad.

---

### 2. Lower Volume Boost (grain-engine.scd)

**File:** `core/grain-engine.scd`
**Line:** 202

**Change from:**
```supercollider
// Phase 6b: Volume boost for overlap mode
// 50x gain boost - GrainBuf output is extremely quiet compared to hardware synths
sig = sig * 50.0;
```

**Change to:**
```supercollider
// Phase 6b: Volume boost for overlap mode
// Moderate gain boost to compensate for grain overlap variations
sig = sig * 2.0;
```

**Why:** 50x was an overreaction to the broken knob. 2x is reasonable compensation for overlap mode density changes.

---

## Testing After Fix

1. Boot main.scd
2. Load Houston audio file
3. Set amp slider to 0.5
4. Check that:
   - Output is reasonable level (not ear-blasting)
   - No harsh distortion (tanh should smooth peaks)
   - Comparable to other SuperCollider patches

---

## Explanation of the Issue

The problem was:
1. User's computer has a **broken output volume knob**
2. Output was stuck at very low level
3. We kept increasing gain to compensate (10x → 50x)
4. User thought MOTU interface controlled output, but computer knob was the actual culprit

The fix:
- Revert excessive gain
- Restore proper soft limiting
- Volume should now be normal with working output knob

---

## Quick Reference

**Files to edit:**
1. `core/mix-bus.scd` line 152
2. `core/grain-engine.scd` line 202

**Time estimate:** 2 minutes

**Risk:** Low (just reverting to known-good values)
