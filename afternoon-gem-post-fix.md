# Th Starting Place
# S-4 RIVAL: Afternoon Session - January 8, 2026 (Revised)

**Session Goal:** Implement Hybrid Engine architecture, fix critical bugs, and clean up Viewfinder UI.

---

## SESSION PRIORITIES (In Order)

### 1. HYBRID ENGINE & UX OVERHAUL (New Priority)
**Status:** Backend Logic Ready / UI Implementation Needed
**Goal:** Fix "engine confusion" by replacing exclusive modes with a continuous mix and centralized transport.
**Includes:** Halo Knob, Transport, Clear Track, Reset Params.

### 2. CRITICAL BLOCKERS (Maintenance)
Must fix before continuing development (Overlap crash).

### 3. DEFERRED / ADJUSTED
Items from the morning session that have been deprioritized or superseded by the Hybrid Engine.

---

## PRIORITY 1: HYBRID ENGINE & UX OVERHAUL

### Backend Logic (core/track-manager.scd)
**Status:** PATCH INSTRUCTIONS READY
**Implementation:**
* Replace `engineMode` (0/1/2) with `engineMix` (0.0 - 1.0).
* **0.0:** Granular Only (Direct synth sleeps).
* **1.0:** Direct Only (Granular synth sleeps).
* **0.5:** Equal-power crossfade (Both run).
* **Optimization:** CPU auto-sleeps the silent engine.

### Viewfinder GUI Updates ("The Halo")
**Status:** TODO
**Time Estimate:** 45 minutes
**Files:** `gui/viewfinder.scd`, `gui/main-window.scd`

**Tasks:**
1.  **Remove Old Controls:**
    * Delete "Granular / Direct / Mix" buttons from Viewfinder (Source of glitchiness).
    * Delete small "Play / Stop" buttons from Main 4-Track Window (Reduces pixel clutter).
2.  **Add "Halo" Mix Knob:**
    * **Visual:** Arc drawing behind knob. Cyan (Granular) to Purple (Mix) to Red (Direct).
    * **Logic:** Controls `~trackManager.setParam(t, \engineMix, val)`.
    * **Monitor:** This serves as the visual indicator of "what is playing" to prevent confusion.
3.  **Add Centralized Transport:**
    * Large **PLAY / STOP** buttons in Viewfinder.
    * **Logic:** Trigger `run(true/false)` on *both* synth nodes (audibility handled by Mix knob).

### Essential Utilities (Promoted to P1)

**4. "Clear Track" Button** (Moved from Feature Requests)
* **Action:** Wipes buffer, resets params, stops synths.
* **Location:** Top right of Viewfinder (Safety Red).
* **Ref:** User explicit request.

**5. "Reset Params" Button** (Moved from Feature Requests)
* **Action:** Snaps all knobs to 0 (except Volume/Pan) using `resetParams` API.
* **Location:** Near the new Transport controls.

---

## PRIORITY 2: CRITICAL / BLOCKERS

### ✅ Fix Viewfinder OSC Listeners ("Quantum Playhead")
**Priority:** CRITICAL
**Status:** FIXED
**Fix:** Updated OSC listeners to filter by synth node ID. Viewfinders are now visually isolated.

### Fix Grain Overlap Crash
**Priority:** CRITICAL
**Time Estimate:** 15 minutes

**Issue:**
Overlap > 64 triggers server-side "Too many grains!" errors.

**Fix:**
**Option A (Selected):** Cap UI Slider at 64 in `viewfinder.scd`.
*(Option B: Increasing maxGrains is rejected for CPU safety)*.

---

## PRIORITY 3: ISSUE #10 PHASE 4

### Pitch Quantization
**Priority:** MEDIUM
**Time Estimate:** 30 minutes
**Status:** 75% complete

**Goal:** Snap pitch values to musical scales.
**Implementation:** Add logic to `setParam` in `track-manager.scd` to round values to nearest scale degree.

---

## DEPRECATED / DEFERRED

### Sequencer Amplitude Control
**Reason:** Superseded by Hybrid Engine.
**Note:** User can now achieve dynamic contrast by mixing between the quiet "Direct" backing track and the loud "Granular" sequence using the Mix Knob. Explicit `seqAmp` parameter is lower priority.

### Engine Mode Button Glitches
**Reason:** Obsolete.
**Note:** We are removing these buttons entirely in favor of the Halo Knob.

### Mix Mode "Non-Functional"
**Reason:** Fixed by Design.
**Note:** The new backend logic specifically addresses the mix architecture.

---

## KNOWN BUGS & FEATURES (Remaining)

### Viewfinder Pitch UI Sync
**Priority:** MEDIUM
**Time Estimate:** 15 minutes
**Issue:** Master Pitch number box does not update the slider.
**Fix:** Link `action` of NumberBox and Slider bidirectionally.

### Grain Envelope (ADSR)
**Priority:** MEDIUM
**Time Estimate:** 60 minutes
**Goal:** Add Attack, Decay, Sustain, Release to `s4GrainEngine`.

### Grain Size Range Extension
**Priority:** LOW
**Goal:** Extend range from 2s to 5s.

---

## SESSION CHECKLIST

### Must Complete:
* [ ] **Backend:** Apply "Hybrid Mix" patch to `track-manager.scd`.
* [ ] **Backend:** Add `resetParams` and `clearTrack` API.
* [ ] **GUI:** Remove old Mode/Play buttons.
* [ ] **GUI:** Implement "Halo Knob" (Mix).
* [ ] **GUI:** Implement Viewfinder Transport (Play/Stop).
* [ ] **GUI:** Add Clear/Reset buttons.
* [x] **Fix:** Viewfinder OSC listeners.
* [ ] **Fix:** Grain Overlap crash.

### If Time Allows:
* [ ] Pitch Quantization.
* [ ] Pitch UI Sync.
* [ ] Grain ADSR.

<!-- Local Variables: -->
<!-- gptel-model: claude-haiku-4-5-20251001 -->
<!-- gptel--backend-name: "Claude-Haiku-4.5" -->
<!-- gptel-max-tokens: 6000 -->
<!-- gptel--bounds: nil -->
<!-- End: -->
