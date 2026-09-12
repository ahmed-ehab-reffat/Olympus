FROM public.ecr.aws/d3j8x8q7/olympus-base-cpp:latest

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates iproute2 libpcap-dev pkg-config python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --break-system-packages clang-format==19.1.6

WORKDIR /app
COPY . .

RUN cmake -S . -B build-pcapng-copy-preflight \
      -DCMAKE_BUILD_TYPE=Debug \
      -DPCAPPP_BUILD_TESTS=ON \
      -DPCAPPP_BUILD_EXAMPLES=OFF \
      -DPCAPPP_BUILD_TUTORIALS=OFF \
    && cmake --build build-pcapng-copy-preflight --target Pcap++Test --parallel

CMD ["/bin/bash"]
