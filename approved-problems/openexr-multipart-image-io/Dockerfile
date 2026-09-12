FROM public.ecr.aws/d3j8x8q7/olympus-base-cpp:latest

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libdeflate-dev \
        libimath-dev \
        ninja-build \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .

RUN cmake -S . -B build-bootstrap -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_TESTING=ON \
        -DOPENEXR_BUILD_EXAMPLES=OFF \
        -DOPENEXR_BUILD_TOOLS=OFF \
    && cmake --build build-bootstrap --parallel 2 \
    && chmod -R a+rwX /app

CMD ["/bin/bash"]
