FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest

WORKDIR /app

# Cargo.lock at the pinned Railway revision resolves crates requiring Rust 1.88.
RUN rustup toolchain install 1.88.0 --profile minimal

# The harness uses nextest for non-fail-fast execution and JUnit output.
RUN cargo +1.88.0 install cargo-nextest --version 0.9.100 --locked

COPY . .

RUN cargo +1.88.0 fetch --locked
RUN cargo +1.88.0 build --locked --all-targets

CMD ["/bin/bash"]
