FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest
WORKDIR /app
RUN pip install --no-cache-dir "rich>=13.0.0" "pytest>=8"
COPY . .
RUN pip install --no-cache-dir --no-deps --no-build-isolation -e .
CMD ["/bin/bash"]
