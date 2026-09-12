FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest
WORKDIR /app
COPY . .
RUN cargo fetch \
    && cargo build -p yara-x --tests \
    && cargo build -p yara-x-cli --tests \
    && chmod -R a+rwX /app /opt/cargo
CMD ["/bin/bash"]
