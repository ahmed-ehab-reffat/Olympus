FROM public.ecr.aws/d3j8x8q7/olympus-base-cpp:latest
WORKDIR /app
COPY . .
RUN make -j"$(nproc)" && chmod -R a+rwX /app
CMD ["/bin/bash"]
