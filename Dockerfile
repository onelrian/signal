# Runtime stage (Debian Bookworm slim - provides glibc 2.36+ and openssl 3)
FROM debian:bookworm-slim

# Install only runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    libssl3 && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create non-root user with no shell
RUN groupadd -g 1000 exporter && \
    useradd -m -u 1000 -g exporter -s /sbin/nologin exporter

WORKDIR /app

# Copy binary directly from CI workspace (target/release)
# Note: CI must run `cargo build --release` before this
COPY target/release/signal /app/exporter

# Verify binary
RUN chmod +x /app/exporter

# Switch to non-root user
USER exporter

ENTRYPOINT ["/app/exporter"]
