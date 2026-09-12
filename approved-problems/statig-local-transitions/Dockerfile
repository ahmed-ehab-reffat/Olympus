FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest

WORKDIR /app

COPY . .

# Pin the compiler used by the repository's current UI-test snapshots.
RUN rustup toolchain install 1.90.0 --profile minimal

# Test runner used by test.sh. It emits the JUnit XML consumed by the harness.
RUN cargo +1.90.0 install cargo-nextest --version 0.9.128 --locked

# Upstream ignores Cargo.lock. Resolve it once while networking is available,
# then fetch and build every workspace target needed by offline test runs.
RUN test -f Cargo.lock || cargo +1.90.0 generate-lockfile
RUN cargo +1.90.0 fetch --locked
RUN cargo +1.90.0 build --workspace --locked --all-targets --all-features

CMD ["/bin/bash"]
