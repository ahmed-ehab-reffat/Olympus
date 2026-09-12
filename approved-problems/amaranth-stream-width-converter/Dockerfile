FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest

WORKDIR /app
COPY . .

# Amaranth is used directly from the source tree via PYTHONPATH (set in test.sh); only its
# pure-Python runtime dependencies and pytest are needed. Simulation requires no external EDA tool.
RUN pip install --no-cache-dir \
        "jschon~=0.11.1" \
        "pyvcd>=0.2.2,<0.5" \
        "Jinja2~=3.0" \
        pytest \
    && chmod -R a+rwX /app

CMD ["/bin/bash"]
