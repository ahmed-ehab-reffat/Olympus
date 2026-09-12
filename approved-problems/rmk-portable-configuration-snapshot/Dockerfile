FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest

RUN apt-get update \
    && apt-get install -y --no-install-recommends libdbus-1-dev=1.14.10-1~deb12u1 \
    && rm -rf /var/lib/apt/lists/*

ENV RUSTUP_TOOLCHAIN=1.95.0

RUN rustup target add wasm32-unknown-unknown
RUN cargo install cargo-nextest --version 0.9.128 --locked
RUN cargo install wasm-bindgen-cli --version 0.2.126 --locked
RUN cargo install cargo-expand --version 1.0.124 --locked

WORKDIR /app
COPY . .

# Warm the dependencies used by the post-build WASM test crate. Restore the
# participant-facing manifest, then leave a lock that matches that pristine
# workspace so the verifier's preliminary locked metadata query can run.
RUN cp rynk/rynk-wasm/Cargo.toml /tmp/rynk-wasm-Cargo.toml \
    && printf '\n[dev-dependencies]\nwasm-bindgen-test = "=0.3.76"\nserde = "=1.0.229"\n' \
        >> rynk/rynk-wasm/Cargo.toml
RUN cargo generate-lockfile --manifest-path rynk/Cargo.toml
RUN cargo fetch --manifest-path rynk/Cargo.toml --locked
RUN cargo fetch --manifest-path rynk/rynk-wasm/Cargo.toml \
    --target wasm32-unknown-unknown --locked
RUN cargo generate-lockfile --manifest-path rmk/Cargo.toml
RUN cargo fetch --manifest-path rmk/Cargo.toml --locked
RUN cargo generate-lockfile --manifest-path rmk-macro/Cargo.toml
RUN cargo fetch --manifest-path rmk-macro/Cargo.toml --locked
RUN cargo build --manifest-path rynk/Cargo.toml \
    --workspace --all-targets --locked --offline
RUN cargo build --manifest-path rmk/Cargo.toml \
    --no-default-features --locked --offline
RUN cargo build --manifest-path rmk-macro/Cargo.toml --locked --offline
RUN cargo check --manifest-path rynk/rynk-wasm/Cargo.toml \
    --target wasm32-unknown-unknown --locked --offline
RUN install -m 0644 /tmp/rynk-wasm-Cargo.toml rynk/rynk-wasm/Cargo.toml
RUN cargo generate-lockfile --manifest-path rynk/Cargo.toml --offline
RUN cargo metadata --manifest-path rynk/Cargo.toml \
    --format-version 1 --locked --offline > /dev/null
RUN cargo build --manifest-path rynk/Cargo.toml \
    --workspace --all-targets --locked --offline
RUN cargo check --manifest-path rynk/rynk-wasm/Cargo.toml \
    --target wasm32-unknown-unknown --locked --offline

# Evaluation runs offline as an arbitrary unprivileged UID. Cargo preserves a
# few restrictive modes from crate archives, so normalize read/search access
# after warming the cache and installing the nested-build tools.
RUN chmod -R a+rX /opt/cargo /opt/rustup

CMD ["/bin/bash"]
