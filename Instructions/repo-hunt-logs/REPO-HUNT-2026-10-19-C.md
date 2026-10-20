# Repo hunt 2026-10-19-C (hunter #74, CONSECUTIVE_MISSES=0)

**Result: CANDIDATE.** RANK 1 is `safebucket/safebucket`, lane **cross-bucket transfer** (move files and whole folders from one bucket to another): written 320 human-effective over 12 production files in 4 subsystems. Two more lanes cleared the 220 written bar and are fallbacks: authorizer merge-users (248, breadth-heavy) and cnpmcore package rename (221, marginal).

All files for this hunt are in `worktrees/_hunt/s_1019h74/`:
- the brief `AGENT_BRIEF_h74.md` (the h74 block `h74_head.md` sits on top of the h73 brief);
- the sweep scripts `sweep1_h74.sh` (app topics) and `sweep2_h74.sh` (storage-topic pairs), with `sweep{1,2}_{raw,uniq,unj}_h74.tsv`;
- the screener `mech_h74.sh` and its outputs `mechA/B/C_h74.out`;
- eight dossiers `dossier_{authorizer,cloudprober,cnpmcore,ezbookkeeping,safebucket,sq,cloudpathlib,siliconcompiler}_h74.md`;
- the sketches:
  - `sketch_safebucket_crossbucket-transfer_h74.patch` (320)
  - `sketch_authorizer_merge-users_h74.patch` (248)
  - `sketch_cnpmcore_package-rename_h74.patch` (221)
  - `sketch_ezbookkeeping_sharding_h74.patch` (132, evidence of death)
  - `sketch_siliconcompiler_steprename_h74.patch` (83, evidence of death)
- tracker dumps (`cp_tracker_h74/`, `issues_cnpmcore_h74.jsonl`, `ezb_issues_h74.jsonl`);
- backups `judged.bak_h74` and `sig_accounts.bak_h74`.

Clones kept (VIABLE lanes only, sketches applied, uncommitted): `safebucket` (8 MB), `authorizer` (19 MB), `cnpmcore` (79 MB). Every other clone was deleted. No builds were run. Disk `/` had 6.4G free at the start and 5.9G at the end (other sessions are building).

