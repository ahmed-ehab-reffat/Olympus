FROM public.ecr.aws/d3j8x8q7/olympus-base-typescript:latest

ENV NODE_ENV=development
ENV HOME=/app
ENV NPM_CONFIG_CACHE=/app/.npm-cache

WORKDIR /app

COPY . .

RUN npm install --no-audit --no-fund \
    && npx -y -p typescript@4.1.3 -p typedoc@0.18.0 tsc --version \
    && mkdir -p packages/maker.js/dist \
    && chmod -R a+rwX /app

CMD ["/bin/bash"]
