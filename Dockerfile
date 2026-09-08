# ==============================================================================
# FASE 1: Compilación y empaquetado del proyecto (Build Stage)
# ==============================================================================
# Usamos la imagen oficial de Maven con OpenJDK 17 basado en Alpine Linux (ultraligera).
# Le asignamos el alias "builder" para poder referenciarla más adelante.
FROM maven:3.9-eclipse-temurin-17-alpine AS builder

# Establecemos el directorio de trabajo donde se compilará la aplicación dentro del contenedor.
WORKDIR /build

# 1. Copiamos únicamente el descriptor de dependencias (pom.xml).
# Esto nos permite descargar primero las librerías necesarias.
COPY pom.xml .

# Descargamos las dependencias necesarias offline. 
# Al hacer esto antes de copiar el código fuente, Docker podrá reutilizar esta capa en caché 
# si no cambias el pom.xml, acelerando enormemente las compilaciones futuras.
RUN mvn dependency:go-offline

# 2. Copiamos el directorio del código fuente ('src').
# Si la carpeta destino './src' no existe en el contenedor, Docker la crea automáticamente.
COPY src ./src

# Generamos el paquete (.war).
# - No usamos 'mvn clean' porque el entorno Docker arranca desde cero (está limpio por defecto).
# - No usamos 'mvn install' porque no necesitamos registrar la librería en el repositorio local .m2.
# - Usamos '-DskipTests' porque las pruebas unitarias ya habrán sido validadas en la fase de CI de GitHub Actions.

# ==============================================================================
# ¿POR QUÉ USAMOS 'mvn package' Y NO 'mvn install'?
# ==============================================================================
#
# Ciclo de vida de build en Maven:
# 1. mvn compile  --> Compila el código Java (.java) a bytecode (.class).
# 2. mvn test     --> Ejecuta las pruebas unitarias.
# 3. mvn package  --> Ejecuta lo anterior y crea el empaquetado final (.war o .jar) 
#                     dentro de la carpeta local 'target/'.
# 4. mvn install  --> Ejecuta lo anterior Y ADEMÁS copia ese .war/.jar en el 
#                     repositorio local de Maven (~/.m2/repository/).
#
# CONCLUSIÓN PARA DOCKER:
# Dentro del contenedor solo necesitamos el archivo .war para pasárselo a Tomcat.
# Hacer 'install' copiaría inútilmente el archivo a la carpeta .m2 del contenedor,
# gastando tiempo de CPU y espacio en disco sin aportar ningún beneficio.
RUN mvn package -DskipTests



# ==============================================================================
# FASE 2: Entorno de ejecución en servidor Apache Tomcat (Final Stage)
# ==============================================================================
# Cambiamos a la imagen oficial de Apache Tomcat 10.1 con Java 17 sobre Alpine.
# En esta fase desechamos todo el entorno de Maven, el código fuente y las dependencias de build.
FROM tomcat:10.1-jdk17-temurin-alpine

# Copiamos ÚNICAMENTE el archivo .war compilado en la FASE 1 ("builder").
# - Lo tomamos desde la carpeta '/build/target/' del contenedor builder.
# - Lo renombramos a 'ROOT.war' al ponerlo en la carpeta 'webapps' de Tomcat.
# - Al llamarse 'ROOT.war', Tomcat le asigna el context path raíz (/), eliminando la necesidad
#   de incluir el nombre del proyecto en la URL (ej: responderá directo en http://localhost:8080/api/miSaludo).

#Punteo entre fases (COPY --from=builder): Docker inspecciona la capa de disco producida por el stage llamado builder, 
#busca el archivo en /build/target/prueba_3-0.0.1.war y lo copia directamente al disco de la nueva imagen en /usr/local/tomcat/webapps/ROOT.war.
COPY --from=builder /build/target/prueba_3-0.0.1.war /usr/local/tomcat/webapps/ROOT.war

# Indicamos que el contenedor escuchará peticiones HTTP en el puerto 8080.
EXPOSE 8080

# Comando para iniciar el servicio de Tomcat en primer plano dentro del contenedor.
CMD ["catalina.sh", "run"]