# BEARULATOR: TODO List

**Active Development Tracker**

---

## 🎯 **Current Phase: 16 (Two Captains Fix + Wow & Flutter)**

**Status:** 🚧 In Progress
**Date:** January 17, 2026

---

## ✅ **COMPLETED TODAY: Phase 16 (Jan 17, 2026)**

### Two Captains Fix ✅

**Problem:** GUI toggle buttons fought with `engineMix` Smart Sleep logic for engine control.

**Solution:** Unified parameter-based engine control system.

1. **✅ Added Engine Enable Parameters**
   - `grainOn`, `spectralOn`, `directOn` (single source of truth)
   - File: `core/track-manager.scd`

2. **✅ Rewrote Smart Sleep Logic**
   - Checks enable flags before waking engines
   - Fixed ghosting bug (threshold 1% → 0.1%, explicit 0.0 amp)
   - File: `core/track-manager.scd`

3. **✅ Updated Viewfinder Buttons**
   - Buttons now set parameters (not manual `.run()`)
   - Sync with backend state correctly
   - File: `gui/viewfinder.scd`

4. **✅ Test Suite Created**
   - 7 comprehensive tests for unified control
   - File: `tests/two-captains-fix-test.scd` (worktree)

**Commit:** 32048d1 - Pushed to GitHub ✅

---

## ✅ **COMPLETED: Wow & Flutter Tape Degradation**

**Status:** Complete ✅
**Commit:** ea32c8e - Pushed to GitHub ✅

1. **✅ Update SynthDef (core/direct-playback.scd)**
   - Added 4 parameters: `wowRate`, `wowDepth`, `flutterRate`, `flutterDepth`
   - Wow = LFNoise1.kr (slow drift, 0.1-2 Hz, ±5% depth)
   - Flutter = LFNoise2.kr (fast warble, 5-15 Hz, ±2% depth)
   - Combined modulation of PlayBuf rate

2. **✅ Update Track Manager (core/track-manager.scd)**
   - Added 4 new params to defaultParams
   - Default: wowRate=0.5, wowDepth=0.0, flutterRate=10.0, flutterDepth=0.0

3. **✅ Add GUI Controls (gui/viewfinder.scd)**
   - "WOW & FLUTTER" section in viewfinder (CYAN label)
   - 2 rate NumberBoxes + 2 depth Sliders
   - Positioned after Spectral Engine controls

4. **✅ Test Script Created**
   - File: `tests/wow-flutter-test.scd` (worktree)
   - 6 comprehensive tests

**Features:**
- Vintage cassette deck emulation (Boards of Canada vibes)
- Disintegration loop aesthetic (William Basinski)
- Minimal CPU impact (2 LFO generators)

---

## ✅ **COMPLETED: KeyStep Pro Multi-Track Routing**

**Status:** Complete ✅
**Commit:** 47fca56 - Pushed to GitHub ✅

1. **✅ Update MIDI Mapping (core/keystep-pro-mapping.scd)**
   - Added `midiEnabledTracks` boolean array [true, false, false, false]
   - Modified CC/note handlers to broadcast to all enabled tracks
   - Added `enableTrackMIDI(trackNum, enabled)` function

2. **✅ Add GUI Buttons (gui/four-track-view.scd)**
   - 4 toggle buttons in Master tab under "KEYSTEP PRO ROUTING"
   - Labels: "T1 MIDI ON/OFF", "T2 MIDI ON/OFF", etc.
   - Green when enabled, gray when disabled

3. **✅ Test Script Created**
   - File: `tests/keystep-multitrack-test.scd` (worktree)
   - 7 comprehensive tests

**Features:**
- Control multiple tracks simultaneously with one KeyStep
- Default: Track 1 only (backward compatible)
- Use cases: all 4 tracks, selective routing (1+3, 2+4, etc.)

---

## 📋 **Backlog (Phase 17+)**

### Spectral Photobooth (~4-6 hours)
- RecordBuf capture of spectral engine output
- Snapshot button in viewfinder
- Target track selector
- Instant loading of frozen spectral frame

### Shared Clock + Phase Lock (~6-8 hours)
- Global TempoClock for all tracks
- Tempo parameter + subdivision selector
- Phase-locked playback system
- Trigger system (track → track triggering)

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
- [ ] Surround sound export (5.1/7.1)
- [ ] Headless Linux build
- [ ] Raspberry Pi stripped version

---

## ✅ **Completed Phases**

- [x] **Phase 1-9:** Core engine, GUI, effects, filters
- [x] **Phase 10:** Dual-topology filters (ZDF Ladder + SVF)
- [x] **Phase 11:** Visual feedback (FFT spectrogram, grain pulse)
- [x] **Phase 12:** MIDI, recording viewfinder, quad output
- [x] **Phase 13:** Audio-rate modulation, spatial automation
- [x] **Phase 14:** Preset system, complete tutorial
- [x] **Phase 15:** Time Stretch, Direct Mode, Presets, MIX Mode
- [x] **Phase 15.5:** Engine Stabilization + MIDI Enhancements
- [x] **Phase 16 (Partial):** Two Captains Fix (engine toggle conflict)

---

## 🐛 **Known Issues**

- Waveform display uses temp files for recorded buffers
- Modulation window is a separate popup (not integrated)
- "Too many grains!" warnings when density/overlap very high

---

## 📊 **Progress Tracking**

**Overall Completion:**
- **Phase 1-15.5:** 100% ✅
- **Phase 16:** 100% ✅ (Two Captains, Wow & Flutter, KeyStep routing)

**Current Session Goals:**
- ✅ Two Captains Fix
- ✅ Wow & Flutter Tape Degradation
- ✅ KeyStep Pro Multi-Track Routing

**Session Summary:**
- 3 major features implemented
- 5 files modified (core/track-manager.scd, core/direct-playback.scd, core/keystep-pro-mapping.scd, gui/viewfinder.scd, gui/four-track-view.scd)
- 3 commits pushed to GitHub
- 3 test scripts created (worktree)
- Total time: ~3 hours

---

**Last Updated:** January 17, 2026 (Phase 16 COMPLETE ✅)
**Version:** v2.3 (Two Captains Fix + Wow & Flutter + Multi-Track MIDI)
