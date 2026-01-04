# Phase 9+ Research & Implementation Notes

**Last Updated:** January 3, 2026
**Status:** Planning & Research Phase
**Target Platform:** Mac Mini M4 (24GB RAM, ~75% CPU headroom available)

---

## 🌌 VISUAL ENHANCEMENTS

### 1. FFT Spectrogram Overlay

**Goal:** Real-time frequency heatmap visualization behind waveform in viewfinder

**Technical Approach:**
- Use `AnalyzeEvents2` or custom `FFT` UGen with `SendReply.ar`
- Broadcast spectral frames at 30-60fps to GUI
- Render as 2D color grid (frequency vs. time)
- Use hardware-accelerated `UserView` or `Image` rendering

**Implementation Strategy:**
```supercollider
// Server-side: FFT analysis + OSC broadcast
chain = FFT(LocalBuf(2048), sig);
SendReply.ar(
    Impulse.ar(30),  // 30 fps update rate
    '/fft',
    FFTMagPhase.ar(chain, 0, 128)  // 128 frequency bands
);

// Client-side: Receive + render heatmap
OSCFunc({ |msg|
    var magnitudes = msg[3..130];  // Extract 128 bands
    viewfinder.drawSpectrogram(magnitudes);
}, '/fft');
```

**Challenges:**
- OSC bandwidth: 128 floats × 30fps = ~15KB/s (acceptable)
- GUI rendering performance: Use `Pen` drawing in cached `Image` buffer
- Color mapping: Magnitude → Hue/Saturation for visual clarity

**Priority:** Medium (high visual impact, moderate implementation complexity)

---

### 2. Grain Pulse Animation

**Goal:** Visual "ping" effects at grain trigger positions

**Technical Approach:**
- Broadcast grain trigger events via `SendReply.ar` from grain engine
- Each trigger sends current playback position
- GUI draws fading "ping" circles at waveform position
- Use alpha decay animation (fade out over 100-200ms)

**Implementation Strategy:**
```supercollider
// Server-side: Broadcast grain triggers
SendReply.ar(
    trig,  // Existing grain trigger signal
    '/grainPing',
    [Phasor.ar(...)]  // Current playback position (0-1)
);

// Client-side: Animate pings
OSCFunc({ |msg|
    var position = msg[3];
    viewfinder.addPing(position, alpha: 1.0, decay: 0.005);
}, '/grainPing');

// Draw loop (60fps)
{
    pings.do({ |ping|
        ping.alpha = ping.alpha * 0.95;  // Exponential decay
        Pen.fillOval(ping.x, ping.y, radius: 5, alpha: ping.alpha);
    });
}.defer(0.016);  // ~60fps
```

**Challenges:**
- High trigger density: Up to 128 grains/sec → 128 OSC messages/sec
- Solution: Rate-limit to max 60 pings/sec or batch triggers
- Performance: Use particle pool to avoid garbage collection

**Priority:** Low-Medium (eye candy, non-critical feature)

---

### 3. Neon Glow Rendering

**Goal:** Hardware-accelerated glow effects for playhead, loop regions, grain window

**Technical Approach:**
- Use layered `UserView` with blend modes
- Apply Gaussian blur to glow layers
- Leverage Qt's `QPainter` composition modes

**Implementation Strategy:**
```supercollider
// Create glow layer
glowView = UserView(parent, bounds)
    .background_(Color.clear)
    .drawFunc_({ |view|
        // Draw glow source (bright core)
        Pen.color = Color.cyan.alpha_(1.0);
        Pen.strokeOval(Rect(x, y, width, height));

        // Apply blur effect (requires Qt5.15+ or manual convolution)
        // Note: SuperCollider doesn't have native blur
        // Workaround: Draw multiple alpha-faded circles at increasing radii
        5.do({ |i|
            var radius = 5 + (i * 2);
            var alpha = 0.3 * (1 - (i / 5));
            Pen.color = Color.cyan.alpha_(alpha);
            Pen.strokeOval(Rect(x - radius, y - radius, width + (radius*2), height + (radius*2)));
        });
    });
```

**Challenges:**
- SuperCollider Qt doesn't expose native blur filters
- Manual blur: Use multi-pass alpha circles (computationally cheap)
- Color bleeding: Ensure glow doesn't obscure waveform detail

**Alternative Approach:**
- Render glow in separate `Image` buffer using 2D convolution
- Composite final image over waveform view

**Priority:** Low (aesthetic polish, high implementation cost without native blur support)

---

## 🔊 AUDIO COMPONENTS

### 4. Dual-Topology Analog-Modeled Filter (Per Track)

**Goal:** Professional-grade filtering with two topologies (Ladder + SVF)

#### 4a. ZDF Ladder Filter (Moog-Style)

