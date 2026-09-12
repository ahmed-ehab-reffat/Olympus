FROM public.ecr.aws/d3j8x8q7/olympus-base-typescript:latest

WORKDIR /app

COPY . .

# The prepare script runs husky, which needs a git directory a source copy does not carry.
RUN npm ci --include=dev --ignore-scripts && chmod -R a+rwX /app

CMD ["/bin/bash"]
