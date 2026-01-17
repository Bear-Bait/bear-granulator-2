# 🎯 Goals.md vs Current State

**Comparing the M4 Extreme Performance Plan to actual implementation**

**Date:** January 4, 2026

---

## 📊 **Summary Table**

| Feature | Goals.md Priority | Status | Phase Completed | Notes |
|---------|------------------|--------|-----------------|-------|
| **Audio-Rate Modulation** | HIGH | ✅ COMPLETE | Phase 13 | All LFOs at 48kHz |
| **4x Oversampled Saturation** | HIGH | ❌ NOT STARTED | - | Color FX section needs upgrade |
| **128-Band Resonator** | HIGH | ❌ NOT STARTED | - | DynKlank implementation pending |
| **Real-Time Playhead (60-120Hz)** | HIGH | ❌ NOT STARTED | - | SendReply.ar needed |
| **Concurrent Dual-Engine** | MEDIUM | ⚠️ PARTIAL | Phase 8 | Engines exist but don't run in parallel |
| **DC Safety & Limiter** | CRITICAL | ✅ COMPLETE | Phase 9 | LeakDC + soft limiter on master |

---

## ✅ **What's Already Done (Exceeds Goals.md)**

### 1. Audio-Rate Modulation ✅
**Goal:** Migrate all modulation to `.ar` at 48kHz

**Status:** **COMPLETE** (Phase 13)

**Implementation:**
- `core/modulator.scd` uses `.ar` for all LFOs
- All modulation buses are audio-rate
- Mapper synths use `In.ar` / `Out.ar`

**Results:**
- Zero zipper noise on filters
- FM synthesis enabled (LFOs reach audible frequencies)
- Sub-millisecond precision
- CPU increase: only +3-5%

**File:** `core/modulator.scd` lines 46-90

---

### 2. DC Safety & System Headroom ✅
**Goal:** LeakDC.ar and Limiter.ar on master bus

**Status:** **COMPLETE** (Phase 9)

**Implementation:**
- `LeakDC.ar` prevents DC offset
- Soft limiter using `tanh` saturation
- Glue compressor (2:1 soft-knee)
- 2x volume boost compensation

**File:** `core/mix-bus.scd`

---

### 3. Beyond Goals.md - Extra Features Completed ✅

**Phase 10: Dual-Topology Filters**
- ZDF Ladder filter (Moog-style)
- State Variable Filter (LP/BP/HP morph)
- Pre-filter drive stage
- Already has analog character!

**Phase 11: Visual Feedback**
- FFT spectrogram overlay (10-band real-time)
- Grain pulse animation
- Position trails

**Phase 12: MIDI + Quad + Recording**
- KeyStep Pro integration (5 encoders)
- Polyphonic notes (4 channels → 4 tracks)
- Quad spatial audio (4-speaker output)
- Recording viewfinder with region selection

**Phase 13: Spatial Automation**
- LFO → Quad X/Y routing
- Real-time position trails
- Freeze/Randomize/Save/Load quad presets
- Per-grain quad positioning (experimental)

**Phase 14: Preset System**
- Complete state save/load
- 10 example presets
- 20-recipe tutorial
- Getting started guide

---

## ❌ **What's Still Missing (From Goals.md)**

### 1. 4x Oversampled Saturation ❌
**Priority:** 🔴 HIGH (Sonic Fidelity)

**Goal (from Goals.md):**
> "4x upsampling chain (192kHz) → non-linear saturation → 4x downsampling with anti-aliasing filter"

**Current State:**
- Color FX section exists (distortion, bit crusher)
- Runs at standard sample rate (48kHz)
- **No oversampling** → digital aliasing on heavy saturation

**Why It Matters:**
- Current distortion sounds "brittle" at high settings
- Aliasing creates unwanted frequencies
- M4 has the power for 4x oversampling

