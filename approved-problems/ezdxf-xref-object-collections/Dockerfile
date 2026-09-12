FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libdbus-1-3=1.14.10-1~deb12u1 \
        libegl1=1.6.0-1 \
        libgl1=1.6.0-1 \
        libxkbcommon0=1.5.0-1 \
    && rm -rf /var/lib/apt/lists/*

COPY . .

# Exact dependency set for the audited repository revision. The editable local
# install below is dependency-free and does not resolve anything at runtime.
RUN python -m pip install --no-cache-dir \
        Cython==3.2.9 \
        Pillow==12.3.0 \
        PyMuPDF==1.28.2 \
        PySide6==6.8.0.2 \
        PySide6-Addons==6.8.0.2 \
        PySide6-Essentials==6.8.0.2 \
        contourpy==1.3.3 \
        cycler==0.12.1 \
        fonttools==4.63.0 \
        iniconfig==2.3.0 \
        kiwisolver==1.5.0 \
        matplotlib==3.11.1 \
        numpy==2.5.2 \
        packaging==26.3 \
        pluggy==1.6.0 \
        pygments==2.20.0 \
        pyparsing==3.3.2 \
        pytest==9.1.1 \
        python-dateutil==2.9.0.post0 \
        setuptools==84.0.0 \
        shiboken6==6.8.0.2 \
        six==1.17.0 \
        typing_extensions==4.16.0 \
        wheel==0.48.0

RUN python -m pip install --no-cache-dir --no-build-isolation --no-deps -e . \
    && chmod -R a+rwX /app

ENV HOME=/tmp/ezdxf-home \
    PYTHONDONTWRITEBYTECODE=1 \
    QT_QPA_PLATFORM=offscreen

CMD ["/bin/bash"]
