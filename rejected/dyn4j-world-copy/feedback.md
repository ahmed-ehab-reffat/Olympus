REJECTED 2026-09-24 at the core-slice precheck: DERIVATIVE, overlap Blocker. 157/492 discounted subject lines (31.9%) and 157/297 candidate lines (52.9%) re-deliver an older submission's live-world copy engine (independent bodies, fixtures, joints, broadphase caches, contacts, warm-start state, time history). Judge: ours "tightens determinism and generalizes placement" but the primary challenge is the same. Upstream and scope checks found no other disqualifier. Shelved to rejected/, see TOO-EASY.md. No picker spend, no batch.

# dyn4j-world-copy - feedback

STATUS (2026-09-23): SLICE-READY (Step 4b). Core slice built and validated in a Docker clean room. No
differentiating scope, no cross-product cells yet (those are FINISH work, listed in DESIGN.md 11/11b).

Repo: dyn4j/dyn4j (538 stars, BSD-3-Clause, Java 100%). Base bcf942adaa9bfd32a1abd043cbc9021ab158d0ad
(= HEAD, release 6.0.0, 2026-07-18). Lane (hunt REPO-HUNT-2026-09-23-J RANK 1): `World.copy()`, a deep
copy of the physics world that stays independent and steps bit-identically with the original.

## Slice contents
- solution.patch: 12 files (4 packages: world, collision/broadphase, dynamics, dynamics/contact), 573
  added lines, **225 honest human-effective** (javadoc, braces, imports, annotations stripped). The
  hook `effective_loc_check.py` reports 461 because it does not strip Java `*` javadoc lines (208 of
  the added lines are javadoc, repo convention). Gate on the honest number.
- test.patch: test.sh (100755) + src/test/java/org/dyn4j/world/WorldCopy0cbf19Test.java, 10 tests.
- Dockerfile: olympus-base-jvm (JDK 17), `COPY --chown=1000:1000 . .`, junit 4.13.1 + hamcrest 1.3
  fetched to /opt/dyn4j-lib, safe.directory, `find /app \( -type d -o -user 0 \) -exec chmod a+rwX {} +`.
  No bind mount, no `COPY --chmod`, no full `chmod -R`. Cold build ~35 s.
- test.sh drives javac + JUnit directly (the pom's `<release>6</release>` + `-Xdoclint -Werror` need
  JDK <= 11 under Maven). Build output goes to a mktemp dir, never into /app. Base mode compiles and runs
  every existing test file except the new one; new mode compiles and runs only the new file. The XML
  runner maps assertion failures to `<failure>` and anything else to `<error>`, replaces `::` in ids,
  and exits nonzero on any failure or on an empty run. When compilation fails in new mode (base commit)
  it writes one failing `<testcase>` per `@Test` method of the new file, same classname and names as the
  real run, carrying the javac log.
- meta.md: full intended contract (300 words), ASCII, one line per paragraph.

## Local validation (Docker clean room: pristine clone at BASE, image built without patches, patches
applied inside, `--network none`)
| user | base pre | new pre | base post | new post |
|---|---|---|---|---|
| 1000:1000 | 2385/2385 pass | 10/10 fail (exit 1) | 2385/2385 pass | 10/10 pass |
| 0:0 | same | same | same | same |
| 4242:4242 (unmapped) | same | same | same | same |
Flakiness (uid 1000, both patches): base x3 identical (2385 pass), new x3 identical (10 pass).
`git status` inside the image before patching: clean.

## Scope-lock gates (all run before code)
- R1 activity: 7 commits in 12 months, all 2026-07-18, incl. real code commit 42e5e0ef "Angular limit and
  reference frame changes". Rule is >= 1 commit in 12 months (OFFICIAL-RUBRIC R1, RULES.md:101). PASS,
  thin (ranking penalty only).
- Gate 1 behavioral gap: base has no world copy; the best 6.0.0 composition (new World, body.copy() in
  order, joint.copy(b1,b2)) is equal at t0 and diverges at step 1 (reproduced 3x). PASS.
- Gate 5 cold: no post-base commits (base = HEAD); nobody building world copy. PASS.
- Gate 6 reproduce: probe above. PASS.
- Gate 7 dedup: nothing in approved-problems/ problems/ rejected/ on physics world copy. Rivals are
  invisible -> precheck owed.