**Characteristics:**
- Liquid resonance under audio-rate modulation
- Self-oscillation at high resonance
- Bass loss compensation (Huovilainen model)

**SuperCollider Implementation:**
```supercollider
// Use MoogFF UGen (zero-delay feedback approximation)
filtered = MoogFF.ar(
    in: sig,
    freq: cutoff.linexp(0, 1, 20, 18000),
    gain: resonance.linlin(0, 1, 0, 4),  // 0-4 for self-oscillation
    reset: 0  // No reset
);

// Bass compensation (optional)
// MoogFF inherently loses bass at high resonance
// Add back fundamental with gentle highpass sidechain
bass = BLowPass.ar(sig, 100, 1.0);
filtered = filtered + (bass * resonance * 0.3);
```

**Challenges:**
- CPU cost: MoogFF is expensive (~5% per instance on M4)
- Solution: Only enable when filter is active (`Select.ar`)
- Self-oscillation: Can blow up if resonance > 0.95
- Safety: Add soft limiter after filter stage

#### 4b. State Variable Filter (SVF)

**Characteristics:**
- Simultaneous LP/HP/BP outputs
- Morphable between filter types
- No bass loss at high resonance

**SuperCollider Implementation:**
```supercollider
// Use RLPF, RHPF, BPF for morphing SVF
var lp, hp, bp, morphed;
var freq = cutoff.linexp(0, 1, 20, 18000);
var rq = resonance.linexp(0.01, 1, 1.0, 0.01);  // Inverse relationship

lp = RLPF.ar(sig, freq, rq);
hp = RHPF.ar(sig, freq, rq);
bp = BPF.ar(sig, freq, rq);

// Morph control: 0=LP, 0.5=BP, 1=HP
var lpAmt = (1 - (morph * 2)).clip(0, 1);
var bpAmt = (1 - ((morph - 0.5).abs * 2)).clip(0, 1);
var hpAmt = ((morph - 0.5) * 2).clip(0, 1);

morphed = (lp * lpAmt) + (bp * bpAmt) + (hp * hpAmt);
```

**Challenges:**
- Three parallel filters = 3x CPU cost
- Solution: Use `Select.ar` to only compute active filter type at extremes
- Crossfade smoothness: Current approach is linear, consider equal-power crossfade

#### 4c. Pre-Filter Drive Stage

**Goal:** Nonlinear saturation before filter for "grit"

**Implementation:**
```supercollider
// Soft saturation with adjustable drive
var driven = (sig * drive.linexp(0, 1, 1, 10)).tanh;
var filtered = MoogFF.ar(driven, cutoff, resonance);

// Alternative: Hard clipping for aggressive distortion
var driven = (sig * drive.linexp(0, 1, 1, 20)).clip(-1, 1);
```

**Considerations:**
- Drive before filter = harmonic generation → filter shapes harmonics
- Drive after filter = tone shaping → drive colors filtered result
- Recommendation: Offer both (switch or blend)

#### 4d. Audio-Rate Cutoff Modulation

**Current State:** All modulation is control-rate (~750Hz)

**Upgrade Path:**
```supercollider
// Before (control-rate)
var cutoff = In.kr(cutoffBus);

// After (audio-rate)
var cutoff = In.ar(cutoffBus);
```

**Benefits:**
- Enables filter FM (modulation in audible range)
- Eliminates zipper noise on fast sweeps
- Allows for audio-rate envelope followers

**CPU Impact:** Negligible on M4 (~1-2% increase per track)

**Priority:** **HIGH** - Essential for professional filter sound

---

### 5. Transient Bypass Logic

**Goal:** Preserve drum transients during heavy spectral stretching

**Problem:**
- Spectral engines (Warp1) smear transients when rate ≠ 1.0
- Drum hits lose "snap" and "punch"

**Solution Approach:**
```supercollider
// Detect transients using amplitude follower
var transient = Amplitude.ar(sig, 0.001, 0.1) > thresh;

// Crossfade between spectral and dry signal during transients
var output = Select.ar(
    transient,
    [
        spectralEngine,  // Normal spectral processing
        sig              // Bypass: Pass dry signal through
    ]
);

// Smooth crossfade to avoid clicks
output = Lag.ar(output, 0.005);  // 5ms smoothing
```

**Advanced Implementation:**
```supercollider
// Use onset detection for precise transient identification
var onsets = Onsets.kr(FFT(LocalBuf(512), sig), thresh: 0.5);

// Create envelope: 1.0 during transient, 0.0 otherwise
var transientEnv = EnvGen.ar(
    Env.perc(0.001, 0.05),  // 1ms attack, 50ms decay
    gate: onsets
);

// Blend: More dry signal during transients
var output = XFade2.ar(
    spectralEngine,  // Spectral (wet)
    sig,             // Dry
    transientEnv.linlin(0, 1, -1, 1)  // Crossfade position
);
```

