FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest

WORKDIR /app
COPY . .

# The test patch (the new integration test plus test.sh) is applied after this image is
# built, and there is no network at run time, so every dependency has to be fetched and
# the crate and its test binaries compiled here. The lock file is resolved once during
# this step and stays in the image, so the offline build the agent runs uses exactly the
# versions resolved here (upstream keeps Cargo.lock out of the repository, so there is
# nothing to pin against at COPY time). benches/ is deliberately left out of the build:
# it opens with #![feature(test)] and only compiles on a nightly toolchain, which is why
# --all-targets cannot be used. Symlinking the toolchain onto the default PATH lets the
# non-root agent find cargo in a non-login shell, and the chmod lets it write the cargo
# cache, the lock file and the target tree.
RUN for f in /opt/cargo/bin/*; do ln -sf "$f" /usr/local/bin/; done \
    && cargo fetch \
    && cargo build --workspace --tests \
    && chmod -R a+rwX /app /opt/cargo /opt/rustup

CMD ["/bin/bash"]
