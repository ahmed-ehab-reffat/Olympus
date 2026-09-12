FROM public.ecr.aws/d3j8x8q7/olympus-base:latest

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libhdf5-dev=1.10.8+repack1-1 \
        pkg-config=1.8.1-1 \
    && rm -rf /var/lib/apt/lists/*

RUN python -m pip install --no-cache-dir \
        "Cython==3.2.9" \
        "numpy==2.5.1" \
        "pkgconfig==1.5.5" \
        "pytest-mpi==0.6"

COPY . .

RUN python -m pip install --no-cache-dir --no-build-isolation -e .

CMD ["/bin/bash"]
