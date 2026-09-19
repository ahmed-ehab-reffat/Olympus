FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest
WORKDIR /app
COPY . .
ENV HOME=/app
ENV MPLBACKEND=Agg
RUN pip install --no-cache-dir numpy==2.2.6 scipy==1.18.0 meshio==5.3.5 \
        pyparsing==3.3.2 tables==3.11.1 sympy==1.14.0 matplotlib==3.11.1 \
        scikit-build==0.19.1 cmake==4.4.2 ninja==1.11.1.1 Cython==3.2.9 \
        pytest==9.0.3 \
    && pip install --no-cache-dir --no-build-isolation --no-deps -e . \
    && python setup.py build_ext --inplace \
    && chmod -R a+rwX /app
CMD ["/bin/bash"]
