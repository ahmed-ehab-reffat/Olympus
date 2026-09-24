FROM public.ecr.aws/d3j8x8q7/olympus-base-jvm:latest

WORKDIR /app

COPY --chown=1000:1000 . .

RUN mkdir -p /opt/dyn4j-lib \
    && curl -fsSL -o /opt/dyn4j-lib/junit-4.13.1.jar https://repo1.maven.org/maven2/junit/junit/4.13.1/junit-4.13.1.jar \
    && curl -fsSL -o /opt/dyn4j-lib/hamcrest-core-1.3.jar https://repo1.maven.org/maven2/org/hamcrest/hamcrest-core/1.3/hamcrest-core-1.3.jar \
    && chmod -R a+rX /opt/dyn4j-lib \
    && git config --system --add safe.directory '*' \
    && find /app \( -type d -o -user 0 \) -exec chmod a+rwX {} +

CMD ["/bin/bash"]
