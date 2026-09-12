# Repo Hunt 2026-08-07-B — protocol / storage / binary-format / emulation sweep

Second sweep of the day. The morning run (`REPO-HUNT-2026-08-07.md`) was geometry/graphics-weighted
and produced tdewolff/canvas as RANK 1 with Gate 1 still owed. This run deliberately avoids that
domain and every domain any prior hunt has touched, going into network protocol engines, storage /
index engines, binary + executable formats, terminal layout, archive/VCS internals, morphological
analysis, CRDTs, emulation and codecs.

Sweep: 6 keyword batches, ~100 single-word keywords x {go,rust}, stars >=500, permissive license,
pushed within 12mo. Heavy AI/LLM-slop contamination in the 2026 index — roughly a third of every
result page is agent tooling and had to be filtered by description.

**Outcome: no clean RANK 1.** One conditional candidate (qmonnet/rbpf, YELLOW), and a long list of
kills worth recording. The morning's canvas remains the better live lead.

---

### qmonnet/rbpf — ★1124 — RANK 1 (CONDITIONAL / YELLOW)

- **URL / stars:** https://github.com/qmonnet/rbpf — ★1124
- **Language:** Rust, pure. Deps: byteorder, log, combine, libc, optional cranelift-*. Dev-deps:
  libc, elf, json, hex. **No `-sys` crate anywhere, no C, no system headers.**
- **Domain:** eBPF virtual machine — assembler, disassembler, verifier, interpreter, x86-64 JIT,
  Cranelift JIT
- **Open issues:** 17. Open PRs: 3.
- **License:** Apache-2.0 OR MIT (both files present, plain, no riders)
- **Last commit:** 2026-06-03 (`e312815`, real code); 16 commits in 2026; 20 in the trailing 12mo
- **Our quota:** 0/6. Not in `SATURATED-REPOS.md`. No `bpf`/`vm`/`jit`/`verifier` feature class
  anywhere in `approved-problems/`, `problems/`, `rejected/`.
- **Test framework:** 559 tests across 10 integration files in `tests/`, table-driven, behavioural
  through the public API (assemble source -> load into VM -> execute -> assert `u64` result or
  error substring). Zero mocks. Ideal f2p surface.
- **Baseline determinism:** **3/3 identical**, 0 failures, 10 ignored (2 documented cranelift trap
  cases). Full cold build + test = **14s**; warm = under 1s.
- **Docker:** Pattern A (`olympus-base-rust`). Cleanest profile seen in weeks — no system deps, no
  network at build, no codegen. Docker itself UNVERIFIED (no local Docker on this workstation).
- **Architecture:** 10k LOC, single crate, 13 modules. Real staged pipeline:
  `asm_parser -> assembler -> verifier -> {interpreter | jit | cranelift}` with `ebpf.rs` as the
  shared ISA table and `stack.rs` as the shared frame model.
- **Capability-lane density (Stage 2c):** low velocity, no `fix/<topic>-*` branch family, no
  corpus-wide invariant test. **But the execution-backend lane is consumed** — see Risks.
- **Maintainer-welcomed lanes (Stage 2d):** none found.
- **Missing machinery (LOC carry):** `verifier.rs` is 312 lines of purely structural checks. It has
  no register state, no type lattice, no control-flow graph, no path model — a real dataflow
  verifier is new machinery, not a call-through, and would plausibly carry 300-500 effective LOC.

**TRAP SEAMS (failure-patterns.md):**
| Pattern | Present | Evidence |
|---|---|---|
| F-8 named-algorithm override | **yes (strong, repo-stated)** | `src/verifier.rs:8-19` states the divergence in the source itself: "It has nothing to do with the much more elaborated verifier inside Linux kernel. There is no verification regarding the program flow control (should be a Direct Acyclic Graph) or the consistency for registers usage (the verifier of the kernel assigns types to the registers and is much stricter)." A documented deliberate divergence from a famous algorithm = fair by construction |
| F-10 capability cross-product | **yes (but see Risks)** | axes: 4 VM structs (`EbpfVmMbuff`, `EbpfVmFixedMbuff`, `EbpfVmRaw`, `EbpfVmNoData`, `lib.rs:175/793/1376/1837`) x 3 execution backends (interpreter / x86-64 JIT / cranelift) x {std, no_std} |
| F-9 cross-stage resolution drop | yes | `verifier.rs:293` rejects TAIL_CALL; `interpreter.rs:492` re-rejects it; `jit.rs:967` and `cranelift.rs:942` `unimplemented!()` it. Four stages independently re-deciding the same thing |
| F-6 ordering inversion | yes | `set_verifier` can be swapped after `set_program`, and `verifier.rs:195` (per README) re-runs on the loaded program — verify-then-compile ordering is observable |
| F-14 declared-vs-derived terminal state | yes | multiple "cannot continue" exits duplicated per backend (`unimplemented!`, `reject(...)`, `Error::other`) — 3+ sites per opcode class |
| F-1 convergent-architecture wall | partial | `ebpf.rs` opcode table is the chokepoint every backend reads |
| F-13 two-tier format | no | flat 8-byte instruction stream (LD_DW is the only two-slot form) |
| F-2 / F-4 | no | no bidirectional construct, no aliasing IR |

