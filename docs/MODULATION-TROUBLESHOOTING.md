# 🔧 Modulation System Troubleshooting Guide

**Common issues and how to fix them**

---

## ❌ **Problem 1: Modulation Not Affecting Sound**

### **Symptoms:**
- You create modulators and route them
- Log shows "Mod X → parameter" messages
- But the sound doesn't change

### **Possible Causes:**

#### **Cause 1A: Grain Synth Not Playing**
**Check:** Is the PLAY button lit up?

**Fix:**
```supercollider
// Press PLAY button in GUI
// Or run this:
~trackManager.getTracks[0].grainSynth.run(true);
```

---

#### **Cause 1B: Multiple Modulators → Same Parameter**
**Check:** Did you route 2+ modulators to the same parameter?

**From your log:**
```
Track 1: Mod 1 → shimmerMix (range: 0.0 to 1.0)
Track 1: Mod 2 → shimmerMix (range: 0.0 to 10.0)  ← CONFLICT!
```

**Problem:** The second mapping **overwrites** the first. Only Mod 2 will work, and its range (0-10) is **invalid** for `shimmerMix` (which only accepts 0-1).

**Fix:**
- Route each modulator to a **different** parameter
- Or use only one modulator per parameter

**Valid Example:**
```
Mod 1 → shimmerMix (0.0 to 1.0)
Mod 2 → pitch (-12 to 12)
Mod 3 → reverbMix (0.0 to 1.0)
Mod 4 → grainSize (0.01 to 2.0)
```

---

#### **Cause 1C: Invalid Parameter Range**
**Check:** Is your min/max range valid for the parameter?

**Common Invalid Ranges:**
```supercollider
// BAD: shimmerMix goes 0-10 (valid range is 0-1)
Mod → shimmerMix (0.0 to 10.0)  ❌

// BAD: grainSize goes negative
Mod → grainSize (-1.0 to 2.0)  ❌

// BAD: overlap > 128
Mod → overlap (1 to 256)  ❌
```

**Valid Ranges:**
```supercollider
// Parameter ranges (from grain-engine.scd):
grainSize:    0.001 to 60.0 (seconds)
overlap:      1 to 128 (grain count)
position:     0.0 to 1.0 (buffer position)
pitch:        -24 to +24 (semitones)
posJitter:    0.0 to 1.0
pitchJitter:  0 to 12 (semitones)
stereoSpread: 0.0 to 1.0

// Effects:
reverbMix:    0.0 to 1.0
delayMix:     0.0 to 1.0
shimmerMix:   0.0 to 1.0
distMix:      0.0 to 1.0

// Filter:
filterFreq:   20 to 18000 (Hz) - but use 0.0-1.0, it's mapped internally
filterRes:    0.0 to 1.0
```

---

#### **Cause 1D: LFO Rate is Zero**
**Check:** Did you set the LFO rate to 0?

**Problem:** If `rate = 0`, the LFO doesn't move!

**Fix:**
- Set rate to at least 0.1 Hz (slow)
- Typical rates: 0.5 Hz (slow), 2 Hz (moderate), 5 Hz (fast)

---

#### **Cause 1E: Modulation Depth is Zero**
**Check:** Is the depth slider at 0?

**Fix:**
- Set depth to 1.0 for full modulation
- Depth = 0 means "no modulation"

---

## ❌ **Problem 2: "Mod X not created yet" Error**

### **Symptoms:**
```
Track 1: Modulator 1 not created yet
```

### **Fix:**
You must **create** the modulator before **routing** it.

**Correct Order:**
1. Click "CREATE" in modulation window
2. Set type, rate, depth, shape
3. THEN click "ROUTE"
4. Choose target parameter

---

## ❌ **Problem 3: Modulation Stops After a While**

### **Possible Causes:**

#### **Cause 3A: Modulator Synth Crashed**
**Check:**
```supercollider
// See all running synths
s.plotTree;

// Look for modulator nodes
// They should be at the tail of the node tree
```

**Fix:** Re-create the modulator in the modulation window

---

#### **Cause 3B: Mapper Synth Freed**
**Check:**
```supercollider
// Run diagnostic
"tests/modulation-debug.scd".loadRelative;

// Look for "SYNTH IS NIL" messages
```

**Fix:**
- Re-route the modulator
- Or restart main.scd

---

## ❌ **Problem 4: Can't Hear LFO Movement**

### **Cause: LFO Too Slow or Too Fast**

**Too Slow:**
```supercollider
rate = 0.01 Hz  // Takes 100 seconds to complete one cycle!
```

**Too Fast:**
```supercollider
rate = 100 Hz  // Moving so fast it sounds like a constant tone
```

**Sweet Spots:**
```supercollider
// Slow evolving textures
rate = 0.1 to 0.5 Hz

// Moderate rhythmic movement
rate = 1 to 4 Hz

// Fast tremolo/vibrato
rate = 5 to 15 Hz

// Audio-rate FM synthesis
rate = 50 to 500 Hz (Phase 13 feature!)
```

