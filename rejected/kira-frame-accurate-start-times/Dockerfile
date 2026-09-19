FROM public.ecr.aws/d3j8x8q7/olympus-base-rust:latest
WORKDIR /app
COPY . .
RUN cargo install cargo2junit \
    && cargo fetch \
    && cargo build -p kira --no-default-features --features symphonia,wav,ogg,vorbis,flac,mp3,pcm \
    && chmod -R a+rwX /opt/cargo /app
CMD ["/bin/bash"]
