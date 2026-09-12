FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest

ENV MPLBACKEND=Agg
ENV PYTHONDONTWRITEBYTECODE=1

WORKDIR /app

COPY . .

RUN pip install --no-cache-dir \
        "numpy==2.4.6" \
        "scipy==1.18.0" \
        "pandas==2.3.3" \
        "networkx==3.6.1" \
        "pandera==0.32.1" \
        "packaging==26.2" \
        "tqdm==4.70.0" \
        "colorama==0.4.6" \
        "deepdiff==9.1.0" \
        "geojson==3.3.0" \
        "typing_extensions==4.16.0" \
        "shapely==2.1.2" \
        "geopandas==1.1.4" \
        "matplotlib==3.11.1" \
        "lxml==6.1.1" \
        "matpowercaseframes==2.1.1" \
        "xlsxwriter==3.2.9" \
        "openpyxl==3.1.5" \
        "cryptography==48.0.0" \
        "psycopg==3.3.4" \
        "plotly==6.9.0" \
        "igraph==1.0.0" \
        "power-grid-model-io==1.3.108" \
        "pytest==9.1.1" \
        "pytest-timeout==2.4.0" \
    && pip install --no-cache-dir --no-build-isolation -e . \
    && chmod -R a+rwX /app

CMD ["/bin/bash"]
