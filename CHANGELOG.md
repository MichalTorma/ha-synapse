# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2024-09-05

### Added
- Initial release of Synapse Matrix Server Home Assistant addon
- Support for all major architectures (amd64, aarch64, armv7, armhf, i386)
- External PostgreSQL database support
- Comprehensive configuration through addon UI
- Automatic admin user creation
- Media repository support with configurable upload limits
- Federation support with configurable ports
- Email SMTP configuration
- TURN server support for VoIP calls
- Metrics support for monitoring
- Security features including registration tokens
- AppArmor security profile
- Health check monitoring
- Persistent data storage using Home Assistant volume mapping

### Technical Details
- Based on official Synapse v1.137.0
- Uses Home Assistant Python 3.11 base images
- Implements Home Assistant addon best practices
- Supports configuration via addon UI
- Logs to stdout for Home Assistant log management
- Automatic database migration support
