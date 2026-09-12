#!/usr/bin/env python3
"""Mutation gates for the ApplyCorrections C+H+V ceiling probe.

Run inside /app after test.patch and solution.patch are applied. Every mutation
must compile, must be killed behaviorally by at least two real named tests, and
must leave no synthetic JUnit entities.
"""

import shutil
import subprocess
import sys
import xml.etree.ElementTree as ET

CORRECTION = "/app/correction.go"
TARGET = "/app/correction_target.go"
UNDO = "/app/correction_undo.go"
REFUSED = "/app/correction_refused.go"
SYNTHETIC = {"", "Failure", "[build failed]", "[no tests to run]", "[no test files]"}


def edit(path, find, replace):
    return path, find, replace


NO_UNDO = edit(
    CORRECTION,
    "undoFile, err := buildUndoFile(f, accepted)",
    "undoFile, err := (*File)(nil), error(nil)",
)

ORDINARY_INDEX_ONLY = edit(
    CORRECTION,
    "for i := range f.IATBatches {",
    "for i := range f.IATBatches[:0] {",
)

NO_CONCRETE_VALIDATION = edit(
    CORRECTION,
    "if data.TransactionCode != 0 && !target.transactionValid() {",
    "if false && data.TransactionCode != 0 && !target.transactionValid() {",
)

NO_REFUSED = edit(
    CORRECTION,
    "refusedFile, err := buildRefusedFile(f, refused)",
    "refusedFile, err := (*File)(nil), error(nil)",
)

NO_OFFSET_REBALANCE = edit(
    CORRECTION,
    "\t\trebalanceOffsets(batch.GetEntries())",
    "\t\t_ = batch.GetEntries()",
)

