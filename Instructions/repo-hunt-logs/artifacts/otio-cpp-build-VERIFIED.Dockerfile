FROM public.ecr.aws/d3j8x8q7/olympus-base-cpp:latest

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        cmake ninja-build python3-dev python3-pip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .

RUN git clone https://github.com/pybind/pybind11 /tmp/pybind11 \
    && git -C /tmp/pybind11 checkout 45fab4087eaaff234227a10cf7845e8b07f28a98 \
    && git clone https://github.com/Tencent/rapidjson /tmp/rapidjson \
    && git -C /tmp/rapidjson checkout 24b5e7a8b27f42fa16b96fc70aade9106cf7102f \
    && git clone https://github.com/AcademySoftwareFoundation/Imath /tmp/Imath \
    && git -C /tmp/Imath checkout fbcfb9833fe78277299080e8700fcf749a468bb0 \
    && git clone https://github.com/zlib-ng/minizip-ng /tmp/minizip-ng \
    && git -C /tmp/minizip-ng checkout d69cb0a5392332d6a55e9b56405a6fa2fc8b157d \
    && for d in pybind11 rapidjson Imath minizip-ng; do rm -rf "src/deps/$d"; mkdir -p "src/deps/$d"; cp -a "/tmp/$d/." "src/deps/$d/"; done \
    && rm -rf /tmp/pybind11 /tmp/rapidjson /tmp/Imath /tmp/minizip-ng

RUN cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=ON \
    && cmake --build build --parallel 2 \
    && chmod -R a+rwX /app

CMD ["/bin/bash"]
