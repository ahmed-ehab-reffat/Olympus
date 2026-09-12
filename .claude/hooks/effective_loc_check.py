#!/usr/bin/env python3
"""EFFECTIVE-LOC estimator for an Olympus solution.patch, calibrated to the HUMAN re-count.

WHY THIS EXISTS: a human reviewer re-counts "effective LOC excluding repetitive and dead code"
and the platform auto-blocks below ~200 effective LOC (design target 250-300, per the current
Aug-2026 floor). We want to predict THAT number before submitting.

CALIBRATION (validated against a real reviewer re-count; a general anchor, not tied to any one task):
on a known case, a ~393-raw, 2-file patch was re-counted by a human at ~346 EFFECTIVE and rejected
under the floor then in effect (a historical ~400; the current floor is ~200 auto-block / 250-300
design target). The two candidate methods predicted:
  - strip       (drop blank / comment / bracket / docstring lines)        = 332  <- within ~4% of human
  - compression (collapse wrapped statements + amortize repeat families)  = 254  <- ~92 UNDER the human
So a human counts close to the STRIP, NOT the aggressive compression. Reporting the compression as the
estimate UNDER-reports the count and makes the gap to the floor look far larger than it really is (on a
verbose, match-arm-heavy patch it can read far below where the human lands). This script therefore
reports the human-calibrated strip as the PRIMARY number and keeps the compression only as a LOWER
BOUND that matters when a patch leans on repetitive breadth.

How to read the output:
  - human-effective  -> PRIMARY estimate of the reviewer's count. Gate on this. Clear 200 with
                        margin (target ~275) because the calibration is +/-~10% and dead code
                        (single-use forwarders, unread params, unreachable arms) is not subtracted.
  - padding-floor    -> lower bound after collapsing multi-line-wrapped statements to one line and
                        amortizing repetitive registry/dispatch/match families to ~the pattern.
                        If padding-floor << human-effective the patch has a lot of repetitive
                        breadth (e.g. exhaustiveness match arms); the reviewer may land below
                        human-effective, so treat the gap as risk and add DEPTH, not more breadth.

Usage:
  effective_loc_check.py [solution.patch] [--target 275] [--raw-target 320] [--hook]
With no patch arg it auto-finds the single problems/*/solution.patch under CLAUDE_PROJECT_DIR or cwd.
--hook: print nothing unless a patch exists AND human-effective < target (non-blocking Stop hook).
Exit code 1 when below a floor (gates a manual/pre-commit run); --hook always exits 0.
"""
from __future__ import annotations

import glob
import os
import re
import sys
from collections import Counter

TARGET = 275
RAW_TARGET = 320
MIN_FILES = 3

COMMENT = re.compile(r"^\s*(#|//)")
BRACKET_ONLY = re.compile(r"^\s*[)\]}][,)\]};:]*$")
STRING_LIT = re.compile(r"""(['"]).*?\1""")
NUM_LIT = re.compile(r"\b\d+(\.\d+)?\b")
IDENT = re.compile(r"\b[A-Za-z_]\w*\b")


def added_by_file(patch_text: str) -> dict[str, list[str]]:
    files: dict[str, list[str]] = {}
    current = None
    for line in patch_text.splitlines():
        if line.startswith("+++ b/"):
            current = line[6:]
            files.setdefault(current, [])
        elif line.startswith("+") and not line.startswith("+++"):
            if current is not None:
                files[current].append(line[1:])
    return files


def _skeleton(line: str) -> str:
    s = STRING_LIT.sub("S", line.strip())
    s = NUM_LIT.sub("N", s)
    s = IDENT.sub("x", s)
    return re.sub(r"\s+", "", s)


def _depth_delta(line: str) -> int:
    s = STRING_LIT.sub("", line)  # ignore brackets inside string literals (approx)
    return s.count("(") + s.count("[") + s.count("{") - s.count(")") - s.count("]") - s.count("}")


def _is_noise(s: str) -> bool:
    return not s or bool(COMMENT.match(s)) or bool(BRACKET_ONLY.match(s))


def human_effective(lines: list[str]) -> int:
    """Strip blanks, comment-only lines, pure-bracket lines, and docstring blocks.

    This is what a human reviewer's effective re-count tracks (see the CALIBRATION note above):
    a near-raw count with the obvious non-logic lines removed and almost no amortization.
    """
    n = 0
    in_doc = False
    doc_delim = ""
    for raw in lines:
        s = raw.strip()
        if in_doc:
            if doc_delim in s:
                in_doc = False
            continue
        if s.startswith('"""') or s.startswith("'''"):
            delim = s[:3]
            if s[3:].count(delim) == 0:
                in_doc, doc_delim = True, delim
            continue
        if _is_noise(s):
            continue
        n += 1
    return n


