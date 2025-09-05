ARG BUILD_FROM
FROM $BUILD_FROM

# Install basic dependencies
RUN apk add --no-cache \
    python3 \
    py3-pip \
    postgresql-client \
    curl \
    build-base \
    python3-dev \
    libffi-dev \
    openssl-dev \
    libpq-dev

# Create synapse user  
RUN addgroup -g 991 synapse && \
    adduser -D -s /bin/sh -u 991 -G synapse synapse

# Create directories
RUN mkdir -p /config/synapse && \
    mkdir -p /media/synapse && \
    chown -R synapse:synapse /config/synapse && \
    chown -R synapse:synapse /media/synapse

# Install Synapse in virtual environment
RUN python3 -m venv /opt/venv && \
    /opt/venv/bin/pip install --upgrade pip && \
    /opt/venv/bin/pip install matrix-synapse[postgres] psycopg2-binary

# Set PATH
ENV PATH="/opt/venv/bin:$PATH"

# Copy rootfs
COPY rootfs /

# Set permissions
RUN chmod +x /etc/cont-init.d/* && \
    chmod +x /etc/services.d/synapse/*

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
