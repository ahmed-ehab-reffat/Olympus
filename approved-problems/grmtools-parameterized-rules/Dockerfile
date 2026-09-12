FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest
ENV CARGO_TARGET_DIR="/app/target"
WORKDIR /app
COPY . .
RUN cargo fetch \
    && cargo build --workspace --tests \
    && chmod -R a+rwX /app "$CARGO_HOME"
CMD ["/bin/bash"]
