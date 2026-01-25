# BEARULATOR: Active TODOs

**Current Version:** v2.2 (January 2026)

---

## 🎯 **High Priority Issues**

### 1. CLEAR TRACK Button Fix
**Status:** Broken in viewfinder GUI
**Impact:** Users cannot reset tracks to clean state
**Location:** `gui/viewfinder.scd:1107-1170`
**Notes:** Visual sliders reset but audio remains glitched

### 2. Hidden Backend Features
- **Pitch Quantization:** `quantizePitch` + `scale` parameters exist, no GUI
- **Phase Alignment Mode:** `phaseAlign` parameter exists, no GUI toggle
- **Spectral Amp:** Works via fallback but not in defaultParams

### 3. Version Information Update
**Files:** `main.scd` header and startup banner
**Issue:** Shows v0.4, should show v2.2
**Impact:** User and developer confusion

---

## 🚀 **Future Enhancements**

### Phase 17+
- Spectral Photobooth (capture spectral frames)
- Shared clock + phase lock system
- Preset management GUI (visual browser)
- Track naming system
- Neon glow rendering (hardware-accelerated)

### Technical Debt
- Remove deprecated filter parameters from grain-engine.scd
- Centralize hardcoded values (filter ranges, update rates)
- Remove unused phaseBus variable from track-manager.scd

---

## 📋 **Known Issues**

- Waveform display uses temp files for recorded buffers (functional but inefficient)
- Modulation window is separate popup (not integrated into main GUI)
- Some GUI elements may overlap in Master tab (layout cleanup needed)

---

**Last Updated:** 2026-01-24
**Archive Location:** `archive/development-history/daily-notes/TODO.md` (historical TODOs)