**Best Olympus feature types:**

1. **Verifier dataflow analysis** (register initialisation / type tracking / CFG reachability). The
   only lane whose core file no open PR touches. `verifier.rs` is the single core file, with
   `ebpf.rs` read-only. **Magnet risk HIGH** — see Risks.
2. **Assembler/disassembler round-trip fidelity.** `asm_parser.rs` (641) + `assembler.rs` (269) +
   `disassembler.rs` (439). rbpf's textual assembly syntax is its OWN, named by no spec, so the
   dedup one-liner needs repo nouns. Open PR #152 touches these two files by 4-5 lines of plumbing
   only. **Weaker:** risks the DEAD "make X consistent with correct sibling Y" class, and the LOC
   carry is unproven.

**Estimated complexity:** ~300-500 effective LOC across 2-4 files for thesis 1.

**Why it matches:** obscure deep engine, not the author-obvious VM class in practice (zero eBPF
submissions anywhere in our corpus, and rbpf is unmentioned in `SATURATED-REPOS.md`). Genuinely
staged. Repo-stated F-8. Best test/determinism/Docker profile measured in several hunts (14s cold
build, 559 behavioural tests, 3/3 deterministic, no system deps).

**Risks (why this is YELLOW, not GREEN):**

- **(a) EXCLUSIVITY — the best seam is under an open PR.** #152 "feat(jit): add RISC-V 64 and
  AArch64 JIT backends" publishes a diff of **`jit.rs` 77+/1015-, new `jit_x86_64.rs` +1009,
  `jit_aarch64.rs` +1197, `jit_riscv64.rs` +1181, plus `interpreter.rs`, `cranelift.rs`, `lib.rs`,
  `stack.rs` and 5 test files.** The F-10 cross-backend-parity thesis — the structurally strongest
  design here — lands squarely on that file set. Per the HARD RULE that is SHELVE, do not author.
  Only the verifier and asm lanes survive.
- **(b) MAGNET — thesis 1 is spec-nameable.** "Add register type tracking and control-flow
  validation to an eBPF verifier" is fully intelligible to an outsider and is named by the Linux
  kernel verifier. That is the Stage-2b HIGH-risk signature, and it is exactly what killed
  lol-html and comrak after full authoring cycles.
- **(c) PORT LINEAGE.** `verifier.rs` header: "Derived from uBPF ... (uBPF: safety checks,
  originally in C)". Anything uBPF already has is a saturated-reference-port.
- **(d) ACTIVITY.** 20 commits/12mo and nothing since 2026-06-03. Clears the gate; thin enough to
  watch at submit.

**Verdict:** authorable only if a capability can be invented inside the verifier or asm lane that
is NOT nameable by the kernel verifier or uBPF. I have not found one, so this is a lead to return
to, not a scope-lock.

---

## Rejected this hunt (do not re-derive)

