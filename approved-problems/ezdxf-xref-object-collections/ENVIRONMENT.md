# Environment gate — ezdxf XREF object collections

Status: `pass for immutable version 7`.

Repository: `mozman/ezdxf @ b3eb37b942acb4c7e2d2487706e614aa29b7f9b2`.

Artifact hashes:

- prompt: `27b8bfcb2d3cf4c92d8fefb4e6bd16c4b1f5e2a777a64c383cf863f75ea5cafc`
- tests: `35520d3dfd8392f911f6850f910d048226a601bb9c3964649c098dcc5685631e`
- reference: `42bb5c0434f2d130cc70872f24001d4b4ed3ddd8baa0347c6a2b324cca7e1aee`
- Dockerfile: `08d4df4c43468592168153cc6e92b83a668bd4cb4ec6d1962831f088a5ad0309`

## Phase A — pristine image

The exact fail-fast command was:

```text
scripts/environment_gate.sh \
  --problem problems/ezdxf-xref-object-collections \
  --repo Work/ezdxf-xref-object-collections-audit \
  --compatible-patch <each of five representative solver patches>
```

The submitted Dockerfile starts with the approved
`public.ecr.aws/d3j8x8q7/olympus-base-python:latest` image and uses only
`WORKDIR /app`. It installs exact dependency versions during the build and
installs the checkout editably without dependency resolution. The base resolved
to `sha256:6ddc78fc675e6cd3a63b60fc63d87eea35a479f503a44a89cf92923abe905dd8`.
The exact second gate build produced image manifest
`sha256:56204f6b995a78d0a5589f79edd7a921dc65dec9dac12c62a3056464f0b66825`,
manifest-list digest
`sha256:77a06a71a023eb9dcfe49407cd59bb9c77cfd98e043ba11e497eb9fb6e87dba0`,
and config digest
`sha256:9cc6b179dc6b66c980de6fd6451895a0930dcdf2ff7dba7e396cde190c90dc49`.

Runtime networking was disabled. The composed checkout was mounted read-only
and executed as UID/GID 10001. Python, pytest, project sources, fixtures, Qt
libraries, and all pinned dependencies were available offline.

## Phase B — exact evaluator composition

The gate cloned the untouched pin, applied the implementation patch first and
`test.patch` second, rejected participant/test path overlap, checked for
unmerged paths, and required real JUnit in every executed lane.

| Tree | Complete base lane | Feature lane | Result |
|---|---:|---:|---|
| pristine + tests | 7,842 passed, 97 skipped, 1 xfailed | 36 behavioral failures | expected baseline |
| reference + tests | 7,842 passed, 97 skipped, 1 xfailed | 36 passed | pass |

The pristine and reference feature JUnit files contained the same 36 testcase
identities. The pristine failures were ordinary behavior failures rather than
collection, startup, permission, dependency, or patch-application errors.

## Representative solver composition

All five historical patches accepted the verifier in evaluator order during
the gate. They were then executed offline from read-only mounts as UID/GID
10001:

| Solver patch | Exact complete base lane | Version-7 feature lane |
|---|---:|---:|
| `agent-runs1/Nova_Nova_4` | 7,850 passed, 97 skipped, 1 xfailed | 35/36 |
| `agent-runs2/Nova_Nova_5` | 7,846 passed, 97 skipped, 1 xfailed | 28/36 |
| `agent-runs2/Nova_Nova_2` | 7,842 passed, 97 skipped, 1 xfailed | 31/36 |
| `agent-runs2/Nova_Nova_1` | 7,847 passed, 97 skipped, 1 xfailed | 26/36 |
| `agent-runs2/Nova_Nova_4` | 7,849 passed, 97 skipped, 1 xfailed | 24/36 |

Differing base totals come from tests carried by solver patches. Every complete
base lane passed. The strongest non-reference architecture passes all four new
version-7 cases.

Verdict: `pass`. Any submission-artifact, dependency, pin, harness, or
composition-order change invalidates this record.
