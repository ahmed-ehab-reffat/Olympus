FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest

ENV RUSTUP_TOOLCHAIN=1.95.0
ENV CARGO_HOME=/opt/cargo

RUN cargo install cargo-nextest --version 0.9.140 --locked
RUN cargo install cargo-expand --version 1.0.124 --locked

WORKDIR /app
COPY . .

ARG LIBDBUS_DEV_VERSION=1.14.10-1~deb12u1
ARG PKG_CONFIG_VERSION=1.8.1-1
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        "libdbus-1-dev=${LIBDBUS_DEV_VERSION}" \
        "pkg-config=${PKG_CONFIG_VERSION}" \
    && rm -rf /var/lib/apt/lists/*

# Build the primary crate from the pristine checkout while the network is
# available. Seed resolution from an upstream-committed lock, compile the exact
# compatible feature lane used by the harness, and leave the resulting lock at
# the package root. Both participant validation and the evaluator use this
# visible file; no second hidden lock is substituted at runtime.
RUN mkdir -p /opt/rmk-handoff \
    && cp examples/use_config/nrf52840_ble/Cargo.lock rmk/Cargo.lock \
    && KEYBOARD_TOML_PATH=/app/examples/use_config/nrf52840_ble/keyboard.toml \
        cargo build --manifest-path rmk/Cargo.toml \
            --no-default-features \
            --features=rynk,_ble,split,async_matrix,storage,steno \
    && KEYBOARD_TOML_PATH=/app/examples/use_config/nrf52840_ble/keyboard.toml \
        cargo test --manifest-path rmk/Cargo.toml \
            --no-run \
            --no-default-features \
            --features=rynk,_ble,split,async_matrix,storage,steno \
    && chmod a+r rmk/Cargo.lock

# Nextest inspects all optional features during metadata discovery. Fetch every
# package named by the pristine-build lock, including target-only dependencies.
RUN cargo fetch --manifest-path rmk/Cargo.toml --locked

# Cache the repository's standalone proc-macro test graph, including the
# macrotest and trybuild dev-dependencies used by its _simulator tests. Retain
# this package lock so the same target starts without network access at runtime.
RUN cargo test --manifest-path rmk-macro/Cargo.toml \
        --no-run \
        --features=_simulator \
    && cargo fetch --manifest-path rmk-macro/Cargo.toml --locked

# Keep the externally reported archive explicit even if resolver/index state
# differs across image builders.
RUN cargo info bytemuck@1.25.2

# Build the supported native sibling workspace and retain its independently
# resolved lock outside the source tree. This also caches nusb, wasm bindings,
# and the Linux BLE dependencies before runtime networking is disabled.
RUN cargo build --manifest-path rynk/Cargo.toml \
    && cp rynk/Cargo.lock /opt/rmk-handoff/rynk.Cargo.lock \
    && rm rynk/Cargo.lock

RUN cp /opt/rmk-handoff/rynk.Cargo.lock rynk/Cargo.lock \
    && cargo fetch --manifest-path rynk/Cargo.toml --locked \
    && rm rynk/Cargo.lock

# Some upstream crate archives preserve owner-only source modes. Normalize only
# the downloaded sources and git checkouts required by the arbitrary-UID runner.
RUN chmod -R a+rX \
    /opt/cargo/registry \
    /opt/cargo/git/checkouts \
    /opt/rmk-handoff
RUN cd / && git config --file /etc/gitconfig --add safe.directory '*'

CMD ["/bin/bash"]
