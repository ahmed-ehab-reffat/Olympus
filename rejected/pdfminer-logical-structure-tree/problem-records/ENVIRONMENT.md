# Environment gate - pdfminer.six logical structure tree

Status: `pass for immutable version 1`.

Immutable version:

- Repository: `pdfminer/pdfminer.six @ a18de2a9c479b4c847538500017b449ddaec177e`
- Prompt: `3eaebbc7e19f7c480801976df1c10f8292467585db64b39601b878d8a0e96830`
- Test patch: `f564861ad943a2fe8fc90d008a82410149898123b3e0171f551c7e61bc4a8bba`
- Solution patch: `faac3cf4e34bb7520682068062a6bf1147f909555f14b061bff5e77627e26c33`
- Dockerfile: `071e55993cff79f283ab05b931c752491a0a72d4dce45aa41d5bea11c1397499`
- Baseline-plus-tests tree: `c83136699547f6ec98770f0512133bf119514510`
- Reference-plus-tests tree: `71d1cccc9fdcfeab99047417ee4209f5c48bf0b1`

## Phase A - pristine image

The final fail-fast command was:

```text
scripts/environment_gate.sh \
  --problem problems/pdfminer-logical-structure-tree \
  --repo Work/pdfminer-logical-structure-tree/source
```

The Dockerfile begins with the approved Python base, contains the exact
`WORKDIR /app`, and was built from an untouched clone with `.git` excluded.
The approved base resolved to
`sha256:6ddc78fc675e6cd3a63b60fc63d87eea35a479f503a44a89cf92923abe905dd8`.
The exact final no-cache build produced image manifest
`sha256:d607ebb24fdbe015f9b6a18f17b7ecc0d2305d3e8c1abe8cb0d78a5b428ba1a8`,
manifest-list digest
`sha256:8a505fae548b77324f9b84d9354d6b62fc34729a06a833e52322c213ea6bdb2b`,
and config digest
`sha256:db225718e3a7678ce941aff72758ae18443719dba1a8c042ea4c4cd33a668b38`.

The build uses the lockfile and exact SCM-derived local version
`20260108.dev6+ga18de2a9c`. It installs Clang and the separated Clang 14
libFuzzer runtime required by the locked Atheris development dependency. The
system-readable `uv` binary and root-owned `.venv` are executable by arbitrary
users. Runtime networking was disabled, the composed checkout was mounted
read-only, and every lane ran as UID/GID 10001. Python, pytest, project sources,
the lockfile, and all 48 locked packages were readable offline.

The full pristine discovery lane ran all 249 upstream tests. An earlier
prototype-only pristine image also passed Ruff format/check and mypy over 65
source files. The final reference composition passed Ruff, mypy over 67 source
files, and all 263 combined tests before the exact evaluator gate.

## Phase B - evaluator composition

The gate cloned the untouched pin for every tree, applied an implementation
patch first and `test.patch` second, checked for participant/test path overlap,
rejected unmerged files, mounted each tree read-only, and required nonempty
JUnit without startup errors.

| Tree | Injection | Base | New | JUnit/startup |
|---|---|---:|---:|---|
| baseline + tests | clean three-way/direct fallback, no unmerged paths | 249 passed | 14 behavioral failures | real JUnit; 14 tests, 14 failures, 0 errors |
| reference + tests | solution then tests, clean | 249 passed | 14 passed | real JUnit; testcase identities match baseline |
| known-good solver + tests | unavailable: no pdfminer.six solver run exists | not run | not run | not silently substituted |
| near/broad solver + tests | unavailable: no pdfminer.six solver run exists | not run | not run | mutation trees were audited separately |

Participant-owned path overlap: `none`. `test.patch` adds only `test.sh` and
`tests/test_logical_structure.py`; the reference changes only `pdfminer/`
production files.

## Quarantined environment attempts

No quarantined attempt is counted as a solver or behavioral result:

1. the first Phase-A image lacked Clang for Atheris;
2. the second lacked the separate libFuzzer runtime;
3. the third exposed `uv` only through root's non-traversable home;
4. the first exact submitted build omitted `.git` and therefore needed an
   explicit setuptools-scm version fallback;
5. the next arbitrary-UID lane found a root-owned runtime `uv` cache; and
6. `uv run` then attempted to create `.venv` in the read-only composed tree, so
   the harness was corrected to use the image's installed pytest directly.

Each artifact correction invalidated the preceding attempt. The final command
reran the complete no-cache build and all evaluator lanes from the exact pin.

## Verdict

`pass`. Both phases and exact evaluator composition succeeded for the immutable
hashes above. Any submission-artifact, dependency, pin, or injection-path
change invalidates this verdict.
