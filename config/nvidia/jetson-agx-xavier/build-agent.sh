#!/bin/bash

go get .
CGO_ENABLED=1 GOOS=linux GOARCH=arm64 GOARM=7 CC=aarch64-linux-gnu-gcc go build .

