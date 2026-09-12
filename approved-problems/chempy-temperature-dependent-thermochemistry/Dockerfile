FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest

ENV HOME=/tmp
ENV MPLBACKEND=Agg
ENV PYTHONDONTWRITEBYTECODE=1

WORKDIR /app
COPY . /app

RUN git config --system --add safe.directory '*'

RUN pip install --no-cache-dir "setuptools==72.1.0" "wheel==0.47.0" "build==1.5.0" "pytest==9.0.3"
RUN pip install --no-cache-dir --no-build-isolation -e .

RUN chmod -R a+rwX /app /tmp

CMD ["/bin/bash"]
