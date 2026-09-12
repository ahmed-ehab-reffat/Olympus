FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest
WORKDIR /app
COPY . .
ENV SETUPTOOLS_SCM_PRETEND_VERSION=1.7.0
ENV TEST_DATA_DIR=/app/staticdata
ENV CARTOPY_DATA_DIR=/opt/cartopy
ENV MPLCONFIGDIR=/tmp/mpl
ENV HOME=/tmp
RUN pip install --no-cache-dir -r ci/requirements.txt -r ci-dev/test_requirements.txt \
        cartopy==0.25.0 dask==2026.7.1 netCDF4==1.7.4 shapely==2.1.2 \
    && pip install --no-cache-dir --no-deps -e . \
    && XDG_DATA_HOME=/opt python ci/download_cartopy_maps.py \
    && chmod -R a+rX /opt/cartopy \
    && chmod -R a+rwX /app
CMD ["/bin/bash"]
