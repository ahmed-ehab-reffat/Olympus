FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest
WORKDIR /app
COPY . .
RUN cargo install cargo2junit --version 0.1.15 && cargo fetch --locked && cargo build --workspace --tests && chmod -R a+rwX /app
CMD ["/bin/bash"]
