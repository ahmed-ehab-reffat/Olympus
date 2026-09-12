FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest

WORKDIR /app
COPY . .

# Install cargo-nextest (test.sh runs the suites through it for native JUnit output) through the cargo
# package manager at a pinned version with `--locked`, so the build is reproducible from
# version-locked crates.io sources without fetching an external file directly, and symlink the
# toolchain onto the default PATH so the non-root agent resolves cargo/rustc/rustup/nextest in any
# shell (the base image keeps them under /opt/cargo/bin, which a non-login shell drops). Internet is
# available during build but not at run time, and the test patch (the new integration test plus
# test.sh) is injected AFTER this build, so fetch every dependency and pre-compile the workspace and
# the library test binary here; the injected integration test then compiles offline at run time
# against the cached artifacts. The chmod lets the non-root UID-1000 agent write the cargo cache and
# the target tree offline.
ENV NEXTEST_VERSION=0.9.138
RUN cargo install cargo-nextest --version "${NEXTEST_VERSION}" --locked --root /usr/local \
    && for f in /opt/cargo/bin/*; do ln -sf "$f" /usr/local/bin/; done \
    && cargo fetch \
    && cargo build --workspace \
    && cargo nextest run --no-run -p tantivy --lib \
    && chmod -R a+rwX /app /opt/cargo /opt/rustup

CMD ["/bin/bash"]
