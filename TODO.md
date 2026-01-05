# S-4 RIVAL: TODO List

**Active Development Tracker**

---

## 🎯 **Current Phase: 15 (M4 Extreme Performance)**

**Status:** Planning Complete, Ready to Implement
**Source:** Goals.md (M4 Extreme Performance Plan)

---

## ✅ **Completed Phases**

- [x] **Phase 1-9:** Core engine, GUI, effects, filters
- [x] **Phase 10:** Dual-topology filters (ZDF Ladder + SVF)
- [x] **Phase 11:** Visual feedback (FFT spectrogram, grain pulse)
- [x] **Phase 12:** MIDI, recording viewfinder, quad output
- [x] **Phase 13:** Audio-rate modulation, spatial automation
- [x] **Phase 14:** Preset system, complete tutorial

---

## 🚧 **Phase 15: M4 Extreme Performance (Audio Quality)**

**From Goals.md - High-Resolution Desktop Architecture**

### 1. 4x Oversampled Saturation (Color Section)
**Priority:** 🔴 HIGH (Sonic Fidelity - from Goals.md)
**Status:** ❌ Not Started
**Assignee:** TBD
**Est. Time:** 3-4 hours

**Task:**
- [ ] Implement 4x upsampling chain (48kHz → 192kHz)
- [ ] Apply nonlinear saturation (.tanh or SoftClipAmp8)
- [ ] Implement 4x downsampling with anti-aliasing filter
- [ ] Wrap Color FX section (distortion, bit crusher)
- [ ] Test CPU impact on M4 (target: <10% increase)
- [ ] A/B comparison: standard vs oversampled

**Files:**
- `core/grain-engine.scd` (lines 257-295 - Color FX section)

**Benefits (from Goals.md):**
- Analog-like "creamy" saturation
- No digital harshness or aliasing artifacts
- Leverages M4's vectorized math performance

**Note:** ZDF filters already exist (Phase 10). This is about oversampled saturation.

---

### 2. 128-Band DynKlank Resonator
**Priority:** 🔴 HIGH (from Goals.md)
**Status:** ❌ Not Started
**Assignee:** TBD
**Est. Time:** 3-4 hours

**Task:**
- [x] Create `core/master-filterbank.scd`
- [x] Implement 128-band resonator using DynKlank.ar
- [x] 128 precise frequency ratios (20Hz - 18kHz log-spaced)
- [x] Buffer-driven frequency table
- [x] Optimize for M4 (target: **<30% CPU per track** - from Goals.md)
- [x] Add global resonance control
- [x] Add wet/dry mix control
- [ ] Optional: Create spectrum visualizer -- needs optimization

**Files:**
- `core/master-filterbank.scd` (new)
- `core/mix-bus.scd` (integrate)
- `gui/filterbank-visualizer.scd` (optional)
- `main.scd` (load module)

**Benefits (from Goals.md):**
- Professional spectral resolution
- Richer harmonic textures
- Sounds like "a physical resonant object" vs "group of filters"

---

