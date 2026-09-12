# PcapPlusPlus SNAP encapsulation research archive

The SNAP problem was closed after external long-horizon scope rejection on
2026-08-06. Its exact package remains technically sound, but the 193-line
reference is localized to one parser/crafting subsystem. This archive was
created while cleaning the later TLS problem because both efforts shared one
scratch namespace.

Canonical SNAP artifacts remain in `problems/pcapplusplus-snap-encapsulation/`.
The preliminary candidate records moved here without content changes. Five
recovery patches preserve every distinct dirty checkout before cleanup:

| Artifact | SHA-256 |
|---|---|
| `prototype-recovery/final-exact.patch` | `a6360e4775476ac9c0d685394da2b6619a740633f17e8583b9314975403cabd5` |
| `prototype-recovery/probe-complete.patch` | `8d03aa87aabc0e906b9825c098592683ac448f1ee2ba04ddcbb2a8fb8c66e7d4` |
| `prototype-recovery/probe-minimal.patch` | `c6c15e34809d6bacf5e863b9e71a69095a3af2c883bb33bedceb90bd35e4c271` |
| `prototype-recovery/test-author.patch` | `4dd1705e92f6763cfabe80348dbc749430652360d272b3922e6155f674106664` |
| `prototype-recovery/test-only.patch` | `1e2a0c6f2ff3a8a68a51b3d152d4a91342749f06b7ad3ef3e1d2324313fe4b88` |

Every patch applies to the pinned PcapPlusPlus commit and reverse-applies to its
source checkout. Historical trailing blank lines are intentionally preserved.
`cleanup-inventory.tsv` records exact pre-cleanup sizes and dirty counts.

Candidate-record hashes are:

| Artifact | SHA-256 |
|---|---|
| `candidate-records/DESIGN.md` | `869a33eb788868dfe1df379d56b767ca9331f0956bfe2a480ed85b6a2c1fbcb6` |
| `candidate-records/ENVIRONMENT.md` | `69284264231ac5f3fd8f45a2df21c867a5a9646b2799c98d2a379433f458b007` |
| `candidate-records/PLAN.md` | `7d808245703a63acec652496516e8b9d709b7a884400117f726b8bc72708b12e` |
| `candidate-records/UPSTREAM_AUDIT.md` | `60950c8fbcc607e23a858bb8be48f1210553adb32d22baf79ea3ef182dee70fe` |

The shared scratch namespace was moved to recoverable macOS Trash only after
these checks passed. Do not revive this task by padding it with documentation,
examples, or unrelated capture features.