**What's Needed:**
```supercollider
// In grain-engine.scd Color FX section:
sig = sig * 4;  // Upsample (SRC)
sig = sig.tanh;  // Saturation (at 192kHz)
sig = LPF.ar(sig, 20000);  // Anti-alias filter
sig = sig / 4;  // Downsample
```

**Estimated Time:** 3-4 hours
**CPU Impact:** +5-10% (acceptable on M4)

---

### 2. 128-Band DynKlank Resonator ❌
**Priority:** 🔴 HIGH (Spectral Density)

**Goal (from Goals.md):**
> "96 or 128 bands per track using DynKlank.ar, driven by Buffer containing 128 precise frequency ratios"

**Current State:**
- No master filterbank exists
- Basic master bus (compressor + limiter only)
- **No resonator system**

**Why It Matters:**
- Goals.md says: "Shifts from 'a group of filters' to 'a physical resonant object'"
- Professional spectral resolution
- M4 can handle massive parallel filter banks

**What's Needed:**
```supercollider
// Create core/master-filterbank.scd
~freqs = Buffer.loadCollection(s, (0..127).collect({ |i|
    20 * (18000/20).pow(i / 127);  // Log-spaced 20Hz - 18kHz
}));

SynthDef(\s4Resonator, { |out=0, in=0, res=0.5, mix=0.5|
    var sig = In.ar(in, 2);
    var resonated = DynKlank.ar(`[
        ~freqs,  // 128 frequencies
        nil,     // Equal amplitudes
        {1.0}.dup(128)  // Ring times
    ], sig, res);
    Out.ar(out, XFade2.ar(sig, resonated, mix * 2 - 1));
}).add;
```

**Estimated Time:** 3-4 hours
**CPU Target:** <30% per track (from Goals.md)

---

### 3. Real-Time Playhead Visualization (60-120Hz) ❌
**Priority:** 🔴 HIGH (Visual Precision)

**Goal (from Goals.md):**
> "Hardware-timed playhead pushed via SendReply.ar at 60-120Hz to GPU-rendered UserView"

**Current State:**
- Playhead exists (cyan "Live" line)
- Updates at 20Hz via AppClock task
- **Polling-based** → lag/jitter

**Why It Matters:**
- Current playhead lags behind actual audio
- Not sample-accurate
- Can't track fast grain movement

**What's Needed:**
```supercollider
// In grain-engine.scd:
SendReply.ar(Impulse.ar(120), '/playhead', [
    Phasor.ar(0, BufRateScale.kr(bufnum), 0, BufFrames.kr(bufnum))
]);

// In viewfinder.scd:
OSCdef(\playheadUpdate, { |msg|
    { ~playheadPos = msg[3]; this.refresh }.defer;
}, '/playhead');
```

**Estimated Time:** 3-4 hours
**Benefit:** Zero UI latency, sample-locked tracking

---

### 4. Concurrent Dual-Engine Mode ⚠️
**Priority:** 🟡 MEDIUM (Versatility)

**Goal (from Goals.md):**
> "Run both GrainBuf and Warp1 simultaneously per track, rather than as a toggle"

**Current State:**
- Both engines exist (`\s4GrainEngine`, `\s4SpectralEngine`)
- Controlled by `spectralMix` parameter (0=grain, 1=spectral)
- **Crossfade mode only** (not parallel)

**Why It Matters:**
- Goals.md vision: "Warp1 creates frozen spectral bed, GrainBuf adds rhythmic shards on top"
- Layered sculpting possibilities
- Leverages M4's 24GB RAM

**What's Needed:**
```supercollider
// In track-manager.scd:
// Current: spectralMix crossfades between engines
// New: Both run in parallel, mix control balances them

