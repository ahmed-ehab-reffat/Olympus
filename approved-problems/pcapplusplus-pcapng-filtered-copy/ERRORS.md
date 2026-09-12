# ERRORS - PcapPlusPlus section-aware PCAPNG filtered copy

## 1. Reference LOC was treated as a terminal horizon proxy

- Date: 2026-07-30
- Source: local candidate audit and user review
- Severity: high
- Verdict: valid correction

### Evidence

The first verdict rejected the task after a correct 178-addition public C++
prototype proved that most block variants share one raw-copy branch. The
architecture-convergence warning is valid, but the terminal inference from
reference size was too strong. Railway's 81-line preview, 638-line accepted
reference, and 850-plus-line representative solver patches demonstrate that
reference LOC can underpredict solver horizon materially.

### Resolution

Reopen the unchanged honest contract as an experimental size-risk package.
Do not add scope merely to increase reference size. Freeze and audit the real
problem, then measure successful solver files, messages, and LOC before
deciding.

Two cold local frontier solves both passed the frozen hidden and base suites.
They produced 420 and 525 strict effective production additions, with a
successful median of 472.5, and used 72 and 54 message/tool events. The
original LOC rejection is therefore empirically disproved.

### Durable lesson

A smallest-complete prototype is strong convergence evidence, not always a
substitute for solver measurements. When the user authorizes the budget and a
close precedent shows large solver expansion, an unpadded experiment is more
informative than a reference-LOC rejection.

## 2. LOC risk and difficulty risk were initially conflated

- Date: 2026-07-30
- Source: two-run cold local pre-filter
- Severity: medium
- Verdict: separate outcomes

### Evidence

Both solvers cleared every size and effort floor, so reference LOC was not a
useful horizon proxy. Both also passed all six hidden entities and the full
70-case base suite on their first attempt. The two solutions used independent
storage strategies but converged on the same public raw-scanner architecture.

### Resolution

Treat LOC as cleared and the 2/2 solve rate as a separate too-easy signal.
Do not spend platform runs on L1 unchanged. Review only legitimate public
invariants for a possible L2; if none adds a distinct semantic boundary,
retire the task for difficulty rather than reviving the disproved LOC reason.

## 3. Multi-interface behavior was stated but not exercised

- Date: 2026-07-31
- Source: external T4 review
- Severity: high
- Verdict: valid correction

### Evidence

Every valid predecessor packet used Interface ID 0 and each section had only
one IDB. An implementation that rejected valid nonzero references, filtered
all EPBs with interface 0, or retained only the first IDB survived that suite.

### Resolution

Add the independent `PcapNgCopy.InterfaceSelection` scenario. It retains two
different IDBs in each of two sections, filters an EPB through Interface ID 1,
and reuses the numeric IDs with different link types after the section
boundary. Three isolated mutants for those shortcuts now fail only this test.

## 4. Complete Custom Block policy was conflated with Custom Options

- Date: 2026-07-31
- Source: external T4 review
- Severity: high
- Verdict: valid correction

### Evidence

The predecessor distinguished copyable and do-not-copy complete Custom Blocks,
but retained-block fixtures contained neither standardized Custom Option code.
A copier that removed a do-not-copy Custom Option from a retained block could
pass.

### Resolution

Add the independent `PcapNgCopy.OptionPreservation` scenario with valid
copyable and do-not-copy Custom Options containing a PEN. Its complete expected
file comparison proves that both options remain untouched. The corresponding
option-stripping mutant fails only this test.

## 5. The reference fell below the revised 200-effective-LOC floor

- Date: 2026-07-31
- Source: lane policy update and external review
- Severity: high
- Verdict: valid correction

### Evidence

The predecessor reference counted 158 effective additions under the review
counter. Although all three prior successful solver patches exceeded 200
effective production additions, the revised lane also requires the reference
to clear that floor.

### Resolution

Expand the public validation obligation at a distinct format boundary instead
of padding the implementation. Retained standardized blocks now require
bounded, padded option framing; Name Resolution Blocks require bounded records
and their record terminator. `MalformedOptions` independently corrupts IDB,
EPB, DSB, and NRB inner framing. The revised reference has 253 raw production
additions and 231 non-comment, non-blank additions. Two option/record framing
mutants fail only `MalformedOptions`, while all three earlier legitimate
solver patches pass the other eight scenarios and fail this new boundary.

