FROM golang:1.21.3-alpine

RUN apk add --no-cache git findutils build-base

WORKDIR /app/reswarmify

RUN mkdir -p cli/ build/

COPY cli/go.mod cli/go.mod
COPY cli/go.sum cli/go.sum

RUN cd cli && go mod download

COPY cli/ cli/
COPY scripts/ scripts/
COPY targets targets

ENTRYPOINT [ "scripts/build-all.sh" ]