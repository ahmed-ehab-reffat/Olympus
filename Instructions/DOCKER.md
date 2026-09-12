# DOCKER.md

> ## ⚠️ NO LOCAL DOCKER ON THIS WORKSTATION (2026-08-05)
>
> Docker is NOT available here. Never run `docker build` / `docker run` to validate, and never report a
> Dockerfile as locally verified. Write it to the patterns below, check it statically (base image,
> offline-buildable, no network at build, non-root, `CMD ["/bin/bash"]`, test.sh at mode 100755), and
> carry Docker validation as OWED to the platform run. Build/test/flakiness/LOC are still validated
> locally, outside Docker, with the repo's native toolchain.
>
> Also: **watch disk** — cargo/go target dirs are the dominant cost; delete `worktrees/*/target` after
> each measurement (see `CLAUDE.md § ENVIRONMENT CONSTRAINTS`).

# DOCKER — How to Write Dockerfiles

One file, one install command. Pick the language-specific image, then copy the matching template.

> **Read first:** `PLAYBOOK.md` § Pattern 4 — Mars Pattern A vs Pattern B decision verified across 13 approved problems.

---

## ⚠️ NEW (May 2026) — Slimmer language-specific images

Admin shipped slimmer per-language images. **Use these for ALL new submissions** — smaller image = faster post-checks + faster agent runs.

| Image | Use for |
|---|---|
| `public.ecr.aws/d3j8x8q7/olympus-base-python:latest` | Python |
| `public.ecr.aws/d3j8x8q7/olympus-base-typescript:latest` | TS / JS |
| `public.ecr.aws/d3j8x8q7/olympus-base-go:latest` | Go |
| `public.ecr.aws/d3j8x8q7/olympus-base-rust:latest` | Rust (workspaces too — replaces mars-base for new subs) |
| `public.ecr.aws/d3j8x8q7/olympus-base-cpp:latest` | C / C++ (✅ SUPPORTED — the 2026-05-14 disable was reverted) |
| `public.ecr.aws/d3j8x8q7/olympus-base-jvm:latest` | Java / JVM (✅ SUPPORTED — the 2026-05-14 disable was reverted) |

> **✅ Java/JVM + C/C++ SUPPORTED again (the 2026-05-14 disable was reverted) — valid targets.** Verified toolchains + footguns in the C++/Java sections below. Platform author guide: <https://docs.google.com/document/d/1aL-RKQmgqadcrf9kdqHxnG8GnCPhL6-mhulnNbnG2hY/edit?tab=t.0>

**Old generic `olympus-base:latest` and `mars-base:latest`** still work for legacy/historical reference but should NOT be used for new submissions. All examples below have been updated to language-specific tags.

---

## ⚠️ Rust JUnit = `cargo2junit` (2026-07 reviewer directive) — NOT the bash-regex placeholder

**A reviewer rejected the bash-regex `run_and_produce_junit` and directed "just use cargo2junit".** It wrote every failure as `<failure message="test failed"/>`, discarding the libtest panic block. The platform author doc lists a JUnit reporter for python/js/go/deno but names NO Rust one, and `olympus-base-rust` ships none, so a real converter is expected. **Use `cargo2junit` for ALL new Rust subs.** Source: APPROVED nickel-1336 + reviewer samridh. (This supersedes the older "no cargo2junit needed / use bash-regex" guidance in Pattern A, `TESTS.md`, `PLAYBOOK.md`, `WORKFLOW.md`.)

> **Confirmed AGAIN (piccolo-to-be-closed, 2026-06-28):** a SECOND Rust sub was REVERTED for the identical bash-regex `<failure message="test failed"/>` placeholder even after a clean 20% batch. This is a hard revert trigger, not a nitpick — a passing eval does NOT save it. Ship cargo2junit from the first draft on every Rust sub. The fix is test.sh + Dockerfile ONLY (add `cargo install cargo2junit`; swap the reporter); solution/tests/difficulty untouched. cargo2junit ALSO fixes multi-target miscounting (piccolo base mode runs `--lib` + 13 `--test` targets — bash-regex over/under-counts across binaries; cargo2junit aggregates the full json stream, verified 14 suites / 33 cases). Local-validate the panic block by forcing one failing test: the `<failure>` must carry the real `assertion left == right ... file:line`, not the placeholder.

**Dockerfile (canonical — NO ENV block, NO chmod, NO symlink loop):**
```dockerfile
FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest
WORKDIR /app
COPY . .
RUN cargo install cargo2junit && cargo fetch && cargo build --workspace
CMD ["/bin/bash"]
```

**test.sh (accurate per-test JUnit from libtest json):**
```bash
#!/usr/bin/env bash
set -uo pipefail
export PATH="/root/.cargo/bin:$PATH"; export CARGO_INCREMENTAL=0; export RUSTC_BOOTSTRAP=1
# ...arg-parse MODE + OUTPUT_PATH...
TEST_JSON=$(mktemp); TEST_ERR=$(mktemp)
case "$MODE" in
  base) cargo test -p <crate> <existing-affected-targets> -- -Z unstable-options --format json --report-time --skip <new_test_mod> > "$TEST_JSON" 2> "$TEST_ERR" ;;
  new)  cargo test -p <crate> --test <new_target> <new_test_mod>  -- -Z unstable-options --format json --report-time                 > "$TEST_JSON" 2> "$TEST_ERR" ;;
esac
STATUS=$?
cat "$TEST_ERR" >&2
if [ -n "$OUTPUT_PATH" ]; then
  mkdir -p "$(dirname "$OUTPUT_PATH")"
  cargo2junit < "$TEST_JSON" > "$OUTPUT_PATH" 2>/dev/null || true
  # build-fail fallback: if no <testcase>, synthesize a compilation-failure <testsuite> from tail of ERR+JSON
  grep -q '<testcase' "$OUTPUT_PATH" 2>/dev/null || { sanitized=$( { cat "$TEST_ERR"; cat "$TEST_JSON"; } | tail -c 4000 | sed -e 's/]]>/]]]]><![CDATA[>/g'); printf '<?xml version="1.0" encoding="UTF-8"?>\n<testsuites>\n  <testsuite name="cargo-test" tests="1" failures="1" errors="0">\n    <testcase name="compilation" classname="cargo-test"><failure message="build failed"><![CDATA[%s]]></failure></testcase>\n  </testsuite>\n</testsuites>\n' "$sanitized" > "$OUTPUT_PATH"; }
fi
exit $STATUS
```

