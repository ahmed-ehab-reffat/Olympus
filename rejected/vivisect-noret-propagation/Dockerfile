FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest
WORKDIR /app
# vivisect/defconfig.py calls getpass.getuser() at import time, so importing vivisect at all
# fails under a uid with no passwd entry. getpass consults these before the passwd database,
# and HOME keeps any ~-relative config path writable, so the image works under any uid.
ENV USER=olympus \
    LOGNAME=olympus \
    HOME=/tmp
COPY . .
RUN pip install --no-cache-dir pyasn1==0.6.4 pyasn1-modules==0.4.2 cxxfilt==0.3.0 msgpack==1.2.1 pycparser==3.0 \
    && pip install --no-cache-dir --no-deps -e . \
    && chmod -R a+rX /app
CMD ["/bin/bash"]
