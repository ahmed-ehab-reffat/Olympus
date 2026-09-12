FROM public.ecr.aws/d3j8x8q7/olympus-base-python:latest

ENV NO_COLOR=""

WORKDIR /app
COPY . .

RUN pip install --no-cache-dir -e ".[syntax]" \
        "rich==14.2.0" \
        "markdown-it-py==4.2.0" \
        "mdit-py-plugins==0.6.1" \
        "linkify-it-py==2.1.0" \
        "typing_extensions==4.15.0" \
        "platformdirs==4.10.0" \
        "pygments==2.20.0" \
        "tree-sitter==0.25.2" \
    && pip install --no-cache-dir \
        "pytest==8.4.2" \
        "pytest-xdist==3.8.0" \
        "pytest-asyncio==1.4.0" \
        "pytest-textual-snapshot==1.1.0" \
        "textual-dev==1.8.0" \
        "httpx==0.28.1" \
    && printf 'import os\n\nos.environ.pop("NO_COLOR", None)\n' > conftest.py \
    && chmod -R a+rwX /app

CMD ["/bin/bash"]