**Three load-bearing details:**
1. **`RUSTC_BOOTSTRAP=1`** unlocks libtest `-Z unstable-options --format json` on the *pinned stable* compiler (repos pin stable via `rust-toolchain.toml`; `--format json` is otherwise nightly-only). No nightly install, pin untouched. Verified: default stable rejects `-Z`; with `RUSTC_BOOTSTRAP=1` it emits json incl. the failing test's `stdout` panic block, which cargo2junit renders into `<failure><![CDATA[...]]>`.
2. **Split streams:** JSON to stdout (fed to cargo2junit), progress to stderr. cargo2junit chokes on non-JSON lines. Take the exit code from `cargo`, NOT the pipe (cargo2junit exits 1 on any failure but writes complete XML first).
3. **`cargo2junit` reachability needs NO chmod/symlink** — `cargo install` drops it in `/root/.cargo/bin`, the exact dir test.sh already prepends to PATH for `cargo`. Reachable exactly like `cargo`.

**NEVER an `ENV RUSTUP_HOME` / `CARGO_HOME` / `PATH` block on `olympus-base-rust`** (measured,
comrak 2026-08-05). The legacy Pattern-A ENV block was carried onto this image and the build died at
`RUN cargo install`: `error: rustup could not choose a version of cargo to run, because one wasn't
specified explicitly, and no default is configured`. The base image does not keep its toolchain under
`/root/.rustup`, so overriding `RUSTUP_HOME` aims rustup at an empty directory and it finds zero
installed toolchains. Inherit the image's environment; `test.sh` sets its own `PATH` anyway.

**NEVER `--tests` or `--all-targets` in the image build command** (same submission, caught by a
static check after the ENV fix). The platform builds the image from the tree with `test.patch`
APPLIED and `solution.patch` NOT applied, so the new tests cannot compile yet: measured 4 compile
errors with `cargo build --lib --bins --tests`, 0 with `cargo build --workspace`, on the identical
tree. `--all-targets` is worse — it also builds benches, and `benches/progits.rs` in comrak needs
`#![feature(test)]`, which fails on the pinned stable toolchain even on a pristine base checkout.
`cargo build --workspace` builds lib + bins only, which is all the image needs to warm the cache.

**Static substitute when local Docker is unavailable:** run the cargo half of the RUN line against a
fresh checkout at BASE_COMMIT with ONLY `test.patch` applied. Building your finished working tree
proves nothing, because it has the solution in it.

**NEVER `chmod -R a+rX /root` on `olympus-base-rust`.** It leaves fetched registry files root-owned AND breaks the platform's solve-time user remap, so the `model` user gets `Permission denied` reading `/root/.cargo/registry/.../Cargo.toml` and agents cannot run cargo/the baseline at solve time (nickel-enum-widening R1: 0/10, perm blocker). The approved image does no chmod and works. The legacy Pattern-A chmod/symlink below was a `mars-base` pattern — do NOT carry it onto `olympus-base-rust`.

**Why not bash-regex** (beyond the rejected placeholder): grep-`test ... ok/FAILED` MISCOUNTS across multiple test binaries — when one binary exits non-zero early, later binaries' tests report as phantom failures ("13 failures" when 1 is real). cargo2junit consumes the full json event stream and reports each test accurately across all targets.

## Pattern Decision

| Pattern | Image | Use for | Approved examples (legacy) |
|---|---|---|---|
| **Rust (2026-07)** | `olympus-base-rust` + `cargo install cargo2junit`, NO chmod | ALL Rust (workspaces too) — canonical, see top section | nickel-1336 (approved) |
| **Pattern A (LEGACY)** | `mars-base` + chmod/symlink workaround | historical Rust re-verify ONLY — chmod breaks solve perms on `olympus-base-rust` | 4 of 5 Mars Rust + all 7 Olympus pest |
| **Pattern B** | language-specific slim image | **ALWAYS for Python/JS/Go/Java/C++**; tiny single-crate Rust | dagster, goja, lightningcss |

**Rule (May 2026): Use language-specific slim images.** Older Mars approveds shipped on `mars-base`/`olympus-base` (generic) — do NOT cite as precedent for new submissions. Slim images cut image size 30-60% which speeds post-checks.

**For NEW Rust subs (2026-07): use the no-chmod cargo2junit pattern at the top of this file — NOT Pattern A's chmod/symlink.** Pattern A below is LEGACY `mars-base`; its `chmod -R a+rX /root` actively breaks solve-time cargo perms on `olympus-base-rust`. The canonical Rust Dockerfile is now just `cargo install cargo2junit && cargo fetch && cargo build --workspace` (no ENV block, no chmod, no symlink).

---

