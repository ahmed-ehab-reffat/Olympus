FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest

RUN apt-get update -qq \
    && apt-get install -y --no-install-recommends curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN curl -sSL -o /tmp/oss-cad-suite.tgz \
        https://github.com/YosysHQ/oss-cad-suite-build/releases/download/2026-07-27/oss-cad-suite-linux-x64-20260727.tgz \
    && tar -xzf /tmp/oss-cad-suite.tgz -C /opt \
    && rm /tmp/oss-cad-suite.tgz

ENV PATH="/opt/oss-cad-suite/bin:${PATH}"

WORKDIR /app

COPY . .

RUN pip install --no-cache-dir "jschon~=0.11.1" "pyvcd>=0.2.2,<0.5" "Jinja2~=3.0" pytest \
    && PDM_BUILD_SCM_VERSION=0.5.6 pip install --no-cache-dir . \
    && chmod -R a+rwX /app

CMD ["/bin/bash"]
