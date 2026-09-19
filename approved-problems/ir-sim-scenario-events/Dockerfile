FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest
WORKDIR /app
COPY . .
ENV HOME=/app
ENV MPLBACKEND=Agg
RUN pip install --no-cache-dir numpy==2.5.3 scipy==1.18.1 shapely==2.1.2 \
        matplotlib==3.11.2 PyYAML==6.0.3 imageio==2.37.4 loguru==0.7.3 \
        pyrvo==0.4.3 pytest==9.1.1 pytest-cov==7.1.0 \
    && pip install --no-cache-dir --no-deps -e . \
    && chmod -R a+rwX /app
CMD ["/bin/bash"]
