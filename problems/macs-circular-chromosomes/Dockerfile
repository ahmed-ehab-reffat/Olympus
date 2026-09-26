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

# The repo's own .dockerignore excludes .git/*, so the build context arrives with an empty .git.
# Recreate a local repository at the base commit so git status / git diff work inside the container.
RUN test -e .git/HEAD || ( \
        git init -q \
        && git add -A \
        && git -c user.name=macs3 -c user.email=macs3@localhost commit -q -m "760ff63b958f79cc82abc8c1a9847705cd99c907" )

# MACS3/fermi-lite/lib is a git submodule (simde), which the build context does not carry.
# Fetch it at the exact commit the base tree's gitlink pins; fermi-lite does not compile without it.
RUN test -f MACS3/fermi-lite/lib/simde-common.h || ( \
        rm -rf MACS3/fermi-lite/lib \
        && git clone -q https://github.com/simd-everywhere/simde-no-tests MACS3/fermi-lite/lib \
        && git -C MACS3/fermi-lite/lib checkout -q 8cd136a43bae7ab9b82316179b9cef8887726778 )

# MACS3 is mostly Cython, so its extensions must be compiled before anything can be imported.
# Install the project editable (extensions built in parallel, placed in the source tree) so /app
# edits are live for every entry point: `python -m pytest`, `pytest`, `python bin/macs3`, `macs3`.
# pip compiles editable extensions in a throwaway directory, so copy them into build/lib as well:
# test.sh runs `setup.py build_ext --inplace`, which then recompiles only what a patch changes.
# bin/macs3 holds the argument parser and pip installs a copy of it, so the installed `macs3`
# command runs the source file instead and edits to bin/macs3 are live too.
# Build outputs are hidden from git status, and /app is opened up because the tests may run as
# root or as an arbitrary uid and test.sh rebuilds changed extensions in place.
RUN printf '[build_ext]\nparallel = 8\n' > /tmp/build_ext.cfg \
    && ( DIST_EXTRA_CONFIG=/tmp/build_ext.cfg python -m pip install --no-cache-dir --no-deps \
            --no-build-isolation -e . > /tmp/build_ext.log 2>&1 || (tail -50 /tmp/build_ext.log; exit 1) ) \
    && BUILD_LIB="build/lib.$(python -c 'import sys, sysconfig; print(sysconfig.get_platform() + "-" + sys.implementation.cache_tag)')" \
    && mkdir -p "$BUILD_LIB" \
    && find MACS3 -name '*.so' -exec cp -p --parents {} "$BUILD_LIB"/ \; \
    && printf '#!/bin/sh\nexec python /app/bin/macs3 "$@"\n' > "$(command -v macs3)" \
    && git status --porcelain --untracked-files=normal | sed -n 's/^?? //p' >> .git/info/exclude \
    && find /app \( -type d -o -user 0 \) -exec chmod a+rwX {} +

CMD ["/bin/bash"]
