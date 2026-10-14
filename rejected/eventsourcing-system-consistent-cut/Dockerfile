FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest
RUN git config --system --add safe.directory '*'
RUN pip install --no-cache-dir poetry-core==2.5.0 typing_extensions==4.15.0 pytest==9.0.3 \
        pycryptodome==3.23.0 cryptography==48.0.0 "psycopg[binary,pool]==3.3.6" psycopg-pool==3.3.3 \
        pydantic==2.13.5 msgspec==0.22.0 orjson==3.12.0
WORKDIR /app
COPY --chown=1000:1000 . .
RUN git ls-files --deleted -z 2>/dev/null | xargs -0 -r git checkout -- 2>/dev/null || true
RUN if [ ! -f README.md ]; then touch README.md; fi
RUN pip install --no-cache-dir --no-deps --no-build-isolation -e .
RUN find /app \( -type d -o -user 0 \) -exec chmod a+rwX {} +
CMD ["/bin/bash"]
