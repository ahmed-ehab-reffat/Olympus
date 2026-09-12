#!/usr/bin/env python3
"""EVAL-FRESHNESS fingerprint + staleness guard for an Olympus problem folder.

WHY THIS EXISTS: an agent eval batch counts as evidence (for the >=1-pass solvability floor, the
~10% pass-rate ceiling, and the >100-message floor) ONLY if it ran on the CURRENT deliverable bytes.
The platform eval output carries NO timestamp / commit / hash (only a duration plus JUnit counts),
so "which came first, the batch or the change?" is NOT answerable by ordering -- freshness is a
content-EQUALITY question. The reliable answer is a digest: fingerprint the 5 deliverables at eval
time, and a reviewer recomputes it and compares. This script makes that fingerprint impossible to
forget or hand-fake: it emits the paste-ready block, and (as a Stop hook) warns when the latest
fingerprint recorded in eval-results.md no longer matches the current deliverables.

The fingerprint is the git blob SHA of each deliverable (identical to `git hash-object`, computed in
pure Python so it works on an uncommitted / untracked tree). The 5 deliverables are:
  solution.patch  test.patch  meta.md  Dockerfile  BASE_COMMIT.txt

CANONICAL recorded line (one per eval batch, written into eval-results.md under the batch header):
  Fingerprint: sol=<sha> test=<sha> meta=<sha> docker=<sha> base=<sha>
The Stop hook greps the LAST such line and compares it to the current deliverables:
  - match    -> the latest batch ran on these exact bytes (FRESH); silent.
  - mismatch -> a deliverable changed since that batch (STALE); warn + name the changed files.
  - none     -> no fingerprint recorded yet; emit the block to paste.
A dirty working tree (uncommitted deliverable edits) is also flagged -- you cannot pin bytes for an
eval from a tree that is still moving; commit first, then fingerprint, then eval.

Usage:
  freshness_check.py [problem_dir] [--hook]
With no dir it auto-finds problems/*/ under CLAUDE_PROJECT_DIR or cwd.
--hook: print nothing unless a RECENTLY-active problem (a deliverable or eval-results.md touched in
the last 90 min) is STALE / dirty / missing a fingerprint (non-blocking Stop hook; always exits 0).
Manual run exits 1 when a problem is STALE or its tree is dirty (gates a pre-submit check).
"""
from __future__ import annotations

import glob
import hashlib
import os
import re
import subprocess
import sys
import time

DELIVERABLES = ["solution.patch", "test.patch", "meta.md", "Dockerfile", "BASE_COMMIT.txt"]
LABELS = ["sol", "test", "meta", "docker", "base"]
RECENT_SECONDS = 90 * 60
HEX = re.compile(r"\b[0-9a-f]{7,40}\b")
FP_LINE = re.compile(r"Fingerprint:", re.IGNORECASE)
DEF_TEST = re.compile(r"^\+.*\bdef test_")
# Markers of a real platform eval run (not pre-eval authoring notes) -- used to stay quiet during
# authoring: a problem that has never been evaluated has nothing that can go stale.
EVAL_MARK = re.compile(r"Solver\s*:|^#+\s*Eval batch|FAIL_[A-Z]|PASS_[A-Z]|Missed Requirement|agent_blame",
                       re.MULTILINE | re.IGNORECASE)


def git_blob_sha(path: str) -> str:
    """SHA-1 of git's blob object for the file content -- equals `git hash-object <path>`."""
    data = open(path, "rb").read()
    h = hashlib.sha1()
    h.update(b"blob %d\0" % len(data))
    h.update(data)
    return h.hexdigest()


def current_fingerprint(problem_dir: str) -> dict[str, str]:
    return {lbl: git_blob_sha(os.path.join(problem_dir, f)) for lbl, f in zip(LABELS, DELIVERABLES)}


def _parse_fp(line: str) -> dict[str, str] | None:
    """Parse one Fingerprint line by label (sol=..) or, failing that, by 5 positional hex tokens."""
    labeled = {}
    for lbl in LABELS:
        m = re.search(rf"{lbl}=([0-9a-f]{{7,40}})", line)
        if m:
            labeled[lbl] = m.group(1)
    if len(labeled) == len(LABELS):
        return labeled
    toks = HEX.findall(line)
    if len(toks) >= len(LABELS):
        return dict(zip(LABELS, toks[: len(LABELS)]))
    return None


