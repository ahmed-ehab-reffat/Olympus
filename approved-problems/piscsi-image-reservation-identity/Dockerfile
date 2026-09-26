FROM public.ecr.aws/d3j8x8q7/olympus-base-cpp:latest
WORKDIR /app
COPY . .
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      libspdlog-dev=1:1.10.0+ds-0.4 \
      libfmt-dev=9.1.0+ds1-2 \
      libpcap-dev=1.10.3-1 \
      protobuf-compiler=3.21.12-3+deb12u1 \
      libprotobuf-dev=3.21.12-3+deb12u1 \
 && rm -rf /var/lib/apt/lists/* \
 && make -C cpp -j"$(nproc)" DEBUG=1 EXTRA_FLAGS=-g0 bin/piscsi_test \
 && chmod -R a+rwX /app
CMD ["/bin/bash"]
