FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest

WORKDIR /app
COPY . .

RUN pip install --no-cache-dir pytest \
    && pip install --no-cache-dir --no-deps -e . \
    && chmod -R a+rwX /app

CMD ["/bin/bash"]
