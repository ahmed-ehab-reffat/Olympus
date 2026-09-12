# Repository search instructions

Use this process whenever searching for a repository or task. The objective is not merely to find an eligible popular project; it is to find an uncommon, repository-native task with enough implementation depth to challenge frontier agents and enough public behavior to test fairly.

## 1. Read local history before searching

Start with the current candidate registry, `SUCCESSES.md`, and then inspect
relevant problem history under `problems/`:

- `SUMMARY.md` or status notes for repository and outcome;
- `LEVELS.md` for what agents found easy or hard;
- `ERRORS.md` for rejection, fairness, similarity, and false-positive lessons;
- `DESIGN.md` and `meta.md` for already-used task shapes;
- compact run summaries or decisive raw trajectories when the failure mechanism matters.

Search across all problem folders, not just accepted ones. Abandoned work is especially useful: `geo-polygonize` shows that a valid, difficult implementation can still fail archive similarity, while accepted work such as `moov-ach` shows the value of repository-specific formats, multiple interacting subsystems, and public round-trip oracles.

Search `archive/` as well as `problems/`. Closed records such as
`archive/calyx-cider-checkpoints/` preserve rejection mechanisms that must shape
new task selection even when their active problem folders have been retired.
Before adding a repo, record whether it or a neighboring domain already appears
in local history. Update the registry's problem-history table whenever a problem
is selected, abandoned, rejected, or accepted. When a problem is accepted,
record its positive selection and discriminator lessons in `SUCCESSES.md`
without deleting its earlier risks or rejection history.

## 2. Generate uncommon search directions

Avoid starting from generic task words such as parser, cache, merge, graph, or serializer. Generate combinations of an allowed language with a less-common production domain, for example:

- binary debugging and executable formats;
- fonts, shaping, color glyphs, and document internals;
- scientific or geospatial file formats;
- storage engines and on-disk indexes;
- archive, packet, telemetry, or observability formats;
- compiler metadata and link-time structures;
- domain-specific validation, reconciliation, or canonicalization.

Good seams often look like one of these:

- the reader exists but the writer is missing;
- a record-level operation exists but the file-level transaction is missing;
- validation exists for individual objects but not a coordinated mutation;
- a format supports parsing but not canonical generation or round-trip editing;
- one family of types supports an operation while a sibling family does not;
- a public tracking issue contains an unchecked, welcomed feature with no implementation PR.

Randomized domain/language seeds are encouraged because predictable searches converge on benchmark-heavy repositories. Record the seed or query so a useful search can be reproduced.

## 3. Apply hard repository gates immediately

Reject or watchlist a repository before deep task design unless all current platform rules pass:

- public GitHub repository;
- supported implementation language;
- at least 500 stars;
- at least one commit in the last 12 months;
- allowed permissive license;
- production-level scope;
- a real existing regression suite that can run offline in the platform container.

Verify these from current primary sources. Record the date, exact default-branch commit, stars, language, license, last push or commit, test command, and whether dependencies can be warmed into an offline image. Eligibility changes over time, so stale entries must be rechecked before selection.

### Supported-language and runtime policy

The supported implementation languages are exactly:

- Python
- JavaScript
- TypeScript
- Go
- Rust
- C++
- Java

C, Ruby, and every language not listed above are unsupported. The repository's
primary production implementation and the expected solution must use a
supported language. Do not infer eligibility only from GitHub's primary-language
label: inspect the build, test runner, generated bindings, fixtures, and every
runtime needed to exercise the task.

An auxiliary compiler or library written in another language is not
automatically disqualifying when it is merely a build dependency and can be
installed, pinned, cached, and used offline. It becomes a hard gate when an
unsupported interpreter or language runtime is required to compile or exercise
the repository's core behavior. For example, a Rust binding whose meaningful
tests require a Ruby interpreter is ineligible while Ruby is unavailable, even
though the patch itself would be Rust.

For a mixed-language repository, record:

1. the primary implementation language;
2. the language of the proposed production changes;
3. every compiler, interpreter, runtime, and external service used by the
   baseline and focused tests;
