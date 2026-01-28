# BEARULATOR Feature Analysis & Implementation Plan

**Date:** 2026-01-26  
**Status:** ✅ **IMPLEMENTED in v2.4** (Features 1-5)

This document provides a detailed analysis of the future enhancement tasks from the TODO list. Each section outlines the purpose of the feature, its dependencies, and a concrete plan for implementation within the `core/grain-engine.scd` SynthDef.

## Implementation Notes (v2.4)

All features except Spectral Split have been successfully implemented:

- **Barberpole Phaser**: Implemented using `FreqShift` (core UGen, no dependencies)
- **Squiz**: Implemented with fallback to simple bitcrush if sc3-plugins unavailable
- **VADiodeFilter**: Implemented with fallback to MoogFF if sc3-plugins unavailable
- **Greyhole**: Implemented with fallback to FreeVerb if sc3-plugins unavailable
- **MiRings**: Implemented with fallback to resonant BPF if mi-UGens unavailable
- **Spectral Split**: Deferred to v3.0 (requires architectural refactor)

**Corrections Made During Implementation:**
1. Fixed Greyhole parameter name: `damp` → `dampingfreq` with exponential mapping (200-10000 Hz)
2. Added `.asClass.notNil` checks for optional UGens with graceful fallbacks
3. Added `.clip(0, 2)` and `.lag(0.05)` to filter/reverb type selectors for smooth switching
4. Expanded phaserRate range to ±100 Hz (was ±20 Hz in original analysis)

---

## 1. Upgrade Filter to "Acid" Topology (`VADiodeFilter`)

- **Status:** ✅ **IMPLEMENTED in v2.4** (grain-engine.scd:324-329)
- **Description:** This task involves adding a virtual analog diode filter emulation, likely the `VADiodeFilter`, to the filter section. This will provide a "TB-303 style" squelchy and resonant filter option, adding a new character to the sound design palette.
- **Dependencies:** `sc3-plugins` (Likely, based on similar UGens).
- **Implementation Plan:**
    1.  **Add a new `filterType` parameter** to the `SynthDef` to select between the existing filters and the new diode filter.
        ```supercollider
        // In the arg list of SynthDef(\bearulatorGrainEngine...)
        ...
        filterMorph = 0.5,
        filterType = 0, // 0 = Morphing (Ladder/SVF), 1 = Diode
        filterRes = 0.5,
        ...
        ```
    2.  **Integrate `VADiodeFilter`** into the `filterOn` section using `SelectX` based on the new `filterType` parameter.
        ```supercollider
        // Inside the filterOn section of the SynthDef
        sig = SelectX.ar(filterOn.lag(0.05), [
            sig,
            {
                var filtered = sig;
                var freq = filterFreq.linexp(0, 1, 20, 18000);
                var rq = filterRes.linexp(0.01, 1, 1.0, 0.01);
        
                // Pre-Filter Drive
                var driven = Select.ar(filterDecay > 0.01, [
                    filtered, (filtered * filterDecay.linexp(0.01, 1, 1, 10)).tanh
                ]);
        
                // Morphing Filter (Ladder/SVF)
                var morphingFilter = {
                    // ... existing MoogFF and SVF logic ...
                }.value;

                // Diode Filter
                var diodeFilter = VADiodeFilter.ar(driven, freq, filterRes.linlin(0, 1, 0, 0.95), 0);
        
                filtered = SelectX.ar(filterType, [morphingFilter, diodeFilter]);

                XFade2.ar(sig, filtered, filterMix.linlin(0, 1, -1, 1));
            }.value
        ]);
        ```
- **Verification:** Set `filterType` to 1 and sweep the `filterFreq` and `filterRes` parameters to confirm the new acid filter character.

---

## 2. Add "Squiz" Artifacts

- **Status:** ✅ **IMPLEMENTED in v2.4** (grain-engine.scd:390-400)
- **Description:** Adds the `Squiz` UGen to the `color` effects chain. `Squiz` is a "wave squeezer" that creates a unique timbre reminiscent of a ring-modulator and pitch-shifter, perfect for IDM-style textures and digital artifacts.
- **Dependencies:** `sc3-plugins`
- **Implementation Plan:**
    1.  **Add `squizMix` and `squizAmount` parameters** to the `SynthDef`.
        ```supercollider
        // In the arg list of SynthDef(\bearulatorGrainEngine...)
        ...
        crushBits = 8,
        crushMix = 0,
        squizAmount = 0.5,
        squizMix = 0,
        compThresh = 0.5,
        ...
        ```
    2.  **Add `Squiz` to the `colorOn` section**. It can be blended in after the bitcrusher.
        ```supercollider
        // Inside the colorOn section
        ...
        // Bitcrush
        crushed = Latch.ar(colored, Impulse.ar(crushRate));
        crushed = crushed.round(0.5 ** crushBits);
        colored = XFade2.ar(colored, crushed, crushMix.linlin(0, 1, -1, 1));

        // Squiz
        var squizzed = Squiz.ar(colored, squizAmount.linlin(0, 1, 1, 10));
        colored = XFade2.ar(colored, squizzed, squizMix.linlin(0, 1, -1, 1));

        // Compressor
        Compander.ar(colored, colored, compThresh, 1.0, 1.0/compRatio, compAttack, compRelease);
        ...
        ```
