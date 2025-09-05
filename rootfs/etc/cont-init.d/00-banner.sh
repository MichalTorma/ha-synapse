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
bashio::log.info " Synapse version: v$(/opt/venv/bin/python -c 'import synapse; print(synapse.__version__)')"
bashio::log.info "-----------------------------------------------------------"
bashio::log.info ""
