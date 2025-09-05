#!/usr/bin/with-contenv bashio
# ==============================================================================
# Home Assistant Community Add-on: Synapse Matrix Server
# Creates registration tokens if configured
# ==============================================================================

# Get configuration - use a different approach for arrays
tokens=()
if bashio::config.exists 'registration_tokens'; then
    # Get the array length
    token_count=$(bashio::config 'registration_tokens | length')
    # Read each token by index
    for ((i=0; i<token_count; i++)); do
        token=$(bashio::config "registration_tokens[$i]")
        if [[ -n "$token" ]]; then
            tokens+=("$token")
        fi
    done
fi
ADMIN_USERNAME=$(bashio::config 'admin_username')
ADMIN_PASSWORD=$(bashio::config 'admin_password')
SERVER_NAME=$(bashio::config 'server_name')

# Debug logging
bashio::log.info "Debug: Registration tokens config exists: $(bashio::config.exists 'registration_tokens' && echo "yes" || echo "no")"
if bashio::config.exists 'registration_tokens'; then
    bashio::log.info "Debug: Token count from config: $(bashio::config 'registration_tokens | length')"
fi
bashio::log.info "Debug: Found ${#tokens[@]} registration tokens"
for token in "${tokens[@]}"; do
    bashio::log.info "Debug: Token: ${token:0:8}..."
done
bashio::log.info "Debug: Admin username: ${ADMIN_USERNAME}"
bashio::log.info "Debug: Admin password configured: $(bashio::var.has_value "${ADMIN_PASSWORD}" && echo "yes" || echo "no")"

if [[ ${#tokens[@]} -gt 0 ]] && bashio::var.has_value "${ADMIN_USERNAME}" && bashio::var.has_value "${ADMIN_PASSWORD}"; then
    bashio::log.info "Creating registration tokens..."
    
    # Create a script to run after Synapse starts
    cat > /tmp/create_registration_tokens.sh << EOF
#!/bin/bash
# Wait for Synapse to be ready
while ! curl -f http://localhost:8008/_matrix/client/versions >/dev/null 2>&1; do
    echo "Waiting for Synapse to start..."
    sleep 2
done

echo "Getting admin access token..."

# Get admin access token
ACCESS_TOKEN=\$(curl -s -X POST "http://localhost:8008/_matrix/client/v3/login" \\
  -H "Content-Type: application/json" \\
  -d '{
    "type": "m.login.password",
    "user": "${ADMIN_USERNAME}",
    "password": "${ADMIN_PASSWORD}"
  }' | python3 -c "import sys, json; print(json.load(sys.stdin).get('access_token', ''))" 2>/dev/null)

if [[ -z "\$ACCESS_TOKEN" ]]; then
    echo "Failed to get admin access token"
    exit 1
fi

echo "Creating registration tokens..."

EOF

    # Add token creation commands for each configured token
    for token in "${tokens[@]}"; do
        if [[ -n "${token}" ]]; then
            cat >> /tmp/create_registration_tokens.sh << EOF

# Create token: ${token}
echo "Creating registration token: ${token}"
RESULT=\$(curl -s -X POST "http://localhost:8008/_synapse/admin/v1/registration_tokens/new" \\
  -H "Authorization: Bearer \$ACCESS_TOKEN" \\
  -H "Content-Type: application/json" \\
  -d '{
    "token": "${token}",
    "uses_allowed": null,
    "expiry_time": null
  }')

if echo "\$RESULT" | grep -q '"token"'; then
    echo "Successfully created registration token: ${token}"
else
    echo "Failed to create token ${token}: \$RESULT"
fi

EOF
        fi
    done

    cat >> /tmp/create_registration_tokens.sh << 'EOF'

echo "Registration token creation completed"
EOF

    chmod +x /tmp/create_registration_tokens.sh
    bashio::log.info "Registration token creation script prepared"
    
    # Run the token creation in background
    nohup /tmp/create_registration_tokens.sh >/var/log/registration-tokens.log 2>&1 &
else
    bashio::log.info "No registration tokens configured or admin credentials missing - skipping token creation"
fi
