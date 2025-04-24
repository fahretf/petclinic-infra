FROM openjdk:17-jdk-alpine
WORKDIR /app
COPY target/*.jar petclinic.jar
EXPOSE 9966
ENTRYPOINT ["java", "-jar", "petclinic.jar"]
