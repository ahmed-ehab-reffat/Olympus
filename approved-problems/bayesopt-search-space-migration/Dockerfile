FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest

ENV PYTHONDONTWRITEBYTECODE=1
ENV MPLBACKEND=Agg
ENV OMP_NUM_THREADS=1
ENV OPENBLAS_NUM_THREADS=1
ENV MKL_NUM_THREADS=1

WORKDIR /app

COPY --chown=1000:1000 . .

RUN git config --system --add safe.directory '*' \
    && git checkout -- . \
    && pip install --no-cache-dir numpy==2.3.3 scipy==1.16.2 scikit-learn==1.7.2 colorama==0.4.6 \
        packaging==25.0 pytest==9.1.1 \
    && pip install --no-cache-dir --no-deps -e . \
    && chmod -R a+rwX /app

CMD ["/bin/bash"]
