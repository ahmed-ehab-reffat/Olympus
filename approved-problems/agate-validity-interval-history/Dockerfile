FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest
WORKDIR /app
COPY . .
ENV DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC
RUN apt-get update \
    && apt-get install -y --no-install-recommends locales tzdata \
    && sed -i 's/^# *\(en_US.UTF-8\)/\1/; s/^# *\(de_DE.UTF-8\)/\1/; s/^# *\(fr_FR.UTF-8\)/\1/; s/^# *\(ko_KR.UTF-8\)/\1/' /etc/locale.gen \
    && locale-gen \
    && rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir \
        babel==2.18.0 \
        cssselect==1.5.0 \
        isodate==0.7.2 \
        leather==0.4.1 \
        lxml==6.1.1 \
        parsedatetime==2.6 \
        pytest==9.0.3 \
        python-slugify==8.0.4 \
        pytimeparse==1.1.8 \
        text-unidecode==1.3 \
    && chmod -R a+rwX /app
ENV PYTHONPATH=/app
CMD ["/bin/bash"]