4. whether each dependency exists in or can be reproducibly added to the
   official platform image; and
5. whether the complete intended test command succeeds after networking is
   disabled.

Do not select a conditional runtime candidate before this preflight. If a
required unsupported runtime is unavailable, reject the candidate and preserve
that reason in `CANDIDATES.md`.

## 4. Find a repository-native task

Read the README, architecture docs, changelog, public APIs, tests, and extension patterns before proposing behavior. A candidate task must satisfy all of the following:

1. It fits the project's philosophy and naming conventions.
2. The base repository exposes enough public behavior to serve as a fair oracle.
3. The implementation naturally spans multiple decisions, files, or subsystems; difficulty is not just a long list of rules.
4. Deterministic tests can distinguish plausible shortcuts without pinning a private architecture.
5. A reference solution can be implemented and verified offline.
6. The task is unlikely to collapse into a textbook algorithm or a direct transcription of a public specification.
7. The task has a plausible route to the current platform's size and
   long-horizon criteria; an initial/reference LOC estimate alone does not
   disqualify it.

Write down one concrete task seed, the expected implementation shape, the public oracle, likely shortcuts, and the anticipated test strategy. A repo with no credible task seed cannot score above 6/10.

Before assigning a task-fit score above 6 or creating a problem folder, search
the exact proposed feature noun, API/type name, command name, and subsystem
directory across the pinned source, tests, documentation, branches, and Git
history. Then search broader behavioral synonyms. The RustPBX SipFlow screen
failed because the exact proposed name already identified a mature production
subsystem; later RWI and reload redesigns likewise overlapped existing
deduplication, resume, preflight, and cluster-reload machinery. A rare domain
and large test count do not compensate for skipping this source-level identity
check.

Before scoring implementation depth, attempt the cheapest legitimate history
reconstruction. Ask whether the requested behavior can be satisfied by retaining
the original inputs plus a progress marker and deterministically replaying, or
by logging nondeterministic observations as a transcript and replaying them
before consuming the unread suffix. If black-box behavior cannot distinguish
that solution from direct serialization of the intended coupled state, score
and scope the replay/transcript solution rather than the desired private
architecture. Do not rescue the task with transcript bans, private-layout
requirements, arbitrary history limits, checkpoint-size limits, or timing
thresholds unless the repository already exposes those as public semantics.

### Treat preliminary LOC as a low-weight forecast

Record the cheapest complete implementation you can currently justify, its
effective-LOC estimate or measured size, the architecture assumed, and a range
or confidence statement. Do not silently turn one reference or prototype into a
prediction that every solver will converge on it.

The applicability rating has no standalone LOC dimension. Preliminary LOC may
move the **Behavioral depth** score by at most one point, so it contributes at
most 1.5 percentage points to the weighted rating. It cannot create a rating
cap or a `rejected` status by itself. Reject for scope before solver evidence
only when repository evidence or more than one independent complete prototype
shows that the cheapest legitimate solution is architecture-convergent and
materially below the current criterion. Preserve that evidence and the initial
assumption.

Once legitimate successful trajectories exist, replace the forecast with their
observed median production files, platform-reported agent messages, and strict
effective production LOC. Railway, Calamine, and PcapPlusPlus are the standing
counterexamples to reference-size determinism: their successful solver work was
materially larger or structurally different than early estimates. Conversely,
a batch such as str0m's, where independent solutions converge on the same small
localized seam, is strong negative scope evidence.

For every task seed, record the repository's primary implementation language and classify the maintainer-facing work as exactly one of `feature request`, `bug fix`, `enhancement`, `optimization`, or `refactor`. Do not use hybrid labels. Choose the category by the public request: a new capability is a feature request, broader or safer behavior for an existing capability is an enhancement, incorrect existing behavior is a bug fix, measurable resource improvement is an optimization, and behavior-preserving structural work is a refactor.

## 5. Audit upstream and local prior art

This is a hard stop, not a final formality. Search all states of:

