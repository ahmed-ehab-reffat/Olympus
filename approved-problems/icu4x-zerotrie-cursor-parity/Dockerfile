FROM public.ecr.aws/d3j8x8q7/olympus-base:latest

ENV RUSTUP_TOOLCHAIN=1.97.1
ENV RUSTUP_HOME=/opt/rustup
ENV CARGO_HOME=/opt/cargo
ENV CARGO_TARGET_DIR=/opt/icu4x-target

RUN mkdir -p /opt/cargo/bin /opt/rustup \
    && cp "$(command -v rustup)" /opt/cargo/bin/rustup \
    && ln -s rustup /opt/cargo/bin/cargo \
    && ln -s rustup /opt/cargo/bin/rustc \
    && ln -s rustup /opt/cargo/bin/rustdoc

ENV PATH=/opt/cargo/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin

RUN rustup toolchain install 1.97.1 --profile minimal
RUN cargo install cargo-nextest --version 0.9.140 --locked

WORKDIR /app
COPY . .

# Resolve only from the repository's committed lockfile, then prebuild the
# package library without compiling repository test targets. The evaluator
# compiles the selected test lanes after composing the submitted patches.
RUN cargo fetch --locked
RUN cargo build --locked -p zerotrie --all-features
RUN cargo check --locked -p zerotrie --no-default-features --lib

# ICU4X's workspace test lane requires all features: the pristine tree has
# integration tests for unstable APIs that do not compile under bare defaults.
# Preserve explicit feature selections, but make an otherwise plain
# `cargo test` use the upstream-supported all-feature configuration.
RUN set -eu; \
    cargo_proxy="$(command -v cargo)"; \
    rustup_proxy="$(command -v rustup)"; \
    rm -f "$cargo_proxy"; \
    printf '%s\n' \
        '#!/bin/sh' \
        'set -eu' \
        "rustup_proxy='$rustup_proxy'" \
        "toolchain='$RUSTUP_TOOLCHAIN'" \
        'selected_toolchain="$toolchain"' \
        'case "${1-}" in' \
        '    +*) selected_toolchain="${1#+}"; shift ;;' \
        'esac' \
        'if [ "${1-}" = "test" ]; then' \
        '    shift' \
        '    explicit_features=false' \
        '    for argument in "$@"; do' \
        '        case "$argument" in' \
        '            --all-features|--features|--features=*|-F|-F*|--no-default-features) explicit_features=true ;;' \
        '        esac' \
        '    done' \
        '    if [ "$explicit_features" = false ]; then' \
        '        set -- --all-features "$@"' \
        '    fi' \
        '    exec "$rustup_proxy" run "$selected_toolchain" cargo test "$@"' \
        'fi' \
        'exec "$rustup_proxy" run "$selected_toolchain" cargo "$@"' \
        > "$cargo_proxy"; \
    chmod 0755 "$cargo_proxy"

# The evaluator mounts the composed source tree read-only and runs as an
# arbitrary UID. Cargo and nextest keep their mutable state in this shared
# prewarmed target directory instead.
RUN chmod -R a+rX /opt/cargo \
    && chmod -R a+rX /opt/rustup \
    && chmod -R a+rwX /opt/icu4x-target \
    && git config --system --add safe.directory '*'

CMD ["/bin/bash"]
