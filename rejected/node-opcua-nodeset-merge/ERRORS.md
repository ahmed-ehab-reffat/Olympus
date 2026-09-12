# Authoring errors and resolutions

| Finding | Classification | Resolution |
|---|---|---|
| Corepack wrote beneath an unwritable root cache | environment blocker | freeze and prepopulate `COREPACK_HOME` |
| tests expected `/app/tmp` | environment blocker | create a sticky world-writable temp root in the image |
| copied pnpm workspace changed its install path | environment blocker | run writable overlays at `/app` |
| shared clone alternates were unavailable in Docker | environment-gate bug | use self-contained `git clone --no-local` clones |
| Bash 3.2 rejected an empty array expansion | environment-gate bug | use safe optional-array expansion |
| per-namespace legacy filtering dropped a selected cross-model edge | reference defect | add selected-endpoint ownership and semantic reload coverage |
| routing legacy export through the new path reordered XML | compatibility defect | preserve the old ordering path and guard its two direct existing tests |
| relationship test counted only one endpoint form | false-positive gap | derive namespace indexes and count both semantic forms |
| proposed selected-model dependency augmentation exceeded repository semantics | fairness defect | remove the rule and its proposed discriminator |
| XML assertions fixed quotes, attribute order, aliases, and namespace numbers | fairness risk | replace with quote/order-neutral or semantic loader checks |
| initial 46-test base slice included unrelated loader cases | evaluator-scope risk | narrow scoring to existing `LNEX5` and `LNEX8` only |
| prompt explicitly restated unchanged legacy output | review noise | remove the participant-facing sentence; retain only existing baseline regression tests |
| descriptive hidden-test path could collide with participant tests | evaluator injection risk | generate suffix `36c2ba` with OpenSSL and rename every harness/verifier reference |
| RequiredModel Version and PublicationDate were indirect | public metadata gap | add quote/order-neutral assertions and an isolated metadata-omission mutant |
| pristine feature run failed in a suite-level `before` hook | wrapper-attribution blocker | keep shared setup repository-only, fail inside each named test, and require exact baseline/reference testcase-name parity |
| generic selected-edge ownership could discard both representations of cross-namespace `HasSubtype` | public relationship defect | preserve subtype-specific inverse ownership and add a semantic fresh-load probe |
| runtime barrel exported the helper but the advertised declaration barrel did not | public API defect | add a declaration-only package signature and compile an isolated package-root TypeScript consumer |
| direct type-barrel re-export introduced a circular runtime import | authoring environment blocker | discard it and retain the repository's deliberate split between callable `main` and declaration-only `types` |
| platform could not pull cached evaluator image `im-Wem…`; a changed Dockerfile produced distinct failed image `im-fBWE…` with no underlying build output | external environment blocker with possible image-import pressure | quarantine both runs; reduce the clean AMD64 image by 78,439,308 bytes, then verify clean AMD64 build/startup and all four exact offline lanes |
| reduced revision-8 Dockerfile produced distinct image `im-7NYIPWZIo3cDR19lk9noMD`, which failed before tests with the same empty generic build report | terminal Shipd image-builder/build-context blocker | retire and archive the problem at 0/10; preserve the final image and evidence; do not interpret the no-starts as solution failures |
| canonical submission files were cloud `dataless` placeholders with zero allocated blocks | submission environment blocker | materialize all four artifacts and verify their contents/blocks before upload; the empty Dockerfile and invalid patch messages were direct consequences |
| warm Docker cache concealed whether the accepted `:latest` base was cold-buildable | environment-verdict defect | retain the validator-approved `FROM` line, use `docker build --pull --no-cache`, record the resolved digest, and rerun all four exact lanes |
| schema custom DataType and nested ExtensionObject paths lacked separate probes | public coverage gap | add two semantic fresh-load tests and two independently isolated compiling mutants |
| selected-node coverage missed namespace 1's independent `i=1` object | public inventory gap | resolve all selected-owned fixture nodes in the existing fresh-load testcase; isolate an independent-object omission mutant |
| RequiredModel metadata was searched globally instead of under its owning Model | public model-scoping gap | locate each Model by ModelUri and compare its exact RequiredModel metadata set; isolate a global-union mutant |

All environment failures were quarantined and never counted as failed
solutions. Every affected artifact version was discarded and its gates were
rerun from zero.
