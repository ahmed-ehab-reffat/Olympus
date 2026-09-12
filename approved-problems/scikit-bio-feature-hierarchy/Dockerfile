FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest

ENV MPLBACKEND=Agg
ENV PYTHONDONTWRITEBYTECODE=1

WORKDIR /app

COPY . .

RUN pip install --no-cache-dir \
        "numpy==2.5.1" \
        "scipy==1.18.0" \
        "pandas==3.0.5" \
        "h5py==3.16.0" \
        "biom-format==2.1.17" \
        "statsmodels==0.14.6" \
        "patsy==1.0.2" \
        "array-api-compat==1.15.0" \
        "requests==2.34.2" \
        "decorator==5.3.1" \
        "natsort==8.4.0" \
        "cython==3.2.9" \
        "setuptools==82.0.1" \
        "wheel==0.47.0" \
        "pytest==9.0.3" \
        "coverage==7.15.4" \
        "responses==0.26.2" \
        "matplotlib==3.11.1" \
    && printf 'import numpy\nnumpy.set_printoptions(legacy="1.13")\nimport pandas\npandas.options.display.max_columns = None\n' \
        > /usr/local/lib/python3.12/site-packages/sitecustomize.py \
    && pip install --no-cache-dir --no-build-isolation -e . \
    && chmod -R a+rwX /app

CMD ["/bin/bash"]
