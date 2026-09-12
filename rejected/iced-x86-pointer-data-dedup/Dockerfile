FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest
WORKDIR /app
COPY . .
RUN cargo install cargo2junit && cargo fetch --manifest-path src/rust/Cargo.toml && cargo build --manifest-path src/rust/Cargo.toml --workspace
CMD ["/bin/bash"]
