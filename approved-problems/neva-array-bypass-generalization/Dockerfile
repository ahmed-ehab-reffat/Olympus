FROM public.ecr.aws/d3j8x8q7/olympus-base-go:latest

ENV GOPATH="/root/go"
ENV PATH="/root/go/bin:${PATH}"
ENV GOTOOLCHAIN="local"
ENV GOFLAGS="-mod=mod"

WORKDIR /app

COPY . .

RUN git config --system --add safe.directory '*' \
    && go mod download \
    && go build ./... \
    && chmod -R a+rwX /app \
    && chmod -R a+rX /root/go

CMD ["/bin/bash"]
