FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest

ENV HOME=/tmp
ENV MPLBACKEND=Agg
ENV MPLCONFIGDIR=/tmp/mpl
ENV PYTHONDONTWRITEBYTECODE=1

WORKDIR /app
COPY . /app

RUN git config --system --add safe.directory '*'

RUN pip install --no-cache-dir "setuptools==80.9.0" "wheel==0.45.1" "pytest==8.4.2"
RUN pip install --no-cache-dir -e .

RUN mkdir -p /tmp/mpl && chmod -R a+rwX /app /tmp

CMD ["/bin/bash"]
