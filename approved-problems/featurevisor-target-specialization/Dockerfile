FROM public.ecr.aws/d3j8x8q7/olympus-base-typescript:latest

WORKDIR /app
COPY . .
ENV HOME=/app
ENV NODE_ENV=development

RUN npm ci --include=dev --ignore-scripts --no-audit --no-fund \
    && npm install --include=dev --no-save --no-audit --no-fund jest-junit@16.0.0 \
    && npx lerna run build --scope @featurevisor/types --scope @featurevisor/sdk --scope @featurevisor/parsers --include-dependencies \
    && npm cache clean --force \
    && chmod -R a+rwX /app

CMD ["/bin/bash"]