- Gate 7b exclusivity (canonical dyn4j/dyn4j, all states, by class: copy, clone, snapshot, serializ,
  save state, rollback, determinis, world copy, Copyable, prediction, restore, deep copy, state): only
  PR #292 (closed; field visibility in AbstractCollisionBody/AbstractPhysicsBody, 2 files, no
  world/broadphase/contact code) and issue #293 (body-level Copyable, shipped 6.0.0). Branches: master
  only. Forks: JNightRider master 0 ahead, OrganizationUsername master, victorlira build branches,
  Ewan-Brown javadoc. `gh search code` for a dyn4j world copy: nothing. CLEAN.
- Gate 8 philosophy: #293 maintainer defines copy as deep ("nothing on the copy references the
  original"), native clone declined in favour of copy(); world never in scope, nothing declined.
  Discussion #300 (prediction) motivates stepping a copy. PASS.
- Gate 9 flakiness: 2385 tests x3 identical (host) and x3 in Docker.
- Gate 10 quota: 0 subs for dyn4j.
- SIX-CHECK: 1-3 above; 4 closed-with-implemented: #293 is body-level only (world copy is the obvious
  next step = MEDIUM derivative magnet, see below); 5 base..HEAD: empty; 6 existing capability: no
  World.copy, composition diverges.

## Risks settled at scope-lock
1. Activity: passes the platform rule (see R1).
2. LOC: the slice already carries almost the whole core at 225 honest eff. Existing machinery absorbs
   only bodies and joints (Body.copy / joint.copy(b1,b2) audited reflectively: every field copied,
   no repo bug there). World state (broadphase trees, contacts + warm start, graph, CCD data, time
   step, accumulator) has no copy machinery at all. FINISH adds brute-force + Sap copies (~40-50) ->
   ~265-280.
3. Derivative: "add World.copy() to dyn4j" is outsider-nameable and the obvious follow-up to #293 ->
   the core-slice precheck is the only instrument that can see rivals. Exclusivity/Gate 5/7b/SIX-CHECK
   clean.
4. Sap determinism measured: fresh-vs-fresh, 20 scenes x 300 steps: without bullets tree/Sap/brute
   force 0/20 diverge; with three bullets 3/20, 4/20, 4/20 (solveTOI groups events in a HashMap keyed
   by body, identity-hash order). Sap also iterates a HashMap of proxies in update(). Decision: meta
   carries a TOI caveat (more than one body needing a TOI correction in one step); tests use at most
   one fast body; Sap is never asserted bit-identical (FINISH: same pair set only).

## Trap reproduction (mutants of the reference, harness worktrees/dyn4j-probe/mut/mutants.py)
Each trap dies only in its own scene, so the band is spread over independent cells:
- Broadphase rebuilt through addBody (fresh fat AABBs / topology): removal history (step 59), moving
  scene copied at step 45 (20), overlap-add (2). Settled stack: survives. [in slice]
- Contacts re-detected / impulses dropped: step 1 in most scenes (self-revealing floor). [in slice]
- Caller-changed constraint enabled/tangent speed reset: only that scene (1). [in slice]
- Fresh TimeStep: only varying step sizes (1). [in slice]
- Accumulated update time lost: only the accumulator scene (1). [in slice]
- Pending broadphase updates dropped: only overlap-add (2). [FINISH]
- contactCollisions not carried: only a contact listener added to the copy (pre/postSolve 148 vs 164). [FINISH]
- Collision-data flags not carried: only collision-data queries (8 mismatches); with a replayed graph
  it becomes step 1. [FINISH]
- Default filter shared with the original: step 2 everywhere (self-revealing). [covered]
- CCD tree rebuilt: no kill in any scene yet (FINISH: design a persistent CCD pair cell or count as
  insurance).

## Decisions taken without a human (conservative)
- Sap bit identity not promised or tested (engine not deterministic there).
- Custom broadphase detectors / joints outside AbstractPaired/SingleBodyJoint throw
  UnsupportedOperationException; not stated in meta, not tested.
- Javadoc on new public/protected members kept (dyn4j documents every member and its pom runs doclint);
  no inline comments.
- Test file carries the repo's license header and one-line javadoc per test (WorldTest.java style).

## FINISH plan (after a clean precheck)
Brute-force + Sap copies; cells: overlap-add, listener-on-copy, collision-data query (order + first
body), unstepped, copy-of-copy x removal, removal x varying dt, sleeping + wake, CopyException subclass,
user data null, shift after copy; CCD single-bullet persistent pair; FP self-check (mutants above
against the suite in base AND new mode); meta trim toward 200 words.

## Attempt history
- 2026-09-23 SLICE built and validated (this entry).
