FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest

WORKDIR /app

COPY . .

# The evaluator's pristine checkout may preserve the gitlink without
# materializing its fixture submodule. Fetch the exact repository-owned pin
# while image networking is available so all later test discovery is offline.
RUN if [ ! -f testfiles/archive/gnu.a ]; then \
        rm -rf testfiles && \
        git clone https://github.com/gimli-rs/object-testfiles.git testfiles && \
        git -C testfiles checkout fe8da208d4013ec3691311915fdc7d71436c0d1e && \
        rm -rf testfiles/.git; \
    fi

RUN rustup toolchain install 1.90.0 --profile minimal
RUN cargo +1.90.0 install cargo-nextest --version 0.9.128 --locked

RUN cargo +1.90.0 fetch --locked
RUN cargo +1.90.0 build --workspace --locked --all-targets --features all

CMD ["/bin/bash"]
