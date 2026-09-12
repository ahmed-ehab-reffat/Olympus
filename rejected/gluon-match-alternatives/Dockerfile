FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest
WORKDIR /app
COPY . .
RUN cargo install cargo2junit --version 0.1.15 --locked \
    && cargo fetch --locked \
    && cargo build --locked --workspace \
    && chmod -R a+rwX /opt/cargo /opt/rustup /app
CMD ["/bin/bash"]
