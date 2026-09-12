FROM public.ecr.aws/d3j8x8q7/olympus-base-jvm:latest

ENV MAVEN_REPO_LOCAL=/opt/maven-cache
ENV MAVEN_OPTS="-Dmaven.repo.local=/opt/maven-cache"

WORKDIR /app

COPY . .

RUN mkdir -p /opt/maven-cache \
    && mvn -B --no-transfer-progress \
      -DskipTests -Dmaven.javadoc.skip=true -Dsource.skip=true \
      -Dgcf.skip=true install \
    && mvn -B --no-transfer-progress dependency:get \
      -Dartifact=org.apache.maven.surefire:surefire-junit-platform:3.2.5 \
    && mvn -B --no-transfer-progress dependency:get \
      -Dartifact=org.junit.platform:junit-platform-launcher:1.10.2 \
    && find /opt/maven-cache -name _remote.repositories -delete \
    && rm -rf /app/*/target /app/target \
    && chmod -R a+rX /opt/maven-cache /app

CMD ["/bin/bash"]
