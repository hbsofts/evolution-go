# Usamos una versión de Go estable y ligera
FROM golang:1.22-alpine AS build

# Instalamos dependencias necesarias para compilar librerías de imágenes y video
RUN apk update && apk add --no-cache git build-base libjpeg-turbo-dev libwebp-dev

# Directorio de trabajo para la compilación
WORKDIR /build

# 1. Copiamos TODO el contenido de tu repositorio HBSofts de una vez
# Esto evita errores de "file not found" con las subcarpetas de whatsmeow
COPY . .

# 2. Descargamos las dependencias (Go buscará los módulos en los archivos ya copiados)
RUN go mod download

# 3. Compilamos el binario de la aplicación
ARG VERSION=dev
RUN CGO_ENABLED=1 go build -ldflags "-X main.version=${VERSION}" -o server ./cmd/evolution-go

# --- Etapa Final ---
FROM alpine:3.19.1 AS final

# Instalamos herramientas de ejecución (ffmpeg para audios/videos de WhatsApp)
RUN apk update && apk add --no-cache tzdata ffmpeg libjpeg-turbo libwebp

WORKDIR /app

# Copiamos solo lo necesario desde la etapa de compilación
COPY --from=build /build/server .
# Verificamos que estas carpetas existan en tu repo, si no, Docker las creará vacías
COPY --from=build /build/manager/dist ./manager/dist
COPY --from=build /build/VERSION ./VERSION

# Configuramos tu zona horaria local (Guatemala)
ENV TZ=America/Guatemala

# Comando para iniciar la Evolution API Go
ENTRYPOINT ["/app/server"]
