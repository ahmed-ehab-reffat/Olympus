FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest

WORKDIR /app

COPY . .

RUN python -m pip install --no-cache-dir -e . && python -m pip install --no-cache-dir pytest

RUN chmod -R a+rwX /app

CMD ["/bin/bash"]