## 6. The prompt named a discoverable filter-setting API

- Date: 2026-07-31
- Source: external professionalism review
- Severity: high
- Verdict: valid correction

### Evidence

The first sentence instructed callers to configure the filter “with
`setFilter()`”. The method name is discoverable from the existing reader API
and does not define additional behavior.

### Resolution

State only that `copyFiltered()` uses the reader's current packet filter. No
test or reference behavior changed. The prompt-only immutable version passed
the complete patch-state and 21-mutant re-audit.

## 7. Simple Packet Block length validation was not isolated

- Date: 2026-07-31
- Source: external T4 review
- Severity: high
- Verdict: valid correction

### Evidence

`MalformedReferences` corrupted Enhanced Packet Block lengths but never made
an SPB body shorter or longer than the captured length implied by its section's
Interface ID 0 snapshot length. An implementation could validate EPBs while
accepting an inconsistent SPB.

### Resolution

Add short and extra-payload SPB cases to `MalformedReferences`. Both must
return `false` and preserve a sentinel destination. The isolated
`accept_extra_spb_payload` mutant compiles and fails only this scenario.

## 8. Three standardized option entry points were uncovered

- Date: 2026-07-31
- Source: external T4 review
- Severity: high
- Verdict: valid correction

### Evidence

L2 malformed-option cases began at IDB, EPB, DSB, and NRB record fields. They
did not prove validation of SHB options, ISB options, or the NRB option list
following its required record terminator.

### Resolution

Add one overrun at each missing entry point to `MalformedOptions`. Separate
skip-SHB, skip-ISB, and skip-NRB-option mutants each compile and fail only that
focused scenario.

## 9. Minor-version acceptance was incorrectly treated as unsupported

- Date: 2026-07-31
- Source: external solution-quality review
- Severity: high
- Verdict: invalidated by later fairness review

### Evidence

L3 interpreted “supported section version” as exactly 1.0 and treated a
section declaring version 1.1 as invalid. That interpretation was not grounded
in a repository acceptance rule.

### Resolution

L3 temporarily required SHB version 1.0 and added an unsupported-minor case to
`MalformedFraming`. L5 removes both after the correction recorded in error 14.

## 10. L2 passed every unhinted working-pool run

- Date: 2026-07-31
- Source: `agent-runs2/` and difficulty review
- Severity: high
- Verdict: valid difficulty signal

### Evidence

All four legitimate unhinted solutions passed 69/69 base and 9/9 L2 focused
tests. Their production patches were substantive and exceeded the 200-line
floor, but 4/4 is above the 50% pass-rate cap. Three independently required an
explicit option terminator; one correctly accepted a padded option list ending
at the block boundary. Every predecessor fixture also configured `tcp`.

### Resolution

Retire L2. L3 adds `OptionTermination` for the trajectory-supported valid
representation and `FilterState` for a non-TCP current-filter expression.
Retrospective replay is now 1/4: one solution passes all 11 scenarios and
three fail only `OptionTermination`. The two new mutants are killed
independently, avoiding another shared malformed-input bottleneck.

## 11. Default and cleared filter states were not exercised

- Date: 2026-07-31
- Source: external T4 review
- Severity: high
- Verdict: valid correction

### Evidence

Every valid focused copy configured a nonempty filter. An implementation could
therefore reject an empty BPF state even though `BpfFilterWrapper::matches()`
explicitly returns `true` for an empty filter and `clearFilter()` restores that
state.

### Resolution

Add `DefaultAndClearedFilter` with distinguishable EPBs and SPBs. It invokes
`copyFiltered()` before setting a filter, then after setting and clearing one,
and requires exact retention in both cases. The isolated nonempty-filter
mutant compiles and fails only this scenario. All three completed L3 solver
patches already pass it.

## 12. L3 concentrated every completed failure on one subtle rule

- Date: 2026-07-31
- Source: `agent-runs3/` and operator review
- Severity: high
- Verdict: valid difficulty-design signal

### Evidence

The three completed L3 implementations were independent, substantive 10/11
near-passes, yet each failed only `OptionTermination`. The unfinished fourth
run has no evaluation. Continuing the batch would measure whether solvers
guessed one specification detail rather than whether the task offers varied
public discriminators.

