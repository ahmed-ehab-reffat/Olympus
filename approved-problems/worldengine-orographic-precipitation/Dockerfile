FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest
WORKDIR /app
COPY . .
RUN pip install --no-cache-dir -e . \
        numpy==2.5.3 protobuf==6.33.6 pypng==0.20220715.0 PyPlatec==1.4.3 \
        h5py==3.16.0 pytest==9.0.3 pluggy==1.6.0 iniconfig==2.3.0 packaging==26.2 \
        grpcio==1.84.0 grpcio-tools==1.81.1 \
    && git init /worldengine-data \
    && git -C /worldengine-data fetch --depth 1 https://github.com/Mindwerks/worldengine-data 802b01d6a5fe13f033331aa6aea9169cc23d99c7 \
    && git -C /worldengine-data checkout --detach FETCH_HEAD \
    && test "$(git -C /worldengine-data rev-parse HEAD)" = 802b01d6a5fe13f033331aa6aea9169cc23d99c7 \
    && rm -rf /worldengine-data/.git \
    && chmod -R a+rwX /app /worldengine-data
CMD ["/bin/bash"]
