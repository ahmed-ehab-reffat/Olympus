FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest

ENV MPLBACKEND=Agg
ENV PYTHONDONTWRITEBYTECODE=1

WORKDIR /app

COPY . .

RUN pip install --no-cache-dir \
        numpy \
        scipy \
        meshio \
        matplotlib \
        pyamg \
        jax \
        jaxlib \
        shapely \
        pytest \
    && pip install --no-cache-dir --no-build-isolation --no-deps -e . \
    && chmod -R a+rwX /app

CMD ["/bin/bash"]
