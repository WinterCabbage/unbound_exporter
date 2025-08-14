# Build stage
FROM --platform=$BUILDPLATFORM docker.io/library/golang:1.21.4-bookworm AS build

# Build arguments for cross-compilation
ARG TARGETOS
ARG TARGETARCH
ARG VERSION

WORKDIR /go/src/app

# Copy go module files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY *.go ./

# Build the binary
ENV CGO_ENABLED=0
RUN GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build \
    -ldflags="-s -w -X main.version=${VERSION}" \
    -o /go/bin/unbound_exporter .

# Final stage
FROM gcr.io/distroless/static-debian12

# Add metadata
LABEL org.opencontainers.image.title="Unbound Exporter" \
      org.opencontainers.image.description="Prometheus exporter for Unbound DNS resolver" \
      org.opencontainers.image.source="https://github.com/letsencrypt/unbound_exporter" \
      org.opencontainers.image.licenses="Apache-2.0"

# Copy the binary from build stage
COPY --from=build /go/bin/unbound_exporter /

# Expose metrics port
EXPOSE 9167

# Run as non-root user
USER nonroot:nonroot

ENTRYPOINT ["/unbound_exporter"]
