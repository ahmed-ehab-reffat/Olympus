# Revision v9 compatibility replays

These five patches contain only participant-owned source changes from `agent-runs6`. The platform patches also recorded generated `build-bootstrap` files that do not exist in the exact clean checkout, so those generated diffs were removed before evaluator-composition checks.

The filtered patches are compatibility injections, not revision v9 solutions. All five solved revision v8, but none implements the new selective rewrite API. Their use here proves that the final hidden patch still injects without participant/verifier path collisions; it does not assign a revision v9 behavioral score.
