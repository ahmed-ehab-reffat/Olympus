FROM public.ecr.aws/d3j8x8q7/olympus-base:latest

ARG TARGETARCH

RUN set -eux; \
    case "$TARGETARCH" in \
      arm64) \
        jdk_url='https://github.com/adoptium/temurin25-binaries/releases/download/jdk-25.0.4%2B7/OpenJDK25U-jdk_aarch64_linux_hotspot_25.0.4_7.tar.gz'; \
        jdk_sha='621f7196f0b682fb557da58bec89bd7dfe5419811fe1c0ba75c9cc8432f084c7' ;; \
      amd64) \
        jdk_url='https://github.com/adoptium/temurin25-binaries/releases/download/jdk-25.0.4%2B7/OpenJDK25U-jdk_x64_linux_hotspot_25.0.4_7.tar.gz'; \
        jdk_sha='e58fcdcd637b25c03ca84cbbcefc70d11efb8f4b4cbd05decc9f661769d77f94' ;; \
      *) echo "unsupported Docker architecture: $TARGETARCH" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "$jdk_url" -o /tmp/jdk.tar.gz; \
    echo "$jdk_sha  /tmp/jdk.tar.gz" | sha256sum -c -; \
    mkdir -p /opt/java; \
    tar -xzf /tmp/jdk.tar.gz -C /opt/java --strip-components=1; \
    rm /tmp/jdk.tar.gz; \
    curl -fsSL 'https://archive.apache.org/dist/maven/maven-3/3.9.12/binaries/apache-maven-3.9.12-bin.tar.gz' -o /tmp/maven.tar.gz; \
    echo '0a1be79f02466533fc1a80abbef8796e4f737c46c6574ede5658b110899942a94db634477dfd3745501c80aef9aac0d4f841d38574373f7e2d24cce89d694f70  /tmp/maven.tar.gz' | sha512sum -c -; \
    mkdir -p /opt/maven; \
    tar -xzf /tmp/maven.tar.gz -C /opt/maven --strip-components=1; \
    rm /tmp/maven.tar.gz; \
    printf '%s\n' \
      '<?xml version="1.0" encoding="UTF-8"?>' \
      '<toolchains>' \
      '  <toolchain>' \
      '    <type>jdk</type>' \
      '    <provides><version>25</version></provides>' \
      '    <configuration><jdkHome>/opt/java</jdkHome></configuration>' \
      '  </toolchain>' \
      '</toolchains>' \
      > /opt/maven-toolchains.xml; \
    ln -sf /opt/maven/bin/mvn /usr/local/bin/mvn; \
    ln -sf /opt/java/bin/java /usr/local/bin/java; \
    ln -sf /opt/java/bin/javac /usr/local/bin/javac

ENV JAVA_HOME=/opt/java
ENV PATH="/opt/maven/bin:/opt/java/bin:${PATH}"
ENV MAVEN_OPTS="-Dmaven.repo.local=/opt/maven-cache"
ENV MAVEN_ARGS="--toolchains /opt/maven-toolchains.xml"

WORKDIR /app

COPY . .

RUN ./tools/download_serialization_test_data.sh cpp go \
    && mvn -B -Dmaven.gitcommitid.skip=true -DskipTests package \
    && mvn -B org.apache.maven.plugins:maven-dependency-plugin:3.9.0:get \
      -Dartifact=org.apache.maven.surefire:surefire-testng:3.5.4 \
    && find /opt/maven-cache -name _remote.repositories -delete \
    && rm -rf /app/target \
    && chmod -R a+rX /opt/java /opt/maven \
    && chmod -R a+rwX /opt/maven-cache /app

CMD ["/bin/bash"]
