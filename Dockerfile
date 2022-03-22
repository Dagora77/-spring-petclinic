FROM tomcat:9.0-alpine
LABEL version = "1.1.3"
COPY target/spring-petclinic-2.6.0-SNAPSHOT.jar /usr/local/tomcat/webapps/spring-petclinic-2.6.0-SNAPSHOT.jar