## Pattern A — Rust chmod/symlink (LEGACY `mars-base` only — do NOT use the chmod on `olympus-base-rust`)

```dockerfile
FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest

ENV RUSTUP_HOME="/root/.rustup"
ENV CARGO_HOME="/root/.cargo"
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /app
COPY . .

RUN chmod -R a+rX /root \
    && for f in /root/.cargo/bin/*; do ln -sf "$f" /usr/local/bin/; done \
    && sed -i '1s/^/#![cfg(feature = "grammar-extras")]\n/' vm/tests/surround.rs \
    && cargo fetch && cargo build --workspace

CMD ["/bin/bash"]
```

(Legacy: existing approved Rust submissions used `public.ecr.aws/x8v8d7g8/mars-base:latest` — keep when reverifying historical builds, but NEW submissions should use `olympus-base-rust`.)

Three mandatory parts:
1. `chmod -R a+rX /root` — non-root reads `/root/.cargo/*`
2. `for f in /root/.cargo/bin/*; do ln -sf "$f" /usr/local/bin/; done` — non-root finds cargo on standard PATH
3. `cargo fetch && cargo build --workspace` — pre-warm offline cache

The `sed` patch shown is repo-specific (pest's `grammar-extras` feature gate on `surround.rs`). Add equivalent patches for any pre-existing feature-gated test that would fail the baseline.

> ⚠️ **SUPERSEDED for new subs (2026-07):** the "no cargo2junit needed / bash-regex" line below is the OLD Mars-era guidance. A reviewer rejected the bash-regex placeholder and directed `cargo2junit` — see `## ⚠️ Rust JUnit = cargo2junit` at the top of this file. Also do NOT apply the `chmod -R a+rX /root` step below on `olympus-base-rust`: it breaks solve-time cargo perms (nickel-enum-widening R1 0/10). Pattern A's chmod/symlink is legacy `mars-base` only.

**(LEGACY)** 4 of 5 approved Mars Rust problems used bash-regex `run_and_produce_junit()` in test.sh — see `TESTS.md`. New Rust subs use `cargo2junit` instead.

### Why the chmod appeared (legacy mars-base note — do NOT reuse the chmod on olympus-base-rust)

Old note: the naive `olympus-base + cargo install cargo2junit && cargo build` was thought to FAIL because `cargo build` creates `/app/target/` root-owned and non-root hits `Permission denied` on `/app/target/debug/.cargo-lock`. In practice the PROVEN nickel-1336 Dockerfile (`cargo install cargo2junit && cargo fetch && cargo build --workspace`, no chmod) builds and solves fine on the current platform — agents run with a user remap that owns their own target. The real trap is the OPPOSITE: `chmod -R a+rX /root` breaks the solve-time remap. Use the no-chmod cargo2junit pattern at the top of this file.

---

## Language-Specific Build Guardrails (Go, Rust)

Several Go/Rust submissions failed because the agent couldn't build the project from the supplied Dockerfile. The platform pre-checks now flag these issues more aggressively. The templates below have unblocked previously-broken builds — **treat them as guardrails, not copy-paste defaults**. You're still expected to modify them to match your repo's actual build steps.

### Go guardrail template

```dockerfile
FROM public.ecr.aws/d3j8x8q7/olympus-base-go:latest

ENV GOPATH="/root/go"
ENV PATH="/root/go/bin:${PATH}"

WORKDIR /app

COPY . .

RUN go mod vendor && go build ./...

CMD ["/bin/bash"]
```

Key elements:
- `GOPATH` + `PATH` exported so non-root agents find any `go install`-ed binaries
- `go mod vendor` pre-populates dependencies offline
- `go build ./...` proves the workspace compiles before tests run

### Rust guardrail template

The Rust guardrail is the cargo2junit pattern at the top of this file: `olympus-base-rust` + `RUN cargo install cargo2junit && cargo fetch && cargo build --workspace` (NO ENV block, NO chmod, NO symlink). `cargo fetch` warms the offline registry cache; `cargo build --workspace` compiles every crate; cargo2junit lands in `/root/.cargo/bin` (on PATH for the agent, same as `cargo`). Do NOT add `chmod -R a+rX /root` — it breaks the platform's solve-time user remap (agents lose read access to the fetched registry).

> **Do not use these blindly.** Feature-gated `sed` patches or system packages (`pkg-config`, `libssl-dev`) — keep those if your repo needs them. But do NOT add `chmod -R a+rX /root` + symlink on `olympus-base-rust` (breaks solve-time cargo perms); that was a legacy `mars-base` workaround only. These templates are baselines for spotting missing commands, not replacements.

---

## Pattern B — Per-language slim image

Pick the slim image matching the repo language. Each ships pre-installed JUnit tooling for its language.

```dockerfile
FROM public.ecr.aws/d3j8x8q7/olympus-base-{lang}:latest

WORKDIR /app
COPY . .
RUN {install_command}
CMD ["/bin/bash"]
```

Replace `{lang}` with `python`, `typescript`, `go`, `rust`, `cpp`, or `jvm` (the `{lang}` placeholder for Java is `jvm`, image `olympus-base-jvm`; cpp/jvm ✅ SUPPORTED — the 2026-05-14 disable was reverted).

For tiny single-crate Rust on `olympus-base-rust` (add cargo2junit for JUnit):
```dockerfile
FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest
WORKDIR /app
COPY . .
RUN cargo install cargo2junit && cargo fetch && cargo build
CMD ["/bin/bash"]
```

That's it. 5 lines. Most Pattern B Dockerfiles should be exactly this with only the install command changing.

---

## Verification (Run Before Submitting)

```bash
docker build -t my-mars-problem . \
  && docker run --rm --network none --user 1000:1000 -v /tmp/out:/out my-mars-problem \
       bash -c "/app/test.sh --output_path /out/base.xml base && /app/test.sh --output_path /out/new.xml new"
grep -c '<testcase' /tmp/out/*.xml   # both should be > 1
```

Both counts > 1 → ✅. Either count is 0 or 1 → permissions broken; switch to Pattern A.

### Build it
```bash
docker build -t {reponame}-{issue} .
```
If build fails, debug the install command — that's usually the issue.

### Run it offline
```bash
docker run -it --network none {reponame}-{issue}
```
Inside the container:
```bash
./test.sh base   # should pass
./test.sh new    # should fail (no solution applied)
```

### Common build failures (during local debug)
- **"permission denied"** → test.sh needs `chmod +x`
- **"module not found"** → wrong install command or missing dependency
- **"npm ERR! could not determine executable to run"** → add `--ignore-scripts`
- **"poetry: command not found"** → shouldn't happen with olympus-base, check FROM line

---

## Environment Blocker Check — Don't Bypass

The env-blocker check catches genuine Docker issues: missing system packages, permission errors, non-root build failures, network dependencies at test time. If it fires, **read the check output first**. Bypassing a real env blocker causes revert/reject. If it's a true false-positive (rare), write a bypass justification.

---

## Install Commands by Language

### Python

| Indicator | Command |
|---|---|
| `pyproject.toml` with `[tool.poetry]` | `poetry install --no-interaction` |
| `pyproject.toml` with `[tool.pdm]` | `pdm install` |
| `pyproject.toml` (setuptools/flit/hatch) | `pip install -e .` |
| `setup.py` or `setup.cfg` | `pip install -e .` |
| `requirements.txt` only | `pip install -r requirements.txt` |
| Extras defined (e.g. `[test]`) | `pip install -e ".[test]"` |
| `uv` projects | `uv sync --frozen` |

Always add `--no-cache-dir` for smaller images.

**Test dependencies** install separately if not in repo's install:
```dockerfile
RUN pip install --no-cache-dir -e .
RUN pip install --no-cache-dir pytest pytest-asyncio  # add what tests need
```

Common test deps: `pytest`, `pytest-cov`, `pytest-xdist`, `pytest-asyncio`, `hypothesis`, `anyio`, `trio`, `trustme`, `uvicorn`, `fastapi`, `httpx`, `faker`.

**Version pinning** for resolver conflicts — install BEFORE `COPY . .` so layers cache:
```dockerfile
WORKDIR /app
RUN pip install --no-cache-dir \
    "package1>=1.0,<2.0" \
    "package2>=3.0"
COPY . .
RUN pip install -e .
```

Or chain pip installs:
```dockerfile
RUN pip install -e . && pip install pytest pytest-asyncio faker coverage
```
Or use line continuation:
```dockerfile
RUN pip install -e . && \
    pip install pytest pytest-asyncio faker coverage
```

### TypeScript / JavaScript

| Lockfile | Command |
|---|---|
| `bun.lockb` or `bun.lock` | `bun install` |
| `pnpm-lock.yaml` | `pnpm install --frozen-lockfile` |
| `package-lock.json` | `npm ci` |
| `yarn.lock` | `yarn install --frozen-lockfile` |

| Problem | Fix |
|---|---|
| Install scripts fail | Add `--ignore-scripts` |
| Dev deps missing | `ENV NODE_ENV=development` before install, use `--include=dev` |
| Needs build after install | `RUN npm run build` |
| Needs compilation | `RUN npm run compile` after install |

### Go

```dockerfile
RUN go mod download
RUN GOBIN=/usr/local/bin go install github.com/jstemmer/go-junit-report/v2@v2.1.0
```

`GOBIN=/usr/local/bin` ensures non-root finds it on PATH.

### Rust on `olympus-base-rust` (JUnit via cargo2junit)

```dockerfile
RUN cargo install cargo2junit && cargo fetch && cargo build          # single-crate
RUN cargo install cargo2junit && cargo fetch && cargo build --workspace  # workspace
```

NO chmod/symlink on `olympus-base-rust` (breaks solve-time cargo perms). test.sh emits JUnit via `RUSTC_BOOTSTRAP=1 ... --format json | cargo2junit` — see the top § ⚠️ Rust JUnit = cargo2junit.

### System dependencies

If cargo/build fails with "pkg-config not found" or similar, install BEFORE `COPY . .`:
```dockerfile
RUN apt-get update && apt-get install -y pkg-config && rm -rf /var/lib/apt/lists/*
COPY . .
RUN cargo fetch
```

Always clean up apt lists with `rm -rf /var/lib/apt/lists/*`.

---

## How to Figure Out the Install Command

1. **Check the project root for clues:**
    - `pyproject.toml` with `[tool.poetry]` → `poetry install --no-interaction`
    - `pyproject.toml` with `[tool.pdm]` → `pdm install`
    - `pyproject.toml` without poetry → `pip install -e .` or `uv sync`
    - `requirements.txt` → `pip install -r requirements.txt`
    - `package.json` + `bun.lockb` → `bun install`
    - `package.json` + `package-lock.json` → `npm install` (or `npm ci`)
    - `package.json` + `pnpm-lock.yaml` → `pnpm install --frozen-lockfile`
    - `package.json` + `yarn.lock` → `yarn install`
    - `go.mod` → `go mod download`
    - `Cargo.toml` → `cargo build` (Pattern B tiny only) or `cargo build --workspace` (Pattern A)

2. **Check for dev dependency needs:**
    - If tests use `pytest` → make sure it's installed
    - If project uses TypeScript → may need `npm run compile` or `npm run build`
    - If project has `--ignore-scripts` in their CI → use it too

3. **Check existing Dockerfiles in approved problems:**
    - Same repo = same Dockerfile (almost always)
    - Elysia always uses `bun install`
    - Happy-DOM always uses `npm install --include=dev --ignore-scripts`
    - All Go repos use `go mod download`

---

## Real Approved Dockerfiles (Reference Templates)

### Go (canopy, goja)
```dockerfile
FROM public.ecr.aws/x8v8d7g8/mars-base:latest
WORKDIR /app
COPY . .
RUN go mod download
RUN GOBIN=/usr/local/bin go install github.com/jstemmer/go-junit-report/v2@v2.1.0
CMD ["/bin/bash"]
```

### Go — Simple (bunster, goja, sh, wazero)
```dockerfile
FROM public.ecr.aws/d3j8x8q7/olympus-base-go:latest
WORKDIR /app
COPY . .
RUN go mod download
CMD ["/bin/bash"]
```

### TypeScript pnpm (bumpp)
```dockerfile
FROM public.ecr.aws/x8v8d7g8/mars-base:latest
WORKDIR /app
COPY . .
RUN pnpm install
CMD ["/bin/bash"]
```

### TypeScript — Bun (elysia)
```dockerfile
FROM public.ecr.aws/d3j8x8q7/olympus-base-typescript:latest
WORKDIR /app
COPY . .
RUN bun install
CMD ["/bin/bash"]
```

### TypeScript — npm with dev deps (happy-dom, cron-parser)
```dockerfile
FROM public.ecr.aws/d3j8x8q7/olympus-base-typescript:latest
WORKDIR /app
COPY . .
ENV NODE_ENV=development
RUN npm install --include=dev --ignore-scripts
CMD ["/bin/bash"]
```

### TypeScript — npm ci with compile step (opentelemetry-js)
```dockerfile
FROM public.ecr.aws/d3j8x8q7/olympus-base-typescript:latest
WORKDIR /app
COPY . .
ENV NODE_ENV=development
RUN npm ci --include=dev
RUN npm run compile
CMD ["/bin/bash"]
```

### TypeScript — pnpm with explicit copy (cleye)
```dockerfile
FROM public.ecr.aws/d3j8x8q7/olympus-base-typescript:latest
WORKDIR /app
COPY package.json .
COPY pnpm-lock.yaml .
COPY tsconfig.json .
RUN pnpm install --frozen-lockfile
COPY . .
CMD ["/bin/bash"]
```

### Python — Simple (attrs, textual)
```dockerfile
FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest
WORKDIR /app
COPY . .
RUN pip install -e . pytest hypothesis
CMD ["/bin/bash"]
```

### Python — Poetry (beets)
```dockerfile
FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest
WORKDIR /app
COPY . .
RUN poetry install --no-interaction
CMD ["/bin/bash"]
```

### Python — Extras (khal)
```dockerfile
FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest
WORKDIR /app
COPY . .
RUN pip install -e ".[test]"
CMD ["/bin/bash"]
```

### Python pip + test deps (h2)
```dockerfile
FROM public.ecr.aws/x8v8d7g8/mars-base:latest
WORKDIR /app
COPY . .
RUN pip install --no-cache-dir -e .
RUN pip install --no-cache-dir pytest pytest-cov pytest-xdist hypothesis
CMD ["/bin/bash"]
```

### Python heavy deps + version pins + env var (ormar)

The most complex approved Dockerfile. Key patterns:
- Deps installed BEFORE `COPY . .` for layer caching
- Two separate `pip install` blocks (runtime vs test deps)
- Version ranges pinned to prevent resolver conflicts
- `ENV` for runtime config

```dockerfile
FROM public.ecr.aws/x8v8d7g8/mars-base:latest
WORKDIR /app
RUN pip install --no-cache-dir \
    "databases>=0.9.0,<0.10.0" \
    "pydantic>=2.11.9,<3.0.0" \
    "SQLAlchemy[asyncio]>=2.0.40,<3.0.0" \
    "aiosqlite>=0.19,<0.23" \
    # ... more pinned runtime deps
RUN pip install --no-cache-dir \
    "pytest>=7.4.4,<9.0.0" \
    "pytest-cov>=4,<6" \
    "pytest-asyncio>=0.21,<0.24" \
    # ... more pinned test deps
COPY . .
RUN pip install -e .
ENV DATABASE_URL=sqlite:///test.db
CMD ["/bin/bash"]
```

### Rust workspace with system deps (oxvg)
```dockerfile
FROM public.ecr.aws/x8v8d7g8/mars-base:latest

ENV RUSTUP_HOME="/root/.rustup"
ENV CARGO_HOME="/root/.cargo"
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /app
RUN apt-get update && apt-get install -y pkg-config && rm -rf /var/lib/apt/lists/*
COPY . .

RUN chmod -R a+rX /root \
    && for f in /root/.cargo/bin/*; do ln -sf "$f" /usr/local/bin/; done \
    && cargo fetch && cargo build --workspace

CMD ["/bin/bash"]
```

### Python monorepo (dagster)
```dockerfile
FROM public.ecr.aws/x8v8d7g8/mars-base:latest
WORKDIR /app
COPY . .
RUN pip install --no-cache-dir \
    -e python_modules/libraries/dagster-shared \
    -e python_modules/dagster-pipes \
    -e "python_modules/dagster[test]" \
    -e python_modules/dagster-graphql \
    -e python_modules/dagster-test
CMD ["/bin/bash"]
```

Install editable packages in dependency order in a single `pip install` so pip resolves the graph in one pass.

---

## C / C++ — `olympus-base-cpp` (✅ SUPPORTED)

Use `public.ecr.aws/d3j8x8q7/olympus-base-cpp:latest`. Verified against jq (autoconf/automake), libuv (CMake/Ninja), nlohmann/json (CMake + FetchContent test data).

Pre-installed (no install needed): gcc/g++ 12, clang/clang++ 21 + clang-tidy/clang-format 21, CMake 4.3.2, Ninja 1.13.2, make/autoconf/automake/libtool/pkg-config/bison/flex/gdb, GoogleTest 1.17.0 (under `/usr/local`), doctest 2.5.2 (`/usr/local/include/doctest.h`), libsnappy-dev, tcl.

Build: CMake `cmake -S . -B build && cmake --build build -j` · Make `make` · Meson `meson setup build && meson compile -C build` · autoconf `autoreconf -fi && ./configure && make` · Bazel ONLY if the repo already uses it. Pre-build during the Docker step so test.sh runs offline. JUnit via gtest `--gtest_output=xml:$OUTPUT_PATH` or catch2 `--reporter=junit`.

```dockerfile
# jq (autoconf)
FROM public.ecr.aws/d3j8x8q7/olympus-base-cpp:latest
WORKDIR /app
COPY . .
RUN clang --version && autoconf --version | head -1
CMD ["/bin/bash"]
```
```dockerfile
# nlohmann/json — pre-fetch the test-data repo so FetchContent works OFFLINE
FROM public.ecr.aws/d3j8x8q7/olympus-base-cpp:latest
WORKDIR /app
COPY . .
RUN git clone --depth 1 --branch v3.1.0 https://github.com/nlohmann/json_test_data.git /opt/json_test_data
ENV FETCHCONTENT_SOURCE_DIR_JSON_TEST_DATA=/opt/json_test_data
CMD ["/bin/bash"]
```
The FetchContent-offline pattern (pre-clone external test-data + redirect via a `FETCHCONTENT_SOURCE_DIR_*` env) generalizes to any CMake project that downloads fixtures at configure time.

## Java / JVM — `olympus-base-jvm` (✅ SUPPORTED)

Use `public.ecr.aws/d3j8x8q7/olympus-base-jvm:latest`. Verified against commons-lang (Maven), mockito + caffeine (Gradle).

Pre-installed (verified by inspecting the image 2026-09-02): Maven 3.9.9, Gradle **8.14.2 and 9.5.0 only** at `/opt/gradle-<version>`, pre-warmed Gradle cache at `/opt/gradle-cache`, `/opt/jdk-25`. Envs: `GRADLE_USER_HOME=/opt/gradle-cache`, `JAVA_HOME=/usr/lib/jvm/default-jdk` (JDK 17), `JDK25_HOME=/opt/jdk-25`. An older note claimed 8.10.2 / 8.14.3 / 9.0.0 were also present; they are NOT. Re-inspect (`docker run --rm <image> ls /opt`) before relying on any version list here.

⚠️ FOOTGUNS:
- **Default JDK is 17, not 25.** Opt into 25 with `ENV JAVA_HOME=/opt/jdk-25` ONLY when you need 19+ features.
- **NO Gradle 7.x SHIPS IN THE IMAGE — a repo pinning an old wrapper has NO system fallback.** The image carries 8.14.2 and 9.5.0. If the target repo's `gradle/wrapper/gradle-wrapper.properties` pins 7.x, a system Gradle cannot substitute for it: Gradle 8 removed `Jar.classifier`, `sourceCompatibility` assignment and more, so an old build script fails at EVALUATION, before any dependency resolution or test. Measured on DataFixerUpper (wrapper 7.4.2) inside the image, offline, as UID 4242: `/opt/gradle-8.14.2/bin/gradle --no-daemon --offline -q test` -> `Could not set unknown property 'classifier' for task ':sourcesJar'` -> BUILD FAILED. A `test.sh` that falls back to "any gradle under /opt" therefore has a branch that can only fail. Either bundle the matching distribution world-readable at image-build time, or take Gradle out of the runtime entirely (see the next bullet).
- **Consider a Gradle-free harness for JVM repos.** `test.sh` does not have to use the repo's build tool. Compiling with `javac` and running JUnit directly removes every Gradle footgun at once (writable home, ownership, daemon, native library, wrapper distribution, version match). Working pattern from datafixerupper-ordered-alternatives: at image build, copy `find /opt/gradle-cache/caches/modules-2 -name '*.jar'` into `/opt/testlibs` and `chmod -R a+rX` it; at run time `javac` the main + selected test sources into a `mktemp -d`, then run a small `JUnitCore` + `RunListener` (emitted from a heredoc inside test.sh) that writes JUnit XML itself. Runtime needs shrink to: a JDK on PATH, a readable jar dir, one writable temp dir. Verified offline at UIDs 4242/1000/0/65534 plus a 16M `/tmp`, an unset `HOME`, and a fully READ-ONLY root filesystem; also ~2.5x faster than Gradle.
- **If you DO keep Gradle at run time, gate on OWNERSHIP, not the write bit.** `chmod -R a+rwX` is NOT sufficient: Gradle calls `chmod()` on files inside its own `GRADLE_USER_HOME`, and `chmod()` requires ownership. A non-owning UID gets `Could not set UNIX mode on <cache>/daemon/<ver> (errno 1: Operation not permitted)`. Test `[ "$(stat -c %u "$HOME_DIR")" = "$(id -u)" ]` and, when it fails, seed a private `mktemp -d` home with BOTH `caches/modules-2` and `native/` (omitting `native/` fails offline with `Failed to load native library 'libnative-platform.so'`). `chmod -R a+rX /root` (the Rust pattern) is worse still — it makes Gradle's daemon fail on lock files.
- **Verify in the container, not on paper.** Every item above was found by `docker run --rm --network none --user 4242:4242 <image> ./test.sh base`, and three of them survived multiple review rounds because passing runs at other UIDs had never exercised the failing branch. A fallback chain you have not executed is untested code, not a safety net.
- **Warm the task graph offline:** `./gradlew --no-daemon test --tests __nope__` compiles the graph + pulls every test dep WITHOUT executing a test (the trick the verified mockito/caffeine Dockerfiles use).

Build: Maven `mvn -B -DskipTests package` (or `-Drat.skip=true -DfailIfNoTests=false test` to pre-resolve test deps) · Gradle `./gradlew --no-daemon assemble compileTestJava` + a no-op `test --tests __no_match__` to warm the graph. JUnit XML: gradle `build/test-results/test/`, maven-surefire `target/surefire-reports/` — test.sh moves it to `$OUTPUT_PATH`.

```dockerfile
# commons-lang (Maven)
FROM public.ecr.aws/d3j8x8q7/olympus-base-jvm:latest
WORKDIR /app
COPY . .
RUN mvn -B -Drat.skip=true -DfailIfNoTests=false test
CMD ["/bin/bash"]
```

Historical Java + C++ author guide (reference only): <https://docs.google.com/document/d/1aL-RKQmgqadcrf9kdqHxnG8GnCPhL6-mhulnNbnG2hY/edit?tab=t.0>

---

## Slim Image Pre-Installed Tools

Never reinstall these:

| Image | Tools |
|---|---|
| `olympus-base-python` | pip, uv, poetry, pdm, pipx, rye, pytest |
| `olympus-base-typescript` | node, npm, pnpm, yarn, bun, jest-junit, mocha-junit-reporter |
| `olympus-base-go` | go 1.26+, go-junit-report |
| `olympus-base-rust` | cargo, rustc 1.93+ |
| `olympus-base-cpp` | gcc, g++, cmake, make, ninja, pkg-config, gtest, catch2 |
| `olympus-base-jvm` | JDK 21, gradle, maven, junit5 |
| All slim images | git, curl, wget, common build tools |

You NEVER need to install any of these. If you find yourself writing `RUN curl ... | sh` or `RUN npm install -g bun` — stop, it's already there.

---

## Rules

**MUST:**
- `FROM public.ecr.aws/d3j8x8q7/olympus-base-{lang}:latest` — pick `python` / `typescript` / `go` / `rust` / `cpp` / `java` matching the repo language (cpp/java ✅ SUPPORTED again). Legacy generic `olympus-base` / `mars-base` only for re-verifying historical submissions.
- `WORKDIR /app`
- `COPY . .` to copy repo
- Install ALL dependencies during build (nothing downloaded at test time)
- `CMD ["/bin/bash"]`
- Must work fully offline (`--network none`)
- Must work WITHOUT test.patch or solution.patch applied
- Must be minimal — no unnecessary installs
- Use `ENV` for runtime configuration when needed (e.g., `ENV DATABASE_URL=sqlite:///test.db`)

**MUST NOT:**
- Install package managers (all pre-installed in base images)
- Run tests in Dockerfile (setup only)
- Reference test/solution patch files
- Use `ENTRYPOINT`
- Use `apt-get` unless truly necessary
- `RUN git clone` (repo already copied via `COPY . .`)
- AI-generated comments

---

## Common Failures Reference

| Error | Cause | Fix |
|---|---|---|
| `permission denied: ./test.sh` | test.sh not executable | `chmod +x test.sh` (mode 100755 in patch) |
| `ModuleNotFoundError` | Missing Python dep | Add to `pip install` |
| `could not determine executable to run` | npm lifecycle scripts failing | `--ignore-scripts` |
| `error: could not compile` / `linker not found` | Missing system dep | `apt-get install -y {pkg}` before COPY |
| `Permission denied (os error 13)` on `/app/target` | Non-root + Docker-built target | Switch to Pattern A |
| `pip install` resolver conflicts | Version mismatch | Pin versions explicitly (ormar pattern) |
| Tests try to download at runtime | Deps not installed at build | Add to Dockerfile install step |
| `\r` carriage return errors (Windows) | Patch has `\r\n` line endings | `sed -i 's/\r$//' test.sh` |

---

## Common Mistakes (BAD/GOOD)

### Using ENTRYPOINT instead of CMD
```dockerfile
# BAD
ENTRYPOINT ["/bin/bash"]

# GOOD
CMD ["/bin/bash"]
```

### Installing package managers
```dockerfile
# BAD — these are already in mars-base/olympus-base!
RUN curl -sSL https://install.python-poetry.org | python3 -
RUN npm install -g bun
RUN pip install poetry

# GOOD — just use them directly
RUN poetry install
RUN bun install
```

### Running tests in Dockerfile
```dockerfile
# BAD — Dockerfile is setup only
RUN pytest
RUN ./test.sh base
RUN bun test

# GOOD — just install deps
RUN pip install -e .
CMD ["/bin/bash"]
```

### Referencing test files
```dockerfile
# BAD — don't copy specific test files
COPY test.sh .
RUN chmod +x test.sh

# GOOD — COPY . . handles everything
COPY . .
```

### Using apt-get unnecessarily
```dockerfile
# BAD — base image has everything for common cases
RUN apt-get update && apt-get install -y gcc python3-dev

# GOOD — only if absolutely required and base image truly doesn't have it
# (check first!)
```

---

## Decision Flowchart

```
1. Is it Rust?
   └── olympus-base-rust + `cargo install cargo2junit && cargo fetch && cargo build --workspace` (NO chmod). test.sh: RUSTC_BOOTSTRAP=1 + --format json | cargo2junit. See top § ⚠️ Rust JUnit = cargo2junit.

2. Is it Python?
   ├── Has pyproject.toml with [tool.poetry]? → poetry install --no-interaction
   ├── Has pyproject.toml with [tool.pdm]? → pdm install
   ├── Has pyproject.toml with uv? → uv sync --frozen
   ├── Has pyproject.toml? → pip install -e .
   ├── Has requirements.txt? → pip install -r requirements.txt
   └── Need test deps? → && pip install pytest {other-deps}

3. Is it TypeScript/JavaScript?
   ├── Has bun.lockb? → bun install
   ├── Has pnpm-lock.yaml? → pnpm install --frozen-lockfile
   ├── Has package-lock.json? → npm install (or npm ci)
   ├── Need dev deps? → ENV NODE_ENV=development + --include=dev
   ├── Scripts fail? → add --ignore-scripts
   └── Needs compilation? → add RUN npm run compile

4. Is it Go?
   └── olympus-base-go + go mod download (go-junit-report preinstalled)

5. Is it C/C++?
   └── olympus-base-cpp + cmake -B build -S . && cmake --build build (gtest/catch2 JUnit preinstalled)

6. Is it Java/JVM?
   └── olympus-base-jvm + ./gradlew build (or mvn package); JDK 21 + gradle + maven preinstalled
```

---

## Checklist

- [ ] `FROM` is the language-specific slim image: `olympus-base-python` / `-typescript` / `-go` / `-rust` / `-cpp` / `-jvm` (May 2026 admin update). Legacy `olympus-base` / `mars-base` only for re-verifying historical submissions.
- [ ] `WORKDIR /app`
- [ ] `COPY . .` placed after any pre-COPY installs (apt-get, pinned pip deps)
- [ ] All runtime dependencies installed
- [ ] All test dependencies installed (pytest, plugins, test utilities)
- [ ] JUnit tool installed (Go: `go-junit-report`; Rust: `cargo install cargo2junit` in Dockerfile + `RUSTC_BOOTSTRAP=1 ... --format json | cargo2junit` in test.sh; JS: framework's built-in or `jest-junit`)
- [ ] **Rust (2026-07):** `cargo install cargo2junit && cargo fetch && cargo build --workspace` — NO chmod, NO symlink (chmod -R /root breaks solve-time cargo perms). test.sh uses `RUSTC_BOOTSTRAP=1 ... --format json | cargo2junit`.
- [ ] Repo-specific `sed` patches present if needed
- [ ] `CMD ["/bin/bash"]`
- [ ] No package manager installations
- [ ] No test execution
- [ ] No test/solution patch references
- [ ] No AI-generated comments
- [ ] Minimal — no unnecessary installs
- [ ] `docker build` succeeds
- [ ] `docker run --network none --user 1000:1000` works
- [ ] `./test.sh --output_path /tmp/base.xml base` passes with `<testcase>` count > 1
- [ ] `./test.sh --output_path /tmp/new.xml new` fails before solution

## ⚠️ CORRECTION 2026-07-30 — Pattern A template in CLAUDE.md is WRONG for olympus-base-rust

Verified by an actual `docker build` (customasm-ruledef-disassembly). The CLAUDE.md / olympus-author
Pattern A snippet sets:

    ENV RUSTUP_HOME="/root/.rustup"
    ENV CARGO_HOME="/root/.cargo"
    ENV PATH="/root/.cargo/bin:${PATH}"
    RUN chmod -R a+rX /root && for f in /root/.cargo/bin/*; do ln -sf "$f" /usr/local/bin/; done

`public.ecr.aws/d3j8x8q7/olympus-base-rust:latest` does NOT install the toolchain there. Inspected:

    CARGO_HOME=/opt/cargo   RUSTUP_HOME=/opt/rustup   PATH=/opt/cargo/bin:...
    toolchain 1.95.0-x86_64-unknown-linux-gnu (active, default)
    /root/.cargo and /root/.rustup DO NOT EXIST

Overriding the env to `/root/...` makes rustup lose its toolchain and the build dies with:
"rustup could not choose a version of cargo to run, because one wasn't specified explicitly, and no
default is configured."

WORKING Pattern A (build-verified: image builds, and `--network none --user 1000:1000` runs both
test.sh modes producing valid JUnit XML):

    FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest
    WORKDIR /app
    COPY . .
    RUN cargo fetch \
        && cargo build \
        && chmod -R a+rwX /opt/cargo /opt/rustup /app
    CMD ["/bin/bash"]

Key points: do NOT override CARGO_HOME/RUSTUP_HOME/PATH; the image already sets them. The chmod must
be `a+rwX` (not `a+rX`) and must cover `/opt/cargo`, `/opt/rustup` AND `/app`, because the platform
runs as non-root and cargo needs to write the registry cache and `target/`. This is the same
`/opt/cargo` permission issue HARDENING 3d calls "env-blocker inflation" - fix it in the Dockerfile
rather than letting it suppress pass rates.

LESSON: build the image before submitting. The template was carried across several submissions
untested because Rust picks were validated on the host only.
