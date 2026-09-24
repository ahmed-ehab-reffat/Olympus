FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest
WORKDIR /app
COPY . .
RUN SETUPTOOLS_SCM_PRETEND_VERSION=0.0.0 pip install --no-cache-dir -e . \
    && pip install --no-cache-dir "pytest>=6.2"
CMD ["/bin/bash"]
