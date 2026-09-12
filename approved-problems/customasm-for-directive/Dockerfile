FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest
WORKDIR /app
COPY . .
RUN cargo fetch \
    && cargo build --tests \
    && chmod -R a+rwX /app /opt/cargo
CMD ["/bin/bash"]
