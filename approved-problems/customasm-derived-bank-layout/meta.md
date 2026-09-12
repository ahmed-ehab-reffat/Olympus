---
Repository: https://github.com/hlorenzi/customasm
Issue: N/A
Commit: 05c738138eea73fb1f8ff595cdc9b58fd35bad91
Language: Rust
Category: feature-request
Title: Add derived bank placement to the assembler's iterative resolver
---

# Add derived bank placement to the assembler's iterative resolver

Add derived bank placement to the assembler. Let the fields `addr`, `addr_end`, `size` and `outp` hold expressions that depend on the result of assembling. A placement that never settles is reported the way an unsettled encoding already is, and so is every label whose address depends on it. A bank may be placed at the end of a bank whose definition appears later in the file, and a field may depend on labels and instruction sizes that are themselves still settling. The current address `$` is still rejected inside a bank definition, also when a function or an asm block reaches it from there; a constant that was computed from `$` elsewhere is an ordinary value.

Report what a bank actually occupies through two members on the value `$bankof` returns. `used` is the furthest point its contents reached, measured from the bank's own start in its address units, with a partial unit counting as a whole one; `end` is the first address past that point. Reserved space occupies units like any other content, while `fill` padding is not content. Moving the cursor backwards does not lower either member. The declared `size` is unaffected.
