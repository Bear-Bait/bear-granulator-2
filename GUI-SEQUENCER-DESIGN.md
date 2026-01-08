# GUI Sequencer Integration - Design Document

**Date:** 2026-01-08
**Status:** Design Phase
**Goal:** Make 64-step sequencer patterns accessible from GUI

---

## Overview

Currently, sequencer patterns are created via code in `.scd` files. Users must:
1. Read example code
2. Select and execute individual patterns
3. Manually type pattern arrays

**Goal:** Create GUI tools to browse, load, edit, and create patterns without coding.

---

## Design Philosophy

**Inspired by hardware:**
- KeyStep Pro (pattern banks, quick-select)
- Elektron Digitone (pattern library, favorites)
- Eurorack sequencers (visual step editing)

**Principles:**
- Fast workflow (2-3 clicks to load pattern)
- Visual feedback (see pattern shape)
- Live editing (hear changes immediately)
- Shareable (export/import patterns)
- Educational (show code alongside GUI)

---

## Proposed Architecture

### 1. Pattern Library System

**File:** `core/pattern-library.scd`

**Structure:**
```supercollider
~patternLibrary = (
    patterns: Dictionary.new,
    categories: [
        \terrestrial,
        \microtonal,
        \rhythmic,
        \mathematical,
        \generative
    ],

    // Register a pattern
    register: { |self, name, category, generator, description|
        self.patterns[name] = (
            name: name,
            category: category,
            generator: generator,  // Function that returns 64-element array
            description: description
        );
    },

    // Get pattern by name
    get: { |self, name|
        self.patterns[name]
    },

    // Get all patterns in category
    getByCategory: { |self, category|
        self.patterns.values.select({ |p| p.category == category })
    },

    // Generate pattern array
    generate: { |self, name|
        self.patterns[name].generator.value
    }
);
```

**Pattern Registration Example:**
```supercollider
~patternLibrary.register(
    name: \pentatonicMajor,
    category: \terrestrial,
    generator: {
        var scale = [0, 2, 4, 7, 9];
        Array.fill(64, { scale.choose });
    },
    description: "Major pentatonic - universal melodic pattern"
);
```

---

### 2. Pattern Browser Window

**File:** `gui/pattern-browser.scd`

**UI Layout:**
```
┌─────────────────────────────────────────────────────────────┐
│ PATTERN BROWSER                                       [X]    │
├─────────────────────────────────────────────────────────────┤
│ Category: [Terrestrial ▼]                    Search: [____] │
├────────────────────┬────────────────────────────────────────┤
│ Pattern List       │ Preview                                │
│                    │                                        │
│ • Pentatonic Major │  ┌───────────────────────────────┐   │
│ • Pentatonic Minor │  │ [Waveform visualization]      │   │
│ • Hirajoshi        │  │                                │   │
│ • In-Sen           │  └───────────────────────────────┘   │
│ • Hijaz            │                                        │
│ • Bhairav          │  Description:                          │
│ • Raga Yaman       │  "Major pentatonic - universal         │
│ ...                │   melodic pattern"                     │
│                    │                                        │
│                    │  [Load to Track 1]  [Load to Track 2] │
│                    │  [Load to Track 3]  [Load to Track 4] │
│                    │                                        │
│                    │  [Show Code]  [Edit Pattern]           │
└────────────────────┴────────────────────────────────────────┘
```

**Features:**
- Filter by category dropdown
- Search by pattern name
- Visual preview of pattern shape
- Description text
- One-click load to any track
- Show code button (educational)
- Edit button (opens pattern editor)

---

### 3. Quick-Access in Viewfinder

**File:** `gui/viewfinder.scd` (additions)

**Add to each track's viewfinder window:**

```
┌─────────────────────────────────────────┐
│ TRACK 1 - WAVEFORM                      │
│ [waveform display]                      │
├─────────────────────────────────────────┤
│ Sequencer:                              │
│ Pitch: [Pentatonic Major ▼]  [Browse]  │
│ Pos:   [Euclidean 7/64    ▼]  [Browse]  │
├─────────────────────────────────────────┤
│ [sliders and controls...]               │
└─────────────────────────────────────────┘
```

