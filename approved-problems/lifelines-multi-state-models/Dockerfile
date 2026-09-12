FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest
WORKDIR /app
COPY . .
RUN pip install --no-cache-dir \
        "numpy>=1.14.0" "scipy>=1.7.0" "pandas>=2.1,<3.0" "matplotlib>=3.0" \
        "autograd>=1.5" "autograd-gamma>=0.3" "formulaic>=0.2.2" \
        pytest pytest-icdiff flaky "dill>=0.3.6" statsmodels joblib Jinja2 \
    && pip install --no-cache-dir --no-build-isolation --no-deps -e . \
    && chmod -R a+rwX /app
CMD ["/bin/bash"]
