FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV SECRET_KEY=dummy-key

WORKDIR /app

COPY --chown=1000:1000 . .

RUN git config --system --add safe.directory '*' \
    && pip install --no-cache-dir -r requirements.txt -r requirements-dev.txt \
        unittest-xml-reporting==4.0.0 \
    && find /app \( -type d -o -user 0 \) -exec chmod a+rwX {} +

CMD ["/bin/bash"]
