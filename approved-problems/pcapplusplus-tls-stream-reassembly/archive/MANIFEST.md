# PcapPlusPlus TLS stream-reassembly archive

The platform accepted this problem on 2026-08-08. Acceptance is a
user-confirmed platform outcome. Canonical submission artifacts and compact
design/history records remain in `problems/pcapplusplus-tls-stream-reassembly/`;
this directory preserves raw solver evidence, preliminary candidate records,
scratch recovery, and cleanup inventories.

## Raw solver evidence

| Archive | Runs | Members | SHA-256 |
|---|---:|---:|---|
| `agent-runs1.zip` | 5 | 45 | `bc8d89871b110159da7c9f30c026b0f193fa9a3916c3034098b6e373d1a51845` |
| `agent-runs2.zip` | 5 | 45 | `f50da32a13d82e3019f26335aa0b9381788f87eb7d37ec99d928ee8a3a4f5892` |

Both archives pass `unzip -t`. Every non-`.DS_Store` file in each readable run
directory was compared by relative path and SHA-256 with its ZIP member; all 80
files match. The compact navigation record is the live problem's `RUNS.md`.

## Preliminary candidate records

| Artifact | SHA-256 |
|---|---|
| `candidate-records/DESIGN.md` | `711eda1b291d349f6bd832449022dcd84acc08915556ae7270c494b876007f95` |
| `candidate-records/PROTOTYPE.md` | `2e82b8ae123da2685813efb819db559f900206037728b9485be0772a86650e1f` |
| `candidate-records/UPSTREAM_AUDIT.md` | `7ac75547deaee26d296d5152bec3b603ecc63676f5a082e2ec73bde603338ed8` |

These files were moved from the active candidate namespace without content
changes after acceptance.

## Scratch recovery

`prototype-recovery/combined-worktree.patch` preserves the exact eight-path
dirty TLS authoring checkout at the accepted repository pin. Its SHA-256 is
`1cfef5c45aa94b6f67c9e844e026c7785ae100dc3feba6eee286f764335657af`.
It passes forward application against the pin and reverse application against
the source checkout. The same state is independently reconstructible by
applying the canonical `test.patch` followed by `solution.patch`.

## Canonical accepted artifacts

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `1f1bede4ecb0f6a9e88e5121e9bcb7f1148b9acc16c2e14861b89016edda262e` |
| `test.patch` | `27ed90ce46b01ec084237a7bc357b8519b381fd6417ae5e9d47d6b6d3142d347` |
| `solution.patch` | `0486854afd97a761ae1bbd04e6f25777eb3da6593958c709b8cefe26d399d245` |
| `Dockerfile` | `db856366a98e81addef3565da1710d827a35344bf66af2109be2052a480d25e6` |

Acceptance freezes these four identities. Archive closeout changes only compact
status/history records and evidence placement.

## Cleanup evidence

`docker-images.tsv` records all 36 retired TLS image tags and full image IDs,
including final test-only image
`sha256:8048d2565c7aeb181b64b9f7c7325cb8eb017790906170ef1a153d0e50f91605`
and reference image
`sha256:17462585fc686abda977120970c6d44a8e5e4168b5205ea6666a92586f53c728`.
`cleanup-inventory.tsv` and `WORKTREE_MANIFEST.md` record the shared scratch
namespace and its recovery disposition.

`cleanup-moved-files.txt` explicitly lists all 8,066 files and symbolic links
moved out of the active workspace. Its SHA-256 is
`9b6fc285e81f209fc8e23b5854078eb5beaa3772cdcbe04155fc50886d5f0ea1`.
`SHA256SUMS` covers every other file in this archive and excludes itself.
