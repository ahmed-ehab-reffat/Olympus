# dyn4j-world-copy - eval results

No platform batch yet (slice awaiting the precheck).

## Local validation - SLICE (2026-09-23)

Image `factory-dyn4j-world-copy` built cold from a pristine clone at bcf942ad (~35 s), patches applied
inside the container, `--network none`.

| run | user | result |
|---|---|---|
| base, test.patch only | 1000 / 0 / 4242 | 2385 pass, exit 0 |
| new, test.patch only | 1000 / 0 / 4242 | 10 fail (compile, per-test fallback with javac log), exit 1 |
| base, both patches | 1000 / 0 / 4242 | 2385 pass, exit 0 |
| new, both patches | 1000 / 0 / 4242 | 10 pass, exit 0 |
| flakiness base x3 | 1000 | identical, 2385 pass |
| flakiness new x3 | 1000 | identical, 10 pass |

LOC: 573 raw added / 225 honest human-effective (hook: 461, over-counts javadoc).

## Mutant kill table (reference mutated, scene battery, first divergent step; -1 = survives 300 steps)

| mutant | settled | removals | moving@45 | vardt | accum | userflags | overlap-add | listener | query |
|---|---|---|---|---|---|---|---|---|---|
| tree rebuilt via addBody | -1 | 59 | 20 | -1 | -1 | -1 | 2 | -1 | -1 |
| contacts re-detected | 1 | 1 | 1 | 1 | 1 | 1 | - | - | - |
| impulses dropped | 1 | 1 | 1 | 1 | 1 | 1 | - | - | - |
| fresh TimeStep | -1 | -1 | -1 | 1 | -1 | -1 | - | - | - |
| time not copied | -1 | -1 | -1 | -1 | 1 | -1 | - | - | - |
| constraint user state reset | -1 | -1 | -1 | - | - | 1 | -1 | -1 | -1 |
| pending updates dropped | -1 | -1 | -1 | -1 | -1 | -1 | 2 | -1 | -1 |
| contactCollisions dropped | -1 | -1 | -1 | -1 | -1 | -1 | -1 | kill | -1 |
| data flags dropped | -1 | -1 | -1 | -1 | -1 | -1 | -1 | -1 | kill |
| default filter shared | 2 | 2 | 2 | - | - | 2 | 2 | kill | -1 |
| CCD tree rebuilt | -1 | -1 | -1 | -1 | -1 | -1 | -1 | -1 | -1 |
| graph replayed (flags kept) | -1 | -1 | -1 | -1 | -1 | -1 | - | - | - |
