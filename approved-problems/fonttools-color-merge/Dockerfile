FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest

WORKDIR /app

COPY . .

ENV PYTHONPATH=/app/Lib
ENV PYTHONDONTWRITEBYTECODE=1

RUN pip install --no-cache-dir pytest==9.1.0 && chmod -R a+rwX /app

CMD ["/bin/bash"]
