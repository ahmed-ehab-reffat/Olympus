FROM public.ecr.aws/d3j8x8q7/olympus-base-go:latest
WORKDIR /app
COPY . .
RUN go mod download && (cd test && go mod download && go test -count=1 -run '^$' ./... > /dev/null) && git config --system --add safe.directory '*' && chmod -R a+rwX /app
CMD ["/bin/bash"]
