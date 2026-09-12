FROM public.ecr.aws/d3j8x8q7/olympus-base-cpp:latest
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        cmake make python3 qemu-user qemu-user-static cloc time libunwind-dev \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY . .
RUN ln -sf /usr/bin/qemu-arm /usr/local/bin/qemu-armhf || true
CMD ["/bin/bash"]
