FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest

ENV PYTHONDONTWRITEBYTECODE=1
ENV SETUPTOOLS_SCM_PRETEND_VERSION=2026.8.0
ENV MPLBACKEND=Agg
ENV HOME=/app

WORKDIR /app

COPY . .

RUN pip install --no-cache-dir \
        "numpy==2.5.1" \
        "scipy==1.18.0" \
        "astropy==7.2.2" \
        "astropy-iers-data==0.2026.8.3.0.53.6" \
        "pandas==3.0.5" \
        "xarray==2026.7.0" \
        "h5py==3.16.0" \
        "lmfit==1.3.4" \
        "matplotlib==3.11.1" \
        "mpmath==1.4.1" \
        "requests==2.32.5" \
        "tqdm==4.70.0" \
        "wrapt==2.3.0" \
        "packaging==25.0" \
        "hypothesis==6.150.3" \
        "pytest==9.0.3" \
        "pytest-cov==7.0.0" \
        "pytest-filter-subpackage==0.2.0" \
        "pytest-regressions==2.9.1" \
        "pytest-rerunfailures==16.1" \
        "pytest-xdist==3.8.0" \
    && pip install --no-cache-dir --no-deps -e . \
    && python -c "from plasmapy.utils.data.downloader import Downloader; Downloader().get_file('NIST_STAR.hdf5')" \
    && chmod -R a+rwX /app

CMD ["/bin/bash"]
