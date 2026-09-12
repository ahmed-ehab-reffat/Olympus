# False-positive audit — pdfminer.six logical structure tree, version 1

Status: `pass; complete for the attempted mutation set`.

Immutable identifiers: repository
`a18de2a9c479b4c847538500017b449ddaec177e`, prompt `3eaebbc7…`, tests
`f564861a…`, reference `faac3cf4…`, Dockerfile `071e5599…`, and combined
reference tree `71d1cccc…`. Full hashes are in `ENVIRONMENT.md`.

The final public-vocabulary clarification and looser empty-collection assertion
leave every mutation predicate unchanged. Exact-version replay preserved all
five 13/14 discriminator isolations and zero survivors in the attempted set.

## Method and requirement map

Every participant-facing obligation was mapped to its strongest test in
`GAP_ANALYSIS.md`. Plausible incorrect implementations were constructed from
the pinned interpreter/layout branches, the reviewed trajectory shortcut
families, and the predecessor suite's weak cells. A survivor had to compile,
pass the focused predecessor, and preserve the complete upstream suite. A probe
was admitted only when it passed the reference, failed the survivor, remained
a behavioral failure on pristine, and observed a distinct public boundary.

| Requirement family | Strongest final discriminator |
|---|---|
| public high-level/document API and absent tree | untagged and direct-document tests |
| ordered elements, MCID, MCR, OBJR | mixed-child test |
| original/resolved roles and all direct/class attributes | mixed metadata arrays |
| page/Form-scoped MCID and `Pg` inheritance/override | same-MCID and MCR-override tests |
| inline/named BDC properties | named-property test plus inline fixtures |
| actual text/image/vector layout objects | page text, image, and vector tests |
| explicit and reverse Form association | explicit MCR and reverse ParentTree tests |
| root and nested ParentTree nodes | reverse test and positive `Kids` test |
| safe cycles, dangling references, invalid values | three strict/nonstrict malformed tests |

## Actionable survivors and probes

| Survivor | Why plausible | Predecessor focused | Upstream suite | Final isolation |
|---|---|---:|---:|---:|
| ParentTree reads root `Nums` but skips positive child nodes while separately detecting direct cycles | simplest use of a root dictionary; prior cycle test did not prove positive recursion | passed 10-test predecessor | 249/249 | 13/14, only child-number-tree test fails |
| MCR always inherits element page | one shared context variable handles integer MCIDs and most MCRs | passed 10-test predecessor | 249/249 | 13/14, only MCR override fails |
| layout capture omits images | text hooks are the obvious first implementation | passed 10-test predecessor | 249/249 | 13/14, only image association fails |
| layout capture handles text/images but omits vector paths | `paint_path` is a separate producer from `render_char` and `render_image` | 13/13 | 249/249 | 13/14, only vector association fails |
| attribute expansion accepts only the first `A` and `C` entry | scalar fixtures and first-entry loops are common parser shortcuts | 13/13 | 249/249 | 13/14, only mixed metadata test fails |

The reference passes all five probes and the full 263-test combined suite.
Each final focused result was executed offline against a read-only tree with the
same installed dependency environment. The ParentTree, MCR, and image probes
were added together after the 10-test audit; geometry and attribute-array probes
were added after two new survivors passed the 13-test intermediate suite.

## Additional attempted mutants

- MCID-only global lookup is rejected by the same-MCID two-page test.
- Inline-only property handling is rejected by the named-resource property
  test.
- Forward-only structure parsing is rejected independently by page and Form
  ParentTree reverse associations.
- OBJR ID-only output is rejected by the resolved-object assertion.
- RoleMap-only or direct-attribute-only metadata is rejected by the mixed
  metadata fixture.
- Form stream identity omitted or replaced with the page identity is rejected
  by the explicit Form MCR test.
- Structure or number-tree recursion without an active identity set is rejected
  by the strict/nonstrict cycle tests; an intentionally hanging version was not
  run after the safe equivalent established the discriminator.

No mutant in this attempted set compiles and passes the final 14-test suite.
Zero survivors is evidence for this set, not proof that false positives are
impossible.

## Rejected and artificial survivors

- Special-casing one arbitrary MCID value, object number, PDF role name, or page
  index was rejected as adversarial fixture overfitting.
- Testing every PDF vector opcode, image colorspace, ParentTree depth, or class
  name was rejected as repetition within an already covered branch.
- Requiring a specific partial tree after malformed input was rejected because
  non-strict omission and strict repository errors are both public outcomes.
- Object ParentTree entries, reusable-Form occurrence aggregation, namespace
  maps, inferred reading order, and generic corrupt-stream repair were rejected
  as outside or intentionally unspecified scope.

## Mutation isolation and exact validation

- Reference focused: 14/14.
- Reference complete combined suite: 263/263.
- Pristine focused: 0/14 with 14 failures and zero errors.
- Pristine and reference base lane: 249/249 each.
- Ruff: 68 files format-clean and all checks passed.
- Mypy: 67 source files, no issues.
- Exact Docker composition: pass; testcase identities match.
- Compatible solver replay: unavailable because no pdfminer.six solver patch
  exists. Mutants are not represented as legitimate solvers.

Verdict: `pass`. No actionable false positive remains in the attempted,
repository-grounded mutation set for the immutable hashes above.
