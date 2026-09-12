FROM public.ecr.aws/d3j8x8q7/olympus-base:latest

WORKDIR /app

ENV SKIP_LARGE=1 \
    SKIP_SLOW=1 \
    SKIP_EXTENDED=1 \
    SKIP_FILE=1 \
    SKIP_VALIDATE=1 \
    SKIP_HTTP=1

COPY . .

RUN python -m pip install --no-cache-dir -e ".[test]"

CMD ["/bin/bash"]
