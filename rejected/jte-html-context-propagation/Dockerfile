FROM public.ecr.aws/d3j8x8q7/olympus-base-jvm:latest
WORKDIR /app
ENV MAVEN_REPO=/opt/m2
COPY . .
RUN mvn -B -q -Dmaven.repo.local=$MAVEN_REPO -pl jte-runtime,jte,jte-kotlin -am test \
 && mvn -B -q -Dmaven.repo.local=$MAVEN_REPO -pl jte-runtime,jte,jte-kotlin -am clean \
 && chmod -R a+rX $MAVEN_REPO \
 && chmod -R a+rwX /app
CMD ["/bin/bash"]
