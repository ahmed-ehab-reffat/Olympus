FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest
WORKDIR /app
COPY . .
ENV MPLBACKEND=Agg
ENV MPLCONFIGDIR=/tmp/mplconfig
RUN pip install --no-cache-dir --no-build-isolation -e ".[plot,xlsx,netw,visa]" \
 && pip install --no-cache-dir pytest pytest-mock pytest-xdist pytest-cov coverage \
 && chmod -R a+rwX /app
CMD ["/bin/bash"]
