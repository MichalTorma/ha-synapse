# https://developers.home-assistant.io/docs/add-ons/configuration#add-on-dockerfile
ARG BUILD_FROM
FROM $BUILD_FROM

# Install required packages
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

# Install Synapse in virtual environment
RUN python3 -m venv /opt/venv && \
    /opt/venv/bin/pip install --upgrade pip && \
    /opt/venv/bin/pip install matrix-synapse[postgres] psycopg2-binary

# Set PATH to use virtual environment
ENV PATH="/opt/venv/bin:$PATH"

# Copy root filesystem
COPY rootfs /

# Ensure service scripts are executable
RUN chmod +x /etc/cont-init.d/* && \
    chmod +x /etc/services.d/synapse/run && \
    chmod +x /etc/services.d/synapse/finish

# Expose ports
EXPOSE 8008 8448

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD curl -f http://localhost:8008/health || exit 1
