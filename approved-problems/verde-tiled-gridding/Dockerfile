FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest

WORKDIR /app

COPY . .

ENV SETUPTOOLS_SCM_PRETEND_VERSION=1.9.0
ENV MPLBACKEND=agg
ENV VERDE_DATA_DIR=/app/.verde-data

RUN pip install --no-cache-dir \
        "numpy" "scipy" "pandas" "xarray" "scikit-learn<1.9" "pooch" \
        "dask[distributed]" "matplotlib" "cartopy" "pytest" "pytest-mpl" \
    && pip install --no-cache-dir --no-build-isolation -e . \
    && python -c "import pathlib, shutil; \
from verde.datasets.sample_data import REGISTRY; \
target = pathlib.Path(REGISTRY.abspath); \
target.mkdir(parents=True, exist_ok=True); \
[shutil.copy('/app/data/' + name, target) for name in REGISTRY.registry]" \
    && chmod -R a+rwX /app

CMD ["/bin/bash"]