## Standing inputs and defaults taken
- **Rules applied as written (2026-10-05 user decisions):** a LEDGER row excludes only its own lane and file set; only repo-scope verdicts block a repo; star margin ~505; return bar 220 written; the Q3 waiver only above ~300 with an internal wall; submission counts reported, never gated.
- **Not relaxed:** the maintainer-roadmap magnet rule, and the AI-commit, velocity, signature and tracker-named rules.
- **Softening:** none (misses 0).
- **Requirement 0 (platform picker):** OWED for every finalist. I cannot check it; the human checks it at precheck.
- **Lens (the #73 hint):** multi-backend / keyed-identity lanes (rename, re-key, re-create or move a keyed entity across 2+ storage backends or providers), scored by production files edited and by traps from the repo's own model, because of the 2026-10-18 passing-run 256k check.
- **Excluded:** centraldogma rename (HUNTED) and any repository/project rename in a git-backed or config-store server; the #73 fallbacks (go-workflows reset, kellnr retention, tork concurrency, slumber pins, athens stash); anycable; every in-flight lane in LEDGER.

## Stage 0-bis: proven pool
- Built the pool (97 slugs with frontmatter) and joined it against `judged.tsv`. Every pool repo except siliconcompiler had a lane audit within the last 60 days or a written verdict (10-05 second-lane sweep, #66, #72 Cwerg/ray-optics/neva, #73 aptly/commafeed/go-workflows). The 2026-08-20 rows that expire today are only "approved (lane taken, ours)" seed rows; those repos were covered by SATURATED-REPOS notes (swarms on petl/python-control/awkward/ezdxf/yara-x, techan codex sweep, beartype roadmap, go-astits reference-tool, pysmt PR-blanket).
- **siliconcompiler (1 accepted sub, flist roundtrip): DEAD for a second lane.** 7 lanes. Flow-change resume was taken by gadfort's #5404 (Claude-assisted, full reset chosen); node result cache is declined in the code docs (tool.py:679-703, 2104-2105); job rename absorbed (~60-90, `SchedulerNode.copy_from`); project-level step rename **written 83**; remote job identity is the hottest area; #3020 maintainer roadmap; #3094 is a port. Python CI fails intermittently on main. Side note: gadfort shipped nested flists on 2026-10-06.
- **Fallbacks on record re-checked:** go-workflows "reset"/"rewind" tracker search still returns only #137/#138 (2022, signal-after-completion bug, a different capability). kellnr search hit the search rate limit; its last-day PR list shows nothing in the lane (#1245 session expiry is unrelated). tork "concurrency" still only #445/#3/#150/#153.

## Cached index
The #73 hint's unaudited app screens (cnpmcore, stump, safebucket, jjui, wishlist) were taken from `s_1019h73/mech1_h73.out`:
- **cnpmcore, safebucket:** audited (below).
- **jjui:** screen drop (TUI over the jj CLI, no multi-backend surface; SAY-5 x1).
- **wishlist:** screen drop (6 Playwright UI specs only).
- **stump:** not audited this hunt (Rust + TS, CI rows are CVE/label workflows only; heavy Rust workspace for a 6G disk). Still unjudged for the next hunt.

## Fresh sweep 1 (of 2): business / self-hosted app topics
- **Topics (52, none in `used_topics.txt` before):** cms, headless-cms, blog-engine, forum, issue-tracker, project-management, kanban, time-tracking, accounting, erp, inventory-management, ecommerce, crm, helpdesk, ticketing, booking, calendar, url-shortener, pastebin, file-sharing, password-manager, identity-provider, oauth2-server, ldap, sso, authorization, rbac, audit-log, full-text-search, time-series, tsdb, uptime, status-page, web-analytics, newsletter, notifications, automation, form-builder, survey, database-migrations, schema-migration, config-server, feature-toggle, secrets, document-management, digital-preservation, library-management, lims, asset-management, cmdb, mail-server, email-server, git-hosting. Appended to `used_topics.txt`.
- **Funnel:** 346 raw rows (505-6000 stars, permissive, in-scope language, pushed within 6 months), 300 unique after the repo-dead list, 291 never judged. Mostly AI tooling, UI component libraries, forecasting libraries and Chinese admin templates.
- **Screened (`mechA/B_h74.out`):** ezbookkeeping, glauth, authorizer, rauthy, lakekeeper, fastschema, topaz, galene, pgschema, promxy, carbon, ralph, cloudprober, checkcle, peekaping, zipline, Palmr, tududi, gentics/mesh, howeyc/ledger, survey-library, kumomta, stackql, rustypaste.
- **Drops:** tududi (2 signature accounts: MatrixNeoKozak, theluckystrike); Palmr (archived); peekaping (254 AI trailers); pgschema (279); stackql (216); promxy (67 + AdamMagued); rauthy (44 AI trailers, heavy Rust); lakekeeper (corporate, postgres-only tests); checkcle (33 commits, no test CI); zipline (no unit tests); glauth (39 commits, 9 AI trailers); fastschema (54 commits, last June); gentics/mesh (corporate, 40 open PRs); survey-library (corporate, 23 AI trailers); kumomta (34 open PRs, SMTP-spec lanes); carbon (7 commits); ledger (ledger-cli format, 17 commits); rustypaste (small; carfeii x1); topaz/galene/ralph left unaudited (corporate or no multi-backend surface).
- **Audited:** authorizer, cloudprober, ezbookkeeping.

## Fresh sweep 2 (of 2): multi-backend lens via storage-topic PAIRS (new)
- **Method:** `gh search repos --topic=A --topic=B` over 29 backend pairs (sqlite+postgresql, postgres+mysql, postgresql+redis, mongodb+redis, s3+minio, s3+gcs, azure-blob+s3, s3+filesystem, leveldb+rocksdb, etcd+redis, ...). A repo carrying two storage topics usually implements both. 305 raw rows, 112 unique, 107 never judged. Mostly ORMs, SQL clients and boilerplates; the app/engine rows were few.
- **Screened (`mechC_h74.out`):** requests-cache, cloudpathlib, limits, sq, SOCI, myduckserver, graphjin, dbos-transact-py, tbls, trdsql, limiters, openworkflow.
- **Drops:** requests-cache (3 signature accounts: binggao1230, ChrisJr404, katsugtgz); trdsql (3: AdamMagued, bensynapse, ChrisJr404); dbos-transact-py (Kuang-xianxin burst x3 in 6 days, plus the durable-workflow class); myduckserver (go-duckdb CGO, Requirement 5); graphjin (42 AI trailers, container DB tests); openworkflow (durable-workflow class); limits/limiters (small, rate-limit algorithms are sibling-cribbable); tbls (ChrisJr404 x1, CI `build` red on main, not audited); SOCI (C++ DB library, tracker-dense, not audited).
- **Audited:** neilotoole/sq, cloudpathlib, plus cnpmcore and safebucket from the cache.

## Audit results

| Repo | Verdict | Best lane / killing gates |
|---|---|---|
| **safebucket/safebucket** (991, Apache-2.0, Go 56% / TS 36%) | **VIABLE, RANK 1** | Cross-bucket transfer, **written 320 / 12 files**. In-bucket rename/move absorbed (shipped #1367 2026-09-20, keys are `buckets/<bucketID>/<fileID>`), file versions #1265 (maintainer) + open PRs #1413/#1422, quotas #1314 (maintainer), provider migration (testcontainers only), lifecycle expiry #906 (maintainer). |
| authorizerdev/authorizer (2115, Apache-2.0, Go) | VIABLE (borderline), FALLBACK 1 | Merge users, **written 248 / 19 files** (~228 net of 20 moved lines, padding-floor 41). Identifier change absorbed (update_profile.go already re-keys, ~60-90), provider export #526 maintainer RFC, multi-email #395, role cleanup #425. Maintainer ships ~25 commits/week with Claude agent roles (AGENTS.md, worktree-agent branches), sweeping storage parity and identity security, none in merge/linking. |
| cnpm/cnpmcore (736, MIT, TS) | VIABLE (marginal), FALLBACK 2 | Package rename, **written 221 / 9 files**. Unpublish/republish #342/#435/#295/#949/#781, per-registry identity #284/#341/#537/#417/#656, user rename absorbed, org rename sits on fengmk2's Org/Team security PRs of Oct 17-18. Needs postgres + redis started by test.sh. |
| cloudprober/cloudprober (708) | DEAD | 9 lanes: series retirement google #581 + #1162/#1445 merged; reload #644 + open PR #1200; churn open PR #1530 + maintainer "pool mode" plan; collisions #436-#445/#1274/#1489; alert retirement absorbed ~70-90; checkpointing #1168. |
| mayswind/ezbookkeeping (5786) | DEAD | Merge declined #709; currency change refused by design (#187/#635); export/import declined #653/#571; object purge is the micasa-reclaim class; sharding **written 132**; storage migration ~100. LudwigJMarx looks signature-like (3 PRs outside lanes). |
| neilotoole/sq (2573) | DEAD | `mv` cache carry absorbed ~100; SLQ per-dialect = maintainer roadmap (#836/#838/#681); diff = open maintainer PR #1002; `tbl rename` absorbed; scratch joins roadmap #999-#1014. Maintainer runs Claude-assisted maintenance and files his own gap issues everywhere. |
| drivendataorg/cloudpathlib (629) | DEAD (repo) | terminalchai signature burst (#600/#601/#602 on 10-09..10-11, #600 inside the cache-identity lane) plus a second signature-like account ai-m-kirk-51517. Version-pinned paths (L1) were tracker-clean and in-process gradable across rigs; recorded in the dossier in case the signature call is ever overruled. |
| siliconcompiler/siliconcompiler (pool) | DEAD | See Stage 0-bis. |

## RANK 1: safebucket/safebucket, cross-bucket transfer
- **HEAD:** 7b2bca5b643b91d277f368d38650c45c9283d201 (2026-10-19, "feat: add bucket description").
- **Licence and size:** Apache-2.0 (read), no vendored dirs. Go 56% / TS 36%, 991 stars.
- **Activity:** 300 commits in 12 months (dependabot 133, yohanleb 90, Renizmy 72). Two maintainers. 17 open PRs.
- **Signature accounts:** 0 in 800 PRs. **AI trailers:** 0.
- **Our submissions on the repo:** 0.
- **CI (Requirement 7):** untagged `go test ./...` and the integration workflow both green on main 2026-10-19.
- **Outsider summary:** "Let users move files and folders from one bucket to another bucket." Seafile's move-between-libraries makes it outsider-nameable; no tracker item names it (I re-ran six phrasings: "another bucket", "between buckets", "cross bucket", "move to bucket", "transfer files", "copy bucket" on issues and PRs: zero hits; the agent grepped every issue/PR body and comment). Mitigation: phrase meta.md on safebucket's own nouns (buckets, trash statuses, public shares and share_files, object metadata, activity).
- **Sketch:** `s_1019h74/sketch_safebucket_crossbucket-transfer_h74.patch`. **320 human-effective**, 451 raw, padding-floor 32 (the hook flags the five provider copy bodies and per-item activity loops as breadth; `bucket_move.go` + `sql/move.go` alone are ~257). Written, not compiled.
- **Footprint:** 12 production files, 4 subsystems:
  - storage: `interfaces.go` plus five providers (`rustfs.go`, `s3.go` + `s3common.go`, `aws.go`, `gcp.go`, `azure.go`);
  - services: `bucket_move.go`, wiring in `bucket.go`;
  - SQL: `sql/move.go`;
  - `activity/constants.go`, `models/move.go`.
  - Reading surface ~7.7 KLOC. No storage parity suite (provider tests are pure functions).
- **Traps (base file:line, from the dossier):**
  1. The in-bucket planner counts root-to-root moves as unchanged (`bucket_move.go:192` `sameFolder`, `:216`); bypassing it drops its duplicate-name check. F-39, misdirecting.
  2. The validator lets uploading files through (`bucket_move.go:175`); multipart state is cached by file id while the object path is rebuilt from `file.BucketID` (`garbage_collector.go:66-73`, `ConfirmShareUpload`). F-9 / F-59.
  3. `GetFolderSubtree` filters `status=created AND deleted_at IS NULL` (`sql/folders.go:16,21`): trashed/deleting/restoring descendants stay in A pointing at a folder now in B; restore and trash-marker paths rebuild from the old bucket (`folder_restore.go:300/382`). F-47 / F-39. This subtree also decides traps 4 and 6.
  4. Shares are keyed by bucket (`public_share.go:230`, `helpers/share.go:14-20`); a folder share on a moved folder still accepts uploads that create rows in A (`public_share.go:338/368`). F-59.
  5. Each backend spells the bucket-id metadata differently (`Bucket-Id` s3common, `x-goog-meta-bucket-id` GCS, `bucket_id` AWS, path-derived Azure `azure.go:184`); the AWS event parser treats a Copy event as an upload (`eventparser/aws.go:58`). F-59, per-backend difference.
  6. Order: copy inside the transaction, remove partial copies on failure, delete sources only after commit.
  7. Destination authorization: `AuthorizeGroup` checks only the path bucket (`authorizer.go:76`) with an admin bypass (`:60`). Independent.
- **Gate 1:** `MoveBody` has no destination bucket and JSON decoding is lax; a destination folder in B returns 404 via `LockMoveTarget(A, ...)`, and a null target leaves the item in A's root or "unchanged". Runtime probe OWED.
- **Stage 6 death-class guard (run by me on the dossier and the clone):**
  - **Q1:** yes. One transfer plan (top-level items + unfiltered subtree + validity) drives the DB re-key, share cleanup, the copy set, the rollback set and activity.
  - **Q2:** yes, moderately. Trap 3 feeds traps 4 and 6; bypassing trap 1 loses the duplicate check; traps 2/3 are what make trap 6's rollback fire; trap 5 couples the copy to the event path. Trap 7 is independent.
  - **Q3:** no standalone file (interface + five providers + service + SQL); 320 with internal walls, so the waiver would apply anyway. Not a printer/serializer.
  - **Q4 (Pre-Pick Guard 1-5):** #1 partial (status checks are validation, but the core is re-key + copy + share cleanup); #2 cross-subsystem; #3 the walls survive being stated (the subtree filter and the bucket-keyed shares sit in code the prompt cannot name); #4 not a port; #5 yes. Residual risk: "make X consistent with Y" chokepoint, softened because the in-bucket move IS where traps 1-3 live.
  - **Result:** GUARD PASSED.
- **Exclusivity / drift:** open PRs #1443/#1420 (transactional outbox, yohanleb) and #1445 (activity interfaces) do not touch `bucket_move.go`, `sql/move.go` or storage; #1413 file versions touches `bucket_file.go`/`models/file.go` (different capability, possible base drift on object keys). The move subsystem is a month old and maintainer-built: re-run Pattern 24 at submit.
- **Tests:** untagged `go test ./...` in package `services`, sqlite `:memory:` via the existing `setupUserServiceTestDB` pattern (bucket_test.go, user_test.go), a recording fake storage that can fail on the Nth copy, filesystem or fake activity logger. The meta must pin the new storage method (`CopyObject(srcPath, dstPath string, metadata map[string]string) error` in the sketch), and test.patch must add it to `gcStubStorage` in `workers/garbage_collector_test.go` (new-API compile-wipe memory). Provider bodies are ungraded by a fake: the builder should add httptest stub endpoints (config endpoint for rustfs/S3/Azure, `AWS_ENDPOINT_URL_S3`, `STORAGE_EMULATOR_HOST`) or stubbed providers become an FP hole.
- **Docker:** go.mod says `go 1.27.1` (install that toolchain in the Dockerfile); mattn sqlite needs CGO/gcc; CI creates a `web/dist/index.html` placeholder. The tagged integration suite needs Docker-in-Docker (testcontainers) and stays out of the untagged run.

## Fallbacks (written >= 220)
1. **authorizerdev/authorizer, merge users** (written 248 / 19 files, ~228 net, padding-floor 41). Passkey user handle on the device (go-webauthn checks userHandle against `WebAuthnID()` = `user.ID`, webauthn.go:205-251, misdirecting "failed to verify passkey"); unique indexes on org membership and authenticators; order against the existing UserOwnedCollections cascade and FGA purge (sql/user.go:89-104, admin_users.go:417); OpenFGA rejects a whole write on one duplicate tuple. One in-process test: SQLite + embedded OpenFGA + memory store + virtualwebauthn. Risks: six near-identical backend methods (only SQL graded; leanest passer ~180-200 if meta promises SQL only); outsider-nameable (Auth0/Keycloak linking); a maintainer with Claude agent roles shipping ~25 commits/week.
2. **cnpm/cnpmcore, package rename** (written 221 / 9 files, marginal). Dist rows carry their own path; leaving files in place breaks only when the old name is republished; tarball re-pack for `strictValidateTarballPkg`; manifests rebuilt from per-version files; rollback journal; team bindings by packageId. Needs postgres + redis in test.sh. Risks: 221 at the bar; "rename a keyed entity in a registry" sits near the centraldogma rename class; ~14 rules vs the requirement-count gate.
3. Carried from #73: go-workflows reset (469), kellnr retention (303), tork concurrency groups (256).

## Side findings
- **The storage-topic PAIR sweep is a cheap multi-backend lens**, but at 505-6000 stars it returns mostly ORMs, SQL clients and boilerplates; only 4 of 107 unjudged rows were app/engine-shaped and screen-clean.
- **App lanes that survived were again invented from storage identity** (cross-bucket transfer, merge users, package rename). Tracker-dense apps (ezbookkeeping, cloudprober, sq) die on maintainer declines and roadmap issues.
- **Signature accounts:** added `terminalchai` (Codex-assisted, ~1 PR/day across 112 repos, touched str0m) and `ai-m-kirk-51517` to `sig_accounts.txt`. Watch (not added): LudwigJMarx (ezbookkeeping, many unrelated repos since 2026-04), no-hup (sq, eval tooling, 5 PRs Aug-Sep).
- **Maintainers working with coding agents are now common** (authorizer AGENTS.md roles, sq CLAUDE.md + skills, siliconcompiler Claude Code PRs, cloudprober Claude footers, cloudpathlib co-author trailers). Read the subjects against the lane, as the rule says; it killed nothing here by itself.

## Submission counts (warning only)
- siliconcompiler 1. Zero on safebucket, authorizer, cnpmcore and every other screened repo.

## Verdict rows
`judged.tsv`: 29 rows appended (backup `s_1019h74/judged.bak_h74`): CANDIDATE safebucket; fallbacks authorizer and cnpmcore; dead lanes on safebucket, authorizer, cnpmcore, cloudprober, ezbookkeeping, sq, siliconcompiler; repo-scope kills cloudpathlib, requests-cache, trdsql, dbos-transact-py, tududi, myduckserver, Palmr; screen notes for peekaping, pgschema, stackql, promxy, graphjin, carbon, checkcle, zipline, wishlist, jjui, openworkflow, glauth.

## NEXT_HUNT_HINT
- Keep the keyed-identity lens; the surviving shape is "move or fold an entity across a boundary the repo treats as fixed" (bucket, account, package name).
- Unaudited, screen-clean leftovers: stumpapp/stump (Rust + TS, check CI and build weight first), allegro/ralph (Django CMDB), aserto-dev/topaz, SOCI/soci (C++ backend parity suite, tracker-dense), k1LoW/tbls (CI `build` red on main: check whether it is a test job).
- The topic-pair sweep is spent at 505-6000 for the 29 pairs listed; widen to pairs with message brokers (kafka+nats, rabbitmq+redis) or object stores (minio+filesystem) if repeated.
