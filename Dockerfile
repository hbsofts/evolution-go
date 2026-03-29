FROM golang:1.23-alpine AS build

RUN apk update && apk add --no-cache git build-base libjpeg-turbo-dev libwebp-dev

WORKDIR /build

# 1. Copiamos todo el repo de HBSofts
COPY . .

# 2. HACK TÉCNICO: Forzamos el cambio de versión en el go.mod a la 1.23 
# para que no bloquee el build en Railway.
RUN sed -i 's/go 1.25/go 1.23/g' go.mod

# 3. Limpiamos y descargamos
RUN go mod tidy
RUN go mod download

# 4. Compilamos el binario
ARG VERSION=dev
RUN CGO_ENABLED=1 go build -ldflags "-X main.version=${VERSION}" -o server ./cmd/evolution-go

# --- Etapa Final ---
FROM alpine:3.19.1 AS final
RUN apk update && apk add --no-cache tzdata ffmpeg libjpeg-turbo libwebp
WORKDIR /app
COPY --from=build /build/server .
RUN mkdir -p manager/dist
COPY --from=build /build/VERSION ./VERSION || echo "1.0.0" > VERSION

ENV TZ=America/Guatemala
ENTRYPOINT ["/app/server"]
