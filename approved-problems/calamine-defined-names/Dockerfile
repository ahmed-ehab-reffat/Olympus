FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest

WORKDIR /app

COPY . .

RUN rustup toolchain install 1.88.0 --profile minimal --component rustfmt --component clippy --target wasm32-unknown-unknown

RUN cargo +1.95.0 install cargo-nextest --version 0.9.140 --locked

RUN test -f Cargo.lock || cargo +1.88.0 generate-lockfile
RUN cargo +1.88.0 fetch --locked
RUN cargo +1.88.0 build --locked --all-targets --all-features

ENV RUSTUP_TOOLCHAIN=1.88.0
ENV CARGO_NET_OFFLINE=true

CMD ["/bin/bash"]
