FROM public.ecr.aws/d3j8x8q7/olympus-base-typescript:latest

WORKDIR /app
ENV HOME=/app
ENV NODE_ENV=development

RUN git config --system --add safe.directory '*'

COPY . .

RUN npm ci --include=dev --ignore-scripts --no-audit --no-fund \
    && npm cache clean --force \
    && rm -rf /app/.npm \
    && chmod -R a+rwX /app

CMD ["/bin/bash"]
