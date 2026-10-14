FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest

ENV PYTHONDONTWRITEBYTECODE=1
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

WORKDIR /app

RUN pip install --no-cache-dir \
        SQLAlchemy==2.1.1 greenlet==3.5.3 typing-extensions==4.16.0 pytest==9.1.1 \
        Flask==3.1.3 Flask-Login==0.6.3 Flask-SQLAlchemy==3.1.1 PyMySQL==1.2.0 packaging==26.2 \
        setuptools

COPY --chown=1000:1000 . .

RUN git config --system --add safe.directory '*'

RUN git ls-files --deleted -z 2>/dev/null | xargs -0 -r git checkout -- 2>/dev/null || true

RUN pip install --no-cache-dir --no-deps --no-build-isolation -e .

RUN find /app \( -type d -o -user 0 \) -exec chmod a+rwX {} +

CMD ["/bin/bash"]
