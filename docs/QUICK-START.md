# Quick Start - Get Sound in 3 Steps

## Step 1: Boot SuperCollider Server
```supercollider
s.boot;
```
Wait for server to finish booting.

## Step 2: Load BEARULATOR
```supercollider
(thisProcess.nowExecutingPath.dirname +/+ "START-HERE.scd").load;
```
Wait for "READY TO PLAY!" message (takes ~3 seconds).

## Step 3: Load Test Sound
Click the cyan **"Load Test Sound"** button in the GUI (top-left corner).

**OR** run this code:
```supercollider
(
fork {
    var tempBuf = Buffer.alloc(s, s.sampleRate * 4, 1);
    tempBuf.sine1([1.0, 0.5, 0.3, 0.2, 0.15, 0.1], true, true, true);
    0.3.wait;
    tempBuf.copyData(~recorder.buffer);
    0.2.wait;
    tempBuf.free;
    "✓ Test sound loaded!".postln;
};
)
```

## YOU SHOULD NOW HEAR SOUND!

If not:
1. Check amplitude slider > 0
2. Check your audio interface volume
3. Run: `~grainSynth.set(\amp, 0.7);`

## Try These Controls

**Move sliders in the GUI:**
- Grain Size: 0.01 - 0.5 seconds
- Density: 1 - 200 grains/sec
- Position: Scan through the 4-second buffer
- Pitch: -24 to +24 semitones

**Enable effects:**
- Filter ON: Morphing resonator
- Color FX ON: Distortion, bit crusher
- Space FX ON: Reverb, delay, shimmer

## Next Steps

See:
- **SOUND-TEST-GUIDE.md** - Comprehensive testing
- **README.md** - Full documentation
- **QUICK-REFERENCE.md** - Parameter reference

## CPU Warning?

Your CPU is at 17-18%, slightly above the 15% target. This is normal for Phase 3 with all effects. You can:
- Reduce Density (fewer grains)
- Turn off effects when not using them
- Increase Grain Size

Phase 4 will add optimizations for running 4 tracks.
