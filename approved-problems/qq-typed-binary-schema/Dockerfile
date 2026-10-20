FROM public.ecr.aws/d3j8x8q7/olympus-base-go:latest
ENV GOPATH=/go
ENV GOCACHE=/go/cache
ENV GOFLAGS=-buildvcs=false
ENV PATH="/go/bin:/opt/go/bin:${PATH}"
WORKDIR /app
COPY --chown=1000:1000 . .
RUN go mod download \
    && go build ./... \
    && chmod -R a+rwX /go \
    && find /app \( -type d -o -user 0 \) -exec chmod a+rwX {} +
CMD ["/bin/bash"]
