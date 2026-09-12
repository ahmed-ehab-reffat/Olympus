FROM public.ecr.aws/d3j8x8q7/olympus-base:latest

WORKDIR /app

ENV CARGO_HOME=/root/.cargo
ENV RUSTUP_HOME=/root/.rustup
ENV PATH=/usr/local/bin:/root/.cargo/bin:$PATH
ENV CARGO_HTTP_MULTIPLEXING=false

COPY . /app

RUN for f in /root/.cargo/bin/*; do install -m 0755 "$f" /usr/local/bin/; done && \
    cargo install cargo-nextest --version 0.9.78 --locked --root /usr/local && \
    cargo fetch && \
    cargo build --workspace --tests && \
    chmod a+rx /root && \
    chmod -R a+rX "$CARGO_HOME" "$RUSTUP_HOME" && \
    chmod -R a+rwX /app

CMD ["bash"]
