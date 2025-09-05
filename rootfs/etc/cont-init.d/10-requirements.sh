#!/usr/bin/with-contenv bashio
# ==============================================================================
# Home Assistant Community Add-on: Synapse Matrix Server
# Check and install additional requirements
# ==============================================================================

bashio::log.info "Checking system requirements..."

# Check if PostgreSQL is accessible
DATABASE_HOST=$(bashio::config 'database_host')
DATABASE_PORT=$(bashio::config 'database_port')

if ! bashio::config.exists 'database_password' || ! bashio::config.has_value 'database_password'; then
    bashio::exit.nok "Database password is required for PostgreSQL connection"
fi

# Test database connectivity
bashio::log.info "Testing database connectivity to ${DATABASE_HOST}:${DATABASE_PORT}..."

DATABASE_USER=$(bashio::config 'database_user')
DATABASE_PASSWORD=$(bashio::config 'database_password')
DATABASE_NAME=$(bashio::config 'database_name')

# Use pg_isready to test PostgreSQL connectivity  
if ! pg_isready -h "${DATABASE_HOST}" -p "${DATABASE_PORT}" -U "${DATABASE_USER}" -t 10; then
    bashio::log.warning "Cannot connect to PostgreSQL database at ${DATABASE_HOST}:${DATABASE_PORT}"
    bashio::log.warning "Please ensure the PostgreSQL addon is running and accessible"
else
    bashio::log.info "Database connectivity test successful"
fi

# Ensure data directories exist with proper permissions
bashio::log.info "Setting up data directories..."

mkdir -p /config/synapse
mkdir -p /config/synapse/keys
mkdir -p /media/synapse
chmod -R 750 /config/synapse
chmod -R 750 /media/synapse
chown -R root:root /config/synapse
chown -R root:root /media/synapse

bashio::log.info "Requirements check completed"
