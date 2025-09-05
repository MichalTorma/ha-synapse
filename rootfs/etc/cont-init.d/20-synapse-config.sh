#!/usr/bin/with-contenv bashio
# ==============================================================================
# Home Assistant Community Add-on: Synapse Matrix Server
# Configures Synapse based on user settings
# ==============================================================================

readonly CONFIG_FILE="/config/synapse/homeserver.yaml"
readonly SIGNING_KEY_FILE="/config/synapse/homeserver.signing.key"
readonly LOG_CONFIG_FILE="/config/synapse/log_config.yaml"

bashio::log.info "Configuring Synapse Matrix server..."

# Create config directory
mkdir -p /config/synapse
mkdir -p /config/synapse/keys

# Read configuration values
SERVER_NAME=$(bashio::config 'server_name')
DATABASE_HOST=$(bashio::config 'database_host')
DATABASE_PORT=$(bashio::config 'database_port')
DATABASE_NAME=$(bashio::config 'database_name')
DATABASE_USER=$(bashio::config 'database_user')
DATABASE_PASSWORD=$(bashio::config 'database_password')
REGISTRATION_ENABLED=$(bashio::config 'registration_enabled')
REGISTRATION_REQUIRES_TOKEN=$(bashio::config 'registration_requires_token')
ENABLE_REGISTRATION_WITHOUT_VERIFICATION=$(bashio::config 'enable_registration_without_verification')
REPORT_STATS=$(bashio::config 'report_stats')
ADMIN_USERNAME=$(bashio::config 'admin_username')
ADMIN_PASSWORD=$(bashio::config 'admin_password')
ADMIN_EMAIL=$(bashio::config 'admin_email')
LOG_LEVEL=$(bashio::config 'log_level')
ENABLE_METRICS=$(bashio::config 'enable_metrics')
TURN_URI=$(bashio::config 'turn_uri')
TURN_USERNAME=$(bashio::config 'turn_username')
TURN_PASSWORD=$(bashio::config 'turn_password')
ENABLE_MEDIA_REPO=$(bashio::config 'enable_media_repo')
MAX_UPLOAD_SIZE=$(bashio::config 'max_upload_size')
FEDERATION_ENABLED=$(bashio::config 'federation_enabled')
PRESENCE_ENABLED=$(bashio::config 'presence_enabled')
PUBLIC_BASEURL=$(bashio::config 'public_baseurl')
SERVE_SERVER_WELLKNOWN=$(bashio::config 'serve_server_wellknown')
EMAIL_SMTP_HOST=$(bashio::config 'email_smtp_host')
EMAIL_SMTP_PORT=$(bashio::config 'email_smtp_port')
EMAIL_SMTP_USER=$(bashio::config 'email_smtp_user')
EMAIL_SMTP_PASS=$(bashio::config 'email_smtp_pass')
EMAIL_SMTP_REQUIRE_TRANSPORT_SECURITY=$(bashio::config 'email_smtp_require_transport_security')
EMAIL_FROM=$(bashio::config 'email_from')
EMAIL_SUBJECT_PREFIX=$(bashio::config 'email_subject_prefix')

# Generate signing key if it doesn't exist (after config is created)
generate_signing_key() {
    if [[ ! -f "${SIGNING_KEY_FILE}" ]]; then
        bashio::log.info "Generating Synapse signing key..."
        /opt/venv/bin/python -m synapse.app.homeserver \
            --server-name="${SERVER_NAME}" \
            --config-path="${CONFIG_FILE}" \
            --generate-keys
    fi
}

# Create log configuration
bashio::log.info "Creating log configuration..."
cat > "${LOG_CONFIG_FILE}" << EOF
version: 1

formatters:
  precise:
    format: '%(asctime)s - %(name)s - %(lineno)d - %(levelname)s - %(message)s'

handlers:
  console:
    class: logging.StreamHandler
    formatter: precise
    stream: ext://sys.stdout

loggers:
  synapse.storage.SQL:
    level: INFO
  synapse.http.server:
    level: INFO

root:
  level: ${LOG_LEVEL}
  handlers: [console]

disable_existing_loggers: false
EOF

# Create main configuration file
bashio::log.info "Creating Synapse homeserver configuration..."

# Build trusted key servers list
TRUSTED_KEY_SERVERS=""
readarray -t key_servers < <(bashio::config 'trusted_key_servers')
for server in "${key_servers[@]}"; do
    if [[ -n "${TRUSTED_KEY_SERVERS}" ]]; then
        TRUSTED_KEY_SERVERS="${TRUSTED_KEY_SERVERS}, "
    fi
    TRUSTED_KEY_SERVERS="${TRUSTED_KEY_SERVERS}\"${server}\": {}"
done

# Generate random secrets
MACAROON_SECRET_KEY=$(openssl rand -hex 32)
REGISTRATION_SHARED_SECRET=$(openssl rand -hex 32)
FORM_SECRET=$(openssl rand -hex 32)

# Database connection string
DB_CONNECTION="postgresql://${DATABASE_USER}:${DATABASE_PASSWORD}@${DATABASE_HOST}:${DATABASE_PORT}/${DATABASE_NAME}?cp_min=5&cp_max=10"

# Create homeserver.yaml
cat > "${CONFIG_FILE}" << EOF
# Synapse Homeserver Configuration
server_name: "${SERVER_NAME}"
pid_file: /data/homeserver.pid
web_client: false
soft_file_limit: 0
log_config: "${LOG_CONFIG_FILE}"

