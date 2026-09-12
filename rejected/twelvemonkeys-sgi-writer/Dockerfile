FROM maven:3.9.11-eclipse-temurin-25

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 \
    && rm -rf /var/lib/apt/lists/*

COPY . .

RUN mvn -pl imageio/imageio-sgi -am test -DskipITs
RUN chmod +x test.sh

CMD ["/bin/bash"]
