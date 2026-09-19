FROM public.ecr.aws/d3j8x8q7/olympus-base-jvm:latest
ENV JAVA_HOME=/opt/jdk-25
ENV PATH=/opt/jdk-25/bin:$PATH
ENV MAVEN_ARGS="-Dmaven.repo.local=/opt/m2"
WORKDIR /app
RUN git config --system --add safe.directory '*'
COPY . .
RUN test -f planetiler-openmaptiles/submodule.pom.xml || ( \
      rm -rf planetiler-openmaptiles && git init -q planetiler-openmaptiles && \
      git -C planetiler-openmaptiles fetch -q --depth 1 https://github.com/openmaptiles/planetiler-openmaptiles.git 373030bce912550e426683eda60812e35048f461 && \
      git -C planetiler-openmaptiles checkout -q FETCH_HEAD )
RUN mvn -B -q -Pflatten -pl planetiler-core -am -DskipTests install && \
    mvn -B -q -Pflatten -pl planetiler-custommap -Dmaven.test.skip=true install && \
    mvn -B -q -pl planetiler-custommap dependency:resolve && \
    mvn -B -q -pl planetiler-custommap dependency:get -Dartifact=org.apache.maven.surefire:surefire-junit-platform:3.5.5 && \
    mvn -B -q -pl planetiler-custommap dependency:get -Dartifact=org.junit.platform:junit-platform-launcher:1.12.2 && \
    mvn -B -q -pl planetiler-custommap dependency:get -Dartifact=org.junit.platform:junit-platform-launcher:6.1.2 && \
    rm -rf planetiler-core/target planetiler-custommap/target && \
    chmod -R a+rwX /opt/m2 /app
CMD ["/bin/bash"]