**Challenges:**
- False positives: High-frequency content can trigger onset detection
- Solution: Use spectral flux instead of amplitude for more accurate detection
- Latency: FFT-based onset detection adds 10-20ms delay
- Solution: Use lookahead buffer to compensate

**Priority:** Medium-High (critical for rhythmic material, adds complexity)

---

### 6. ✅ Phase-Aligned Granulation

**Status:** ✅ **COMPLETED** (Phase 9)

**Implementation:** See `core/grain-engine.scd` lines 145-159

**Results:**
- Zero-crossing aligned grain triggers prevent phase cancellation
- Bass frequencies maintain power and clarity
- Switchable: `phaseAlign` parameter (0=off, 1=on)

---

### 7. ✅ Master Bus "Glue" Compressor

**Status:** ✅ **COMPLETED** (Phase 9)

**Implementation:** See `core/mix-bus.scd` lines 151-162

**Results:**
- 2:1 soft-knee compression at 0.6 threshold
- 10ms attack, 100ms release
- Bonds 4 tracks together for cohesive mix

---

### 8. 4× Oversampled Color Section

**Goal:** Anti-aliased saturation/distortion for warm analog sound

**Problem:**
- Nonlinear processing (tanh, distortion, bit-crushing) creates aliasing
- Aliasing = unwanted frequencies that fold back into audible range
- Result: Harsh, brittle digital artifacts

**Solution: Oversampling**
```supercollider
// 1. Upsample to 192kHz (4× 48kHz)
var upsampled = Upsample.ar(sig, 4);

// 2. Apply nonlinear processing at high sample rate
var saturated = (upsampled * drive).tanh;

// 3. Lowpass filter to remove aliasing
var filtered = LPF.ar(saturated, 20000);  // Remove content above Nyquist

// 4. Downsample back to 48kHz
var output = Decimate.ar(filtered, 4);
```

**Challenges:**
- `Upsample` and `Decimate` don't exist in SuperCollider
- Solution: Use `Latch` + interpolation for manual upsampling
- CPU cost: 4× processing = potentially 4× CPU usage

**Alternative Implementation (Efficient):**
```supercollider
// Use oversampling only on nonlinear stage
SynthDef(\oversampledSaturation, {
    arg in, drive = 1.0;
    var sig, up, sat, down;

    // Read input
    sig = In.ar(in, 2);

    // Manual 4× upsampling using linear interpolation
    up = [sig, sig, sig, sig].flat;  // Naive approach (needs proper interpolation)

    // Apply saturation
    sat = (up * drive).tanh;

    // Lowpass filter (anti-aliasing)
    sat = LPF.ar(sat, 20000, mul: 0.25);  // Compensate for 4× gain

    // Downsample: Take every 4th sample
    down = Latch.ar(sat, Impulse.ar(SampleRate.ir / 4));

    Out.ar(in, down);
}).add;
```

**Better Approach:**
- Use external plugins (e.g., FaustUGens) with built-in oversampling
- Or: Implement in C++ as custom UGen for production use

**Priority:** Medium (high sonic impact, high implementation complexity)

---

### 9. 128-Band Resonator (DynKlank Upgrade)

**Goal:** Ultra-dense spectral resonance for "physical object" sound

**Current State:** 48-band parallel BPF filterbank (see `mix-bus.scd`)

