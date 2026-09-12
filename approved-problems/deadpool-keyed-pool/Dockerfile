FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest

ENV CARGO_HOME=/opt/cargo
ENV PATH=/opt/cargo/bin:${PATH}

WORKDIR /app
COPY . .

# The repository ships standalone crates and has no root manifest, so cargo
# cannot be driven from the repository root at all. Add a workspace manifest
# covering the deadpool crate and the path dependency it needs, so that the
# usual `cargo build` / `cargo test` work from /app. The remaining crates pull
# in database drivers that need network access and system libraries, so they are
# excluded rather than made members.
RUN printf '%s\n' \
    '[workspace]' \
    'resolver = "3"' \
    'members = ["crates/deadpool", "crates/deadpool-runtime"]' \
    'exclude = [' \
    '    "crates/deadpool-diesel",' \
    '    "crates/deadpool-lapin",' \
    '    "crates/deadpool-libsql",' \
    '    "crates/deadpool-memcached",' \
    '    "crates/deadpool-postgres",' \
    '    "crates/deadpool-r2d2",' \
    '    "crates/deadpool-redis",' \
    '    "crates/deadpool-sqlite",' \
    '    "crates/deadpool-sync",' \
    '    "examples",' \
    '    "tools",' \
    ']' \
    > Cargo.toml

# Upstream ships no Cargo.lock (it is a library), so one is resolved once here and
# then treated as authoritative: every later command uses --locked, so the lock is
# never silently updated and the image resolves the same versions for its whole
# lifetime. Dependencies (including the dev-dependencies needed to compile the
# tests) are fetched so the container works fully offline. Test binaries are
# deliberately NOT compiled here: test.sh compiles and runs them at run time.
RUN cargo generate-lockfile \
    && cargo build --locked \
    && cargo build --locked -p deadpool --features rt_tokio_1 \
    && cargo fetch --locked \
    && chmod -R a+rwX /app /opt/cargo

ENV CARGO_NET_OFFLINE=true

CMD ["/bin/bash"]