def recorded_fingerprints(eval_results: str) -> list[tuple[str, dict[str, str]]]:
    """Every recorded fingerprint, oldest->newest, each tagged with its nearest preceding `#` header
    (the batch title) so each eval batch can be labelled FRESH/STALE individually."""
    if not os.path.exists(eval_results):
        return []
    header = "(top of file)"
    out: list[tuple[str, dict[str, str]]] = []
    for line in open(eval_results, encoding="utf-8", errors="replace").read().splitlines():
        s = line.strip()
        if s.startswith("#"):
            h = s.lstrip("#").strip()
            if h:
                header = h
            continue
        if FP_LINE.search(line):
            fp = _parse_fp(line)
            if fp:
                out.append((header, fp))
    return out


def matches(cur: str, rec: str) -> bool:
    """Prefix-tolerant: the author may have recorded a 7- or 40-char SHA."""
    return cur == rec or cur.startswith(rec) or rec.startswith(cur)


def dirty_deliverables(problem_dir: str) -> list[str]:
    """Deliverables with uncommitted changes (empty if not a git repo / all clean).

    Queried per file so we never have to parse git's (quoted, repo-root-relative) path output:
    a non-empty porcelain status for a single pathspec means that file is modified/staged/untracked.
    """
    dirty = []
    for f in DELIVERABLES:
        try:
            out = subprocess.run(
                ["git", "-C", problem_dir, "status", "--porcelain", "--", f],
                capture_output=True, text=True, timeout=10,
            ).stdout
        except (OSError, subprocess.SubprocessError):
            return []
        if out.strip():
            dirty.append(f)
    return dirty


def short_sha(problem_dir: str) -> str:
    try:
        r = subprocess.run(
            ["git", "-C", problem_dir, "rev-parse", "--short", "HEAD"],
            capture_output=True, text=True, timeout=10,
        )
        return r.stdout.strip() or "unknown"
    except (OSError, subprocess.SubprocessError):
        return "unknown"


def build_identity(problem_dir: str) -> dict[str, int]:
    sol = open(os.path.join(problem_dir, "solution.patch"), encoding="utf-8", errors="replace").read()
    test = open(os.path.join(problem_dir, "test.patch"), encoding="utf-8", errors="replace").read()
    meta = open(os.path.join(problem_dir, "meta.md"), encoding="utf-8", errors="replace").read()
    files = len([l for l in sol.splitlines() if l.startswith("+++ b/") and "/dev/null" not in l])
    new_tests = len([l for l in test.splitlines() if DEF_TEST.match(l)])
    return {"files": files, "new_tests": new_tests, "meta_words": len(meta.split())}


def paste_block(problem_dir: str, fp: dict[str, str], bid: dict[str, int]) -> str:
    sha = short_sha(problem_dir)
    line = "Fingerprint: " + " ".join(f"{lbl}={fp[lbl]}" for lbl in LABELS)
    return (
        f"  deliverables @ {sha} (commit BEFORE eval so this pins the bytes)\n"
        f"  {line}\n"
        f"  Build: files={bid['files']} test.patch_def_test~={bid['new_tests']} "
        f"meta_words={bid['meta_words']} | platform baseline=<fill from eval JSON> new=<fill>\n"
        f"  Stamp the batch header with date AND time (e.g. 2026-06-15 14:30)."
    )


def find_problem_dirs() -> list[str]:
    root = os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd()
    dirs = []
    for parent in ("problems", "diamond-problems"):
        for sol in glob.glob(os.path.join(root, parent, "*", "solution.patch")):
            dirs.append(os.path.dirname(sol))
    return sorted(dirs)


def recently_active(problem_dir: str) -> bool:
    now = time.time()
    for f in DELIVERABLES + ["eval-results.md"]:
        p = os.path.join(problem_dir, f)
        if os.path.exists(p) and now - os.path.getmtime(p) <= RECENT_SECONDS:
            return True
    return False


