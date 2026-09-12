# CAPABILITY-SHAPES — what an approvable pick actually looks like

Mined 2026-09-01 from the **capability statement (title + first body sentence) of all 98 problems in
`approved-problems/`**. Built after three consecutive picks died at the LOC floor because the method
was *find a repo, then look for a hole in it*. Holes are small by construction — a hole exists
because nobody needed it. **Every approved pick is an INVENTION, sized by the author.**

**Use this file by inverting the hunt.** Pick a SHAPE first, then look for a repo whose domain can
host it. Repo choice is the LAST step, not the first. `olympus-hunt` finds repos that clear the
mechanical gates; this file says what to build in one.

---

## ⚠️ FIRST — the correction this extraction forced

Earlier the same day, `TOO-EASY.md § MISSING-ARM-OF-A-DISPATCH` was written to say a "missing arm"
pick is **absorbed by construction**. **That is too strong, and this corpus disproves it.**
`icu4x-zerotrie-cursor-parity` ("PerfectHash and ExtendedCapacity still lack the stepwise cursor
workflow used by the ASCII trie") and `calamine-defined-names` ("to every Reader implementation for
XLS, XLSX, XLSB and ODS") are both missing-arm picks, and both were APPROVED.

**The real discriminator is whether the arms SHARE machinery or each need their OWN:**

| | Verdict | Why |
|---|---|---|
| The surrounding engine is **generic** — it would absorb the new arm | **DEAD** | thermo (phase-agnostic flash absorbs a new phase type); choco (`GeneralizedMinDomVarSelector` GRAPH arm is ~10 lines of existing accessors); geometry-central (a generic callback table) |
| The engine is a **facade over per-arm implementations**, each needing different machinery | **ALIVE** | icu4x (stepping a perfect-hash trie is genuinely not stepping an ASCII trie); calamine (XLS/XLSX/XLSB/ODS are four different formats); pcapplusplus, tablesaw |

The one-hour probe still settles it: **delete the guard, run the feature.** If it silently no-ops or
nearly works, the engine is generic. If each arm needs its own traversal/parser/solver, it does not.

---

## The nine shapes

Counts are approximate assignments over ~85 readable capability statements; several picks span two.

### S-B. Missing domain effect (~16 — the largest cluster)
The domain model omits a real-world phenomenon. Add it and thread it through every existing consumer.
- acoular: *"Acoular propagates sound straight from source to microphone. Add reflecting panels so it also arrives after bouncing off them."*
- turmoil: *"Nothing in the simulator has a rate."* · smoltcp: *"Nothing in this stack reacts to an incoming ICMP error."*
- pvlib loss attribution · metpy parcel trajectories · pandapower reliability · skrf transient · sfepy modal · lifelines multi-state · pyriemann geodesic curves
**Needs:** a repo modelling a physical/economic reality, with several consumers of one shared model.
**Why it is hard:** the effect perturbs state the consumers assumed static. The LOC is the model.
**Search:** a simulation/analysis library; read its docs for the assumption sentence ("straight from", "no rate", "ignores").

### S-E. Generalisation to every form (~10)
A construct works only in restricted form. Lift the restriction; the **cross-product of forms** is the difficulty (this is F-10 by construction).
- neva: *"Every form the network supports for an ordinary connection has to work for an array-bypass connection too."*
- wirefilter: *"wherever a literal was required, an expression is now accepted"* · python-control: *"interconnect today refuses subsystems whose sample times differ"* · dyon ordering over compound values · cadence default arguments · toydb subqueries · yara-x aggregates
**Needs:** a construct with an explicit restriction plus >=2 independent form axes.
**Why it is hard:** agents implement each axis and never build the off-diagonal cell.
**Search:** grep the source for `refuses`/`only supports`/`must be a literal`/`not supported for`.

### S-F. Analysis or accounting layer (~8)
Surface what the engine already computes implicitly but never reports.
- rust-minidump: *"a trust accounting layer... and a record of why each walk ended"* · calyx whole-program dead-port elimination · astits stream analyzer · techan cost-basis ledger · sparse connected regions · causal-learn MEC enumeration · pyparsing parse enumeration
**Needs:** an engine making internal decisions it discards.
**Why it is hard:** the accounting must stay correct across every path the engine can take, including its failure paths.

### S-C. Inversion (~7 — the highest-yield shape per unit of scope)
The repo does X. Add X-inverse, which is **not symmetric** and must reuse the same model.
- customasm: assemble -> *"prints the instructions the assembled bytes encode"* (493 eff LOC) · pysmt bit-vector -> Boolean · barcode encoder -> decoder · cantools decode -> `encode_signals` · awkward `windows` -> `unwindows` · numbat `unit_name` -> `unit_from` · mp4ff fragmented -> progressive
**Needs:** an existing one-directional transform whose richness comes from a **DECLARATIVE
specification the repo INTERPRETS** — not from executable callbacks the repo merely invokes.
**Why it is hard:** the inverse is ambiguous where the forward direction was lossy; resolving that ambiguity **using the repo's own model** is the invention.
**Search:** a repo that interprets a declarative spec and only goes one way — ruledefs, grammar files, binary-format definitions, schema languages, mapping tables, wire-protocol descriptions.

> ### ⛔ S-C PRECONDITION — declarative spec, NOT executable callbacks (measured 2026-09-01)
>
> **The killer test: is the forward transform's semantics DATA the repo reads, or CODE the user
> supplies?** Data can be inverted. Closures cannot, and scoping them out removes exactly the
> coupling that would have made the pick hard.
>
> **Measured on handlebars-rust**, chasing `extract(template, rendered) -> context` as the inverse of
> `render`. It looked ideal — F-11 adjacent-variable ambiguity by construction, a round-trip law, an
> uncontested repo, a clean absorption probe. It died in one reading pass:
> - Whitespace trim is applied at **PARSE** time (`template.rs:567,622-654`), so the AST's
>   `RawString`s arrive pre-trimmed and extraction gets trim semantics **for free**. `render.rs`
>   contains **zero** `trim` references — one hoped-for coupling source, gone.
> - Everything semantically rich in `TemplateElement::render` (`render.rs:867+`) is an **arbitrary
>   user closure**: helpers (`render_helper`), `EscapeFn = Arc<dyn Fn(&str) -> String>` registered
>   via `register_escape_fn`, the `helper_missing` hook. None is invertible even in principle.
> - So an honest extraction must be scoped to *no helpers, no escaping, no subexpressions* — leaving
>   literal segments + path expressions + block structure, which is a **self-contained matcher over
>   `Vec<TemplateElement>`**. That is the explicit "solvable by a standalone new file with minimal
>   wiring" REJECT.
>
> **This is a property of the CAPABILITY, not of handlebars-rust** — every template engine puts its
> richness in user-supplied helpers/filters/escape functions. **Template extraction is dead as an
> S-C pick across all template engines.**
>
> **Why customasm's disassembler worked instead:** a ruledef is a *declarative specification
> customasm interprets*, not a closure it calls. The inverse can interpret the same data. That single
> distinction separates a 493-effective-LOC approved pick from this dead one.

### S-A. Second mode over shared machinery (~6)
An opt-in alternative behaviour that **breaks an invariant the existing code assumes**.
- afero `NewCopyOnWriteFsWithDeletions` · sqlfluff `fix_transaction` · gojq `--ordered-keys` · lyon opt-in interior-vertex elimination · pulldown-cmark `ENABLE_BARE_URL_AUTOLINKS` · starlark-go `Generators` file option
**Needs:** machinery shared by many callers (S3 baseline-preservation comes free — the natural implementation regresses an existing behaviour).
**Why it is hard:** the mode must not disturb the default path, and the shared chokepoint is where agents break it.

### S-D. Preservation across a pipeline (~6)
Something is silently destroyed by an existing transform. Require it to survive end to end.
- gluon: *"keeps every comment the author wrote, attached to the code they attached it to"* · enmime *"without disturbing what was not edited"* · pyparsing source tree · fonttools color-table merge · amaranth streams *"no valid/ready timing causes unintended loss, duplication, or reordering"*
**Needs:** a multi-stage pipeline with a lossy early stage (this is F-1 territory).
**Why it is hard:** the information is destroyed before the stage you would naturally patch.

### S-H. Reconstruction after teardown (~4)
Live-only state becomes serializable, relocatable or replayable **with identical downstream behaviour**.
- h5py: reconstruct a virtual dataset *"after its file is closed"*, and relocate it · datasketches: persist `ThetaAnotB` preserving virgin/empty/exact/estimation modes · sqlsync observed sync state · rmk portable configuration snapshot
**Needs:** an object whose state is entangled with a live handle.
**Why it is hard:** every internal mode must round-trip, including the degenerate ones nobody tests.

### S-I. Per-flavour parity where each arm needs its OWN machinery (~4)
The alive form of "missing arm" — see the correction above.
- icu4x cursor parity across trie flavours · calamine defined names across XLS/XLSX/XLSB/ODS · tablesaw Arrow through the normal I/O API · pcapplusplus TLS-over-TCP reassembly
**Needs:** a facade over genuinely different backends. **Verify the arms do not share an engine.**

### S-G. Finite resource / graceful degradation (~3)
An operation assumes an unbounded resource or simply fails. Make it degrade correctly.
- avo: *"Spill registers to the stack instead of failing allocation"* · turmoil finite link capacity · deadpool shared global capacity
**Needs:** an allocator/scheduler/pool with a failure path.
**Why it is hard:** the degradation interacts with everything the resource touches.

---

## How to run the inverted hunt

1. **Pick 2-3 shapes** — prefer S-C (inversion) and S-B (domain effect): highest LOC yield, lowest
   absorption risk, and both are inventions no tracker will have named.
2. **Search for the shape, not the repo.** Each shape above carries its own search line — an
   assumption sentence in the docs, an encoder with no decoder, an explicit `refuses`.
3. **Only then** run `olympus-hunt`'s mechanical gates (stars/licence/activity/live-upstream),
   Stage 2b on issue BODIES, Stage 2b-bis PR-author profiling, and Stage 3b absorption.
4. **Sketch the diff before scope-locking.** Every shape above has an approved LOC figure to
   calibrate against.

**Anti-check:** if the capability can be phrased as *"support X here too"* and the engine behind
"here" is generic, it is the dead form of S-I. If each site needs its own machinery, it is the live
form. That single question has decided all six picks examined this session.