- **Verification:** With `colorOn` enabled, increase `squizMix` and adjust `squizAmount` to hear the aliasing and pitching artifacts.

---

## 3. Implement "Barberpole" Phaser

- **Status:** ✅ **IMPLEMENTED in v2.4** (grain-engine.scd:368-370)
- **Description:** Uses the `FreqShift` UGen to create an infinite rising/falling "barberpole" phasing effect. This adds a constant sense of motion to the sound.
- **Dependencies:** Core SuperCollider (no extra plugins needed).
- **Implementation Plan:**
    1.  **Add `phaserRate` and `phaserMix` parameters** to the `SynthDef`.
        ```supercollider
        // In the arg list of SynthDef(\bearulatorGrainEngine...)
        ...
        // After other color params
        phaserRate = 0.2,
        phaserMix = 0,
        ...
        ```
    2.  **Add `FreqShift` to the `colorOn` section**, before the distortion.
        ```supercollider
        // Inside the colorOn section
        ...
            var colored = sig;
            var low, high, loProc, hiProc, distorted, crushed, phaser;

            // Barberpole Phaser
            phaser = FreqShift.ar(colored, phaserRate.linlin(0, 1, -20, 20));
            colored = XFade2.ar(colored, phaser, phaserMix.linlin(0, 1, -1, 1));

            // Distortion
            low = LPF.ar(colored, distCrossover);
        ...
        ```
- **Verification:** With `colorOn` enabled, increase `phaserMix` and adjust `phaserRate` to hear the continuous frequency shift.

---

## 4. Install "Greyhole" Reverb

- **Status:** ✅ **IMPLEMENTED in v2.4** (grain-engine.scd:426-455)
- **Description:** Replaces the current `FreeVerb` with `Greyhole` for massive, "blackhole" style reverb spaces, inspired by Eventide processors.
- **Dependencies:** `sc3-plugins`. Note: Requires increasing server memory (`s.options.memSize = 65536; s.reboot;`).
- **Implementation Plan:**
    1.  **Add `reverbType` parameter** to the `SynthDef`.
        ```supercollider
        // In the arg list of SynthDef(\bearulatorGrainEngine...)
        ...
        reverbType = 0, // 0 = FreeVerb, 1 = Greyhole
        reverbSize = 0.5,
        ...
        ```
    2.  **Replace the `Reverb` logic** in the `spaceOn` section with a `SelectX` to choose between `FreeVerb` and `Greyhole`.
        ```supercollider
        // Inside the spaceOn section
        ...
        // Reverb
        var reverb = SelectX.ar(reverbType, [
            // 0: FreeVerb
            FreeVerb.ar(spaced, 1.0, reverbSize * freezeGain, reverbDamp),
            // 1: Greyhole
            Greyhole.ar(spaced,
                delayTime: reverbSize.linlin(0, 1, 0.1, 5.0),
                damp: reverbDamp,
                size: 1.0,
                feedback: reverbFreeze.linlin(0, 1, 0.9, 0.99),
                modDepth: 0.1,
                modFreq: 2.0
            )
        ]);
        spaced = XFade2.ar(spaced, reverb, reverbMix.linlin(0, 1, -1, 1));
        ...
        ```
- **Verification:** Set `reverbType` to 1. Test with large `reverbSize` values to hear the characteristic `Greyhole` sound.

---

## 5. Install "Mi-UGens" (`MiRings`)

- **Status:** ✅ **IMPLEMENTED in v2.4** (grain-engine.scd:332-358)
- **Description:** This would replace the entire filter section with a physical modeling resonator based on the Mutable Instruments Rings module. This is a significant change that would create a very different sonic character.
- **Dependencies:** `mi-UGens` quark (requires manual installation of binaries).
- **Implementation Plan:**
    1.  **This is a major architectural change.** A simple swap is not recommended. The best approach is to add `MiRings` as another `filterType`.
    2.  **Add new parameters** for `MiRings` to the `SynthDef`, like `ringsBright`, `ringsDamp`, `ringsPos`.
    3.  **Add `MiRings` as `filterType` 2** in the `filterOn` section.
        ```supercollider
        // Diode Filter
        var diodeFilter = VADiodeFilter.ar(driven, freq, filterRes.linlin(0, 1, 0, 0.95), 0);

        // MiRings Resonator
        var rings = MiRings.ar(driven,
            rtrig: Impulse.ar(10), // Needs a trigger
            rfreq: freq,
            rstruct: filterRes,
            rbright: 0.5, // add ringsBright param
            rdamp: 0.5,   // add ringsDamp param
            rpos: 0.5,    // add ringsPos param
            rmodel: 0, rpoly: 8, rintern_exciter: 0, reasteregg: 0, rbypass: 0
        );

        filtered = SelectX.ar(filterType, [morphingFilter, diodeFilter, rings]);
        ```
