FROM public.ecr.aws/d3j8x8q7/olympus-base-cpp:latest
WORKDIR /app
COPY --chown=1000:1000 . .
RUN git config --system --add safe.directory '*' \
    && make -j"$(nproc)" pict libpict.so \
    && find /app \( -type d -o -user 0 \) -exec chmod a+rwX {} +
CMD ["/bin/bash"]
