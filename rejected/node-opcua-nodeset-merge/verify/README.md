# Verification helper

`mutations.sh` composes the exact reference and verifier patches over the pinned
pristine checkout, creates nineteen isolated plausible defects, and runs each
offline as UID 10001. A focused survivor is automatically escalated to the
complete pre-existing `node-opcua-address-space` Mocha suite after removing the
hidden test file from the disposable runtime tree.

An optional third argument is a comma-separated mutation filter, used for an
isolated detail replay.

Run from the workspace root:

```sh
problems/node-opcua-nodeset-merge/verify/mutations.sh \
  /path/to/node-opcua-at-e233d906 \
  node-opcua-nodeset-merge-phase-a
```
