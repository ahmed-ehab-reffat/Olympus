FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest
WORKDIR /app
COPY . .
ENV SETUPTOOLS_SCM_PRETEND_VERSION=1.7.23
RUN pip install --no-build-isolation --no-deps -e . \
    && chmod -R a+rwX /app
CMD ["/bin/bash"]
