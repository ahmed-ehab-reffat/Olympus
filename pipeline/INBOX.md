# Factory inbox

Add one line per message under "New". The loop picks it up (it watches this file), acts on it, and moves
the line to "Processed".

    <slug>: clean                   precheck passed; the loop records it and leaves the problem to you
    <slug>: finish                  you want the LOOP to finish this one instead of doing it yourself
    <slug>: finish | <pasted precheck warnings>  same, with warnings for the loop to fix
    <slug>: dead <reason>           precheck dedupe/scope failed -> loop shelves it to rejected/
    <slug>: picker-refused          repo reserved on the platform -> shelve + SATURATED-REPOS A0
    <slug>: claimed                 you took it into your own session; the loop leaves it alone
    hunt-hint: <text>               steer the next hunts (languages, domains, repos to try or avoid)

## New

## Processed

    dyn4j-world-copy: dead derivative overlap Blocker 52.9% of rival   (said in session 2026-09-24; handled)

    teavm-method-summaries: claimed   (said in session 2026-09-23; handled)
    bayesopt-search-space-migration: claimed   (said in session 2026-09-23; handled)
    pict-engine-negative-values: claimed   (said in session 2026-09-23; handled)

    piscsi-image-reservation-identity: claimed   (said in session 2026-09-23; handled)

    openglobus-entitycollections-tree-maintenance: dead derivative overlap Blocker 46.7%   (said in session 2026-09-22; handled)

    pyocd-sequence-expression-kernel: claimed   (said in session 2026-09-21; handled)

    messageformat/messageformat: claimed   (said in session 2026-09-19; handled)
    libspatialindex-tpr-temporal-knn: clean   (precheck passed, no warnings; said in session 2026-09-19; handled)
    libspatialindex-tpr-temporal-knn: claimed   (said in session 2026-09-20; handled)
    pyfakefs-block-inode-accounting: claimed   (said in session 2026-09-20; handled)
    siliconcompiler-flist-roundtrip: clean   (picker eligible + precheck passed, no warnings; 2026-09-20; recorded)
    siliconcompiler-flist-roundtrip: claimed   (2026-09-20; handled - the human finishes it)
