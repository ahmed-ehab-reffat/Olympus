FROM public.ecr.aws/d3j8x8q7/olympus-base-typescript:latest

ENV NODE_ENV=development

WORKDIR /app

COPY --chown=1000:1000 . .

RUN git config --system --add safe.directory '*' \
    && npm ci --no-audit --no-fund --ignore-scripts --include=dev \
    && npm rebuild canvas \
    && npx lerna run build \
    && find /app \( -type d -o -user 0 \) -exec chmod a+rwX {} +

CMD ["/bin/bash"]
