# BEARULATOR: Master TODO List

**Current Version:** v2.2 (January 2026)

---

## 🎯 **Immediate Priorities: The v2.1 Engine Deployment**

### 1. Deploy v2.1 Engine
**Status:** **High Priority.** The current v2.0 engine has critical audio bugs.
**Action:** Overwrite the contents of `core/grain-engine.scd` with the v2.1 code stored in `bearulator_project_state.org`.
**Verification:**
- Run the "Deploy Script" from `bearulator_project_state.org`.
- Confirm that switching filters and modes no longer causes audio glitches.
- Verify `timeStretch` at 0.0 freezes audio without a pitch drop.
- Verify `pitchSeq` accepts 64-step arrays.

### 2. Create "Sigur Ros" Preset
**Status:** Pending v2.1 deployment.
**Objective:** Create a generative ambient preset rivaling "1-5fq".
**Recipe:**
- **Sample:** Pure Rhodes, Chime, or Female Vocal.
- **Settings:** `timeStretch` = 0.1, `reverbMix` = 0.7, `shimmerMix` = 0.5.
- **Sequencer:** 64-step slow drift on a Pentatonic scale.

### 3. Implement `DiskOut` for Recording
**Status:** Pending v2.1 deployment.
**Task:** Implement `DiskOut` in the engine to record the output directly to a WAV file, building a sample library.



## 🔬 **Research & Cross-Pollination**

### Harmonium Evaluation & Cannibalizing
**Status:** Scheduled evaluation.
**Objective:** Study Trevor Treglia's Harmonium synth and identify valuable patterns/components for Bearulator.
**Reference Files:**
- `~/Documents/supercollider/harmonium.scd` (main synth)
- `~/Documents/supercollider/harmonium_analysis.md` (component breakdown)
**Key Areas to Evaluate:**
- Additive synthesis partials grid (vs. Bearulator's granular approach)
- Voice stealing & MIDI polyphony management (solid implementation)
- Krell-inspired generative arpeggiator (potential inspiration)
- Spectral shaping via manual parameter arrays
- Ring mod & FM implementation
- Buchla-style LPG (Low Pass Gate) with vactrol emulation
- Recording system with timestamped filenames
**Potential Cannibalizations:**
- Voice stealing logic for Bearulator's poly engine
- Generative arpeggiator for performance macro system
- Spectral shaping concepts for synth design
- LPG topology for creative filter morphing
**Note:** Harmonium is additive (bottom-up); Bearulator is granular (top-down). Value will be in specific techniques, not architecture.

---

## 🚀 **Future Enhancements & 2026 Roadmap**

### Core Engine & Sound Design
- **[ ] Install "Mi-UGens":** Replace the filterbank with `MiRings` for physical modeling resonance.
- **[ ] Install "Greyhole":** Replace `FreeVerb` with Greyhole for "Blackhole" style spaces.
- **[ ] Implement "Spectral Split":** Use `PV_HainsworthFoote` or `FluidHPSS` to route transients away from reverb.
- **[ ] Implement "Barberpole" Phaser:** Use `FreqShift` for infinite rising/falling spectral sweeps.
- **[ ] Upgrade Filter to "Acid" Topology:** Use `VADDiodeFilter` (TB-303 style) for squelchy resonance.
- **[ ] Add "Squiz" Artifacts:** Use the `Squiz` UGen for aliasing/downsampling IDM textures.
- **[ ] Spectral Photobooth:** A feature to capture and manipulate spectral frames.

### System & UI
- **[ ] Shared Clock & Phase Lock:** A system to sync all four tracks.
- **[ ] Preset Management GUI:** A visual browser for managing presets.
- **[ ] Track Naming System:** Allow users to name their tracks.
- **[ ] Neon Glow Rendering:** Implement hardware-accelerated "glow" visuals.

---

## 🧹 **Technical Debt & Known Issues**

- **[ ] Remove Deprecated Parameters:** Clean up unused filter parameters in `grain-engine.scd`.
- **[ ] Centralize Hardcoded Values:** Refactor filter ranges, update rates, etc., into a central location.
- **[ ] Remove Unused Variables:** Remove the `phaseBus` variable from `track-manager.scd`.
- **[ ] Inefficient Waveform Display:** The waveform display uses temporary files for recorded buffers, which is functional but inefficient.
- **[ ] GUI Layout Cleanup:** Some GUI elements overlap in the Master tab and need tidying.

---
**Last Updated:** 2026-01-28
