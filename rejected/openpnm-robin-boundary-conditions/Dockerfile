FROM python:3.13.11-slim-bookworm@sha256:20080e807bfc404f8450b185cf0fc95d553462673598549613735f70a5b4d5d0

ENV MPLBACKEND=Agg \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN python -m pip install --no-cache-dir \
    asttokens==3.0.2 \
    attrs==25.4.0 \
    certifi==2025.11.12 \
    charset-normalizer==3.4.4 \
    chemicals==1.5.0 \
    contourpy==1.3.3 \
    coverage==7.12.0 \
    cycler==0.12.1 \
    decorator==5.2.1 \
    docrep==0.3.2 \
    executing==2.2.1 \
    fastjsonschema==2.21.2 \
    fluids==1.3.0 \
    fonttools==4.61.0 \
    h5py==3.15.1 \
    idna==3.11 \
    imageio==2.37.2 \
    iniconfig==2.3.0 \
    ipython==9.8.0 \
    ipython-pygments-lexers==1.1.1 \
    jedi==0.20.0 \
    jsonschema==4.25.1 \
    jsonschema-specifications==2025.9.1 \
    kiwisolver==1.4.9 \
    lazy-loader==0.4 \
    llvmlite==0.45.1 \
    markdown-it-py==3.0.0 \
    matplotlib==3.10.7 \
    matplotlib-inline==0.2.1 \
    mdurl==0.1.2 \
    mpmath==1.3.0 \
    networkx==3.6 \
    numba==0.62.1 \
    numpy==2.1.3 \
    packaging==25.0 \
    pandas==2.3.3 \
    parso==0.8.7 \
    pexpect==4.9.0 \
    pillow==12.0.0 \
    pluggy==1.6.0 \
    prompt-toolkit==3.0.53 \
    ptyprocess==0.7.0 \
    pure-eval==0.2.3 \
    pyamg==5.3.0 \
    pygments==2.19.2 \
    pyparsing==3.2.5 \
    pytest==8.4.2 \
    pytest-cov==7.0.0 \
    pytest-custom-exit-code==0.3.0 \
    pytest-split==0.10.0 \
    python-dateutil==2.9.0.post0 \
    pytz==2025.2 \
    referencing==0.37.0 \
    requests==2.32.5 \
    rich==14.2.0 \
    rpds-py==0.30.0 \
    scikit-image==0.25.2 \
    scipy==1.16.3 \
    six==1.17.0 \
    stack-data==0.6.3 \
    sympy==1.14.0 \
    thermo==0.6.0 \
    tifffile==2025.10.16 \
    tqdm==4.67.1 \
    traitlets==5.16.0 \
    transforms3d==0.4.2 \
    tzdata==2025.2 \
    urllib3==2.6.0 \
    wcwidth==0.8.2

COPY . .

RUN python -m pip install --no-cache-dir --no-deps -e .

CMD ["/bin/bash"]
