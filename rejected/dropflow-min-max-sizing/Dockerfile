FROM public.ecr.aws/d3j8x8q7/olympus-base-typescript:latest

ENV NODE_ENV=development

WORKDIR /app

COPY . .

RUN npm ci --include=dev --ignore-scripts && chmod -R a+rwX /app

CMD ["/bin/bash"]
