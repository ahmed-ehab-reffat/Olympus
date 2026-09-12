FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest

ENV HOME=/opt/pydicom-home
ENV PYTHONDONTWRITEBYTECODE=1

WORKDIR /app

COPY . .

RUN mkdir -p "$HOME" \
    && pip install --no-cache-dir pytest pyfakefs \
    && pip install --no-cache-dir --no-build-isolation -e . \
    && python -c "from pydicom.data import fetch_data_files; fetch_data_files()" \
    && chmod -R a+rwX "$HOME" /app

CMD ["/bin/bash"]
