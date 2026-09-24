FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest

ENV SETUPTOOLS_SCM_PRETEND_VERSION=0.38.8
ENV PYTHONDONTWRITEBYTECODE=1
ENV HOME=/app
ENV MPLBACKEND=Agg

WORKDIR /app

COPY --chown=1000:1000 . .

RUN git config --system --add safe.directory '*' \
    && git checkout -- . \
    && chown -R 1000:1000 /app/tests /app/docs /app/setup \
    && chmod 777 /app \
    && pip install --no-cache-dir -e ".[test,server]" \
    && chmod -R a+rwX /app/siliconcompiler.egg-info \
    && rm -rf /app/.cache

CMD ["/bin/bash"]
