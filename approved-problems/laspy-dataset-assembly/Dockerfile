FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest

WORKDIR /app

COPY . .

RUN pip install --no-cache-dir numpy==2.5.2 pytest==9.0.3 lazrs==0.8.2 hatchling==1.32.0 editables==0.5 && \
    pip install --no-cache-dir --no-build-isolation --no-deps -e . && \
    pip uninstall -y -q hatchling editables && \
    rm -rf /root/.cache /tmp/* && \
    python -c "import laspy, sys; assert laspy.__file__.startswith('/app'), laspy.__file__"

CMD ["/bin/bash"]
