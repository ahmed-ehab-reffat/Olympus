FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest
ENV MPLBACKEND=Agg
ENV MPLCONFIGDIR=/tmp/mpl
WORKDIR /app
COPY . .
RUN pip install --no-cache-dir pytest seaborn \
    && pip install --no-cache-dir --index-url https://download.pytorch.org/whl/cpu torch \
    && pip install --no-cache-dir -e .
CMD ["/bin/bash"]
