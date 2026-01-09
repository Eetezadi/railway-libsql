FROM golang:1.25-alpine AS token-compiler
WORKDIR /app
COPY main.go .
RUN go mod init token-gen && \
    go get github.com/golang-jwt/jwt/v5 && \
    go build -o /token-gen main.go

FROM ghcr.io/tursodatabase/libsql-server:v0.24.33

USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends gosu ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/lib/sqld && chown sqld:sqld /var/lib/sqld

COPY --from=token-compiler /token-gen /usr/local/bin/token-gen
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/token-gen

STOPSIGNAL SIGINT
ENTRYPOINT ["entrypoint.sh"]
