# Morning Checklist - Phase 6b & 7 Testing

**Date:** 2026-01-02 (Tomorrow Morning)
**Estimated Time:** 30-60 minutes

---

## CRITICAL FIXES FIRST (5 minutes)

### 1. Fix Volume Settings
**Issue:** Volume was cranked to 50x due to broken computer output knob (now identified)

**Files to edit:**

**A. Revert Limiter** (`core/mix-bus.scd` line 152)
```supercollider
// CHANGE FROM:
mix = mix.clip(-1.0, 1.0);

// BACK TO:
mix = mix.tanh;
```

**B. Lower Volume Boost** (`core/grain-engine.scd` line 202)
```supercollider
// CHANGE FROM:
sig = sig * 50.0;

// BACK TO:
sig = sig * 2.0;
```

**Save both files after editing!**

---

## BOOT TEST (5 minutes)

### 2. Clean Boot
```supercollider
// Close SuperCollider completely
// Reopen
// Run:
main.scd
```

**Check for:**
- [ ] No "Too many grains" errors
- [ ] "SYSTEM READY!" message appears
- [ ] All modules loaded successfully
- [ ] No syntax errors in post window

---

## PHASE 6B TESTING: Overlap Mode (10 minutes)

### 3. Verify Overlap Slider Exists
- [ ] GUI has "Overlap" slider (not "Density")
- [ ] Default value is 4
- [ ] Range is 1-128
- [ ] Help text says "Overlap = simultaneous grains..."

### 4. Test Full-Length Playback
```supercollider
// Load Houston audio file on Track 1
// Use "Load Audio File" button or:
// /Users/forrestmuelrath/Documents/supercollider/sounds/a11wlk01-44_1.aiff

// Set these values:
Grain Size: 2.7s (drag slider to max)
Overlap: 1 (drag to minimum)
Position: 0.5
Amp: 0.5
Material Mode: TAPE (should be default)
```

**Expected Result:**
- [ ] Hear FULL "columbia this houston over" phrase
- [ ] Loops cleanly (no glitches)
- [ ] No feedback or artifacts
- [ ] Volume is reasonable (not ear-blasting after fix)

### 5. Test Overlap Variations
- [ ] Overlap = 1: Very sparse, clean
- [ ] Overlap = 4: Default, balanced
- [ ] Overlap = 8: Denser texture
- [ ] Overlap = 16: Very dense cloud

**All should work without "Too many grains" error**

---

## PHASE 7 TESTING: Viewfinder (20 minutes)

### 6. Open Viewfinder
```supercollider
// Method 1: Click "LOOP VIEW" button in Track 1 tab (blue, top-right)
// Method 2: Code
~viewfinder.createWindow(0);
```

**Check:**
- [ ] Viewfinder window opens
- [ ] Waveform displays (cyan on black)
- [ ] Title says "Track 1 Viewfinder"
- [ ] Grid visible
- [ ] Three buttons at bottom (Reset Loop, Select All, Refresh)

### 7. Test Loop Selection (TAPE Mode)
- [ ] Drag across waveform to select region
- [ ] Selection highlights visually
- [ ] Status bar updates: "Loop: 0.52s - 1.84s..."
- [ ] Audio changes immediately (hear only selected region loop)
- [ ] Post window shows feedback

### 8. Test "Reset Loop" Button
- [ ] Click "Reset Loop"
- [ ] Selection expands to full buffer
- [ ] loopStart = 0.0, loopEnd = 1.0
- [ ] Hear full audio again

### 9. Test Small Loop Window
- [ ] Select only "houston" word (middle section)
- [ ] Should hear only that word looping
- [ ] Position slider scans through "houston"

### 10. Test Minimum Window Size
- [ ] Try to select very small region (< 1% of buffer)
- [ ] Should get warning in post window
- [ ] Window auto-expands to 1% minimum

---

## MATERIAL MODE INTEGRATION (15 minutes)

### 11. POLY Mode with Loop Window
```supercollider
~trackManager.setMode(0, 1);  // POLY mode
```

- [ ] Select "columbia" (beginning of buffer)
- [ ] Set Position = 0.0
- [ ] Grains trigger from "co" sound
- [ ] No looping (grains read forward only)
- [ ] Different Position values = different trigger points

### 12. LIVE Mode with Loop Window
```supercollider
~trackManager.setMode(0, 2);  // LIVE mode
```