**Upgrade Path:**
```supercollider
// Create buffer with 128 frequency ratios
~freqBuf = Buffer.loadCollection(s,
    128.collect({ |i| (i + 1) * fundamentalFreq })
);

// Create buffer with 128 amplitude weights
~ampBuf = Buffer.loadCollection(s,
    128.collect({ |i| 1.0 - ((i / 128) * (1.0 - decay)) })
);

// Create buffer with 128 ring times
~ringBuf = Buffer.loadCollection(s,
    128.collect({ |i| ringTime * (1.0 - (i / 128 * 0.5)) })
);

// Use DynKlank for efficient parallel resonance
var resonated = DynKlank.ar(
    specificationsArrayRef: `[~freqBuf, ~ampBuf, ~ringBuf],
    input: sig,
    freqscale: 1.0,
    decayscale: 1.0
);
```

**Challenges:**
- DynKlank uses fixed-frequency buffers (can't morph in real-time)
- Current implementation morphs LP/BP/HP per band
- Solution: Keep current 48-band approach OR sacrifice morphing for density

**Recommendation:**
- Hybrid approach: 48-band morphing filterbank for "sculpting"
- 128-band DynKlank for "resonance" mode (separate toggle)

**Priority:** Low-Medium (sonic improvement, but current 48-band sounds good)

---

## 📊 IMPLEMENTATION PRIORITY RANKING

| Priority | Feature | Effort | Impact | Status |
|----------|---------|--------|--------|--------|
| **#1** | Audio-Rate Filter Modulation | Low | High | ⏳ **Next** |
| **#2** | Dual-Topology Filter (Ladder + SVF) | Medium | High | 📋 Planned |
| **#3** | Pre-Filter Drive Stage | Low | Medium | 📋 Planned |
| **#4** | FFT Spectrogram Overlay | Medium | Medium | 📋 Planned |
| **#5** | Transient Bypass Logic | Medium | Medium | 📋 Planned |
| **#6** | 4× Oversampled Saturation | High | High | ⚠️ Requires custom UGen |
| **#7** | Grain Pulse Animation | Low | Low | 💡 Eye candy |
| **#8** | 128-Band DynKlank Resonator | Medium | Low | ⚠️ Conditional |
| **#9** | Neon Glow Rendering | Medium | Low | 💡 Eye candy |

---

## 🎯 RECOMMENDED IMPLEMENTATION ORDER

### Phase 10: Filter System (HIGH PRIORITY)
1. Add audio-rate modulation support to track-manager
2. Implement ZDF Ladder Filter (MoogFF)
3. Implement SVF with LP/BP/HP morph
4. Add pre-filter drive stage
5. Wire up filter controls in viewfinder GUI

**Estimated Effort:** 4-6 hours
**Impact:** Professional-grade filter sound, enables FM synthesis

---

### Phase 11: Visual Feedback (MEDIUM PRIORITY)
1. Implement FFT Spectrogram overlay
2. Add grain pulse animation
3. Polish with neon glow effects (if time permits)

**Estimated Effort:** 3-4 hours
**Impact:** Enhanced visual feedback, better understanding of audio processing

---

### Phase 12: Advanced Processing (CONDITIONAL)
1. Implement transient bypass logic for spectral engine
2. Research oversampling UGen options (Faust? Custom C++?)
3. Evaluate 128-band DynKlank vs. current 48-band system

**Estimated Effort:** 6-8 hours (variable)
**Impact:** Refinement of existing features, diminishing returns

---

## 🔬 TECHNICAL RESEARCH NOTES

### Audio-Rate Modulation Considerations

**Current Modulation System:**
- All LFOs run at control-rate (`.kr`)
- Update rate: ~750Hz (64 samples per block at 48kHz)
- Modulation buses: `Bus.control`

**Upgrade Requirements:**
1. Change all modulation buses to `Bus.audio`
2. Update all LFO UGens from `.kr` to `.ar`
3. Update all `In.kr` modulation readers to `In.ar`
4. Test for CPU impact (expected: <5% increase)

**Files to Modify:**
- `core/track-manager.scd` - Modulation bus allocation
- `core/grain-engine.scd` - Modulation inputs
- `core/spectral-engine.scd` - Modulation inputs
- GUI files - No changes needed (OSC messages unchanged)

---

### SuperCollider Filter UGen Comparison

| UGen | Type | Resonance | CPU Cost | Best For |
|------|------|-----------|----------|----------|
| `MoogFF` | Ladder (ZDF) | Self-oscillating | High | Liquid, musical sweeps |
| `RLPF/RHPF` | 2-pole Resonant | Moderate | Low | General-purpose filtering |
| `BPF` | Bandpass | Fixed-Q | Low | Spectral isolation |
| `SVF` (custom) | State Variable | Morphable | Medium | Versatile tone shaping |
| `DFM1` | Moog-style | High | Medium | Aggressive resonance |

**Recommendation:** Use `MoogFF` for Ladder mode, custom SVF using `RLPF/RHPF/BPF` for morphing.

---

### FFT Analysis Best Practices

**For Spectrogram Visualization:**
- FFT Size: 2048 samples (43Hz resolution @ 48kHz)
- Window: Hann or Blackman-Harris (reduce spectral leakage)
- Update Rate: 30-60fps (balance between smoothness and CPU)
- Frequency Bins: 128 bands (subsample full 1024 bins)

**Implementation:**
```supercollider
chain = FFT(LocalBuf(2048), sig, wintype: 1);  // Hann window
magnitudes = FFTMagPhase.ar(chain, 0, 128);    // First 128 bins
SendReply.ar(Impulse.ar(30), '/fft', magnitudes);
```

---

## 📝 OPEN QUESTIONS

1. **Oversampling Implementation:**
   - Should we implement custom C++ UGen for production quality?
   - Or use approximate method with `LPF.ar` + gain compensation?

2. **Filter Topology:**
   - Offer both Ladder + SVF simultaneously (blend parameter)?
   - Or use mode switch (Ladder OR SVF)?

3. **128-Band Resonator:**
   - Is morphing more important than density?
   - User preference needed for final decision

4. **GUI Framework:**
   - Continue with native SuperCollider Qt?
   - Or explore external GUI (TouchOSC, Max/MSP, custom Electron app)?

---

**End of Phase 9+ Research Notes**
