FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest

WORKDIR /app

COPY . .

# quantecon/util/tests/test_notebooks.py downloads a file from github.com
# on every run and cannot pass without network access, so it is dropped
# from the image; nothing else in the suite reaches the network.
RUN rm -f quantecon/util/tests/test_notebooks.py \
    && pip install --no-cache-dir \
        "numpy==2.4.6" "scipy==1.18.0" "numba==0.66.0" "sympy==1.14.0" \
        "requests==2.34.2" "pandas==3.0.5" "pytest==9.0.3" \
    && pip install --no-cache-dir --no-deps -e . \
    && chmod -R a+rwX /app

CMD ["/bin/bash"]
