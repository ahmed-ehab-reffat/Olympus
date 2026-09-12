FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest

WORKDIR /app

COPY . .

# setuptools_scm reads the version from git metadata, which a source copy without
# a .git directory does not carry.
ENV SETUPTOOLS_SCM_PRETEND_VERSION=0.19.1

RUN pip install --no-cache-dir \
        "numpy==2.4.6" "numba==0.66.0" "scipy==1.18.0" "networkx==3.6.1" \
        "dask==2026.7.1" "scikit-learn==1.9.0" "toolz==1.1.0" \
        "pytest==9.1.1" "pytest-cov==7.1.0" "pytest-xdist==3.8.0" \
    && pip install --no-cache-dir --no-deps -e . \
    && chmod -R a+rwX /app

CMD ["/bin/bash"]
