FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest

WORKDIR /app

COPY . .

RUN cargo install cargo-nextest --version 0.9.140 --locked
RUN cargo fetch --locked
RUN cargo build --locked --no-default-features --features rust-crypto --all-targets

CMD ["/bin/bash"]
