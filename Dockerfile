# syntax=docker/dockerfile:1

FROM golang:1.26-alpine AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY main.go ./
COPY templates ./templates
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/server .

FROM alpine:3.24 AS runtime
RUN apk --no-cache upgrade && apk add --no-cache tini ca-certificates \
    && addgroup -S app && adduser -S -G app -h /app app
WORKDIR /app
COPY --from=build /out/server /app/server
COPY --from=build /src/templates /app/templates
ENV PORT=8080
EXPOSE 8080
USER app
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/app/server"]
