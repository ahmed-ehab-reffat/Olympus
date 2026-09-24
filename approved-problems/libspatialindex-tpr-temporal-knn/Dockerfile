FROM public.ecr.aws/d3j8x8q7/olympus-base-cpp:latest

WORKDIR /app
COPY . .

RUN cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=ON \
    && cmake --build build --parallel 4 \
    && chmod -R a+rwX /app

CMD ["/bin/bash"]
