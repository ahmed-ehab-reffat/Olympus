FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest
WORKDIR /app
COPY --chown=1000:1000 . .
RUN cargo install cargo2junit --version 0.1.15 && cargo fetch && cargo build --workspace \
    && cargo test --no-run -p rosomaxa -p vrp-core -p vrp-pragmatic --lib \
    && find /app \( -type d -o -user 0 \) -exec chmod a+rwX {} + \
    && chmod -R a+rwX /opt/cargo
CMD ["/bin/bash"]