MUTATIONS = [
    (
        "C no-undo-output",
        [NO_UNDO],
        "omits the executable inverse journal",
    ),
    (
        "C undo-forward-order",
        [edit(
            UNDO,
            "for i := len(accepted) - 1; i >= 0; i-- {",
            "for i := 0; i < len(accepted); i++ {",
        )],
        "emits inverses in acceptance order",
    ),
    (
        "C post-state-inverse",
        [edit(
            CORRECTION,
            "\t\t\t\t\tbefore: before,",
            "\t\t\t\t\tbefore: target.snapshot(),",
        )],
        "records the post-change state instead of the immediate pre-state",
    ),
    (
        "C intermediate-undo-dfi",
        [edit(
            UNDO,
            "OriginalDFI:   accepted.target.finalDFI(),",
            "OriginalDFI:   accepted.before.routing[:8],",
        )],
        "names intermediate routing identities in a chained undo",
    ),
    (
        "C unsynchronized-undo-traces",
        [edit(
            UNDO,
            "entry.SetTraceNumber(odfi, sequence)",
            "entry.TraceNumber = accepted.entry.TraceNumber",
        )],
        "reuses source traces without synchronizing Addenda98",
    ),
    (
        "C partial-C03-inverse",
        [edit(
            TARGET,
            "case \"C03\":\n\t\tdata.RoutingNumber = before.routing\n\t\tdata.AccountNumber = before.account",
            "case \"C03\":\n\t\tdata.RoutingNumber = before.routing",
        )],
        "drops the account component of a C03 inverse",
    ),
    (
        "C partial-C06-inverse",
        [edit(
            TARGET,
            "case \"C06\":\n\t\tdata.AccountNumber = before.account\n\t\tdata.TransactionCode = before.transaction",
            "case \"C06\":\n\t\tdata.AccountNumber = before.account",
        )],
        "drops the transaction component of a C06 inverse",
    ),
    (
        "C partial-C07-inverse",
        [edit(
            TARGET,
            "case \"C07\":\n\t\tdata.RoutingNumber = before.routing\n\t\tdata.AccountNumber = before.account\n\t\tdata.TransactionCode = before.transaction",
            "case \"C07\":\n\t\tdata.RoutingNumber = before.routing\n\t\tdata.AccountNumber = before.account",
        )],
        "drops the transaction component of a C07 inverse",
    ),
    (
        "C06 forward-account-omitted",
        [edit(
            CORRECTION,
            "\treturn target, data, \"\"",
            "\tif strings.EqualFold(addenda98.ChangeCode, \"C06\") { data.AccountNumber = \"\" }\n\treturn target, data, \"\"",
        )],
        "accepts C06 without applying its account component",
    ),
    (
        "C06 forward-transaction-omitted",
        [edit(
            CORRECTION,
            "\treturn target, data, \"\"",
            "\tif strings.EqualFold(addenda98.ChangeCode, \"C06\") { data.TransactionCode = 0 }\n\treturn target, data, \"\"",
        )],
        "accepts C06 without applying its transaction component",
    ),
    (
        "C refused-target-in-undo",
        [edit(
            CORRECTION,
            "\t\t\t\tif code != \"\" {\n\t\t\t\t\trefused = append(refused, refusedNotification{",
            "\t\t\t\tif code != \"\" {\n\t\t\t\t\tif target != nil { accepted = append(accepted, acceptedNotification{header: batch.GetHeader(), entry: entry, target: target, before: before}) }\n\t\t\t\t\trefused = append(refused, refusedNotification{",
        )],
        "journals refusals which happened after matching",
    ),
    (
        "C accepted-noop-omitted",
        [edit(
            CORRECTION,
            "\t\t\t\taccepted = append(accepted, acceptedNotification{",
            "\t\t\t\tif before == target.snapshot() { continue }\n\t\t\t\taccepted = append(accepted, acceptedNotification{",
        )],
        "drops accepted no-op notifications from Undo",
    ),
    (
        "C source-addenda-aliased",
        [edit(
            UNDO,
            "\tentry.Addenda98 = &Addenda98{",
            "\tentry.SetTraceNumber(odfi, sequence)\n\tentry.Addenda98 = &Addenda98{",
        )],
        "mutates the source Addenda98 through a shallow copy",
    ),
    (
        "H ordinary-index-only",
        [ORDINARY_INDEX_ONLY],
        "does not index IAT receiver entries",
    ),
    (
        "H IAT-identification-ignored",
        [edit(
            TARGET,
            "\tif data.Identification != \"\" && target.iatEntry.Addenda15 != nil {",
            "\tif false && data.Identification != \"\" && target.iatEntry.Addenda15 != nil {",
        )],
        "does not write C09 into IAT Addenda15",
    ),
    (
        "H ordinary-C08-accepted",
        [edit(TARGET, "\treturn code != \"C08\"", "\treturn true")],
        "accepts C08 on an ordinary target",
    ),
    (
        "H unsupported-IAT-codes-accepted",
        [edit(
            TARGET,
            "\t\tdefault:\n\t\t\treturn false\n\t\t}",
            "\t\tdefault:\n\t\t\treturn true\n\t\t}",
        )],
        "accepts ordinary-only correction layouts on IAT",
    ),
    (
        "H IAT-controls-not-rebuilt",
        [edit(
            CORRECTION,
            "\tfor batch := range iatBatches {\n\t\tbatch.Header.ServiceClassCode = coveringIATServiceClassCode(batch.Header.ServiceClassCode, batch.Entries)\n\t\tif err := batch.Create(); err != nil {\n\t\t\treturn err\n\t\t}\n\t}",
            "\tfor batch := range iatBatches {\n\t\tbatch.Header.ServiceClassCode = coveringIATServiceClassCode(batch.Header.ServiceClassCode, batch.Entries)\n\t}",
        )],
        "changes IAT entries without rebuilding batch controls",
    ),
    (
        "H IAT-acceptance-absent-from-undo",
        [edit(
            CORRECTION,
            "\t\t\t\taccepted = append(accepted, acceptedNotification{",
            "\t\t\t\tif target.iatEntry == nil { accepted = append(accepted, acceptedNotification{",
        ), edit(
            CORRECTION,
            "\t\t\t\t\tbefore: before,\n\t\t\t\t})",
            "\t\t\t\t\tbefore: before,\n\t\t\t\t}) }",
        )],
        "does not journal accepted IAT corrections",
    ),
    (
        "V no-concrete-validation",
        [NO_CONCRETE_VALIDATION],
        "relies on global transaction-code validity and final rebuild",
    ),
    (
        "V prenote-only-allowlist",
        [edit(
            CORRECTION,
            "if data.TransactionCode != 0 && !target.transactionValid() {",
            "if data.TransactionCode != 0 && data.TransactionCode%10 == 3 && before.transaction%10 != 3 {",
        )],
        "models the Nova global prenote/live-entry rule",
    ),
    (
        "V failed-target-not-restored",
        [edit(
            CORRECTION,
            "\t\t\t\t\t\ttarget.restore(before)\n\t\t\t\t\t\tcode = \"C69\"\n\t\t\t\t\t} else if !target.offsetsFeasible() {",
            "\t\t\t\t\t\tcode = \"C69\"\n\t\t\t\t\t} else if !target.offsetsFeasible() {",
        )],
        "leaves a concretely invalid tentative transaction on the receiver",
    ),
    (
        "P abort-on-first-refusal",
        [edit(
            CORRECTION,
            "\t\t\t\t\tcontinue\n\t\t\t\t}\n\n\t\t\t\taccepted = append",
            "\t\t\t\t\treturn &CorrectionResult{Refused: refusedFileForMutation(f, refused)}, nil\n\t\t\t\t}\n\n\t\t\t\taccepted = append",
        ), edit(
            CORRECTION,
            "import \"strings\"",
            "import \"strings\"\n\nfunc refusedFileForMutation(f *File, refused []refusedNotification) *File { out, _ := buildRefusedFile(f, refused); return out }",
        )],
        "stops after the first refusal",
    ),
    (
        "P partial-corrected-data-accepted",
        [edit(
            CORRECTION,
            "return addenda98.ParseCorrectedData()",
            "return addenda98.ParseCorrectedData(PartialCorrectedData())",
        )],
        "accepts incomplete multi-field corrected data instead of C65",
    ),
    (
        "G no-refused-output",
        [NO_REFUSED],
        "omits the refused artifact",
    ),
    (
        "G refused-controls-not-built",
        [edit(
            REFUSED,
            "\tif err := file.Create(); err != nil {\n\t\treturn nil, err\n\t}\n",
            "",
        )],
        "returns a refused file without file controls",
    ),
    (
        "O no-offset-feasibility",
        [edit(
            CORRECTION,
            "} else if !target.offsetsFeasible() {",
            "} else if false && !target.offsetsFeasible() {",
        )],
        "accepts a correction which empties an offset population",
    ),
    (
        "O no-offset-rebalance",
        [NO_OFFSET_REBALANCE],
        "does not recalculate preserved offset amounts",
    ),
    (
        "O wrong-offset-direction",
        [edit(
            CORRECTION,
            "\t\tcase \"C\":\n\t\t\tentry.Amount = debits\n\t\tcase \"D\":\n\t\t\tentry.Amount = credits",
            "\t\tcase \"C\":\n\t\t\tentry.Amount = credits\n\t\tcase \"D\":\n\t\t\tentry.Amount = debits",
        )],
        "balances offsets from the same direction",
    ),
    (
        "M trace-only-matching",
        [edit(
            CORRECTION,
            "dfi:   addenda98.OriginalDFIField(),",
            "dfi:   \"\",",
        ), edit(
            CORRECTION,
            "key := originalEntryKey{trace: target.originalTrace, dfi: target.originalDFI}",
            "key := originalEntryKey{trace: target.originalTrace, dfi: \"\"}",
        )],
        "matches by trace without the as-sent DFI",
    ),
    (
        "K no-service-class-widening",
        [edit(
            CORRECTION,
            "\t\trebalanceOffsets(batch.GetEntries())\n\t\theader := batch.GetHeader()\n\t\theader.ServiceClassCode = coveringServiceClassCode(header.ServiceClassCode, batch.GetEntries())",
            "\t\trebalanceOffsets(batch.GetEntries())\n\t\theader := batch.GetHeader()\n\t\theader.ServiceClassCode = header.ServiceClassCode",
        )],
        "does not widen an ordinary service class",
    ),
    (
        "K output-service-class-not-rebuilt",
        [edit(
            CORRECTION,
            "func createCorrectionBatch(batch *BatchCOR) error {\n\theader := batch.GetHeader()\n\theader.ServiceClassCode = coveringServiceClassCode(header.ServiceClassCode, batch.GetEntries())\n\treturn batch.Create()\n}",
            "func createCorrectionBatch(batch *BatchCOR) error {\n\treturn batch.Create()\n}",
        )],
        "validates mixed-direction Refused and Undo batches under the copied source class",
    ),
    (
        "K no-file-control-rebuild",
        [edit(
            CORRECTION,
            "\tif len(batches) > 0 || len(iatBatches) > 0 {\n\t\treturn f.Create()\n\t}",
            "\tif len(batches) > 0 || len(iatBatches) > 0 {\n\t\treturn nil\n\t}",
        )],
        "leaves file controls describing the as-sent batches",
    ),
    (
        "COMPOSITE nova-5-as-written",
        [NO_UNDO, ORDINARY_INDEX_ONLY, NO_CONCRETE_VALIDATION],
        "forward/refusal/offset architecture with neither history, IAT, nor concrete V",
    ),
    (
        "COMPOSITE nova-6-as-written",
        [NO_UNDO, ORDINARY_INDEX_ONLY, NO_CONCRETE_VALIDATION, NO_REFUSED],
        "the second forward-only recipe adapted to the new result type",
    ),
    (
        "COMPOSITE C-only",
        [ORDINARY_INDEX_ONLY, NO_CONCRETE_VALIDATION],
        "implements history but neither IAT targets nor concrete validation",
    ),
    (
        "COMPOSITE H-only",
        [NO_UNDO, NO_CONCRETE_VALIDATION],
        "implements IAT targets but neither history nor concrete validation",
    ),
    (
        "COMPOSITE V-only",
        [NO_UNDO, ORDINARY_INDEX_ONLY],
        "implements concrete validation but neither history nor IAT targets",
    ),
    (
        "COMPOSITE C+H",
        [NO_CONCRETE_VALIDATION],
        "implements history and IAT but not concrete validation",
    ),
    (
        "COMPOSITE C+V",
        [ORDINARY_INDEX_ONLY],
        "implements history and concrete validation but not IAT targets",
    ),
    (
        "COMPOSITE H+V",
        [NO_UNDO],
        "implements IAT and concrete validation but not history",
    ),
]