# Database configuration
database:
  name: psycopg2
  args:
    user: "${DATABASE_USER}"
    password: "${DATABASE_PASSWORD}"
    database: "${DATABASE_NAME}"
    host: "${DATABASE_HOST}"
    port: ${DATABASE_PORT}
    cp_min: 5
    cp_max: 10
  allow_unsafe_locale: true

# Security configuration
macaroon_secret_key: "${MACAROON_SECRET_KEY}"
registration_shared_secret: "${REGISTRATION_SHARED_SECRET}"
form_secret: "${FORM_SECRET}"

# Network configuration
listeners:
  - port: 8008
    tls: false
    type: http
    x_forwarded: true
    bind_addresses: ['0.0.0.0']
    resources:
      - names: [client, federation]
        compress: false
EOF

if bashio::var.true "${FEDERATION_ENABLED}"; then
cat >> "${CONFIG_FILE}" << EOF
  - port: 8448
    tls: false
    type: http
    x_forwarded: true
    bind_addresses: ['0.0.0.0']
    resources:
      - names: [federation]
        compress: false
EOF
fi

# Add public baseurl if configured
if bashio::var.has_value "${PUBLIC_BASEURL}"; then
cat >> "${CONFIG_FILE}" << EOF

public_baseurl: "${PUBLIC_BASEURL}"
EOF
fi

# Add server well-known if enabled
if bashio::var.true "${SERVE_SERVER_WELLKNOWN}"; then
cat >> "${CONFIG_FILE}" << EOF
serve_server_wellknown: true
EOF
fi

# Media repository configuration
if bashio::var.true "${ENABLE_MEDIA_REPO}"; then
cat >> "${CONFIG_FILE}" << EOF

# Media repository
media_store_path: "/media/synapse"
max_upload_size: "${MAX_UPLOAD_SIZE}"
max_image_pixels: "32M"
dynamic_thumbnails: false
EOF
fi

# Registration configuration
cat >> "${CONFIG_FILE}" << EOF

# Registration
enable_registration: ${REGISTRATION_ENABLED}
registration_requires_token: ${REGISTRATION_REQUIRES_TOKEN}
enable_registration_without_verification: ${ENABLE_REGISTRATION_WITHOUT_VERIFICATION}

# Security
bcrypt_rounds: 12
EOF

# Email configuration
if bashio::var.has_value "${EMAIL_SMTP_HOST}"; then
cat >> "${CONFIG_FILE}" << EOF

# Email
email:
  smtp_host: "${EMAIL_SMTP_HOST}"
  smtp_port: ${EMAIL_SMTP_PORT}
  smtp_user: "${EMAIL_SMTP_USER}"
  smtp_pass: "${EMAIL_SMTP_PASS}"
  require_transport_security: ${EMAIL_SMTP_REQUIRE_TRANSPORT_SECURITY}
  notif_from: "${EMAIL_FROM}"
  app_name: "Synapse"
  subject_prefix: "${EMAIL_SUBJECT_PREFIX}"
EOF
fi

# TURN server configuration
if bashio::var.has_value "${TURN_URI}"; then
cat >> "${CONFIG_FILE}" << EOF

# TURN server
turn_uris:
  - "${TURN_URI}"
turn_shared_secret: "${TURN_PASSWORD}"
turn_user_lifetime: 86400000
turn_allow_guests: true
EOF
fi

# Federation and presence
cat >> "${CONFIG_FILE}" << EOF

# Federation
federation_domain_whitelist: null
send_federation: ${FEDERATION_ENABLED}

# Presence
use_presence: ${PRESENCE_ENABLED}

# Metrics
enable_metrics: ${ENABLE_METRICS}

# Trusted key servers
trusted_key_servers:
  - server_name: "matrix.org"
    verify_keys:
      "ed25519:auto": "Noi6WqcDj0QmPxCNQqgezwTlBKrfqehY1u2FyWP9uYw"
EOF

# Add additional trusted key servers if configured
if [[ -n "${TRUSTED_KEY_SERVERS}" && "${TRUSTED_KEY_SERVERS}" != "\"matrix.org\": {}" ]]; then
    for server in "${key_servers[@]}"; do
        if [[ "${server}" != "matrix.org" ]]; then
cat >> "${CONFIG_FILE}" << EOF
  - server_name: "${server}"
EOF
        fi
    done
fi

cat >> "${CONFIG_FILE}" << EOF

# Signing key
signing_key_path: "${SIGNING_KEY_FILE}"

# Report stats
report_stats: ${REPORT_STATS}

# Room directory
room_list_publication_rules:
  - user_id: "*"
    alias: "*"
    room_id: "*"
    action: allow

# User directory
user_directory:
  enabled: true
  search_all_users: false
  prefer_local_users: true

# Retention
retention:
  enabled: false

# Caches
caches:
  global_factor: 0.5
  per_cache_factors:
    get_users_who_share_room_with_user: 2.0

# Worker configuration
worker_app: synapse.app.homeserver

# Additional settings
suppress_key_server_warning: true
EOF

# Generate signing key now that config file exists
generate_signing_key

# Set permissions (use root since synapse user doesn't exist in HA base image)
chown -R root:root /config/synapse
chmod 600 "${CONFIG_FILE}"
chmod 600 "${SIGNING_KEY_FILE}" 2>/dev/null || true

bashio::log.info "Synapse configuration completed!"
