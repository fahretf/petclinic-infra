FROM openjdk:17-jdk-alpine
WORKDIR /app
RUN mkdir -p /app/logs && chmod 777 /app/logs
COPY target/*.jar petclinic.jar
EXPOSE 9966
ENTRYPOINT ["java", "-jar", "petclinic.jar"]
