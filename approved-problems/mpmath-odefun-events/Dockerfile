FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest

ENV MPLBACKEND=Agg
ENV PYTHONDONTWRITEBYTECODE=1
ENV SETUPTOOLS_SCM_PRETEND_VERSION=1.5.0

WORKDIR /app

COPY . .

RUN pip install --no-cache-dir \
        "setuptools==80.9.0" \
        "setuptools-scm==9.2.0" \
        "wheel==0.45.1" \
        "pytest==9.1.1" \
        "pytest-timeout==2.4.0" \
        "hypothesis==6.165.2" \
        "numpy==2.5.1" \
        "packaging==26.3" \
        "matplotlib==3.11.1" \
        "pexpect==4.9.0" \
        "ipython==9.16.1" \
    && pip install --no-cache-dir --no-build-isolation --no-deps -e . \
    && chmod -R a+rwX /app

CMD ["/bin/bash"]
