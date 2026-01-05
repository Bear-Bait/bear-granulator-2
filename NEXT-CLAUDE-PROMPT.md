# Prompt for Next Claude Instance

## Context
You're working on the S-4 Rival granular sampler (SuperCollider project). An overnight autonomous session implemented 7 major features, but there are 2 remaining SuperCollider syntax errors preventing main.scd from loading.

## IMMEDIATE TASK: Fix 2 Syntax Errors

### 1. gui/modulation-window.scd line 260
**Error:** `unexpected VAR, expecting '}'` at line 260

**Fix:**
- Line 243: Change `var val1, val2;` to `var val1, val2, y1, y2;`
- Line 260: Change `var y1 = midY - (val1 * midY * 0.8);` to `y1 = midY - (val1 * midY * 0.8);`
- Line 261: Change `var y2 = midY - (val2 * midY * 0.8);` to `y2 = midY - (val2 * midY * 0.8);`

**Reason:** SuperCollider requires ALL var declarations at the top of each block. Lines 260-261 are trying to declare vars in the middle of a `.do` loop.

### 2. gui/viewfinder.scd line 1145
**Error:** `unexpected ',', expecting '}'` at line 1145

**Fix:** Read lines 1140-1150 to identify the stray comma or unclosed structure. Likely caused by the recent fix at line 1059.

## After Fixing
1. Test main.scd loads successfully
2. Test all 7 completed features (see HANDOFF-SYNTAX-FIXES.md for list)
3. Proceed with MIDI features per TODO.md

## Reference Documents
- HANDOFF-SYNTAX-FIXES.md - Detailed error explanations
- OVERNIGHT-PROGRESS.md - Complete feature documentation
- TODO.md - Project tracking

## Working Directory
`/Users/forrestmuelrath/Documents/supercollider/granular`

---

**START HERE:**
1. Fix modulation-window.scd line 260 (add y1, y2 to var list at line 243, remove var keywords from lines 260-261)
2. Fix viewfinder.scd line 1145 (find and fix stray comma)
3. Run main.scd to verify no errors
4. Test the 7 new features with user