def has_eval_history(eval_results: str) -> bool:
    """True if eval-results.md shows a real platform eval run (not just pre-eval authoring notes)."""
    if not os.path.exists(eval_results):
        return False
    return bool(EVAL_MARK.search(open(eval_results, encoding="utf-8", errors="replace").read()))


def assess(problem_dir: str) -> tuple[str, list[str]]:
    """Return (state, lines). state in {fresh, stale, none, incomplete}.

    Labels EACH fingerprinted eval batch FRESH/STALE against the current deliverables, so a reviewer
    can tell which batches' results are still valid evidence and which ran on superseded bytes.
    """
    missing = [f for f in DELIVERABLES if not os.path.exists(os.path.join(problem_dir, f))]
    if missing:
        return "incomplete", [f"missing deliverable(s): {', '.join(missing)}"]
    cur = current_fingerprint(problem_dir)
    bid = build_identity(problem_dir)
    dirty = dirty_deliverables(problem_dir)
    fps = recorded_fingerprints(os.path.join(problem_dir, "eval-results.md"))
    lines: list[str] = []
    if dirty:
        lines.append(
            "DIRTY TREE: uncommitted edits to " + ", ".join(dirty) + " -- the current bytes match no "
            "committed state and no eval. Commit before triggering an eval so the fingerprint pins them."
        )
    if not fps:
        lines.append(
            "No fingerprint recorded in eval-results.md -- digest differentiation unavailable; fall back "
            "to the platform baseline/new test counts vs the current test.patch. Record this going forward:"
        )
        lines.append(paste_block(problem_dir, cur, bid))
        return ("none", lines)
    any_fresh = False
    lines.append(f"Recorded eval batches vs CURRENT deliverables ({len(fps)} fingerprinted):")
    for header, fp in fps:
        changed = [f for lbl, f in zip(LABELS, DELIVERABLES) if not matches(cur[lbl], fp.get(lbl, ""))]
        if changed:
            lines.append(f"  [STALE] {header}  (changed since: {', '.join(changed)})")
        else:
            lines.append(f"  [FRESH] {header}")
            any_fresh = True
    if any_fresh:
        lines.append(
            "At least one fingerprinted batch matches the current build -> its eval results ARE valid "
            "evidence (the FRESH one(s) above); ignore the STALE batches for the gates."
        )
        return ("fresh", lines)
    lines.append(
        "NONE of the recorded batches matches the current build -> ALL eval evidence is STALE for "
        "solvability / pass-rate / message-count; re-eval, then record:"
    )
    lines.append(paste_block(problem_dir, cur, bid))
    return ("stale", lines)


def main() -> int:
    args = sys.argv[1:]
    hook = "--hook" in args
    args = [a for a in args if a != "--hook"]
    target = args[0] if args else None

    dirs = [target] if target else find_problem_dirs()
    if not dirs:
        if not hook:
            print("freshness_check: no problems/*/ or diamond-problems/*/ folder found", file=sys.stderr)
        return 0

    worst = "fresh"
    rank = {"fresh": 0, "none": 1, "incomplete": 1, "stale": 2}
    printed = False
    for d in dirs:
        if hook and not recently_active(d):
            continue
        state, lines = assess(d)
        if hook:
            # Stay quiet unless there is something actionable: a stale fingerprinted batch, or a
            # problem that HAS been evaluated but recorded no fingerprint. Pre-eval authoring
            # (state fresh/incomplete, or no eval history yet) is silent.
            if state in ("fresh", "incomplete"):
                continue
            if state == "none" and not has_eval_history(os.path.join(d, "eval-results.md")):
                continue
        if not printed:
            print("=== Olympus eval-freshness check (digest equality, not timestamp ordering) ===")
            printed = True
        print(f"[{state.upper()}] {os.path.relpath(d)}")
        for ln in lines:
            print(ln)
        if rank.get(state, 0) > rank.get(worst, 0):
            worst = state

    if not printed and not hook:
        print("=== Olympus eval-freshness check ===")
        print("all problems FRESH (or no recently-active problem).")
    return 1 if (worst == "stale" and not hook) else 0


if __name__ == "__main__":
    sys.exit(main())
