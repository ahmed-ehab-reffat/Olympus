FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest

ENV PYTHONDONTWRITEBYTECODE=1
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

WORKDIR /app

RUN pip install --no-cache-dir \
        tortoise-orm==1.1.8 pypika-tortoise==0.6.5 iso8601==2.1.0 aiosqlite==0.22.1 \
        dictdiffer==0.10.0 asyncclick==8.4.2.1 anyio==4.14.2 tomli-w==1.2.0 \
        pydantic-settings==2.15.0 aiomysql==0.3.2 pymysql==1.2.0 asyncpg==0.31.0 \
        pytest==9.1.1 pytest-mock==3.15.1 pdm-backend

COPY --chown=1000:1000 . .

RUN git config --system --add safe.directory '*'

RUN git ls-files --deleted -z 2>/dev/null | xargs -0 -r git checkout -- 2>/dev/null || true

RUN pip install --no-cache-dir --no-deps --no-build-isolation -e .

RUN find /app \( -type d -o -user 0 \) -exec chmod a+rwX {} +

CMD ["/bin/bash"]
