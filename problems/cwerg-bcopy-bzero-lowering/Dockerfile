FROM public.ecr.aws/d3j8x8q7/olympus-base-cpp:latest

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        python3=3.11.2-1+b1 \
        libunwind-dev=1.6.2-3 \
        qemu-user=1:7.2+dfsg-7+deb12u18+b3 \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /usr/bin/qemu-arm /usr/local/bin/qemu-armhf

WORKDIR /app
COPY . .

ENV PYTHONPATH=/app

RUN make cmake_setup \
    && cd build \
    && make -j2 a32_codegen_tool.exe a64_codegen_tool.exe x64_codegen_tool.exe optimize_tool.exe \
    && chmod -R a+rwX /app

CMD ["/bin/bash"]
