FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest

ENV MPLBACKEND=Agg
ENV SETUPTOOLS_SCM_PRETEND_VERSION=0.10.2

WORKDIR /app
COPY . .

RUN pip install --no-cache-dir \
        "numpy>=2.0,<2.4" \
        "scipy>=1.13,<1.16" \
        "matplotlib>=3.8,<3.10" \
        pytest \
        numpydoc \
        pytest-timeout \
    && chmod -R a+rwX /app

CMD ["/bin/bash"]
