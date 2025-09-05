ARG BUILD_FROM
FROM $BUILD_FROM

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Build arguments
ARG BUILD_ARCH
ARG SYNAPSE_VERSION=1.137.0

# Install runtime dependencies
RUN \
    apk add --no-cache \
        ca-certificates \
        tzdata \
        postgresql-client \
        curl \
        python3 \
        py3-pip \
        build-base \
        python3-dev \
        libffi-dev \
        openssl-dev \
        libpq-dev

# Create synapse user and directories
RUN \
    addgroup -g 991 synapse \
    && adduser -D -s /bin/bash -u 991 -G synapse synapse \
    && mkdir -p /synapse/data \
    && mkdir -p /synapse/config

# Install Synapse in virtual environment
RUN \
    python3 -m venv /opt/venv \
    && /opt/venv/bin/pip install --upgrade pip \
    && /opt/venv/bin/pip install "matrix-synapse[postgres]==${SYNAPSE_VERSION}" psycopg2-binary

# Set permissions
RUN \
    chown -R synapse:synapse /synapse \
    && chmod -R g+w /synapse

# Set PATH
ENV PATH="/opt/venv/bin:$PATH"

# Copy rootfs
COPY rootfs /

# Build arguments for labels
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION

# Labels
LABEL \
    io.hass.name="${BUILD_NAME}" \
    io.hass.description="${BUILD_DESCRIPTION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="Michal Torma <torma.michal@gmail.com>" \
    org.opencontainers.image.title="${BUILD_NAME}" \
    org.opencontainers.image.description="${BUILD_DESCRIPTION}" \
    org.opencontainers.image.vendor="Home Assistant Community Add-ons" \
    org.opencontainers.image.authors="Michal Torma <torma.michal@gmail.com>" \
    org.opencontainers.image.licenses="AGPL-3.0" \
    org.opencontainers.image.url="https://github.com/MichalTorma/ha-synapse" \
    org.opencontainers.image.source="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.documentation="https://github.com/${BUILD_REPOSITORY}/blob/main/README.md" \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.revision=${BUILD_REF} \
    org.opencontainers.image.version=${BUILD_VERSION}

# Expose ports
EXPOSE 8008 8448

# Set working directory
WORKDIR /data

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD curl -f http://localhost:8008/health || exit 1
