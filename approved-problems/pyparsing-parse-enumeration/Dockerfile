FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest

WORKDIR /app
COPY . .

# pyparsing is used from the source tree; only pytest and the two optional
# dependencies of its railroad-diagram tests are needed.
RUN pip install --no-cache-dir \
        pytest \
        "railroad-diagrams~=3.0" \
        "Jinja2~=3.1" \
    && chmod -R a+rwX /app

CMD ["/bin/bash"]
