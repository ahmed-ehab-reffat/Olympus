FROM public.ecr.aws/d3j8x8q7/olympus-base-typescript:latest

ENV NODE_ENV=development
ENV NPM_CONFIG_CACHE=/tmp/protobuf-es-npm-cache

WORKDIR /app
COPY --chown=1000:1000 . .
RUN chown 1000:1000 /app

USER 1000:1000
RUN npm ci --include=dev --no-audit --no-fund \
    && npm run build --workspace upstream-protobuf \
    && find packages/upstream-protobuf/.tmp -mindepth 2 -name test-proto-include -type d | grep -q . \
    && npm run build --workspace @bufbuild/protobuf \
    && npm run build --workspace @bufbuild/protobuf-test \
    && npm cache clean --force

USER root
RUN chmod -R a+rwX /app
CMD ["/bin/bash"]