def padding_floor(lines: list[str]) -> int:
    """Lower bound: collapse multi-line-wrapped statements to one line, then amortize each
    repetitive (literal/identifier-stripped) skeleton family to <= 3. Aggressive on purpose --
    only realistic when the patch is genuinely breadth-padded."""
    in_doc = False
    doc_delim = ""
    depth = 0
    logical: list[str] = []
    for raw in lines:
        s = raw.strip()
        if in_doc:
            if doc_delim in s:
                in_doc = False
            continue
        if s.startswith('"""') or s.startswith("'''"):
            delim = s[:3]
            if s[3:].count(delim) == 0:
                in_doc, doc_delim = True, delim
            continue
        continuation = depth > 0
        depth += _depth_delta(raw)
        if continuation:
            continue
        if _is_noise(s):
            continue
        logical.append(_skeleton(s))
    return sum(min(n, 3) for n in Counter(logical).values())


def find_patch() -> str | None:
    root = os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd()
    hits = sorted(glob.glob(os.path.join(root, "problems", "*", "solution.patch")))
    return hits[0] if len(hits) == 1 else (hits[-1] if hits else None)


def main() -> int:
    args = sys.argv[1:]
    hook = "--hook" in args
    args = [a for a in args if a != "--hook"]
    target, raw_target = TARGET, RAW_TARGET
    patch = None
    i = 0
    while i < len(args):
        if args[i] == "--target":
            target = int(args[i + 1]); i += 2
        elif args[i] == "--raw-target":
            raw_target = int(args[i + 1]); i += 2
        else:
            patch = args[i]; i += 1
    patch = patch or find_patch()
    if not patch or not os.path.exists(patch):
        if not hook:
            print("effective_loc_check: no solution.patch found", file=sys.stderr)
        return 0

    # In hook mode (auto-run every turn) only nag about a patch ACTIVELY authored (mtime < 90 min).
    if hook:
        import time
        if time.time() - os.path.getmtime(patch) > 90 * 60:
            return 0

    files = added_by_file(open(patch, encoding="utf-8", errors="replace").read())
    raw = sum(len(v) for v in files.values())
    human = sum(human_effective(v) for v in files.values())
    floor = sum(padding_floor(v) for v in files.values())
    below = human < target or raw < raw_target or len(files) < MIN_FILES
    breadth_heavy = human > 0 and floor < 0.75 * human

    if hook and not below:
        return 0

    out = sys.stdout
    print("=== Olympus effective-LOC check (calibrated to the human re-count) ===", file=out)
    print(f"files: {len(files)}  (need >= {MIN_FILES})", file=out)
    print(f"raw added:        {raw:4d}  (target >= {raw_target})", file=out)
    print(f"human-effective:  {human:4d}  <- PRIMARY: the reviewer's effective count (strip method, human-calibrated). Gate on this; target >= {target}", file=out)
    print(f"padding-floor:    {floor:4d}  <- lower bound (wraps collapsed, repetitive families amortized)", file=out)
    for f, v in files.items():
        print(f"   {len(v):4d} raw / {human_effective(v):4d} human-eff  {f}", file=out)
    if breadth_heavy:
        print(
            f"NOTE: padding-floor ({floor}) is well below human-effective ({human}) -> this patch "
            "leans on repetitive breadth (e.g. exhaustiveness match arms / registry rows). The "
            "reviewer may land below human-effective; add orthogonal DEPTH, not more breadth.",
            file=out,
        )
    if below:
        print(
            f"WARNING: under floor (human-effective {human} < {target}, or raw < {raw_target}, or "
            f"< {MIN_FILES} files). The human re-counts effective LOC and the platform auto-blocks "
            "under ~200; a green raw gauge or an AI LOC waiver is NON-BINDING. Add an ORTHOGONAL "
            "algorithm/surface or PIVOT to a feature whose irreducible distinct logic is already "
            "200+ (design target 250-300); never pad.",
            file=out,
        )
    else:
        print(f"OK: human-effective {human} >= {target} (clears the 200 floor with margin).", file=out)
    return 1 if (below and not hook) else 0


if __name__ == "__main__":
    sys.exit(main())
