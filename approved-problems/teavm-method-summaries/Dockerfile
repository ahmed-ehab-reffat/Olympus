FROM public.ecr.aws/d3j8x8q7/olympus-base-jvm:latest
ENV GRADLE_USER_HOME=/opt/gradle-cache
WORKDIR /app
RUN git config --system --add safe.directory '*'
COPY --chown=1000:1000 . .
RUN ./gradlew --no-daemon :core:testClasses :core:checkstyleMain \
 && mkdir -p /opt/testlibs \
 && for jar in hppc-0.10.0 asm-9.10.1 asm-commons-9.10.1 asm-util-9.10.1 asm-tree-9.10.1 asm-analysis-9.10.1 \
        rhino-1.9.1 jackson-annotations-2.21 junit-4.13.2 hamcrest-core-1.3; do \
      found="$(find /opt/gradle-cache/caches/modules-2 -name "$jar.jar" | head -n 1)"; \
      test -n "$found" || exit 1; \
      cp "$found" /opt/testlibs/; \
    done \
 && chmod -R a+rwX /opt/testlibs \
 && find /app \( -type d -o -user 0 \) -exec chmod a+rwX {} + \
 && find /opt/gradle-cache \( \( -type d ! -perm -o+rwx \) -o \( ! -type d ! -perm -o+rw \) \) -exec chmod a+rwX {} + \
 && rm -rf /opt/gradle-cache/daemon/9.7.1
CMD ["/bin/bash"]
