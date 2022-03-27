FROM openjdk:8-jre-alpine3.9
COPY target/spring-petclinic-2.6.0-SNAPSHOT.jar  /spring-petclinic-2.6.0-SNAPSHOT.jar
CMD ["java", "-jar", "/spring-petclinic-2.6.0-SNAPSHOT.jar"]
