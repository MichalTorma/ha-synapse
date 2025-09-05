# Minimal test to isolate /init permission issue
ARG BUILD_FROM
FROM $BUILD_FROM

# Install only python3
RUN apk add --no-cache python3

# Create minimal rootfs structure
RUN mkdir -p /etc/cont-init.d && \
    mkdir -p /etc/services.d/test

# Create minimal banner script
RUN echo '#!/usr/bin/with-contenv bashio' > /etc/cont-init.d/00-test.sh && \
    echo 'bashio::log.info "Minimal test banner"' >> /etc/cont-init.d/00-test.sh && \
    chmod +x /etc/cont-init.d/00-test.sh

# Create minimal service
RUN echo '#!/usr/bin/with-contenv bashio' > /etc/services.d/test/run && \
    echo 'bashio::log.info "Test service starting"' >> /etc/services.d/test/run && \
    echo 'exec sleep infinity' >> /etc/services.d/test/run && \
    chmod +x /etc/services.d/test/run

# Create service type
RUN echo 'longrun' > /etc/services.d/test/type

# Expose port
EXPOSE 8008
