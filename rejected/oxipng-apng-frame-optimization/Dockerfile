FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest
WORKDIR /app
COPY . .
RUN cargo install cargo2junit \
    && cargo fetch \
    && cargo test --features sanity-checks --no-run --lib --bins --test alpha --test filters --test flags --test lib \
    && chmod -R a+rwX /opt/cargo /app
CMD ["/bin/bash"]
