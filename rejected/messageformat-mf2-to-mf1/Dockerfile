FROM public.ecr.aws/d3j8x8q7/olympus-base-typescript:latest

WORKDIR /app
COPY . .
ENV HOME=/app
ENV NODE_ENV=development

RUN npm ci --include=dev --no-audit --no-fund \
    && npm run build:esm -w mf1/packages/runtime \
    && npm cache clean --force \
    && chmod -R a+rwX /app

CMD ["/bin/bash"]
