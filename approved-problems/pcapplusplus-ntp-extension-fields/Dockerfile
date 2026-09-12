FROM public.ecr.aws/d3j8x8q7/olympus-base:latest

RUN apt-get update \
    && apt-get install -y --no-install-recommends cmake libpcap-dev pkg-config \
    && rm -rf /var/lib/apt/lists/*

# PcapPlusPlus enables its Google Benchmark example for a default top-level
# configure. Keep the pinned source in the image so that configure also works
# when the evaluation sandbox has no network.
RUN git clone --branch v1.9.5 --depth 1 https://github.com/google/benchmark.git /opt/google-benchmark \
    && git config --system url."file:///opt/google-benchmark".insteadOf https://github.com/google/benchmark.git

WORKDIR /app
COPY . .

# Packet++Test also documents running the binary from its source test directory.
# Make the copied OUI fixture available there as well as in CMake's binary directory.
RUN ln -sf ../../3rdParty/OUIDataset/PCPP_OUIDataset.json Tests/Packet++Test/PCPP_OUIDataset.json

RUN cmake -S . -B build-ntp-extension-tests \
      -DCMAKE_BUILD_TYPE=Debug \
      -DPCAPPP_BUILD_PCAPPP=OFF \
      -DPCAPPP_BUILD_TESTS=ON \
      -DPCAPPP_BUILD_EXAMPLES=OFF \
      -DPCAPPP_BUILD_TUTORIALS=OFF \
    && cmake --build build-ntp-extension-tests --target Packet++Test --parallel 2

CMD ["/bin/bash"]
