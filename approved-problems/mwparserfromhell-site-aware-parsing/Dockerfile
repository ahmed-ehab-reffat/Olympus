FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest
WORKDIR /app
COPY . .
RUN pip install setuptools setuptools-scm pytest && WITH_EXTENSION=1 pip install --no-build-isolation -e . \
    && git config --system safe.directory '*' && chmod -R a+rwX /app
CMD ["/bin/bash"]
