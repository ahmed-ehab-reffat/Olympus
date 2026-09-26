FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV PYTHONDONTWRITEBYTECODE=1
ENV SETUPTOOLS_SCM_PRETEND_VERSION=5.4.1.dev21

WORKDIR /app

COPY --chown=1000:1000 . .

RUN git config --system --add safe.directory '*' \
    && pip install --no-cache-dir \
        aiohappyeyeballs==2.7.1 aiohttp==3.14.3 aiosignal==1.4.0 asdf_standard==1.5.0 attrs==26.1.0 \
        frozenlist==1.8.0 fsspec==2026.9.0 idna==3.20 iniconfig==2.3.0 jmespath==1.1.0 lz4==4.4.5 \
        multidict==6.9.1 numpy==2.5.3 packaging==26.3 pluggy==1.6.0 propcache==0.5.4 psutil==7.2.2 \
        Pygments==2.21.0 pytest==9.1.1 PyYAML==6.0.3 semantic-version==2.10.0 syrupy==6.1.1 \
        typing_extensions==4.16.0 yarl==1.25.1 \
    && pip install --no-cache-dir --no-deps -e . \
    && find /app \( -type d -o -user 0 \) -exec chmod a+rwX {} +

CMD ["/bin/bash"]
