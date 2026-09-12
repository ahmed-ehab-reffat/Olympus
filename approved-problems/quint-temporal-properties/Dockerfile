FROM public.ecr.aws/d3j8x8q7/olympus-base-typescript:latest
WORKDIR /app
COPY . .
RUN npm --prefix quint install --ignore-scripts --include=dev && chmod -R a+rwX /app
CMD ["/bin/bash"]
