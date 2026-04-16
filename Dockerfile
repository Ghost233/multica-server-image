# syntax=docker/dockerfile:1.7

FROM golang:1.26-alpine AS builder

RUN apk add --no-cache git

WORKDIR /src

COPY upstream/server/go.mod upstream/server/go.sum ./server/
RUN cd server && go mod download

COPY upstream/server/ ./server/

ARG VERSION=dev
ARG COMMIT=unknown

RUN cd server && CGO_ENABLED=0 go build -ldflags "-s -w" -o bin/server ./cmd/server
RUN cd server && CGO_ENABLED=0 go build -ldflags "-s -w" -o bin/migrate ./cmd/migrate

FROM alpine:3.21

RUN apk add --no-cache ca-certificates tzdata

WORKDIR /app

COPY --from=builder /src/server/bin/server ./server
COPY --from=builder /src/server/bin/migrate ./migrate
COPY upstream/server/migrations/ ./migrations/
COPY entrypoint.sh ./entrypoint.sh

RUN chmod +x ./entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["./entrypoint.sh"]
CMD ["./server"]
