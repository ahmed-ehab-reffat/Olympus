FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app/src
ENV HOME=/tmp
ENV MPLCONFIGDIR=/tmp/mpl

WORKDIR /app
COPY . .

RUN printf '%s\n' \
        'numpy==2.5.1' \
        'pyparsing==3.3.2' \
        'typing_extensions==4.16.0' \
        'fonttools==4.63.0' \
        'pillow==12.3.0' \
        'pytest==9.1.1' \
        > /tmp/requirements.txt \
    && pip install --no-cache-dir --retries 10 --timeout 60 -r /tmp/requirements.txt \
    && mkdir -p /tmp/mpl \
    && chmod -R a+rwX /app /tmp/mpl

RUN groupadd -g 1000 model && useradd -u 1000 -g model -m model
USER model

CMD ["/bin/bash"]
