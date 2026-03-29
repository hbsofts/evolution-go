FROM golang:1.22-alpine AS build

# Instalamos git y las librerías necesarias
RUN apk update && apk add --no-cache git build-base libjpeg-turbo-dev libwebp-dev

WORKDIR /build

# 1. Copiamos todo el repo
COPY . .

# 2. LIMPIEZA: Eliminamos cualquier enlace roto de dependencias locales
# Esto obliga a Go a usar lo que está en el repo o descargarlo de nuevo
RUN go mod tidy

# 3. Descargamos (ahora sí debería pasar)
RUN go mod download

# 4. Compilamos
ARG VERSION=dev
RUN CGO_ENABLED=1 go build -ldflags "-X main.version=${VERSION}" -o server ./cmd/evolution-go

FROM alpine:3.19.1 AS final
RUN apk update && apk add --no-cache tzdata ffmpeg libjpeg-turbo libwebp
WORKDIR /app
COPY --from=build /build/server .
# Usamos un truco para que si estas carpetas no existen, no falle el build
RUN mkdir -p manager/dist
COPY --from=build /build/VERSION ./VERSION || echo "1.0.0" > VERSION

ENV TZ=America/Guatemala
ENTRYPOINT ["/app/server"]
