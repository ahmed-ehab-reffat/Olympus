FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest

WORKDIR /app
COPY . .

RUN chmod -R a+rwX /opt/cargo /opt/rustup \
    && cargo fetch \
    && cargo build --workspace \
    && chmod -R a+rwX /opt/cargo /app

CMD ["/bin/bash"]