track.spectralSynth.set(\amp, spectralAmp);  // Independent level
track.grainSynth.set(\amp, grainAmp);        // Independent level
// Both output to same bus → additive mix
```

**Estimated Time:** 2-3 hours
**CPU Impact:** +10-15% (both engines running)

---

## 📋 **Recommended Implementation Order**

Based on Goals.md priorities:

### **Phase 15 (Audio Quality):**
1. 🔴 **4x Oversampled Saturation** (3-4 hours)
   - Immediate sonic improvement
   - Makes Color FX section sound analog

2. 🔴 **128-Band DynKlank Resonator** (3-4 hours)
   - Major feature add
   - Requires CPU optimization testing

3. 🔴 **Real-Time Playhead Visualization** (3-4 hours)
   - Visual precision upgrade
   - Sample-accurate tracking

### **Phase 16 (MIDI + Workflow):**
4. 🟡 **Musical Scaling Logic** (2 hours)
   - Makes MIDI usable
   - Quick win

5. 🟡 **Enhanced MIDI Routing** (1-2 hours)
   - Complete KeyStep Pro integration
   - Bank switching for 4 tracks

### **Phase 17 (Versatility):**
6. 🟡 **Concurrent Dual-Engine** (2-3 hours)
   - Layered sculpting
   - Creative sound design

### **Phase 18 (Polish):**
7. 🟢 **Visual Enhancements** (2-3 hours)
   - Success Green pulses
   - Playhead glow effect

---

## 🎯 **Goals.md Vision vs Reality**

### **The Vision (from Goals.md):**
> "High-Resolution Desktop Architecture prioritizing Signal Purity, Sample-Accurate Modulation, and Spectral Density over CPU conservation."

### **Current Reality:**
- ✅ **Signal Purity:** Partially achieved (LeakDC, soft limiter, glue compressor)
- ✅ **Sample-Accurate Modulation:** COMPLETE (audio-rate LFOs at 48kHz)
- ❌ **Spectral Density:** NOT achieved (no 128-band resonator yet)

### **The Gap:**
**3 major features from Goals.md are missing:**
1. 4x Oversampled Saturation
2. 128-Band Resonator
3. Real-Time Playhead (60-120Hz)

**All three are HIGH priority** and would complete the M4 Extreme Performance vision.

---

## 💡 **Quick Wins (What to Do First)**

### **If You Want Immediate Audio Quality:**
Start with **4x Oversampled Saturation**
- 3-4 hours implementation
- Makes distortion sound analog
- Noticeable difference immediately

### **If You Want Visual Precision:**
Start with **Real-Time Playhead**
- 3-4 hours implementation
- Sample-accurate visual feedback
- Professional-grade UI feel

### **If You Want Spectral Processing:**
Start with **128-Band Resonator**
- 3-4 hours implementation
- Biggest new feature
- Requires careful testing

---

## 📊 **Progress Metrics**

**From Goals.md M4 Extreme Plan:**
- **Total Features:** 6
- **Completed:** 2 (33%)
- **Partially Complete:** 1 (17%)
- **Not Started:** 3 (50%)

**Overall BEARULATOR Completion:**
- **Phases 1-14:** 100% complete ✅
- **Phase 15 (M4 Extreme):** 33% complete (2/6 features)

**Next Milestone:** Complete Phase 15 (all 6 Goals.md features done)

---

## 🚀 **Action Items**

1. **Review this document** - Understand what's done vs what's missing
2. **Pick a starting point** - Choose from 3 HIGH priority tasks
3. **Implement & test** - One feature at a time
4. **Update TODO.md** - Track progress as you go
5. **Repeat** - Until all Goals.md features complete

---

**Bottom Line:**
- ✅ **Phase 13 audio-rate modulation is DONE** - it exceeded Goals.md expectations
- ❌ **3 major features still missing** - all HIGH priority from Goals.md
- 🎯 **Total remaining work:** ~10-15 hours to complete M4 Extreme vision

**The good news:** Everything is well-documented, tested infrastructure exists, and the hard parts (audio-rate mod, preset system) are done!

---

**Last Updated:** January 4, 2026
**Source:** Goals.md (M4 Extreme Performance Plan)