### Resolution

Retire L3 at 0/3 and state the block-end option-list rule explicitly. Add two
trajectory-separated opacity cases backed by the format specification:
`LocalUseOpacity` catches Nova 1's interpretation of a local-use block payload,
while `ReservedFieldOpacity` catches Nova 2's rejection of nonzero ignored IDB
reserved bits. After normalizing only the newly explicit rule, Nova 1 and Nova
2 fail different tests and Nova 3 passes 14/14.

## 13. Unknown-block and IDB reader opacity were only implicit

- Date: 2026-07-31
- Source: PCAPNG draft review and L3 differential replay
- Severity: high
- Verdict: valid correction

### Evidence

The prompt required unknown blocks and every IDB to be copied byte-for-byte,
but valid fixtures did not put opaque, non-TLV data in a local-use block or a
nonzero value in the IDB reserved field. A scanner could overclassify a
local-use type and parse its payload, or enforce a writer-side zero rule while
reading.

### Resolution

Add exact-copy valid captures for both cases. Each corresponding mutant
compiles and fails only its own scenario. The probes do not assign semantics
to private payloads or require a particular scanner; they assert that those
bytes remain uninterpreted.

## 14. `MalformedFraming` pinned an unfair SHB minor-version policy

- Date: 2026-07-31
- Source: external fairness review
- Severity: high
- Verdict: valid correction

### Evidence

L4 required an otherwise valid SHB changed from 1.0 to 1.1 to be rejected.
Neither the prompt nor public repository API declares minor zero exclusive.
Bundled LightPcapNg reads the minor field into file metadata and writes that
stored value back without rejecting it. The earlier “supported section
version” wording was too vague to justify the hidden exact-minor policy.

All reviewed solver patches copied the same minor-zero restriction, but that
is not independent trajectory support: they were responding to the same prompt
and test contract.

### Resolution

Retire L4 before calibration. L5 says “supported major section version,”
removes the 1.1 rejection and the test scanner's minor-zero assumption, removes
the reference's minor check, and retires the corresponding mutant. An
audit-only 1.1 exact-copy probe passes, but no minor-version permutation is
used as a hidden discriminator. The complete matrix, 30-mutant audit, and
solver replays were restarted for the new immutable version.

## 15. L5 calibrated above the solve-rate cap

- Date: 2026-07-31
- Source: `agent-runs4/`
- Severity: high
- Verdict: valid hardening signal

### Evidence

Seven of ten unhinted working-pool agents passed all 14 L5 scenarios and all 69
baseline cases. The implementations were legitimate and substantive, so this
is a difficulty-calibration result rather than leakage or invalid work.

Raw trajectory and patch inspection found a real semantic split hidden by L5.
Five of the seven passing scanners validate an EPB's option area before
applying the filter; two validate options only after deciding to retain the
EPB. The prompt requires option framing in retained standardized blocks.

### Resolution

Retire L5 at 7/10. L6 adds a structurally safe UDP EPB whose option area is
malformed and whose active TCP filter result is false. The expected copy omits
that EPB and succeeds. Move the reference option validator after the positive
filter result. Exact replay now projects 2/10: five former passes fail only
this case, two pass, and the three pre-existing failures retain distinct
DSB/multi-section signatures.

## 16. Const API and identical-path success lacked direct coverage

- Date: 2026-07-31
- Source: external T3/T4 review
- Severity: high/medium
- Verdict: valid coverage gaps, not calibration discriminators

### Evidence

Every L5 test called `copyFiltered()` on a mutable reader even though the
required public signature is const-qualified. No success path reused the exact
input spelling as its destination. A non-const-only overload or premature
same-path truncation could therefore evade the focused suite.

All ten L5 solver patches already use the const signature and a sibling
temporary output, so neither gap explains the 7/10 result. The original
same-path prototype reused the complex DSB fixture and made the three existing
DSB failures fail a second scenario; that coupling was rejected during
prototype replay.

### Resolution

`StructureAndFiltering` now binds the configured reader to a const reference
at the call site. `InPlaceReplacement` uses the DSB-free filter-state capture,
selects UDP, overwrites the identical path, and exact-compares the shortened
result. The prompt states this same-path behavior. All ten historical patches
pass the isolated same-path case, while corresponding mutants are killed only
by their own new boundaries.