---

## ❌ **Problem 5: Shimmer Mix Goes Above 1.0**

### **Symptoms:**
- Shimmer effect sounds distorted or cuts out
- Log shows `shimmerMix (0.0 to 10.0)`

### **Problem:**
`shimmerMix` is a wet/dry parameter (0-1 range), but you set max to 10.

**Fix:**
```supercollider
// In modulation window, set:
Min: 0.0
Max: 1.0  ← NOT 10!

// Then re-route
```

---

## ✅ **How to Verify Modulation is Working**

### **Method 1: Visual Check**
```supercollider
// Run diagnostic script
"tests/modulation-debug.scd".loadRelative;

// Should show:
//   Modulator: EXISTS
//   Bus values: CHANGING (not stuck at 0)
//   Mapper: EXISTS
//   Parameter: MAPPED
```

### **Method 2: Node Tree Check**
```supercollider
s.plotTree;

// Look for your grain synth
// Mapped parameters show as "a##" (audio bus number)
// Example:
//   shimmerMix: a21  ← GOOD (mapped to bus 21)
//   shimmerMix: 0.0  ← BAD (fixed value, not modulated)
```

### **Method 3: Listen Test**
```supercollider
// Route LFO → pitch with wide range
Min: -12 (one octave down)
Max: +12 (one octave up)
Rate: 0.5 Hz (slow enough to hear)

// You should hear pitch sweeping up and down clearly
// If you don't hear it, something is wrong
```

---

## 🛠️ **Quick Fix Scripts**

### **Script 1: Restart Everything**
```supercollider
// Stop all tracks
4.do({ |i| ~trackManager.getTracks[i].grainSynth.run(false); });

// Wait
1.0.wait;

// Start Track 1
~trackManager.getTracks[0].grainSynth.run(true);

// Modulation should now work
```

### **Script 2: Diagnostic**
```supercollider
"tests/modulation-debug.scd".loadRelative;
// Reads all modulation state and bus values
```

### **Script 3: Quick Fix**
```supercollider
"tests/modulation-quick-fix.scd".loadRelative;
// Automatically restarts synths to refresh mappings
```

---

## 📋 **Modulation Checklist**

Before reporting a bug, check these:

- [ ] Grain synth is PLAYING (PLAY button lit)
- [ ] Modulator is created (shows in modulation window)
- [ ] LFO rate > 0 (not zero!)
- [ ] Depth > 0 (not zero!)
- [ ] Only ONE modulator per parameter (no conflicts)
- [ ] Parameter range is valid (check list above)
- [ ] Ran `s.plotTree` and see `a##` on mapped params
- [ ] Bus values are changing (run diagnostic script)

---

## 🔍 **Advanced Debugging**

### **Read Modulation Bus Directly**
```supercollider
// Get bus number
var track = ~trackManager.getTracks[0];
var busNum = track.modBusses[0].index;  // Mod 1

// Read value
track.modBusses[0].get({ arg value;
    "Mod 1 bus value: %".format(value).postln;
});

// Should be between 0.0 and 1.0
// Should change over time if LFO is running
```

### **Monitor Bus Continuously**
```supercollider
(
// Monitor Mod 1 bus for 5 seconds
fork {
    var track = ~trackManager.getTracks[0];
    10.do({
        track.modBusses[0].get({ arg value;
            { "Mod 1: %".format(value.round(0.01)).postln; }.defer;
        });
        0.5.wait;
    });
};
)
```

### **Check if Synth is Receiving Mapped Values**
```supercollider
// This requires server-side polling (advanced)
// For now, use s.plotTree and look for 'a##' prefixes
```

---

## 💡 **Common Misconceptions**

### **Misconception 1: "More modulators = better"**
❌ **Wrong:** Routing 4 LFOs to the same parameter creates chaos

✅ **Right:** Use 1 modulator per parameter for predictable results

---

### **Misconception 2: "Higher rate = better"**
❌ **Wrong:** Rate = 100 Hz just sounds like a buzz

✅ **Right:** Musical rates: 0.1-5 Hz for evolving textures

---

### **Misconception 3: "Max range doesn't matter"**
❌ **Wrong:** Setting `shimmerMix` to 10 breaks it

✅ **Right:** Check valid range for each parameter

---

## 📖 **Further Reading**

- **Phase 13 Tutorial:** `docs/PHASE-13-TUTORIAL.md`
  - Recipe 1-10: Audio-rate modulation examples
  - Includes filter sweeps, FM synthesis, tremolo, etc.

- **Modulator Code:** `core/modulator.scd`
  - See how LFOs are implemented at audio-rate

- **Track Manager:** `core/track-manager.scd` (lines 420-530)
  - See how routing works internally

---

**Still stuck?** Run the diagnostic script and share the output:
```supercollider
"tests/modulation-debug.scd".loadRelative;
```
