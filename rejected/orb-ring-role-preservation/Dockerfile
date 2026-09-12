FROM public.ecr.aws/d3j8x8q7/olympus-base-go:latest
WORKDIR /app
COPY . .
RUN go mod download && go build ./...
CMD ["/bin/bash"]
