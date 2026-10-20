FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest
WORKDIR /app
COPY --chown=1000:1000 . .
RUN git config --system --add safe.directory '*' \
    && cargo install cargo2junit \
    && cargo fetch \
    && cargo test --no-default-features --features flate2_rust --no-run \
    && chmod -R a+rwX /opt/cargo \
    && find /app \( -type d -o -user 0 \) -exec chmod a+rwX {} +
CMD ["/bin/bash"]
