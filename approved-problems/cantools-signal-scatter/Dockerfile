FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest

ENV SETUPTOOLS_SCM_PRETEND_VERSION=0.0.0
ENV PYTHONDONTWRITEBYTECODE=1

WORKDIR /app

COPY . .

RUN pip install --no-cache-dir -e . \
    && pip install --no-cache-dir pytest diskcache freezegun matplotlib parameterized \
    && chmod -R a+rwX /app

CMD ["/bin/bash"]