- [ ] Select last 50% of buffer
- [ ] Position = 0.0 (most recent)
- [ ] Position = 1.0 (furthest back)
- [ ] Sounds like delay/echo effect

### 13. Back to TAPE Mode
```supercollider
~trackManager.setMode(0, 0);  // TAPE mode
```

- [ ] Verify looping behavior returns

---

## MULTI-TRACK TESTING (5 minutes)

### 14. Multiple Viewfinders
```supercollider
// Open viewfinder for Track 2
~viewfinder.createWindow(1);
```

- [ ] Second viewfinder window opens
- [ ] Independent of Track 1 viewfinder
- [ ] Can select different loop regions
- [ ] Each track maintains its own loop window

---

## EDGE CASES (5 minutes)

### 15. No Buffer Loaded
- [ ] Try opening viewfinder on empty track
- [ ] Should get warning: "Track has no buffer loaded"
- [ ] No crash

### 16. Close and Reopen
- [ ] Close viewfinder window (Cmd+W)
- [ ] Reopen with button or code
- [ ] Should remember current loop window
- [ ] Should load correctly

---

## AUTOMATED TEST SCRIPT (Optional)

### 17. Run Test Script
```supercollider
TEST-VIEWFINDER.scd
```

- [ ] Loads Houston audio automatically
- [ ] Opens viewfinder
- [ ] Displays instructions
- [ ] No errors

---

## SUCCESS CRITERIA

**Phase 6b (Overlap) is successful if:**
- ✅ Overlap slider exists and works
- ✅ Overlap=1, GrainSize=2.7s plays full Houston audio cleanly
- ✅ No "Too many grains" errors
- ✅ Volume is reasonable (after fix)

**Phase 7 (Viewfinder) is successful if:**
- ✅ Viewfinder opens and displays waveform
- ✅ Dragging updates loop window in real-time
- ✅ Works with TAPE mode (looping)
- ✅ Works with POLY mode (sample trigger)
- ✅ Works with LIVE mode (lookback)
- ✅ Independent per-track loop windows
- ✅ Status bar shows loop info

---

## IF ISSUES FOUND

### Volume Still Wrong
- Check computer output knob is working
- Check MOTU interface settings
- Adjust `sig = sig * 2.0` multiplier up/down as needed

### Viewfinder Won't Open
- Check `~viewfinder.postln` - should be an Event
- Check buffer loaded: `~trackManager.getTrack(0).recorder.buffer.postln`
- Try `~viewfinder.createWindow(0)` from code

### Syntax Errors
- Run `SYNTAX-CHECK.scd` to find issues
- Check post window for specific error message
- Look for unmatched braces/parens

### Selection Not Working
- Wait ~1 second after opening for waveform to load
- Click "Refresh" button
- Close and reopen viewfinder

---

## AFTER SUCCESSFUL TESTING

### Commit to Git
```bash
# Add all changes
git add .

# Commit with message
git commit -m "$(cat <<'EOF'
Phase 6b & 7 Complete: Overlap Control + Dynamic Windowing Sampler

Phase 6b:
- Overlap parameter replaces Density
- Auto-density calculation: density = overlap / grainSize
- Fixed "Too many grains" error
- Volume normalization (2x boost + tanh limiter)

Phase 7:
- Waveform viewfinder with SoundFileView
- Real-time loop window selection
- Integration with TAPE/POLY/LIVE material modes
- Per-track independent loop windows
- Reset/Select All/Refresh buttons
- Dynamic status text

Version: v0.7.001
EOF
)"

# Push to GitHub
git push origin main
```

---

## QUICK REFERENCE COMMANDS

```supercollider
// Open viewfinder
~viewfinder.createWindow(0);

// Change material mode
~trackManager.setMode(0, 0);  // TAPE
~trackManager.setMode(0, 1);  // POLY
~trackManager.setMode(0, 2);  // LIVE

// Set overlap
~trackManager.setParam(0, \overlap, 4);

// Close all viewfinders
~viewfinder.closeAll;

// Check synth running
~trackManager.getTrack(0).grainSynth.postln;
```

---

**Total Estimated Time:** 30-60 minutes
**Priority:** High (2 major features to validate)
**Risk Level:** Low (clean implementation, syntax validated)

**Good luck with testing! 🎛️✨**
