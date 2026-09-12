#!/usr/bin/env python3
"""Compare the test entities of two JUnit reports.

The grading wrapper classifies individual testcases, not whole reports. A testcase
that exists in only one of the two runs can land in neither the pass-to-pass set nor
the fail-to-pass set, and is reported as unclassified. The most common cause in Go is
a package that does not compile at the base commit, which go-junit-report records as a
single synthetic "[build failed]" testcase.

Usage: census.py <before.xml> <after.xml>

  before.xml  the `new` run with test.patch only
  after.xml   the `new` run with test.patch + solution.patch
"""

import sys
import xml.etree.ElementTree as ET

SYNTHETIC = ("[build failed]", "[no tests to run]", "[no test files]")


def entities(path):
    """Map of testcase name -> outcome for a JUnit report."""
    out = {}
    for case in ET.parse(path).getroot().iter("testcase"):
        name = case.get("name")
        if case.find("error") is not None:
            out[name] = "errored"
        elif case.find("failure") is not None:
            out[name] = "failed"
        elif case.find("skipped") is not None:
            out[name] = "skipped"
        else:
            out[name] = "passed"
    return out


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        return 2

    before, after = entities(sys.argv[1]), entities(sys.argv[2])
    problems = []

    for name in sorted(set(before) - set(after)):
        problems.append(f"only before the solution: {name} ({before[name]})")
    for name in sorted(set(after) - set(before)):
        problems.append(f"only after the solution:  {name} ({after[name]})")

    for label, table in (("before", before), ("after", after)):
        for name in sorted(table):
            if name in SYNTHETIC:
                problems.append(f"synthetic entity {label} the solution: {name}")

    # Every entity common to both runs has to move from not-passing to passing,
    # otherwise it belongs in the regression set rather than this one.
    for name in sorted(set(before) & set(after)):
        if before[name] == "passed":
            problems.append(f"passes without the solution: {name}")
        elif after[name] != "passed":
            problems.append(f"still not passing with the solution: {name} ({after[name]})")

    print(f"  entities before: {len(before)}   after: {len(after)}")
    if problems:
        for problem in problems:
            print(f"  PROBLEM: {problem}")
        return 1

    print(f"  all {len(after)} entities fail without the solution and pass with it")
    return 0


if __name__ == "__main__":
    sys.exit(main())
