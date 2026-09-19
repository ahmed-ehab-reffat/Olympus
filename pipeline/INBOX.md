# Factory inbox

Add one line per message under "New". The loop picks it up (it watches this file), acts on it, and moves
the line to "Processed".

    <slug>: clean                   precheck passed and picker accepts the repo -> loop finishes the problem
    <slug>: clean | <pasted precheck warnings>   same, with warnings for the loop to fix
    <slug>: dead <reason>           precheck dedupe/scope failed -> loop shelves it to rejected/
    <slug>: picker-refused          repo reserved on the platform -> shelve + SATURATED-REPOS A0
    <slug>: claimed                 you took it into your own session; the loop leaves it alone
    hunt-hint: <text>               steer the next hunts (languages, domains, repos to try or avoid)

## New

## Processed

    messageformat/messageformat: claimed   (said in session 2026-09-19; handled)
    libspatialindex-tpr-temporal-knn: clean   (precheck passed, no warnings; said in session 2026-09-19; handled)