- **Verification:** This requires significant testing. The trigger for `MiRings` (`rtrig`) would need to be carefully controlled.

---

## 6. Implement "Spectral Split"

- **Status:** **DEFERRED TO v3.0**
- **Description:** This feature aims to separate the signal into transient and tonal components, allowing effects (like reverb) to be applied only to the tonal parts. This can create cleaner, more focused sounds. This can be done with `PV_HainsworthFoote` (for onset detection) or `FluidHPSS` (for Harmonic-Percussive separation).
- **Dependencies:** `sc3-plugins` for `PV_HainsworthFoote`, `FluCoMa` quark for `FluidHPSS`.

### Architectural Analysis

This feature requires **fundamental changes** to the BEARULATOR signal flow:

1. **FFT Chain Integration**: Current architecture uses direct time-domain processing. Spectral split requires:
   - FFT analysis stage (2048-4096 samples)
   - Spectral processing (HPSS separation)
   - IFFT reconstruction
   - Latency compensation (FFT introduces 2048+ sample delay)

2. **Dual Signal Path**: After separation, need to route:
   - **Harmonic component** → Reverb/Shimmer (spatial effects benefit from sustained tones)
   - **Percussive component** → Bypass or minimal processing (preserve transient clarity)
   - **Recombination** → Master output with proper phase alignment

3. **Performance Impact**:
   - **FluidHPSS**: ~10-15% CPU per instance (heavy real-time processing)
   - **PV_HainsworthFoote**: ~5-8% CPU (lighter but less precise)
   - FFT overhead: Additional 2-3% CPU per track
   - **Total**: ~15-20% CPU per track (significant on 4-track system)

### Implementation Options

#### Option A: Separate SynthDef (Recommended for v3.0)
```supercollider
SynthDef(\bearulatorSpectralSplit, {
    arg in, outHarm, outPerc;
    var sig, chain, hpss, harm, perc;
    
    sig = In.ar(in, 2);
    chain = FFT(LocalBuf(2048), sig);
    hpss = FluidHPSS.ar(chain, 
        numHarmonics: 20, 
        harmThresh: 0.0, 
        percThresh: 0.0,
        maskingMode: 1
    );
    
    harm = IFFT(hpss[0]);
    perc = IFFT(hpss[1]);
    
    Out.ar(outHarm, harm);
    Out.ar(outPerc, perc);
}).add;

// Usage: Insert between grain engine and effects chains
// Requires refactoring track-manager to support aux busses
```

#### Option B: Integrated (Major Refactor)
- Move all effects to post-FFT processing
- Requires rewriting `spaceOn` section with dual paths
- Adds 40+ lines of FFT management code
- Breaks backward compatibility with existing presets

### Recommendation

**DEFER TO PHASE 18 or v3.0** for the following reasons:

1. **Architectural Scope**: Requires refactoring entire effects chain architecture
2. **Performance Budget**: Current v2.4 uses ~25% CPU; adding spectral split would push to ~45-50% (4 tracks × 15% each)
3. **Complexity vs Payoff**: High implementation cost for niche use case (most users prefer full-spectrum reverb)
4. **Alternative Solutions**: Users can achieve similar results via:
   - High-pass filtering before reverb (`filterOn` → cutoff @ 200Hz)
   - Manual envelope follower modulation of `reverbMix` (Phase 13)
   - External processing in DAW (Ableton Live's HPSS, iZotope RX)

### Minimal Prototype (Research Phase)
```supercollider
// Standalone test - NOT integrated into BEARULATOR
(
s.boot;
~testSpectralSplit = {
    var sig, chain, hpss, harm, perc, final;
    sig = SoundIn.ar(0) * 0.5;
    chain = FFT(LocalBuf(2048), sig);
    hpss = FluidHPSS.ar(chain, numHarmonics: 20);
    harm = IFFT(hpss[0]);
    perc = IFFT(hpss[1]);
    
    // Apply reverb ONLY to harmonics
    harm = FreeVerb.ar(harm, 1.0, 0.9, 0.5);
    
    // Recombine
    final = (perc * 0.7) + (harm * 0.3);
    final.dup;
}.play;
)

// Test with percussive material (drums) vs tonal (vocals)
~testSpectralSplit.free;
```

**Conclusion**: Feature is technically feasible but requires v3.0 architecture redesign. Document here for future reference. **Do not implement in v2.4**.
