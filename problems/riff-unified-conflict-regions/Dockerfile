FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest
WORKDIR /app
COPY --chown=1000:1000 . .
RUN cargo install cargo2junit \
    && cargo fetch \
    && cargo build \
    && cargo test --no-run \
    && git config --system --add safe.directory /app \
    && chmod -R a+rwX /opt/cargo \
    && find /app \( -type d -o -user 0 \) -exec chmod a+rwX {} +
CMD ["/bin/bash"]
