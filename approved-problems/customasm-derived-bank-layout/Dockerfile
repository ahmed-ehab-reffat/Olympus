FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest
WORKDIR /app
COPY . .
RUN cargo fetch --locked \
    && cargo build --locked --tests \
    && chmod -R a+rwX /opt/cargo /opt/rustup /app
CMD ["/bin/bash"]
