FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest
WORKDIR /app
COPY --chown=1000:1000 . .
RUN git config --system --add safe.directory '*' \
    && cargo install cargo2junit \
    && cargo fetch \
    && cargo test -p hayro-syntax -p hayro-write -p hayro-interpret -p hayro-cmap -p hayro-postscript --lib --no-run \
    && cargo test -p hayro-tests --test tests --no-run \
    && chmod -R a+rwX /opt/cargo \
    && find /app \( -type d -o -user 0 \) -exec chmod a+rwX {} +
CMD ["/bin/bash"]
