# -- Etapa de Construcción --
FROM eclipse-temurin:17-jdk-jammy as builder
WORKDIR /app

# Caché de dependencias
COPY .mvn/ .mvn
COPY mvnw pom.xml ./
RUN chmod +x mvnw
RUN ./mvnw dependency:go-offline

# Compilación del código fuente
COPY src ./src
RUN ./mvnw clean package -DskipTests

# -- Etapa de Ejecución --
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

# Copia del artefacto
COPY --from=builder /app/target/*.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