- pull requests;
- issues;
- GitHub Discussions;
- release notes and changelogs;
- repository code and tests;
- forks when a suspicious abandoned implementation is referenced.

Search the proposed API name, behavior, domain vocabulary, likely helper names, and broader synonyms. Confirm no open, merged, closed, or abandoned PR already implements it and no maintainer discussion declines it. Save dated queries and direct links in the future problem's `UPSTREAM_AUDIT.md`.

Also compare against local problem history. Reusing a repo, a named textbook operation, or the same architectural shape increases similarity risk even when upstream has no implementation.

## 6. Score applicability from 1 to 10

Score each dimension from 1 to 10:

| Dimension | Weight | A high score means |
|---|---:|---|
| Eligibility and health | 15% | every hard gate passes with strong maintenance margin |
| Rarity | 20% | absent from common coding-agent benchmarks and uncommon among challenge authors |
| Task applicability | 25% | a concrete, maintainer-aligned gap with strong public oracles exists |
| Behavioral depth | 15% | non-local state, cross-subsystem interactions, or canonical generation creates genuine depth across plausible architectures |
| Harness feasibility | 15% | substantial deterministic tests run offline without awkward fixtures or services |
| Prior-art and similarity safety | 10% | upstream and local searches show low duplication and archive-neighborhood risk |

Round the weighted result to a whole-number applicability rating from 1 through 10. Apply these caps:

- any failed hard eligibility gate: at most 3;
- no genuine existing regression suite: at most 4;
- unresolved PR, issue, discussion, or license concern: at most 4;
- no concrete task seed: at most 6;
- textbook or highly benchmarked task shape: at most 6.

The rating is a decision aid, not a substitute for evidence. Record dimension scores and the reason for every cap.

## 7. Update the registry during every search

For each researched repository, add or update:

- repository and URL;
- verification date and commit;
- eligibility facts;
- dimension scores and overall rating;
- proposed task seed;
- primary language and task type;
- upstream-history result;
- local-history and similarity risk;
- status: `researching`, `shortlist`, `selected`, `watchlist`, `rejected`, `used`, or `stale`;
- the next concrete action.

This update is part of the screening itself, not a later cleanup step. Whenever
the user supplies a repository, record it in `CANDIDATES.md` before returning
the verdict. Include candidates rejected during the first hard-gate check as
well as candidates advanced for audit. If a later check changes the verdict,
update the current entry and retain the earlier decision in the dated history.

Never silently delete a rejected candidate. Its rejection reason prevents
repeated work. When facts change, append a dated note or replace the current
facts while preserving the earlier decision in the history section. On
acceptance, also add the problem to `SUCCESSES.md`; success is a second lifecycle
record, not a reason to rewrite the earlier screen.

Every `problems/<problem-name>/SUMMARY.md` must state the production language
and exactly one task type from `feature request`, `bug fix`, `enhancement`,
`optimization`, or `refactor`. Do not rely on the candidate row, `PLAN.md`, or
reader inference for either field.

When selecting a repo, compare the top candidates directly and explain why the winner beats the runner-up. Then complete the exhaustive audit and preflight before marking it `selected` or creating a problem folder. For parallel work, repeat this independently in ranked order. A passing candidate receives its own stable `problems/<problem-name>/PLAN.md`; a failing candidate is preserved with the rejection reason and the next ranked candidate is audited instead. When a problem closes, update the status and record the outcome before searching again.

## 8. Search stop conditions

Stop investing in a candidate when:

- a hard gate fails;
- prior art implements or declines the task;
- the repository has no real base tests;
- legitimate replay or transcript reconstruction satisfies the observable
  contract and collapses the intended scope or discriminator;
- the task depends on network services, proprietary fixtures, timing, or nondeterminism;
- tests would need to enforce private architecture rather than behavior;
- the task resembles an already rejected local or archive-saturated problem;
- a strong solver can reduce the task to a familiar single algorithm with little repository reading.

Advance a candidate only when eligibility, novelty, task fit, testability, and implementation depth are all supported by recorded evidence.
