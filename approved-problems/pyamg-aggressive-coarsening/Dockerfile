FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest
WORKDIR /app
COPY . .
RUN pip install --no-cache-dir \
        numpy==2.2.6 \
        scipy==1.14.1 \
        meson==1.11.2 \
        meson-python==0.20.0 \
        ninja==1.13.0 \
        pybind11==3.1.0 \
        versioningit==3.3.0 \
        pytest==9.0.3 \
    && printf '\n[tool.versioningit]\ndefault-version = "5.3.0"\n' >> pyproject.toml \
    && pip install --no-build-isolation --no-deps -e . \
    && chmod -R a+rwX /app
CMD ["/bin/bash"]
