FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest

WORKDIR /app

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV PYTHONPATH=/app
ENV PYTHONDONTWRITEBYTECODE=1

COPY --chown=1000:1000 . .

RUN git config --system --add safe.directory '*' \
    && chmod -R a+rwX /app \
    && groupadd -g 1000 model \
    && useradd -u 1000 -g model -m model

USER model

CMD ["/bin/bash"]
