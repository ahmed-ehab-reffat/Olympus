# Summary — node-opcua deterministic multi-model NodeSet export

Repository: `node-opcua/node-opcua` at
`e233d906138995583f42359831d1908e3cb005e7`.

State: `archived — locally viable but repeated Shipd image-builder no-start;
calibration 0/10`.

The task adds `exportNodeset2XML(namespaces)` for deterministic selected-model
NodeSet export. Revision 5 closes the two reviewed translation gaps with
separate semantic fresh-load tests for custom structure-field DataType
identifiers and nested structured encoded values. The feature file now has
fifteen focused cases under the randomized `36c2ba` path.

Revision 6 adds no testcase. The existing fresh-load case now resolves every
selected-owned node in the committed two-model fixture, including namespace 1
`i=1`. The existing dependency case now scopes RequiredModel assertions to each
selected Model and checks the exact URI/version/publication-date set. The
participant feature count remains fifteen.

The five platform run directories are not solver trajectories. Each contains
only a short `run.txt`; none contains a solver patch, build/evaluator log, or
JUnit. The local cloud-managed problem directory exposed the root environment
failure: `meta.md`, `solution.patch`, and `Dockerfile` were dataless placeholders
with zero allocated blocks and read as empty. That directly caused the empty
Dockerfile and invalid-patch errors. The canonical artifacts are now
materialized, but the exhausted cloud quota still needs operator attention.

The Dockerfile now uses the validator-approved TypeScript base line, and the
reusable gate forces a cold pull/no-cache build while recording the resolved
digest. The untouched image builds and starts offline as UID/GID
10001. Exact evaluator composition yields pristine base 2/2, pristine feature
15 named failures, reference base 2/2, and reference feature 15/15, with exact
testcase-name parity and no hook/startup/skip.

Revision 7 did produce a new Shipd image ID, but the new `im-fBWE…` image also
failed and its displayed build log contained no underlying Docker output.
Revision 8 reduces the clean AMD64 image from 636,185,865 to 557,746,557 bytes
by assigning permissions during `COPY` and deleting disposable build caches.
Clean AMD64 build, offline non-root startup, and the cold exact gate all pass.
No test was added and no broad package suite was run.

The zero-based nineteen-mutant audit kills eighteen public feature/API defects
in named focused tests. The custom-DataType and nested-recursion defects each
fail only their intended new testcase. The only focused survivor is a deliberate
legacy single-namespace ordering regression; it fails exactly `LNEX5` and
`LNEX8` in the complete 1,040-test pre-existing suite, with two existing skips.
No actionable survivor remains in the revision 6 semantic audit. The revision
8 environment gate passes; formal revision 8 gap, fairness, and false-positive
reapproval remains separate from this cache-only retry. Platform solver
calibration has not begun.

Shipd subsequently allocated the distinct revision-8 image
`im-7NYIPWZIo3cDR19lk9noMD`, so the reduced Dockerfile was ingested. It failed
before tests with no underlying Docker output, exactly as the prior two image
records did. The problem is therefore retired as platform-environment blocked;
these no-starts are not solution results.
