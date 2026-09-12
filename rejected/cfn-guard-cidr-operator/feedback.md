# cfn-guard-cidr-operator — feedback / iteration log

Olympus. Repo: aws-cloudformation/cloudformation-guard (Rust, Apache-2.0). Base 57bbdbf.
PIVOT from cfn-guard-arithmetic (DERIVATIVE 0.865 vs a prior same-repo arithmetic superset; shelved in rejected/). This pick is a NEW central capability in a DIFFERENT subsystem (the CmpOperator comparison evaluator, networking domain) = distinct.

Feature: four IP/CIDR comparison operators for the Guard language (issue #182, maintainer engaged, not declined, no PR, cold; no existing CIDR/IP handling): in_cidr (containment), cidr_overlaps (overlap), is_cidr / is_ip (unary validity). IPv4 + IPv6 via std::net parsing; containment/overlap bit-math is our own.

## Local validation
- Build clean. 4 operators verified end-to-end.
- New tests: 19/19 PASS on solution, 0/19 on base (via ./test.sh new: 19 failures on base).
- Base regression: 286 lib tests + suite = 287 JUnit cases, 0 failures.
- Flakiness: base 5x + new 3x deterministic (fixed cargo2junit stdout-contamination: base tests leak the eval tree to real stdout; `--test-threads=1` serializes + `grep '^{'` filters).
- Effective LOC 254 across 7 files (values, parser, eval/operators, eval, eval_context, reporters x2). D-new regression shape: new CmpOperator variants threaded through exhaustive matches + runtime unreachable reporter arms.

## Hardening
- S3 keyword-ordering preservation: in_cidr must be parsed before in (else tag("in") eats "in_cidr"); base 286 tests guard existing operator/wildcard/regex syntax.
- Trap web in CIDR math (all fair, RFC-defined, tested): /0 prefix shift-overflow (must special-case; naive u32::MAX << 32 panics), host-bits masked to network on BOTH operands, CIDR-in-CIDR prefix-direction check (wider block not contained), mixed IPv4/IPv6 never contained, invalid/non-string operand -> NotComparable (not silent pass).
- Error-kind law: comparators must return Ok(bool) or Err(NotComparable) (repo convention; other kinds hit unreachable!()); used NotComparable throughout.

## Attempt history
- A1 (2026-07-22): pivot from arithmetic; full hardened implementation + deliverable. Pending platform eval batch.


## A2 (2026-07-22): tightening after 5/10 batch
Batch 1 was 5/10 (over the 40% cap). Differential harness (13 fair probes) + your FP data proved ALL 5 passers (Nova 1,2,5,6,8) are genuinely correct on every fair predicate edge -> no fair test can split them (REFERENCE-UNCHANGED law; CIDR predicates are knowable). The list-operand dissent is a dead test (reference flattens identically).
Lever added: `covered_by` (target range covered by the UNION of a list of CIDR ranges) -- the must-derive trap the predicates lack. Naive Guard-idiomatic reading is pairwise ("in any one element"), which is WRONG: a /8 is covered by two /9s but contained in neither. Correct fix is an interval sweep. Contract stated in meta ("even when no single range contains the whole left side"); fix hidden (derivation). Failers on batch 1 were 3 INTEGRATION_ERROR + 2 MISSED_REQUIREMENT (the D-new wiring), consistent with difficulty living in DOING.
Also added the reviewer's 3 coverage areas: non-string operands (number/bool/object) for binary ops, /33 and /129 prefix bounds, IPv6 + mixed-family overlap + is_cidr IPv6.
Now: 5 operators, 356 eff LOC / 8 files, 29 tests, f2p 29-on-solution/0-on-base, base 287-green, flakiness deterministic. New pass rate is the platform batch's to measure.

## A3 (2026-07-22): fix covered_by correctness bug (reviewer FAIL)
Reviewer found a real bug in range_covered: `reach` starts at target_start and the loop-top `if reach >= target_end` returned true BEFORE examining any range -> a single-host target (start==end) was declared covered unconditionally, and `>=` accepted when target_end itself was still uncovered. Fix: `>` (covered only when reach advances PAST target_end). Verified: host-outside-range -> FAIL, final-address-uncovered -> FAIL, all correct cases still hold, base 286 green.
Added discriminator + reviewer coverage tests (34 total): a_host_outside_every_range_is_not_covered (catches this exact bug), covered_by_requires_the_last_address_to_be_covered, is_cidr/is_ip reject non-strings, `!` negation form, bare-address overlap on either side. (The `!`/bare-overlap cases were verified correct end-to-end; earlier shell "failures" were bash !-history-expansion artifacts, not impl bugs.)
Now: 356 eff LOC, 34 tests, f2p 34/0, base 287-green, flakiness deterministic, patches clean.

## A4 (2026-07-22): batch(3) 6/10; reporter fix + tightening attempt
Batch(3) = 6/10 (Nova 2,3,5,7,8,10 pass; 1,4,6,9 fail broadly on wiring/integration).
FIXED 3 real bugs the reviewer + differential harness surfaced (my reference was BEHIND the passing agents):
  1. cmp_str() unary branch: IsCidr/IsIp missing -> unreachable!() panic in CFN/TF output (reviewer code-quality note). Added arms.
  2. report_all_failed_clauses_for_rules() unary match: IsCidr/IsIp fell through to "was float". Added arms.
  3. cidr_bounds: `start + count - 1` overflowed u128 at the TOP of the address space (v4 /31 top, v6 /127 top) -> PANIC. Fixed precedence to `start + (count - 1)`.
Added reviewer coverage + bug-catch tests (38 total): top-of-space covered_by, is_cidr non-canonical, cidr_overlaps out-of-range prefix, covered_by invalid RHS element.

TIGHTENING VERDICT (differential harness, 20+ fair probes vs all 6 passers): NO fair test splits them. Probes tried: single-host-uncovered, final-address-uncovered, unsorted union, overlapping ranges, mid-gap, duplicates, IPv6 /0, adjacency-touch, mixed-family-in-list, empty-rhs, top-of-space overflow, irrelevant-range. All 6 passers handle EVERY one correctly (they are more thorough than the original reference, which had the 3 bugs above). The cmp_str/CFN wiring lever is dead too: all 6 passers wired cmp_str. CIDR incl. covered_by union-coverage is MAXIMALLY KNOWABLE -> the 60% is the genuine ceiling; it cannot be fairly lowered by adding tests (REFERENCE-UNCHANGED law). The only failing agents fail on the D-new WIRING (integration), not semantics.
Now: 384 eff LOC, 38 tests, f2p 38/0, base 287-green, flakiness deterministic. Submission is MORE correct but pass-rate unchanged.
