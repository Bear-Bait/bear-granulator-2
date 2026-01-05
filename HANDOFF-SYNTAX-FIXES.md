# S-4 Rival: Syntax Fix Handoff

## Current Status (Jan 5, 2026)

**Context:** Previous Claude instance implemented 7 major features overnight. All features are complete but SuperCollider syntax errors prevent main.scd from loading.

## Progress So Far

### ✅ Fixed (2/3 files):
1. **four-track-view.scd** - Moved `presetTrackNum` variable to parent function's var declarations at top
2. **viewfinder.scd line 1042** - Fixed pitch quantize button block by adding `.value;` to properly close the block scope

### ❌ Remaining Errors (2 files):

#### 1. modulation-window.scd line 260
**Error:**
```
ERROR: syntax error, unexpected VAR, expecting '}'
  line 260 char 8:
      var y1 = midY - (val1 * midY * 0.8);
```

**Problem:** Lines 260-261 declare `var y1` and `var y2` AFTER other statements inside the `.do` block. SuperCollider requires ALL var declarations at the top of each block.

**Location:** gui/modulation-window.scd lines 238-264

**The Fix:**
```supercollider
numPoints.do({ arg i;
    var x1 = (i / numPoints) * w;
    var x2 = ((i + 1) / numPoints) * w;
    var phase1 = (i / numPoints) + (time * rate * 0.5);
    var phase2 = ((i + 1) / numPoints) + (time * rate * 0.5);
    var val1, val2, y1, y2;  // <-- ADD y1, y2 HERE

    // Calculate waveform value based on shape
    val1 = case
        { shape == 0 } { (phase1 * 2pi).sin }
        { shape == 1 } { ((phase1 % 1) * 4 - 2).abs - 1 }
        { shape == 2 } { ((phase1 % 1) * 2) - 1 }
        { shape == 3 } { if((phase1 % 1) < 0.5, 1, -1) }
        { 0 };

    val2 = case
        { shape == 0 } { (phase2 * 2pi).sin }
        { shape == 1 } { ((phase2 % 1) * 4 - 2).abs - 1 }
        { shape == 2 } { ((phase2 % 1) * 2) - 1 }
        { shape == 3 } { if((phase2 % 1) < 0.5, 1, -1) }
        { 0 };

    y1 = midY - (val1 * midY * 0.8);  // <-- REMOVE 'var' keyword
    y2 = midY - (val2 * midY * 0.8);  // <-- REMOVE 'var' keyword

    Pen.line(Point(x1, y1), Point(x2, y2));
});
```

**Action Required:**
1. Change line 243 from `var val1, val2;` to `var val1, val2, y1, y2;`
2. Change line 260 from `var y1 = midY...` to `y1 = midY...`
3. Change line 261 from `var y2 = midY...` to `y2 = midY...`

---

#### 2. viewfinder.scd line 1145
**Error:**
```
ERROR: syntax error, unexpected ',', expecting '}'
  line 1145 char 4:
      },
   ^
```

**Problem:** There's a stray comma or unclosed structure around line 1145. This is a NEW error that appeared after fixing line 1042.

**Action Required:**
1. Read viewfinder.scd lines 1140-1150 to identify the syntax error
2. Look for:
   - Missing closing braces
   - Extra commas
   - Unclosed function calls
3. Fix the syntax error

**Likely cause:** The `.value;` I added at line 1059 may have broken something downstream, OR there was already a latent syntax error that's now exposed.

---

## After Fixing Syntax Errors

### Test All 7 Features:

1. **Time Stretch** - Verify PitchShift UGen works (pitch shift without speed change)
2. **Rate Parameter** - Test direct playback speed control (0.25x-4x range)
3. **Recording Playhead** - Verify red line playhead still tracks during recording
4. **Preset System** - Test SAVE/LOAD/BROWSE buttons in four-track view
5. **Direct Mode Controls** - Test Rate slider and SMTH/QNTZ toggle in viewfinder
6. **Mini-Scope Visualizers** - Open modulation window, verify 80x40px waveform displays animate
7. **MIX Mode** - Test 3-mode engine switching (GRANULAR/DIRECT/MIX button)

### Then Proceed With MIDI Features:

From TODO.md:
1. Add MIDI clock receiver for tempo sync
2. Implement tempo-synced LFO rates (1/4, 1/8, 1/16 notes)
3. Add KeyStep Pro MIDI velocity mapping to grain density
4. Add KeyStep Pro MIDI velocity mapping to saturation

---

## Key Technical Context

### SuperCollider Variable Declaration Rule:
```supercollider
// CORRECT - all vars at top of block
{ arg x, y;
    var a, b, c;
    a = x + 1;
    b = y + 2;
    c = a + b;
}

// WRONG - var in middle of block
{ arg x, y;
    var a;
    a = x + 1;
    var b;  // ERROR! Can't declare var here
    b = y + 2;
}
```

### File Locations:
- Main file: `/Users/forrestmuelrath/Documents/supercollider/granular/main.scd`
- Modulation window: `gui/modulation-window.scd`
- Viewfinder: `gui/viewfinder.scd`
- Four-track view: `gui/four-track-view.scd`

### Testing Command:
```bash
cd /Users/forrestmuelrath/Documents/supercollider/granular
# Then in SuperCollider IDE, run: main.scd
```

---

## Files Modified in Overnight Session:

**Created:**
- core/preset-manager.scd (243 lines - complete preset save/load system)
- OVERNIGHT-PROGRESS.md (full documentation)
- HANDOFF-SYNTAX-FIXES.md (this file)

**Modified:**
- core/direct-playback.scd (time stretch, pitch compensation)
- core/track-manager.scd (3-mode engine switching)
- gui/viewfinder.scd (Rate slider, Quantize button, 3-mode)
- gui/four-track-view.scd (Preset GUI, MIX mode PLAY logic) - PARTIALLY FIXED
- gui/modulation-window.scd (Mini-scopes) - NEEDS FIX
- main.scd (Preset manager integration)
- TODO.md (updated with testing status)

---

## Next Steps for New Claude Instance:

1. **IMMEDIATE:** Fix remaining syntax errors in modulation-window.scd and viewfinder.scd
2. **TEST:** Run main.scd in SuperCollider IDE and verify all 7 features work
3. **DOCUMENT:** Update TODO.md to mark testing complete
4. **PROCEED:** Begin MIDI features implementation per TODO.md

---

**Last Updated:** January 5, 2026
**Status:** 2/3 files fixed, 2 syntax errors remaining
**Ready for:** New Claude instance to complete syntax fixes and begin testing
