FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        cmake \
        libunwind-dev \
        liblzma-dev \
        qemu-user \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /usr/bin/qemu-arm /usr/local/bin/qemu-armhf \
    && mkdir -p /opt/cxxshim \
    && touch /opt/cxxshim/format

ENV CPLUS_INCLUDE_PATH=/opt/cxxshim
ENV PYTHONPATH=/app

WORKDIR /app

COPY --chown=1000:1000 . .

RUN git config --system --add safe.directory "*" \
    && make cmake_setup CWERG_FLAGS="-include bit -Wno-error" \
    && cd build \
    && make -j4 compiler.exe a32_codegen_tool.exe a64_codegen_tool.exe x64_codegen_tool.exe \
    && chmod -R a+rwX /app/build

CMD ["/bin/bash"]
