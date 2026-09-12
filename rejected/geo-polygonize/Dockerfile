FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest

WORKDIR /app

COPY . .

# Test runner used by test.sh; it emits the JUnit XML the harness reads.
RUN cargo install cargo-nextest --locked

# Fetch dependencies and warm the build cache so the offline test run
# (`--network none`) needs no network. The test and solution patches are
# applied after the image is built.
RUN cargo fetch
RUN cargo build -p geo --tests

CMD ["/bin/bash"]
