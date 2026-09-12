# Fairness analysis — pdfminer.six logical structure tree, version 1

Verdict: `pass`.

Repository: `pdfminer/pdfminer.six` at
`a18de2a9c479b4c847538500017b449ddaec177e`.

Artifact identifiers: prompt `3eaebbc7…`, tests `f564861a…`, reference
`faac3cf4…`, Dockerfile `071e5599…`, baseline tree `c8313669…`, and reference
tree `71d1cccc…`. Full hashes are recorded in `ENVIRONMENT.md`.

## Rejection-predicate provenance

| Test/assertion/lane | What it rejects | Public or repository provenance | Implementation freedom preserved | Verdict |
|---|---|---|---|---|
| untagged result and both entry points | missing API or fabricated tree | prompt names both APIs and `None` behavior; existing high-level/document patterns | parser/walker architecture unrestricted | fair |
| mixed child sequence | reordered or omitted standard child form | prompt explicitly names `/K` order and four forms | eager, lazy, cached, or shared nodes may pass | fair |
| role and attribute values | BDC tag substitution, lost RoleMap/ClassMap, first-only arrays | prompt names public fields and expansion order | internal metadata representation unrestricted before public result | fair |
| OBJR target identity | unresolved or wrong referenced object | prompt names `object_objid` and `object` | no private resolver/helper is inspected | fair |
| two-page same MCID | global MCID key or wrong page inheritance | prompt explicitly requires page/Form scoping and page context | any compound key or post-pass association passes | fair |
| named property list | handling inline BDC dictionaries only | prompt explicitly includes resource-named property dictionaries; interpreter resources are public repository behavior | resolution timing and cache are free | fair |
| explicit Form MCR | ignoring `Stm`, Form StructParents, or containing page | prompt names all exposed fields and Form behavior | recursive interpreter or separate pass both pass | fair |
| ParentTree page/Form reverse links | forward-only implementation | prompt explicitly requires reverse association with page/Form StructParents | tree may be walked before or after rendering | fair |
| positive ParentTree `Kids` | root-leaf-only number-tree parser | ParentTree is a number tree and repository `NumberTree` supports `Kids` | arbitrary recursion/iteration accepted | fair |
| MCR-local `Pg` | always inheriting element page | prompt explicitly states MCR inheritance or override according to `Pg` | context stack or local lookup accepted | fair |
| text/image/vector item identity | summaries or omitted renderer producer | prompt requires actual layout objects; `LTChar`, `LTImage`, and `LTLine` are existing public layout types | no exact container hierarchy or serialization required | fair |
| document API empty items | hidden rendering requirement | prompt provides parsed-document API; without a rendered mapping no layout objects exist | eager metadata parse or lazy result accepted | fair |
| structure and ParentTree cycles | unbounded recursion or wrong-node association | prompt explicitly names both cycles and strict/nonstrict behavior | exact message and retained partial tree are not asserted | fair |
| dangling/invalid children | crash, hang, or invented association | prompt explicitly names these malformed graph cases | strict exception or non-strict omission remains allowed | fair |
| complete base lane | regression in repository behavior | repository contains 249 deterministic tests and the change touches parser/interpreter/layout paths | no new implementation structure required | fair |
| harness and JUnit | missing execution or startup failure | workspace evaluator contract | no product latency or output wording asserted | fair |

## Architecture replay

| Legitimate implementation | Distinct architecture | Result | Fairness conclusion |
|---|---|---:|---|
| reference patch | safe graph walker plus device-assisted layout capture | 249/249 base; 14/14 focused | demonstrates complete solvability |
| independent pdfminer.six solver | unavailable | not run | no solver trajectory exists; none was invented or replaced with an unrelated patch |

The mutation trees use deliberately incomplete versions of the reference and
are discriminator evidence, not claimed as legitimate alternative
architectures. No materially different correct solver implementation is
available for replay.

## Unspecified-constraint audit

- Private implementation structure: pass. Tests import only the public types
  and fields explicitly stated in the prompt and existing public layout types.
- Encoding and malformed bytes: pass. Positive PDFs are deterministic,
  syntactically valid raw PDFs. Negative inputs violate only graph/value cases
  explicitly named by the prompt.
- Ordering, batching, and exact counts: pass. Exact order is asserted only for
  public `/K` and attribute expansion order. Item counts are asserted only for
  one-object fixtures.
- Timing, scheduling, and watchdogs: pass. There are no sleeps, timeouts,
  concurrency, or absence sampling.
- Feature/build surfaces: pass. Tests use the repository's default locked
  Python feature set and public parser/layout APIs.
- Harness tools, network, permissions, and UID: pass. The exact Docker gate
  runs offline from a read-only mount as UID 10001 using installed pytest.
- Error strings and wrapper expectations: pass. No exact error text is tested;
  only the prompt-permitted repository syntax/type exception families are used.
- Progress markers and quiescence: not applicable. No asynchronous absence
  assertion or lifecycle marker exists.

## Corrections and rejected complaints

Corrected before this verdict:

- The public module locations and exact child-kind vocabulary are now explicit,
  and the document-API empty-items check accepts any empty collection rather
  than prescribing a list or tuple representation. The complete exact-version
  gate was repeated after this representation-neutral correction.
- Top-level imports initially made the pristine feature lane a collection
  error; optional discovery now produces ordinary behavioral failures.
- `uv run` initially attempted to mutate the read-only checkout; the harness now
  calls the image-installed pytest directly.
- The image initially depended on `.git` version inference and root-owned cache
  paths; the exact SCM version and separate runtime paths remove both hidden
  requirements.

Rejected complaints:

- Raw object IDs are fair fixture identities because the public result
  explicitly exposes object IDs and each PDF deterministically defines them.
- `LTImage.stream.objid` and `LTLine.pts` are existing public layout-object
  state; checking them proves association with the intended actual object, not
  a private semantic-tree helper.
- Strict-mode exception families are explicit in the prompt; exact messages and
  one particular partial-result policy are not required.
- The named classes and fields are not hidden implementation prescriptions;
  they are the participant-facing API contract stated verbatim in `meta.md`.

## Final fairness statement

Every rejection predicate is grounded in the public prompt, pinned repository
APIs, standard PDF object forms used by that prompt, or the evaluator contract.
The suite is deterministic and black-box at the promised API boundary, and it
does not prescribe traversal, caching, graph storage, rendering pass order, or
error wording. Exact-version verdict: `pass`.
