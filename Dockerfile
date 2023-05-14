FROM adoptopenjdk/openjdk8:alpine-slim
EXPOSE 8080
ARG JAR_FILE=target/*.jar
RUN addgroup -S pipleine && adduser -S k8s-pipeline -G pipleine
COPY ${JAR_FILE} /home/k8s-pipeline/app.jar
USER k8s-pipeline
ENTRYPOINT ["java","-jar","/home/k8s-pipeline/app.jar"]