| Repo | ★ | Kill |
|---|---|---|
| ikawaha/kagome | 976 | **Requirement 6 corpse.** 63 commits/12mo, of which **3 are non-chore and none touch the analyzer** (a demo-UI redesign, an FFI usage example, a README fix). Everything else is dependabot/CI. The bunster profile exactly. Otherwise very attractive (MIT, pure Go, self-contained Viterbi lattice + user dictionary + tokenize modes, obscure domain, 0 open issues) so it WILL resurface in Go sweeps. |
| sminez/penrose | 1349 | **Docker + activity.** Linux dev-dependency `penrose_ui` pulls `yeslogic-fontconfig-sys` and `x11` (xft/xlib) C libraries; cargo builds the whole dev-dep graph for any test target, so no test target is Docker-feasible offline (the fundsp failure mode). Also **1 commit in all of 2026** (2026-01-15). Genuinely good seams otherwise — `src/pure/` is a 4.5k-LOC pure data model with a mock X connection and quickcheck tests, and the layout-transformer message-routing chain is a textbook F-5 pass-through. Dead on the mechanics, not the design. |
| lindera/lindera | 648 | **Lane density.** 272 commits/12mo sweeping the exact seams — `Lattice::char_category_cache` invalidation, `NBestGenerator` per-edge scan, Viterbi/segmenter cleanups, unknown-word surface form, user-dictionary context-ID relabelling. Maintainer is closing the whole bug class. Also MeCab/kuromoji port lineage. |
| holo-routing/holo | 534 | **Capability wave in both streams.** 300 commits/12mo (isis 67, bgp 37, ospf 27) AND 20 open PRs that are almost entirely `bgp: EVPN ...` / routing-policy / ADD-PATH / multipath, plus #153 "[preview] Integrated routing feature branch (VRF/L3VPN/EVPN/policy/…)". The maintainer is eating the entire protocol capability space. RFC-named throughout as well. |
| rust-embedded/svd2rust | 849 | **No cold core file left.** Only 32 commits/12mo (attractive), but **16 open PRs blanket every file in `src/generate/`** — device.rs, peripheral.rs, register.rs, generic*.rs, util.rs all appear repeatedly (#960, #841, #879, #430, #551, #576, #216). The objdiff death. Shame: SVD `derivedFrom` inheritance is a real F-13 two-tier format. |
| tafia/calamine | 2384 | **Capability wave.** 12 open PRs shipping charts, cell styles, conditional formatting, workbook properties, region projection; 128 commits/12mo. Also OOXML/XLS = spec-named. |
| VirusTotal/yara-x | 1242 | **Capability wave.** 300 commits/12mo shipping continuously across compiler, scanner, modules (msi/vba/olecf/lnk), LS and C/Python APIs. Also "a rewrite of YARA" = port lineage. |
| yorkie-team/yorkie | 926 | **Lane density.** 275 commits/12mo and the recent stream IS the CRDT correctness bug class — tree RGA anchors, tombstone movement on merge, GC pair registration for split pieces, style ranges crossing merge anchors, identity-preserving undo/redo. Nothing left to find there. |
| TimelyDataflow/differential-dataflow | 2995 | 15+ open PRs blanketing the join/reduce/arrangement core (#818, #817, #810, #808, #782, #728, #723, #636). |
| RoaringBitmap/roaring | 2918 | 138 commits/12mo of BSI64 + container perf work, 10 open PRs on the same core. Roaring is also a named published format. |
| flanglet/kanzi-go | 620 | **Maintainer sweep across every lane at once.** 120 commits/12mo: "All transforms should return an error instead of panicking on malformed input", bound checks, overflow fixes, `Harden LZPCodec`, `Harden ROLZ decompression`, header checksum work. Systematically closing exactly the bug class a pick would hunt. 0 open issues, single maintainer, direct pushes. |
| suyashkumar/dicom | 1073 | **2 code commits/12mo** (near-corpse) while 12 open PRs — mostly bot-generated "⚡ Bolt" perf patches — sit on `dicomio`. DICOM is also spec-named. |
| flux-rs/flux | 902 | Very active capability stream (points_to analysis, `qualifier!` macro, 91 open issues) and it is a rustc driver needing nightly — Docker risk on top of lane risk. |
| wasmi-labs/wasmi | 2166 | WASM proposals = spec-named magnet, and the "clean embeddable VM" class saturates regardless of stars. |
| madsim-rs/madsim | 1142 | Last commit 2026-02-16 and the crate is a thin shim over tokio/tonic APIs — LOC carry unlikely. |
| s-arash/ascent, ekzhang/crepe | 571/526 | Proc-macro Datalog; small surface, LOC-floor risk. egglog is already blocklisted. |
| iliekturtles/uom | 1248 | Units class self-collides with approved `numbat-parse-unit-expressions`; const-generic/macro heavy. |
| harfbuzz/ttf-parser | 788 | Mid maintainer sweep (a burst of ~15 fix commits on 2026-08-05/06) and font tables are spec-named. |
| qmonnet/rbpf thesis "cross-backend parity" | — | See Risks (a): open PR #152 publishes the diff. |
| golang/geo, DioxusLabs/taffy, google/mtail, egraphs-good/egglog, paulmach/orb, ron-rs/ron, SamiPerttu/fundsp, yeslogic/allsorts, hlorenzi/customasm, deepnoodle-ai/risor, nevalang/neva, sharkdp/numbat, printfn/fend, ironcalc/IronCalc | — | Already blocklisted, already ours, or already audited in a prior hunt. |

**Sweep noise note (2026 index).** Roughly a third of every result page for generic engineering
keywords (`inference`, `token`, `router`, `index`, `terminal`, `agent`, `scheduler`) is now AI
tooling. Keywords that stayed productive: `disassembler`, `elf`, `dwarf`, `crdt`, `emulator`,
`compression`, `morphological`, `bitmap`, `physics`, `dataflow`. Keywords that returned pure noise:
`inference`, `storage`, `index`, `protocol`, `packet`, `allocator`.

**Disk:** rbpf target dir (384M) deleted after measurement; penrose clone removed entirely. rbpf
clone kept at `worktrees/rbpf` (3M) so the audit is not repeated. `/home` at 92%, 9.1G free.
