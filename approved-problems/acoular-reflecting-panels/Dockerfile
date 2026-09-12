FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest
WORKDIR /app
COPY . .
RUN apt-get update && apt-get install -y --no-install-recommends libportaudio2 \
    && rm -rf /var/lib/apt/lists/* \
    && pip install --no-cache-dir -e . \
    && pip install --no-cache-dir "pytest<9.1" pytest-mock pytest-regtest pytest-cases pytest-env pytest-cov h5py pylops PyYAML sounddevice traitsui \
    && chmod -R a+rwX /app
CMD ["/bin/bash"]
