#!/usr/bin/with-contenv bashio
# ==============================================================================
# Home Assistant Community Add-on: Synapse Matrix Server
# Creates admin user if configured
# ==============================================================================

ADMIN_USERNAME=$(bashio::config 'admin_username')
ADMIN_PASSWORD=$(bashio::config 'admin_password')
ADMIN_EMAIL=$(bashio::config 'admin_email')
SERVER_NAME=$(bashio::config 'server_name')

if bashio::var.has_value "${ADMIN_USERNAME}" && bashio::var.has_value "${ADMIN_PASSWORD}"; then
    bashio::log.info "Setting up admin user: ${ADMIN_USERNAME}"
    
    # Create a script to run after Synapse starts
    cat > /tmp/create_admin_user.sh << EOF
#!/bin/bash
# Wait for Synapse to be ready
while ! curl -f http://localhost:8008/_matrix/client/versions >/dev/null 2>&1; do
    echo "Waiting for Synapse to start..."
    sleep 2
done

# Create admin user (skip existence check as it requires auth)
echo "Creating admin user @${ADMIN_USERNAME}:${SERVER_NAME}..."

# Register user using registration_shared_secret
    /opt/venv/bin/python -c "
import hashlib
import hmac
import json
import requests
import sys
import yaml

# Load config to get registration shared secret
with open('/config/synapse/homeserver.yaml', 'r') as f:
    config = yaml.safe_load(f)

# Get registration shared secret from config
secret = config.get('registration_shared_secret')
if not secret:
    print('Error: registration_shared_secret not found in config')
    sys.exit(1)

# First, get a nonce
try:
    nonce_response = requests.get('http://localhost:8008/_synapse/admin/v1/register', timeout=10)
    if nonce_response.status_code != 200:
        print(f'Failed to get nonce: {nonce_response.status_code} - {nonce_response.text}')
        sys.exit(1)
    nonce = nonce_response.json()['nonce']
    print(f'Got nonce: {nonce}')
except Exception as e:
    print(f'Error getting nonce: {e}')
    sys.exit(1)

# Create admin user
username = '${ADMIN_USERNAME}'
password = '${ADMIN_PASSWORD}'
admin = True
user_type = None

mac = hmac.new(
    key=secret.encode('utf8'),
    digestmod=hashlib.sha1,
)

mac.update(nonce.encode('utf8'))
mac.update(b'\x00')
mac.update(username.encode('utf8'))
mac.update(b'\x00')
mac.update(password.encode('utf8'))
mac.update(b'\x00')
mac.update(b'admin' if admin else b'notadmin')
if user_type:
    mac.update(b'\x00')
    mac.update(user_type.encode('utf8'))

mac_str = mac.hexdigest()

data = {
    'nonce': nonce,
    'username': username,
    'password': password,
    'admin': admin,
    'mac': mac_str,
}

if user_type:
    data['user_type'] = user_type

try:
    response = requests.post(
        'http://localhost:8008/_synapse/admin/v1/register',
        json=data,
        timeout=10
    )
    if response.status_code == 200:
        print(f'Successfully created admin user: @${ADMIN_USERNAME}:${SERVER_NAME}')
    else:
        print(f'Failed to create admin user: {response.status_code} - {response.text}')
except Exception as e:
    print(f'Error creating admin user: {e}')
"
fi
EOF

    chmod +x /tmp/create_admin_user.sh
    bashio::log.info "Admin user creation script prepared"
    
    # Run the admin user creation in background
    nohup /tmp/create_admin_user.sh >/var/log/admin-user-creation.log 2>&1 &
else
    bashio::log.info "No admin user configured - skipping admin user creation"
fi
