FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest
ENV CARGO_HOME=/opt/cargo
WORKDIR /app
COPY . .
RUN cargo install cargo2junit --version 0.1.13 --root /usr/local \
    && cargo fetch --locked \
    && cargo build --workspace --locked --tests \
    && chmod -R a+rwX /opt/cargo /app
CMD ["/bin/bash"]