def failing_tests(report):
    try:
        root = ET.parse(report).getroot()
    except (ET.ParseError, FileNotFoundError):
        return None
    names = set()
    for case in root.iter("testcase"):
        if case.find("failure") is not None or case.find("error") is not None:
            names.add(case.get("name"))
    return names


def run_suite():
    subprocess.run(
        ["./test.sh", "--output_path", "/tmp/mutation.xml", "new"],
        cwd="/app",
        capture_output=True,
    )
    return failing_tests("/tmp/mutation.xml")


def main():
    baseline = run_suite()
    if baseline is None or baseline:
        print("baseline is not green, cannot run mutations:", baseline)
        return 1
    print("baseline: all tests pass\n")

    survivors = []
    weak = []
    for name, edits, description in MUTATIONS:
        touched = {path for path, _, _ in edits}
        originals = {path: open(path).read() for path in touched}
        counts = [(path, originals[path].count(find)) for path, find, _ in edits]
        if any(count != 1 for _, count in counts):
            detail = ", ".join(f"{path}x{count}" for path, count in counts)
            print(f"{name:38s} SKIPPED (anchor count: {detail})")
            survivors.append(name)
            continue

        for path in touched:
            shutil.copyfile(path, path + ".orig")
        try:
            mutated = dict(originals)
            for path, find, replace in edits:
                mutated[path] = mutated[path].replace(find, replace, 1)
            for path, contents in mutated.items():
                open(path, "w").write(contents)
            killed = run_suite()
        finally:
            for path in touched:
                shutil.move(path + ".orig", path)

        if killed is None:
            print(f"{name:38s} NO REPORT")
            survivors.append(name)
        elif not killed:
            print(f"{name:38s} SURVIVED  ({description})")
            survivors.append(name)
        else:
            synthetic = killed & SYNTHETIC
            marker = "SYNTHETIC" if synthetic else "killed"
            print(f"{name:38s} {marker} by {len(killed)} test(s)")
            if synthetic or len(killed) < 2:
                weak.append(name)
            for test in sorted(killed):
                print(f"    {test}")

    print()
    print(
        f"mutations: {len(MUTATIONS)}  survivors: {len(survivors)}  "
        f"killed by fewer than 2 tests: {len(weak)}"
    )
    if survivors:
        print("survivors:", ", ".join(survivors))
    if weak:
        print("weak:", ", ".join(weak))
    return 1 if survivors or weak else 0


if __name__ == "__main__":
    sys.exit(main())