**Dropdown behavior:**
- Shows last 5-10 used patterns
- "Browse..." option opens Pattern Browser
- "Edit..." option opens Pattern Editor
- "Clear" option resets to zeros

---

### 4. Pattern Editor Window

**File:** `gui/pattern-editor.scd`

**UI Layout:**
```
┌─────────────────────────────────────────────────────────────┐
│ PATTERN EDITOR - Pentatonic Major                     [X]    │
├─────────────────────────────────────────────────────────────┤
│ Type: [Pitch ▼]  Track: [1 ▼]                              │
├─────────────────────────────────────────────────────────────┤
│ Step Editor (64 steps):                                     │
│ ┌───────────────────────────────────────────────────────┐  │
│ │ [Visual step sequencer grid - 64 sliders/bars]        │  │
│ │                                                        │  │
│ │  0   4   7   9  12   0   2   4 ...                    │  │
│ │ ┃━━ ┃━━ ┃━━ ┃━━ ┃━━ ┃━━ ┃━━ ┃━━                       │  │
│ └───────────────────────────────────────────────────────┘  │
│                                                             │
│ Zoom: [1x] [2x] [4x]    View: [0-63] [0-15] [16-31] etc   │
│                                                             │
│ Quick Fill:                                                 │
│ Scale: [Major ▼]  [Fill Random]  [Fill Ascending]          │
│ Rhythm: [Euclidean ▼] Hits:[7]  [Fill Pattern]             │
│                                                             │
│ Math:                                                       │
│ [Sine] [Triangle] [Saw] [Exp] [Random Walk]                │
│                                                             │
│ [Apply to Track]  [Save Preset]  [Show Code]               │
└─────────────────────────────────────────────────────────────┘
```

**Features:**
- Visual step editing (64 sliders or bars)
- Zoom controls (show 64, 32, or 16 steps at a time)
- Quick-fill buttons for common patterns
- Scale selector + auto-fill
- Rhythm generator (Euclidean, etc.)
- Mathematical function buttons
- Real-time preview (hear as you edit)
- Show generated code (educational)
- Save as new preset

---

### 5. Preset System

**File:** `core/pattern-presets.scd`

**Architecture:**
```supercollider
~patternPresets = (
    presetDir: Platform.userAppSupportDir +/+ "Bearulator/patterns/",

    // Save pattern to disk
    save: { |self, name, pitchSeq, posSeq, metadata|
        var path = self.presetDir +/+ name ++ ".pattern";
        var data = (
            name: name,
            pitchSeq: pitchSeq,
            posSeq: posSeq,
            metadata: metadata,
            created: Date.getDate.stamp
        );
        data.writeArchive(path);
    },

    // Load pattern from disk
    load: { |self, name|
        var path = self.presetDir +/+ name ++ ".pattern";
        Object.readArchive(path);
    },

    // List all saved patterns
    list: { |self|
        PathName(self.presetDir).files.select({ |p| p.extension == "pattern" });
    }
);
```

**User Presets Location:**
```
~/Library/Application Support/SuperCollider/Bearulator/patterns/
    my-melody.pattern
    glitch-rhythm.pattern
    hijaz-walk.pattern
    ...
```

---

## Implementation Plan

### Phase 1: Core Pattern Library ✅ READY
- Create `core/pattern-library.scd`
- Register all examples from `v2.1-sequencer-examples.scd`
- Add pattern metadata (name, category, description)
- Test pattern generation

### Phase 2: Pattern Browser GUI
- Create `gui/pattern-browser.scd`
- Implement category filtering
- Add search functionality
- Visual pattern preview (UserView with waveform)
- Load to track buttons
- Show code button

### Phase 3: Viewfinder Integration
- Add sequencer dropdown menus to `gui/viewfinder.scd`
- Recent patterns list
- Quick-load functionality
- Browse button → opens Pattern Browser

