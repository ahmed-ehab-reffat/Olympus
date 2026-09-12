FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest
WORKDIR /app
COPY . .
RUN cargo install cargo2junit --version 0.1.13 --locked && cargo fetch && cargo build --workspace
CMD ["/bin/bash"]
