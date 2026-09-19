---
Repository: https://github.com/featurevisor/featurevisor
Issue: N/A
Commit: b88f3981989c3cc7a06efea2597807517a624d16
Language: TypeScript
Category: feature-request
Title: Keep bucketed users in place when traffic changes
---

# Keep bucketed users in place when traffic changes

Make the datafile builder move as few bucketed users as possible when a feature's traffic changes. Today `getTraffic` only carries allocations over when a rule's percentage grows; a decrease, a weight change, an added or removed variation, or weights overridden on the rule all throw the previous allocation away and refill from the start, so users change variation for no reason.

Bucket values run from 0 to 100000, and a share of one percent is 1000 of them. A rule's region is the first `percentage` bucket values of the ranges the feature may use, walked in order, which is the whole space for a feature outside a group and the feature's slot ranges inside one. Each variation's target is its weight times the rule percentage, taking a weight the rule overrides through `variationWeights`, zero included, over the one on the variation.

Build each rule's allocation from the previous release's allocation for that same rule key. A variation keeps its own previous bucket values that still fall inside the region, lowest first, up to its target. Bucket values of variations that are gone, that fall outside the region, or that exceed their variation's target are free again, and so is everything the previous release never allocated. Then give every variation still short of its target the free bucket values, lowest first, taking the variations in the order the feature declares them. A rule with no previous allocation fills its whole region this way. Report the result sorted by bucket value, with neighbouring entries of one variation merged into a single range, and with empty ranges dropped. Building the same definitions again against the state the last build wrote must produce that same allocation.

Alongside this, report what each build moved. `buildDatafile` takes an optional `rebucketing` array in its options and appends one `RebucketingChange` for every rule whose previous allocation lost bucket values, in the order the features and rules are built. Each carries the `environment`, `feature` and `rule` it belongs to, then `kept`, `moved`, `added` and `removed` as bucket value counts, and a `variations` record giving `kept`, `gained` and `lost` per variation value. Kept means held by the same variation before and after, moved means taken by another variation, added means newly allocated, and removed means no longer allocated at all. `getAllocationChanges` in the builder's allocator computes the same figures from two allocations, treating a missing one as empty.

`buildProject` exports `formatRebucketing`, which turns those changes into one line each for the build output, naming the feature, the rule in parentheses, and the four figures as percentages with trailing zeros dropped, reading `kept 50%, moved 12.345%, added 0%, removed 20%`. A build prints them for its environment once its targets are done.
