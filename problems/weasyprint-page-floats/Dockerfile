FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest
ENV HOME=/tmp XDG_CACHE_HOME=/tmp
WORKDIR /app
COPY . .
RUN apt-get update && apt-get install -y --no-install-recommends \
      libpango-1.0-0 libpangoft2-1.0-0 libharfbuzz-subset0 libjpeg62-turbo \
      ghostscript fonts-dejavu-core \
    && rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir \
      pytest==9.0.3 \
      pydyf==0.12.1 \
      cffi==2.0.0 \
      pycparser==3.0 \
      tinyhtml5==2.1.0 \
      tinycss2==1.5.1 \
      cssselect2==0.10.1 \
      webencodings==0.6.1 \
      Pyphen==0.18.1 \
      Pillow==12.3.0 \
      fonttools==4.65.0 \
      brotli==1.2.0 \
      zopfli==0.4.3 \
      flit_core==3.12.0 \
    && pip install --no-cache-dir --no-build-isolation --no-deps -e . \
    && chmod -R a+rwX /app
CMD ["/bin/bash"]
