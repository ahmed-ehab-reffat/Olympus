FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest

WORKDIR /app
COPY . .

# Symlink the toolchain into /usr/local/bin (which stays on the default and login-shell PATH) so cargo/
# rustc/rustup resolve in any shell -- the base image keeps them under /opt/cargo/bin, which a login shell
# drops from PATH. Pin to the toolchain that ships in the base image (the repo pins a newer one that is not
# installed and would need a network download). Internet is available during build but not at run time, and
# the test patch is injected after this build, so fetch every dependency and compile the crate and its
# existing tests here; the injected test then compiles offline at run time against the cached dependencies.
# chmod makes the build and toolchain caches writable by the non-root eval user.
RUN for f in /opt/cargo/bin/*; do ln -sf "$f" /usr/local/bin/; done \
    && echo "1.95.0" > rust-toolchain \
    && cargo fetch \
    && cargo build \
    && cargo test --lib --no-run \
    && chmod -R a+rwX /app "$CARGO_HOME" "$RUSTUP_HOME"

CMD ["/bin/bash"]
