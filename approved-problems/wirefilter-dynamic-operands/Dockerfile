FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest
WORKDIR /app
COPY . .
RUN rm -f rust-toolchain.toml \
    && cargo fetch \
    && cargo build --workspace --tests \
    && chmod -R a+rwX /app /opt/cargo
CMD ["/bin/bash"]
