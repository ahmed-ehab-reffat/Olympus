FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest

WORKDIR /app
COPY . .

RUN cargo fetch \
    && cargo build \
    && chmod -R a+rwX /app /opt/cargo \
    && chmod -R a+rX /opt/rustup

CMD ["/bin/bash"]
