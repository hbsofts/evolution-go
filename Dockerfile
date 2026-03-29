# Usamos la 1.23 que es la más reciente compatible en la mayoría de nubes
FROM golang:1.23-alpine AS build

RUN apk update && apk add --no-cache git build-base libjpeg-turbo-dev libwebp-dev

WORKDIR /build

# Copiamos todo el repo de HBSofts
COPY . .

# Forzamos la actualización de dependencias para la versión 1.23
RUN go mod tidy

# Descargamos
RUN go mod download

# Compilamos el binario
ARG VERSION=dev
RUN CGO_ENABLED=1 go build -ldflags "-X main.version=${VERSION}" -o server ./cmd/evolution-go

FROM alpine:3.19.1 AS final
RUN apk update && apk add --no-cache tzdata ffmpeg libjpeg-turbo libwebp
WORKDIR /app
COPY --from=build /build/server .
# Evitamos errores si no existen estas carpetas
RUN mkdir -p manager/dist
COPY --from=build /build/VERSION ./VERSION || echo "1.0.0" > VERSION

ENV TZ=America/Guatemala
ENTRYPOINT ["/app/server"]
