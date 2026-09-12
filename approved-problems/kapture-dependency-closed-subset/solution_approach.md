# Solution approach

Normalize and validate timestamp, physical-sensor, and camera-path selectors
against the complete source model. When image identifiers are present, scan
camera records first and collect only occurrences satisfying all three
selectors. Their timestamps form a second gate for every record family; camera
records additionally require a requested path. With no selector at all, return
a detached full copy.

Build or prune the selected model, collect used sensor IDs and record
timestamps, close nested rig ancestors to a fixed point, and keep trajectories
only at selected timestamps for retained physical sensors or required rigs.
Derive surviving images from camera record paths, intersect feature metadata,
retain matches with both endpoints, and rebuild points/observations together in
source point order.

For directory output, finish all loading, model writing, and retained payload
transfers in a sibling staging area before making destination state visible.
For an existing destination, enumerate the old paths owned by its public model:
metadata, record payload values, ordinary feature/match identifiers, feature
configuration files, and tar archives. Form a candidate that removes those old
owned paths while preserving every other file, then overlay the staged subset.
An inverse plan—start with staged output and copy only old unowned files—is
equivalent. Commit with a backup/restore boundary. For a fresh destination,
publish the completed staging tree in one commit. Clean staging artifacts on
every path.

Expose repeatable `--image` alongside the existing selectors, delegate the CLI
to the saved API, register the exact PEP 621 target, and include the algorithm
module in the installed distribution.
