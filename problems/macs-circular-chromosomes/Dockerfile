FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest

ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PYTHONPATH=/app

WORKDIR /app

RUN python -m pip install --no-cache-dir \
        Cython==3.0.12 \
        numpy==2.5.3 \
        scipy==1.18.1 \
        scikit-learn==1.9.1 \
        hmmlearn==0.3.3 \
        pandas==3.0.6 \
        anndata==0.13.4 \
        ncls==0.0.70 \
        pytest==9.0.3 \
    && git config --system --add safe.directory '*'

COPY --chown=1000:1000 . .

RUN ( test -e .git/HEAD || ( \
        git init -q \
        && git add -A \
        && git -c user.name=macs3 -c user.email=macs3@localhost commit -q -m "760ff63b958f79cc82abc8c1a9847705cd99c907" ) ) \
    && ( test -f MACS3/fermi-lite/lib/simde-common.h || ( \
        rm -rf MACS3/fermi-lite/lib \
        && git clone -q https://github.com/simd-everywhere/simde-no-tests MACS3/fermi-lite/lib \
        && git -C MACS3/fermi-lite/lib checkout -q 8cd136a43bae7ab9b82316179b9cef8887726778 ) ) \
    && ( python setup.py build_ext --inplace -j 8 > /tmp/build_ext.log 2>&1 || (tail -50 /tmp/build_ext.log; exit 1) ) \
    && git status --porcelain --untracked-files=normal | sed -n 's/^?? //p' >> .git/info/exclude \
    && find /app \( -type d -o -user 0 \) -exec chmod a+rwX {} +

CMD ["/bin/bash"]
