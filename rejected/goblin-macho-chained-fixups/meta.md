---
Repository: https://github.com/m4b/goblin
Issue: N/A
Commit: dca2e753b2abb66a38f42bcb245cf7232049e69e
Language: Rust
Category: feature-request
Title: Add Mach-O chained-fixups import resolution to goblin
---

# Add Mach-O chained-fixups import resolution to goblin

Add support for resolving imported symbols from the `LC_DYLD_CHAINED_FIXUPS` load command in the Mach-O parser. Today only the legacy `LC_DYLD_INFO`/`LC_DYLD_INFO_ONLY` bind-opcode stream is walked, so a binary that declares its imports only through chained fixups returns none even though it genuinely imports symbols.

Support the `DYLD_CHAINED_PTR_ARM64E` pointer format (both its authenticated and unauthenticated encodings) and the `DYLD_CHAINED_PTR_64`/`DYLD_CHAINED_PTR_64_OFFSET` formats, together with the `DYLD_CHAINED_IMPORT` and `DYLD_CHAINED_IMPORT_ADDEND` import-table formats. Any other pointer format, import-table format, or a compressed (non-zero) symbols format is unsupported: return an error naming the unsupported value.

Each fixup chain mixes rebase and bind entries. A rebase entry must still be traversed to reach later entries in the same chain, but only bind entries produce an import; a page with no fixups contributes nothing. Resolve each bind to its dylib by ordinal, carrying through its weak-import flag and addend (zero when the import format carries none). The resulting import's address and offset must reflect the fixup pointer slot's own location, not the symbol's eventual runtime address.

The two import sources are independent and additive: a binary may carry the legacy bind-opcode stream, chained fixups, or both, and every source present must be reported.
