FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest

WORKDIR /app

COPY . .

# Exact dependency closure resolved for the pinned repository and base image.
RUN python -m pip install --no-cache-dir --only-binary=:all: \
        "bracex==3.0.1" \
        "build==1.5.0" \
        "certifi==2026.5.20" \
        "charset-normalizer==3.4.7" \
        "contourpy==1.3.3" \
        "cycler==0.12.1" \
        "dataclasses==0.6" \
        "fonttools==4.63.0" \
        "idna==3.18" \
        "iniconfig==2.3.0" \
        "kiwisolver==1.5.0" \
        "llvmlite==0.49.0" \
        "matplotlib==3.11.1" \
        "numba==0.67.0" \
        "numpy==2.5.2" \
        "numpy-quaternion==2024.0.13" \
        "packaging==26.2" \
        "Pillow==12.3.0" \
        "piexif==1.1.3" \
        "pluggy==1.6.0" \
        "Pygments==2.20.0" \
        "pyparsing==3.3.2" \
        "pyproject-hooks==1.2.0" \
        "pytest==9.0.3" \
        "python-dateutil==2.9.0.post0" \
        "pytz==2026.3.post1" \
        "PyYAML==6.0.3" \
        "requests==2.34.2" \
        "scipy==1.18.0" \
        "setuptools==82.0.1" \
        "setuptools-scm==10.0.5" \
        "six==1.17.0" \
        "tabulate==0.10.0" \
        "tqdm==4.70.0" \
        "urllib3==2.7.0" \
        "vcs-versioning==1.1.1" \
        "wcmatch==11.0.1" \
        "wheel==0.47.0"

# The pin declares README.md but currently tracks README.adoc. Create a
# packaging-only fallback only when needed, then install the checkout editably
# without resolving any additional dependencies or build requirements.
RUN generated_readme=0 \
    && if [ ! -f README.md ]; then \
           if [ -f README.adoc ]; then cp README.adoc README.md; \
           else printf '%s\n' 'kapture' > README.md; fi; \
           generated_readme=1; \
       fi \
    && python -m pip install --no-cache-dir --no-deps --no-build-isolation -e . \
    && if [ "$generated_readme" = 1 ]; then rm -f README.md; fi \
    && chmod -R a+rX /app

CMD ["/bin/bash"]