### Phase 4: Pattern Editor
- Create `gui/pattern-editor.scd`
- 64-step visual editor (MultiSliderView)
- Quick-fill buttons
- Real-time preview
- Save functionality

### Phase 5: Preset System
- Create `core/pattern-presets.scd`
- Save/load functionality
- User preset directory
- Import/export features

---

## Technical Considerations

### Pattern Generation on Demand
Patterns are generated fresh each time (via `generator` function) to allow:
- Randomization (each load is different)
- Parameterization (future: pass arguments to generator)
- Memory efficiency (don't store 64-element arrays for 100+ patterns)

### Visual Preview
Use `UserView` or `MultiSliderView` to show pattern shape:
```supercollider
var preview = MultiSliderView()
    .thumbSize_(2)
    .elasticMode_(1)
    .value_(pattern.normalize(0, 1));
```

### Live Preview (Real-time Editing)
When editing in Pattern Editor, apply changes immediately:
```supercollider
slider.action = { |sl|
    ~trackManager.setParam(trackNum, \pitchSeq, currentPattern);
};
```

### Code Display (Educational)
Show generated SuperCollider code alongside GUI:
```supercollider
// Show Code button reveals:
var scale = [0, 2, 4, 7, 9];
var pattern = Array.fill(64, { scale.choose });
~trackManager.setParam(0, \pitchSeq, pattern);
~trackManager.setParam(0, \pitchJitter, 1);
```

---

## UI/UX Design Notes

### Color Coding by Category
- **Terrestrial:** Green/earth tones
- **Microtonal:** Purple/cosmic
- **Rhythmic:** Orange/red (energetic)
- **Mathematical:** Blue (logical)
- **Generative:** Cyan (algorithmic)

### Pattern Icons
Each pattern could have a small icon representing its character:
- 🎵 Melodic scales
- 🥁 Rhythmic patterns
- 📐 Mathematical functions
- 🌍 World music
- 🛸 Xenharmonic

### Keyboard Shortcuts
- `Cmd+P` - Open Pattern Browser
- `Cmd+E` - Open Pattern Editor
- `Cmd+S` - Save current pattern
- `1-4` - Quick-load to Track 1-4

---

## Future Enhancements

### Pattern Chaining
Play multiple patterns in sequence (pattern playlist):
```
Track 1: Pentatonic → Hijaz → Bhairav → repeat
```

### Pattern Morphing
Crossfade between two patterns over time:
```supercollider
var patternA = [0, 2, 4, 7, 9];
var patternB = [0, 1, 4, 5, 7];
var morph = 0.5;  // 0=A, 1=B
var result = (patternA * (1 - morph)) + (patternB * morph);
```

### Pattern Modulation
Use LFOs to modulate pattern playback:
- Speed: How fast through 64 steps
- Direction: Forward/backward/ping-pong
- Step: Skip steps (play every 2nd, 3rd, etc.)

### Community Pattern Sharing
- Export patterns as `.pattern` files
- Share via GitHub/Discord
- Import patterns from URLs
- Rate/favorite patterns

### AI Pattern Generation
- Train model on user's favorite patterns
- Generate new patterns in similar style
- "More like this" button

---

## Questions for User Approval

1. **Priority:** Which phase should we implement first?
   - Pattern Browser (explore existing patterns)
   - Pattern Editor (create new patterns visually)
   - Viewfinder dropdowns (quick access)

2. **UI Style:** Match existing Bearulator aesthetic?
   - Minimal/functional (current style)
   - Add more visual flair (icons, colors)

3. **Scope:** How many built-in patterns?
   - Core set (~20-30 essential patterns)
   - Comprehensive library (~100+ patterns from guide)

4. **Education:** Show code alongside GUI?
   - Always visible
   - Toggle button
   - Separate "Learn Mode" window

---

## Next Steps

1. User reviews design document
2. User approves approach and priority
3. Implement Phase 1 (Pattern Library core)
4. Build Pattern Browser GUI
5. Test with existing patterns
6. Iterate based on user feedback

---

**Status:** Awaiting user feedback before implementation.
