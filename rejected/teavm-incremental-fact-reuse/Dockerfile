FROM public.ecr.aws/d3j8x8q7/olympus-base-jvm:latest
ENV GRADLE_USER_HOME=/opt/gradle-cache
WORKDIR /app
RUN git config --system --add safe.directory '*'
COPY --chown=1000:1000 . .
RUN printf '%s\n' \
      'allprojects {' \
      '  if (path == ":tests") {' \
      '    afterEvaluate {' \
      '      tasks.register("collectTestLibs", Copy) {' \
      '        from(configurations.testRuntimeClasspath)' \
      '        into("/opt/testlibs")' \
      '      }' \
      '    }' \
      '  }' \
      '}' > /tmp/collect-libs.gradle \
 && ./gradlew --no-daemon -I /tmp/collect-libs.gradle :tests:collectTestLibs \
 && rm -f /tmp/collect-libs.gradle \
 && ls /opt/testlibs | grep -q junit-jupiter-engine \
 && chmod -R a+rwX /opt/testlibs \
 && find /app \( -type d -o -user 0 \) -exec chmod a+rwX {} + \
 && find /opt/gradle-cache \( \( -type d ! -perm -o+rwx \) -o \( ! -type d ! -perm -o+rw \) \) -exec chmod a+rwX {} + \
 && rm -rf /opt/gradle-cache/daemon
CMD ["/bin/bash"]
