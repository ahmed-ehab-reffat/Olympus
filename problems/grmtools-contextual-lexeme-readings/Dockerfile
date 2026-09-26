FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest
WORKDIR /app
COPY --chown=1000:1000 . .
RUN cargo install cargo2junit \
    && cargo fetch \
    && cargo build --workspace --tests \
    && git config --system --add safe.directory '*' \
    && find /app /opt/cargo \( -type d -o -user 0 \) -exec chmod a+rwX {} +
CMD ["/bin/bash"]
