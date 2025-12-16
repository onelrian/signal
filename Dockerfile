# Multi-stage build using consistent Debian version (Bullseye)
# This ensures builder and runtime have the same OpenSSL 1.1 version
FROM rust:1.83-slim-bullseye AS builder

# Install all build dependencies in one layer
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    pkg-config \
    libssl-dev \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /build

# Copy Cargo files first (for better layer caching)
COPY Cargo.toml Cargo.lock* ./
COPY src ./src

# Build the release binary
RUN cargo build --release --locked

# Normalize binary name: cargo may emit `signal`
# deterministic symlink `/build/target/release/signal` -> `/build/target/release/exporter` for runtime copy.
RUN if [ -f /build/target/release/signal ]; then \
    ln -sf /build/target/release/signal /build/target/release/exporter; \
    else \
    echo "ERROR: Binary signal not found in /build/target/release" && exit 1; \
    fi

# Runtime stage (Debian Bullseye slim)
FROM debian:bullseye-slim

# Install only runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    libsqlite3-0 \
    libssl1.1 && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create non-root user with no shell (more secure)
RUN groupadd -g 1000 exporter && \
    useradd -m -u 1000 -g exporter -s /sbin/nologin exporter

WORKDIR /app

# Copy binary from builder (we normalized the name to `/build/target/release/exporter`)
COPY --from=builder --chown=exporter:exporter /build/target/release/exporter /app/exporter

# Verify binary is executable
RUN chmod +x /app/exporter && \
    test -x /app/exporter || (echo "ERROR: Binary not executable!" && exit 1)

# Switch to non-root user
USER exporter

# Set entrypoint
ENTRYPOINT ["/app/exporter"]
