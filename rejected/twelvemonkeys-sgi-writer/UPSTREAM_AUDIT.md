# Upstream audit

Repository: `haraldk/TwelveMonkeys`

Pinned commit: `41aaf3b1bc7fe8144b3bbd16c62d13a559feb7c5`

The candidate-stage audit searched repository history, open and closed GitHub issues and pull requests, Discussions, and source TODOs for SGI writing and `SGIImageWriter`. It found no owned or completed writer implementation. The SGI provider explicitly had reader entries and null writer entries at the pin.

The closest local precedent is the rejected Gimli missing-writer problem, which creates an architectural-discoverability concern but is neither the same repository nor the same binary format or behavior. The earlier TwelveMonkeys DDS source-selection candidate was also rejected for one-helper convergence; this problem uses independent SGI provider, header, layout, RLE, table, selection, and reader-interoperability boundaries.
