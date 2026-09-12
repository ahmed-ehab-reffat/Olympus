# Repository map

Repository pin: `dnsjava/dnsjava@06a0599933114f36efe59667cd80ee0246a1a882`.

| Path | Role in this task |
|---|---|
| `src/main/java/org/xbill/DNS/Zone.java` | live zone storage, read/write locks, derived state, mutation, validation, and the new public operation |
| `src/main/java/org/xbill/DNS/ZoneTransferIn.java` | transfer execution, current/IXFR/AXFR modes, wire parser, and ordered public delta lists |
| `src/main/java/org/xbill/DNS/Serial.java` | repository RFC 1982 comparison semantics |
| `src/main/java/org/xbill/DNS/Record.java` | DNS record equality, including TTL-insensitive identity used by deletion |
| `src/main/java/org/xbill/DNS/RRset.java` | ordinary records and covered-type signatures observed after publication |
| `src/test/java/org/xbill/DNS/ZoneTest.java` | primary existing zone behavior and constructor invariants |
| `src/test/java/org/xbill/DNS/ZoneWithSoaSigTest.java` | existing signed-SOA zone behavior |
| `src/test/java/org/xbill/DNS/SerialTest.java` | existing serial arithmetic regression cases |
| `src/test/java/org/xbill/DNS/TSIGTest.java` | existing package-local transfer/client fixture precedent |
| `src/test/java/org/xbill/DNS/ZoneIXFRApply0db94eTest.java` | randomized additive 17-case feature suite injected by `test.patch` |
| `test.sh` | offline base/new selector and Surefire XML aggregator injected by `test.patch` |

The reference changes only `Zone.java`; that file layout and its staged map are
not hidden requirements.
