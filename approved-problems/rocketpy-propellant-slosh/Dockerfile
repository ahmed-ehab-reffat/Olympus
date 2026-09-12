FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest

WORKDIR /app
COPY . .

ENV MPLBACKEND=Agg
ENV MPLCONFIGDIR=/tmp/matplotlib

RUN pip install --no-cache-dir -r requirements.txt \
    && pip install --no-cache-dir -r requirements-tests.txt \
    && pip install --no-cache-dir numericalunits statsmodels prettytable \
    && pip install --no-cache-dir --no-deps -e . \
    && mkdir -p /tmp/matplotlib && chmod 777 /tmp/matplotlib \
    && chmod -R a+rwX /app

CMD ["/bin/bash"]
