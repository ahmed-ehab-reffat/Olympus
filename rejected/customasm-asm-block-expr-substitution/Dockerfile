FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest
ENV RUSTUP_HOME="/root/.rustup"
ENV CARGO_HOME="/root/.cargo"
ENV PATH="/root/.cargo/bin:${PATH}"
WORKDIR /app
COPY . .
RUN chmod -R a+rX /root \
    && for f in /root/.cargo/bin/*; do ln -sf "$f" /usr/local/bin/; done \
    && cargo fetch && cargo build
CMD ["/bin/bash"]
