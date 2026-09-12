FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends clang=1:14.0-55.7~deb12u1 \
    && rm -rf /var/lib/apt/lists/*

RUN rustup toolchain install 1.91.1 \
        --profile minimal \
        --component clippy,rustfmt \
    && rustup target add wasm32-unknown-unknown --toolchain 1.91.1 \
    && rustup default 1.91.1

RUN cargo install just --version 1.43.1 --locked \
    && cargo install wasm-pack --version 0.13.1 --locked \
    && npm install --global pnpm@9.15.9

RUN cargo install cargo-nextest --version 0.9.128 --locked
RUN cargo install wasm-bindgen-cli --version 0.2.105 --locked

WORKDIR /app
COPY . .

ENV CC=clang

RUN cargo fetch --locked
RUN cargo build --workspace --all-features --locked
RUN test -f pnpm-lock.yaml && pnpm install --frozen-lockfile
RUN just build
RUN just package-sqlsync-worker dev
RUN cargo build --package sqlsync --lib --locked \
    && test -f target/debug/deps/libsqlsync.rlib
RUN command -v node \
    && command -v pnpm \
    && command -v wasm-pack \
    && rustup target list --installed | grep -qx wasm32-unknown-unknown

CMD ["/bin/bash"]