### 3. Concurrent Dual-Engine Mode (GrainBuf + Warp1)
**Priority:** 🟡 MEDIUM (Versatility - from Goals.md)
**Status:** ⚠️ Partially Complete (engines exist but don't run in parallel)
**Assignee:** TBD
**Est. Time:** 2-3 hours

**Current State:**
- Both `\s4GrainEngine` and `\s4SpectralEngine` exist
- They run as toggle mode (one or the other)
- NOT running concurrently

**Task:**
- [ ] Enable parallel operation of both engines simultaneously
- [ ] Add crossfade/mix control between engines
- [ ] Update GUI to show both engines active
- [ ] Test CPU impact (should be manageable on M4)
- [ ] Create presets showcasing dual-engine layering

**Files:**
- `core/track-manager.scd` (enable parallel mode)
- `gui/four-track-view.scd` (show both engines)

**Benefits (from Goals.md):**
- **Layered Sculpting:** Warp1 creates "frozen spectral bed"
- GrainBuf adds rhythmic "shards" or "sculpted pulses" on top
- Same audio material, two processing approaches simultaneously
- Leverages M4's 24GB RAM and bandwidth

---

### 4. Real-Time Playhead Visualization (60-120Hz)
**Priority:** 🔴 HIGH (from Goals.md)
**Status:** ❌ Not Started
**Assignee:** TBD
**Est. Time:** 3-4 hours

**Current State:**
- Static waveform display
- Playhead updates with polling lag
- No sample-accurate timing

**Task:**
- [ ] Add `SendReply.ar` to grain/spectral engines
- [ ] Broadcast playhead position at 60-120Hz
- [ ] GPU-rendered playhead in UserView
- [ ] Sample-locked visual tracking
- [ ] Zero UI latency
- [ ] Works during real-time recording

**Files:**
- `core/grain-engine.scd` (add SendReply.ar)
- `core/spectral-engine.scd` (add SendReply.ar)
- `gui/viewfinder.scd` (GPU rendering)

**Benefits (from Goals.md):**
- Sample-locked visual tracking
- Zero UI latency
- Real-time recording visualization
- Professional-grade visual feedback

---

## 🎹 **Phase 16: KeyStep Pro Bridge Enhancements**

### 3. Enhanced MIDI Channel Routing
**Priority:** 🟡 Medium
**Status:** ⚠️ Partially Complete (Track 1 only)
**Assignee:** TBD
**Est. Time:** 1-2 hours

**Task:**
- [ ] Add encoder bank switching (4 banks for 4 tracks)
- [ ] Map additional CCs (79-93) to Tracks 2-4
- [ ] Add bank selector (CC 94)
- [ ] Visual feedback for active bank
- [ ] Add "global" mode for master controls

**Files:**
- `core/midi-mapping.scd`
- `gui/four-track-view.scd` (bank indicator)

---

### 4. Musical Scaling Logic
**Priority:** 🔴 High
**Status:** ❌ Not Started
**Assignee:** TBD
**Est. Time:** 2 hours

**Task:**
- [ ] Create unified scaling system for MIDI CCs
- [ ] Implement logarithmic scaling (frequency, cutoff)
- [ ] Implement exponential scaling (grain size, time)
- [ ] Implement custom curves (resonance)
- [ ] Test "musical" feel of knob movements
- [ ] Document scaling functions

**Files:**
- `core/midi-mapping.scd`

**Details:** See `docs/PHASE-15-TODO.md` for scaling function specs

---

## 🎨 **Phase 17: Visual Enhancements (Doom Aesthetic)**

### 5. "Success Green" Note Pulse
**Priority:** 🟢 Low
**Status:** ❌ Not Started
**Assignee:** TBD
**Est. Time:** 1 hour

**Task:**
- [ ] Add expanding ring effect on MIDI note trigger
- [ ] Use Doom Material Success Green (#c3e88d)
- [ ] 0.5 second fade-out animation
- [ ] Position at playhead location
- [ ] Test performance impact (<0.5% CPU)

**Files:**
- `gui/viewfinder.scd`
- `core/midi-mapping.scd`

---

### 6. Playhead Glow Effect
**Priority:** 🟢 Low
**Status:** ❌ Not Started
**Assignee:** TBD
**Est. Time:** 1-2 hours

**Task:**
- [ ] Add glow/shadow to playhead line
- [ ] Use Doom Cyan (#89DDFF)
- [ ] Implement fake blur (layered rendering)
- [ ] Optional: Toggle glow on/off
- [ ] Ensure visibility without obscuring waveform

**Files:**
- `gui/viewfinder.scd`

**Note:** SC GUI doesn't have native blur, need to fake it

---

## 📋 **Backlog (Phase 18+)**

### Future Features:
- [ ] Preset management GUI (visual browser)
- [ ] Preset tags/categories
- [ ] A/B preset comparison mode
- [ ] MIDI-triggered preset switching
- [ ] Preset morphing (interpolation)
- [ ] Track naming system
- [ ] Neon glow rendering (hardware-accelerated)
- [ ] 3D spatial visualization (quad field + height)
- [ ] Transient bypass logic (preserve drum attacks)
- [ ] 4× oversampled color section (anti-aliasing)
- [ ] Surround sound export (5.1/7.1)
- [ ] Headless Linux build
- [ ] Raspberry Pi stripped version

---

## 🐛 **Known Issues**

### Phase 14:
- None reported yet (pending user testing)

### Phase 13:
- None reported

### General:
- Waveform display uses temp files for recorded buffers
- Modulation window is separate popup (not integrated)

---

## 🧪 **Testing Checklist**

Before marking a task as complete:
- [ ] Unit tests pass (if applicable)
- [ ] CPU usage measured and documented
- [ ] Preset compatibility verified
- [ ] User acceptance testing completed
- [ ] Documentation updated
- [ ] Example code created

---

## 📊 **Progress Tracking**

**Overall Completion:**
- **Phase 1-14:** 100% ✅
- **Phase 15:** 0% (planning complete)
- **Phase 16:** 25% (basic MIDI done, enhancements pending)
- **Phase 17:** 0%

**Next Milestone:** Phase 15 Complete (Core Audio Upgrades)

**Estimated Completion:** TBD (depends on priority decisions)

---

## 🎯 **Recommended Order**

If starting fresh, tackle in this order:

1. **Musical Scaling Logic (Task 4)** - Quick win, makes MIDI usable
2. **ZDF Filter Integration (Task 1)** - Core audio quality improvement
3. **Enhanced MIDI Routing (Task 3)** - Completes KeyStep Pro integration
4. **128-Band Resonator (Task 2)** - Big feature, may take time
5. **Visual Enhancements (Tasks 5-6)** - Polish, low priority

---

## 📝 **Notes**

- All Phase 14 tasks complete as of Jan 4, 2026
- Phase 15+ tasks extracted from commit `16c4a7d`
- Audio-rate modulation already done in Phase 13
- Basic MIDI integration done in Phase 12
- Current CPU usage: ~25% (5% headroom available)

**For detailed task specs, see:**
- `docs/PHASE-15-TODO.md` - Complete technical specifications
- `docs/PHASE-14-SUMMARY.md` - What was just completed
- `FEATURES.md` - Complete feature list

---

**Last Updated:** January 4, 2026
**Version:** Phase 14 Complete, Phase 15 Planning

<!-- Local Variables: -->
<!-- gptel-model: claude-haiku-4-5-20251001 -->
<!-- gptel--backend-name: "Claude-Haiku-4.5" -->
<!-- gptel-max-tokens: 6000 -->
<!-- gptel--bounds: nil -->
<!-- End: -->
