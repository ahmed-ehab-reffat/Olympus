# Repository map — ICU4X ZeroTrie cursor parity

- `utils/zerotrie/src/cursor.rs`: existing public cursor APIs for simple ASCII
  and ASCII-ignore-case tries; natural home for new public wrappers.
- `utils/zerotrie/src/reader.rs`: serialized node reader, ordinary multi-layout
  lookup, ASCII-only cursor helpers, PHF-aware allocating iterator, and branch
  offset decoding.
- `utils/zerotrie/src/options.rs`: the four layout policies and their concrete
  type assignments.
- `utils/zerotrie/src/zerotrie.rs`: concrete trie variants, runtime flavor,
  store conversion/borrowing, ordinary lookup, builders, and iterators.
- `utils/zerotrie/src/byte_phf/`: PHF lookup and serialized edge-table rules.
- `utils/zerotrie/src/builder/`: repository-native generation of span,
  binary-search, and PHF fixtures.
- `utils/zerotrie/tests/`: existing package-level behavior and builder tests.
- `Cargo.toml`, `Cargo.lock`, and `rust-toolchain.toml`: exact workspace,
  dependency, and Rust 1.97.1 environment inputs.
