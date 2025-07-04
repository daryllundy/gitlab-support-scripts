FROM ruby:3.2-alpine

# Install system dependencies
RUN apk add --no-cache \
    bash \
    curl \
    tar \
    gzip \
    findutils \
    coreutils \
    file

# Set working directory
WORKDIR /app

# Copy application files
COPY scripts/ ./scripts/
COPY tests/ ./tests/
COPY bin/ ./bin/
COPY README.md CLAUDE.md ./

# Make scripts executable
RUN chmod +x scripts/*.rb scripts/*.sh tests/*.sh bin/*

# Add /app/bin to PATH so wrapper scripts can be run directly
ENV PATH="/app/bin:$PATH"

# Create a non-root user
RUN addgroup -g 1000 gitlab && \
    adduser -D -s /bin/bash -u 1000 -G gitlab gitlab

# Switch to non-root user
USER gitlab

# Set default entrypoint
ENTRYPOINT ["/app/bin/entrypoint.sh"]
CMD ["--help"]