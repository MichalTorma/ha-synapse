#!/usr/bin/with-contenv bashio
# ==============================================================================
# Home Assistant Community Add-on: Synapse Matrix Server
# Displays a banner on startup
# ==============================================================================

bashio::log.info ""
bashio::log.info "-----------------------------------------------------------"
bashio::log.info " Add-on: Synapse Matrix Server"
bashio::log.info " Matrix homeserver written in Python/Twisted + Rust"
bashio::log.info "-----------------------------------------------------------"
bashio::log.info " Add-on version: $(bashio::addon.version)"

# Check if virtual environment exists and Synapse is accessible
if [[ -f "/opt/venv/bin/python" ]]; then
    bashio::log.info " Virtual environment: OK"
    if /opt/venv/bin/python -c 'import synapse' 2>/dev/null; then
        bashio::log.info " Synapse version: v$(/opt/venv/bin/python -c 'import synapse; print(synapse.__version__)')"
    else
        bashio::log.warning " Synapse installation: FAILED to import"
    fi
else
    bashio::log.error " Virtual environment: NOT FOUND"
fi

bashio::log.info "-----------------------------------------------------------"
bashio::log.info ""
