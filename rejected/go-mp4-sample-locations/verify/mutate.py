#!/usr/bin/env python3
"""Run focused source mutations against the solved sample-location suite."""

import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(sys.argv[1] if len(sys.argv) > 1 else "/app")
SOURCE = ROOT / "probe.go"
COMMAND = ["go", "test", "-count=1", "-tags", "samplelocations", "./grader_tests"]

MUTATIONS = [
    (
        "constant stsz ignored",
        [(
            """size := stsz.SampleSize
			if size == 0 {
				size = stsz.EntrySize[len(track.Samples)]
			}""",
            """size := uint32(0)
			if stsz.SampleSize == 0 {
				size = stsz.EntrySize[len(track.Samples)]
			}""",
            1,
        )],
    ),
    (
        "signed ctts forced unsigned",
        [("ctts.GetSampleOffset(i)", "int64(uint32(ctts.GetSampleOffset(i)))", 1)],
    ),
    ("absent stss means no sync", [("IsSync: stss == nil", "IsSync: false", 1)]),
    (
        "chunk-local accumulation omitted",
        [("offset, err = addUint64(offset, uint64(sample.Size))", "_, err = addUint64(offset, uint64(sample.Size))", 1)],
    ),
    (
        "trex defaults ignored",
        [("duration, size, flags = trex.DefaultSampleDuration, trex.DefaultSampleSize, trex.DefaultSampleFlags", "duration, size, flags = 0, 0, 0", 1)],
    ),
    ("only last traf retained", [("for _, traf := range trafs {", "for _, traf := range trafs[len(trafs)-1:] {", 1)]),
    ("only first trun handled", [("for _, trun := range truns {", "for _, trun := range truns[:1] {", 1)]),
    (
        "first sample flags leak",
        [("} else if index == 0 && trun.CheckFlag(0x000004) {", "} else if trun.CheckFlag(0x000004) {", 1)],
    ),
    (
        "signed data offset treated unsigned",
        [(
            """value, err := presentationTime(base, int64(trun.DataOffset))
				if err != nil || value < 0 {
					return nil, errors.New(\"invalid fragment data offset\")
				}
				offset = uint64(value)""",
            """offset, err = addUint64(base, uint64(trun.DataOffset))
				if err != nil {
					return nil, err
				}""",
            1,
        )],
    ),
    (
        "one global decode cursor",
        [
            ("decodeTime := decodeTimes[tfhd.TrackID]", "decodeTime := decodeTimes[0]", 1),
            ("decodeTimes[tfhd.TrackID] = decodeTime", "decodeTimes[0] = decodeTime", 1),
        ],
    ),
    (
        "mdat containment skipped",
        [("if sample.Offset >= mdat.start && end <= mdat.end {", "if true || sample.Offset >= mdat.start && end <= mdat.end {", 1)],
    ),
    (
        "partial result returned after range failure",
        [
            (
                """for _, track := range probeInfo.Tracks {
		if err := validateSampleRanges(track.Samples, mdats); err != nil {
			return nil, err
		}""",
                """for _, track := range probeInfo.Tracks {
		if err := validateSampleRanges(track.Samples, mdats); err != nil {
			return probeInfo, err
		}""",
                1,
            ),
            (
                """for _, segment := range probeInfo.Segments {
		if err := validateSampleRanges(segment.Samples, mdats); err != nil {
			return nil, err
		}""",
                """for _, segment := range probeInfo.Segments {
		if err := validateSampleRanges(segment.Samples, mdats); err != nil {
			return probeInfo, err
		}""",
                1,
            ),
        ],
    ),
]


def run_suite():
    return subprocess.run(
        COMMAND,
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        timeout=120,
        check=False,
    )


original = SOURCE.read_text()
failed = []
try:
    baseline = run_suite()
    if baseline.returncode:
        print(baseline.stdout)
        raise SystemExit("unmutated suite failed")

    for name, replacements in MUTATIONS:
        mutated = original
        for anchor, replacement, expected in replacements:
            count = mutated.count(anchor)
            if count < expected:
                raise SystemExit(f"anchor missing for {name}: {anchor[:80]!r}")
            mutated = mutated.replace(anchor, replacement, expected)
        SOURCE.write_text(mutated)
        result = run_suite()
        assertions = len(re.findall(r"Error Trace:", result.stdout))
        killed = result.returncode != 0 and assertions >= 2
        print(f"{'PASS' if killed else 'FAIL'}  {name}: failing assertions={assertions}")
        if not killed:
            failed.append(name)
finally:
    SOURCE.write_text(original)

if failed:
    raise SystemExit("mutation survivors or weak kills: " + ", ".join(failed))
print(f"{len(MUTATIONS)} mutations killed with at least two assertion failures each")
