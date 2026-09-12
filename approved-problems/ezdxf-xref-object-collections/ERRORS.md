# Errors and resolved findings — ezdxf XREF object collections

## Docker base, workdir, and reproducibility

Version 1 used an unapproved upstream base and `/src`. The current Dockerfile
starts with the approved Olympus Python image, uses `/app`, installs an exact
pinned dependency set at build time, and installs the checkout editably without
dependency resolution. Version 7 passes the complete offline, read-only,
non-root gate.

Earlier PySide6 collection attempts missing `libEGL.so.1` and then
`libxkbcommon.so.0` remain quarantined environment failures. They were never
counted as behavioral or calibration evidence.

## Mandatory easing history

All eight clean version-2 solvers treated XREF/NUM prefixes as conflict
resolution and retained a free key. Version 3 removed that 8/8 interpretation
trap and tests prefixes only on occupied keys.

Version 3 then solved 0/5. Four implementations correctly isolated a
soft-owned leaf but omitted an empty nested dictionary stored as another soft
entry. Version 4 narrows the public contract and fixture to soft-owned
non-dictionary entries. The removed management-container cell is not enforced
indirectly elsewhere.

## Pointer classification coverage

The former XRECORD tests centered on 330, 340, and 360, allowing per-code
hard-coding. Version 4 adds representative 350, 390, 480, and 1005 cases plus an
unchanged 320 boundary. The 390- and 480-only targets are otherwise unselected,
so they prove discovery as well as translation. A distinct 330-only target
still proves that soft pointers do not create reachability.

Group 1005 belongs to XDATA. The final fairness pass moved it from ordinary raw
tags to valid XDATA created through `set_xdata()`, while retaining source and
save/reload checks. Unknown ordinary and embedded raw groups independently
cover the other pointer categories.

## KEEP conflict cleanup

The earlier reference destroyed a conflicting named parent but could leave an
already-copied hard-owned child live and unattached. Version 4 discards that
dependent subgraph unless an object is otherwise retained, and redirects
surviving references to the existing target leaf. Separate mutants prove that
parent-only cleanup and cleanup-without-redirection are both rejected.

## Copied dictionary-wide defaults

A selected `DictionaryWithDefault` formerly retained its source-side `_default`
and group-340 handle. The reference registers the unnamed default, maps it to a
target copy, updates ownership, and verifies save/reload. A reused target
management dictionary still retains its existing target default. Version 4 now
states copied-default ownership directly.

## Description quality and prescriptiveness

The compressed sentence “is management structure and is reused” was rewritten
as natural maintainer prose. The pointer paragraph now states observable group
categories and behavior; it no longer directs contributors to internal DXF
classification helpers.

## Matching hard-dictionary reuse

Generic KEEP conflict handling previously discarded a selected hard-owned
dictionary when the target already contained a dictionary under the same key.
Version 5 reuses that target dictionary, preserves its resident entries, moves
the copied source content into it with correct ownership, and verifies audit
and save/reload. A non-dictionary occupant remains a real conflict.

## Resource-reached conflict policies

XREF_PREFIX and NUM_PREFIX were covered only for directly selected leaves. A
hard resource reference can reach a named leaf through a different placement
branch, allowing direct-only conflict handling to pass. Version 5 adds one
otherwise unselected named resource per policy and observes only that the
existing key survives, the import receives a unique key, and the copied
reference resolves to the import. No exact generated key is required.

## Generated-key collision depth

The former prefix tests exercised only the first occupied source key. A fixed
one-shot generated key could therefore pass. Version 6 performs two transfers
with the same source key and prefix, requiring both imported payloads under
distinct keys without asserting either generated spelling.

## Pointer range endpoints

The public ranges were previously sampled only at lower representatives.
Version 6 adds valid 339, 349, 359, 369, 399, and 481 tags to the existing
XRECORD graph. Separate endpoint mutants all fail that case, while interior
codes remain grouped with their already tested classifier branch.

## Shared descendant and merged-default lifecycle

Ownership-only KEEP cleanup previously destroyed a hard-owned child even when
another surviving selected holder hard-referenced it. The reference now tracks
incoming hard dependencies, retains such a child, and cleans only the
unretained part of the discarded ownership graph.

Destroying a temporary copied `DictionaryWithDefault` after merging its named
contents could leave its separately registered source default alive and
unattached. Version 6 applies the same final retention analysis to that unnamed
default: a reused target keeps its own default, and the unused source-default
copy is removed before audit and reload.

## Inline hard-owned child identity

A hard-owned dictionary copies its entries inline, but resource registration
could also queue one of those entries independently. The later independent copy
overwrote the source handle's inline mapping and was treated as a real leaf-key
conflict under XREF_PREFIX or NUM_PREFIX. The target then contained both the
inline child and a generated-key duplicate.

Version 7 marks hard-owned inline descendants before their resources register.
It suppresses later discoveries and removes a child that was explicitly queued
before its parent. Separate tests cover a sibling hard pointer to an inline
child and child-first direct selection. Both require one final object and one
named entry under XREF_PREFIX and NUM_PREFIX.

## Unknown-object XDATA mapping

The unknown-object fixture previously exercised ordinary raw subclasses and
embedded groups but no XDATA. An implementation could therefore omit the base
entity mapper while preserving both raw containers. Version 7 attaches valid
group-1005 XDATA through `set_xdata()` and verifies its target-side handle live
and after reload while keeping the source unchanged.

## Description readability

The complete contract formerly appeared as five dense paragraphs. Version 7
keeps the behavior unchanged but separates selection, path/conflict handling,
ownership/identity, opaque handles, and persistence into short maintainer-style
sections. It does not expose hidden fixtures or prescribe internal helpers.

## Current invalidation boundary

The exact environment, gap, fairness, false-positive, replay, and mutation
results apply only to the version-7 hashes recorded in the audit files. Any
submission-artifact or evaluator-path change invalidates them and restarts
calibration at 0/10.
