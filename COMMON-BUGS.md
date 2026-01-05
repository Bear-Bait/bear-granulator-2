# Common SuperCollider Bugs & Gotchas

## **ERROR: syntax error, unexpected VAR, expecting '}'**

### The Problem
SuperCollider requires ALL variable declarations to be at the **TOP** of a code block, before any other statements.

### Bad Example (WILL FAIL)
```supercollider
if(someCondition, {
    Pen.strokeRect(Rect(0, 0, 100, 100));  // Statement comes first
    var myVar = 10;  // ERROR! Variable declared after statement
    Pen.fillRect(Rect(0, 0, myVar, myVar));
});
```

### Good Example (CORRECT)
```supercollider
if(someCondition, {
    var myVar = 10;  // ALL variables declared FIRST

    Pen.strokeRect(Rect(0, 0, 100, 100));
    Pen.fillRect(Rect(0, 0, myVar, myVar));
});
```

### Alternative: Inline Expressions
If you only need a variable once, use inline expressions instead:
```supercollider
if(someCondition, {
    Pen.strokeRect(Rect(0, 0, 100, 100));
    // No variable - just use the expression directly
    Pen.fillRect(Rect(0, 0, (someValue ? 0) * 10, 10));
});
```

### Key Rules
1. **All `var` declarations must be at the top of a block**
2. **No statements can come before `var` declarations**
3. **Multiple `var` lines must be grouped together**
4. **This applies to all blocks: functions, if statements, loops, etc.**

### When This Happens
- Adding new variables to existing code
- Copy-pasting code into the middle of blocks
- Refactoring inline expressions to variables

### Quick Fix
Either:
1. Move ALL `var` declarations to the very top of the block
2. Remove the `var` and use the expression inline
3. Wrap the code in a new nested block with vars at its top

---

## Other Common Issues

### OSC Address Conflicts
**Problem:** Multiple synths sending to the same OSC address causes data conflicts.

**Solution:** Use unique addresses for each synth:
```supercollider
// Bad - both use '/playhead'
SendReply.ar(Impulse.ar(60), '/playhead', [pos1]);
SendReply.ar(Impulse.ar(60), '/playhead', [pos2]);

// Good - unique addresses
SendReply.ar(Impulse.ar(60), '/grainPlayhead', [pos1]);
SendReply.ar(Impulse.ar(60), '/spectralPlayhead', [pos2]);
```

### Deferred GUI Updates
**Problem:** Updating GUI elements from non-GUI threads causes crashes.

**Solution:** Always use `.defer` for GUI updates:
```supercollider
// Bad
fork {
    server.sync;
    myButton.value_(1);  // CRASH!
};

// Good
fork {
    server.sync;
    { myButton.value_(1) }.defer;  // Safe
};
```

### Buffer Allocation Timing
**Problem:** Trying to use buffers before they're allocated.

**Solution:** Always use `server.sync` in a fork:
```supercollider
// Bad
var buf = Buffer.alloc(s, 48000);
buf.write(path);  // May fail - buffer not ready!

// Good
fork {
    var buf = Buffer.alloc(s, 48000);
    server.sync;  // Wait for allocation
    buf.write(path);  // Now safe
};
```

### Event Callback Arguments
**Problem:** Callbacks stored in Events receive the Event itself instead of passed arguments.

**Bad Example:**
```supercollider
// Define callback in Event
recorder = (
    onStop: { arg path;
        "Path: %".format(path).postln;  // Will print entire Event!
    }
);

// Call it
recorder.onStop.value("my/file.wav");  // Prints Event, not path
```

**Solution:** Access Event fields directly instead of passing them:
```supercollider
// Define callback that accesses Event fields
recorder = (
    filePath: nil,
    onStop: {
        var path = recorder.filePath;  // Access directly
        "Path: %".format(path).postln;  // Correct!
    }
);

// Set field, then call
recorder.filePath = "my/file.wav";
recorder.onStop.value();  // Prints path correctly
```

**Alternative:** Use external functions:
```supercollider
// Define function OUTSIDE the Event
var callback = { arg path;
    "Path: %".format(path).postln;
};

recorder = (onStop: callback);
recorder.onStop.value("my/file.wav");  // Works!
```

---

**Last Updated:** 2026-01-04 (Phase 15 Implementation)
