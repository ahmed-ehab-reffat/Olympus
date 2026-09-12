FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest

ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV XLA_PYTHON_CLIENT_PREALLOCATE=false
ENV JAX_PLATFORMS=cpu

WORKDIR /app
COPY . .

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential \
        ccache \
        cmake \
        libatomic1 \
        llvm-16 \
        ninja-build \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/mitsuba-renderer/drjit-core /tmp/drjit-core \
    && git -C /tmp/drjit-core checkout 8574d491f9e8657ebf19b60dd624249ab8771cc4 \
    && git -C /tmp/drjit-core submodule update --init --recursive \
    && git clone https://github.com/wjakob/nanobind /tmp/nanobind \
    && git -C /tmp/nanobind checkout 86e5626728fc282637a6c338597120913dded1bb \
    && git -C /tmp/nanobind submodule update --init --recursive \
    && rm -rf -- /app/ext/drjit-core /app/ext/nanobind \
    && mkdir -p ext/drjit-core ext/nanobind \
    && cp -a /tmp/drjit-core/. ext/drjit-core/ \
    && cp -a /tmp/nanobind/. ext/nanobind/ \
    && sed -i '/jitc_llvm_target_features = LLVMGetHostCPUFeatures();/a\\    if (strstr(jitc_llvm_target_triple, "aarch64") && strcmp(jitc_llvm_target_cpu, "generic") == 0 && !strstr(jitc_llvm_target_features, "+fullfp16")) { const char *extra = ",+fullfp16"; StringBuffer features; features.put(jitc_llvm_target_features, strlen(jitc_llvm_target_features)); features.put(extra, strlen(extra)); LLVMDisposeMessage(jitc_llvm_target_features); jitc_llvm_target_features = LLVMCreateMessage(features.get()); }' ext/drjit-core/src/llvm_core.cpp

RUN python -m pip install --no-cache-dir --no-deps \
        iniconfig==2.3.0 \
        hatch-fancy-pypi-readme==25.1.0 \
        jax==0.11.1 \
        jaxlib==0.11.1 \
        ml_dtypes==0.6.0 \
        nanobind==2.14.0 \
        numpy==2.5.2 \
        opt_einsum==3.4.0 \
        packaging==26.2 \
        pluggy==1.6.0 \
        pygments==2.20.0 \
        pytest==9.1.1 \
        scikit-build-core==1.0.3 \
        scipy==1.18.0 \
        typing_extensions==4.15.0

RUN cmake -S . -B /tmp/drjit-build -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/opt/drjit-runtime \
        -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
        -DDRJIT_ENABLE_CUDA=OFF \
        -DDRJIT_ENABLE_LLVM=ON \
        -DDRJIT_ENABLE_METAL=OFF \
        -DDRJIT_ENABLE_OPTIX=OFF \
    && cmake --build /tmp/drjit-build --parallel 2 \
    && cmake --install /tmp/drjit-build \
    && python -m pip install --no-cache-dir --no-build-isolation --no-deps \
        --config-settings=cmake.build-type=Release \
        --config-settings=cmake.define.DRJIT_ENABLE_CUDA=OFF \
        --config-settings=cmake.define.DRJIT_ENABLE_LLVM=ON \
        --config-settings=cmake.define.DRJIT_ENABLE_METAL=OFF \
        --config-settings=cmake.define.DRJIT_ENABLE_OPTIX=OFF \
        --config-settings=build.tool-args=-j2 \
        -e . \
    && drjit_site="$(python -c 'import site; print(site.getsitepackages()[0])')" \
    && test "$drjit_site" = /usr/local/lib/python3.12/site-packages \
    && cp -a "$drjit_site/drjit/"*.so /app/drjit/ \
    && cp -a "$drjit_site/drjit/auto" /app/drjit/ \
    && cp -a "$drjit_site/drjit/config.py" /app/drjit/config.py \
    && drjit_build="$(find /app/build -mindepth 1 -maxdepth 1 -type d -name 'cp*-cp*-linux_*' -print -quit)" \
    && test -n "$drjit_build" \
    && rm -rf -- "$drjit_site/drjit" /app/build \
    && printf "/app\n" > "$drjit_site/_editable_skbc_drjit.pth" \
    && printf "[pytest]\nnorecursedirs = ext build\n" > /app/pytest.ini \
    && cmake -S /app -B "$drjit_build" -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
        -DDRJIT_ENABLE_CUDA=OFF \
        -DDRJIT_ENABLE_LLVM=ON \
        -DDRJIT_ENABLE_METAL=OFF \
        -DDRJIT_ENABLE_OPTIX=OFF \
    && mv pyproject.toml /opt/drjit-pyproject.toml \
    && chmod -R a+rX /opt/drjit-runtime /opt/drjit-pyproject.toml

CMD ["/bin/bash"]
