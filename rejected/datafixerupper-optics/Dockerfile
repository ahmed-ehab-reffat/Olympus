FROM public.ecr.aws/d3j8x8q7/olympus-base-jvm:latest
WORKDIR /app
ENV GRADLE_USER_HOME=/opt/gradle-cache
ENV DFU_TEST_LIBS=/opt/testlibs
COPY . .
RUN chmod +x gradlew \
 && ./gradlew --no-daemon assemble compileTestJava \
 && ./gradlew --no-daemon dependencies --configuration testRuntimeClasspath \
 && mkdir -p /opt/testlibs \
 && find /opt/gradle-cache/caches/modules-2 -name '*.jar' ! -name '*-sources.jar' ! -name '*-javadoc.jar' -exec cp -n {} /opt/testlibs/ \; \
 && rm -rf /app/build /app/.gradle \
 && chmod -R a+rX /opt/testlibs \
 && chmod -R a+rwX /app /opt/gradle-cache
CMD ["/bin/bash"]
