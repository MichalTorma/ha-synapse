# Home Assistant Add-on: Synapse Matrix Server

![Supports aarch64 Architecture][aarch64-shield] ![Supports amd64 Architecture][amd64-shield] ![Supports armhf Architecture][armhf-shield] ![Supports armv7 Architecture][armv7-shield] ![Supports i386 Architecture][i386-shield]

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armhf-shield]: https://img.shields.io/badge/armhf-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
[i386-shield]: https://img.shields.io/badge/i386-yes-green.svg

## About

This add-on provides a [Synapse Matrix Server](https://github.com/element-hq/synapse) for Home Assistant. Synapse is the reference homeserver implementation of the Matrix protocol, written in Python/Twisted with performance-critical modules implemented in Rust.

Matrix is an open standard for interoperable, decentralized, real-time communication over IP. It can be used to power Instant Messaging, VoIP/WebRTC signaling, Internet of Things communication, and anything else that needs a standard HTTP API for publishing and subscribing to data whilst tracking the conversation history.

## Features

- 🏠 **Matrix Homeserver**: Full-featured Matrix homeserver implementation
- 🔒 **Secure**: AppArmor security profile and secure defaults
- 🗄️ **PostgreSQL Support**: External PostgreSQL database support
- 📁 **Persistent Storage**: Automatic data persistence using Home Assistant volumes
- 🌍 **Federation**: Optional federation with other Matrix servers
- 📧 **Email**: SMTP email notifications support
- 📞 **VoIP**: TURN server support for voice and video calls
- 📊 **Monitoring**: Optional Prometheus metrics
- 👤 **Admin User**: Automatic admin user creation
- 🎛️ **Configurable**: Extensive configuration through Home Assistant UI

## Installation

1. Add this repository to your Home Assistant Add-on Store
2. Install the "Synapse Matrix Server" add-on
3. Configure the add-on (see configuration section below)
4. Start the add-on

## Prerequisites

### PostgreSQL Database

This add-on requires a PostgreSQL database. We recommend using the official PostgreSQL add-on:

1. Install the "PostgreSQL" add-on from the Official Add-ons repository
2. Configure the PostgreSQL add-on with:
   ```yaml
   databases:
     - synapse
   logins:
     - username: synapse
       password: YOUR_SECURE_PASSWORD
   rights:
     - username: synapse
       database: synapse
   ```
3. Start the PostgreSQL add-on
4. Use these database settings in the Synapse configuration:
   - Database Host: `core-postgres`
   - Database Port: `5432`
   - Database Name: `synapse`
   - Database User: `synapse`
   - Database Password: `YOUR_SECURE_PASSWORD`

## Configuration

### Required Configuration

The following settings **must** be configured before starting the add-on:

- **Server Name**: The domain name of your Matrix homeserver (e.g., `matrix.example.com`)
- **Database Password**: Password for the PostgreSQL database connection
- **Admin Username**: Username for the initial admin user
- **Admin Password**: Password for the initial admin user

### Example Configuration

```yaml
server_name: "matrix.example.com"
database_host: "core-postgres"
database_port: 5432
database_name: "synapse"
database_user: "synapse"
database_password: "your_secure_database_password"
registration_enabled: false
registration_requires_token: true
admin_username: "admin"
admin_password: "your_secure_admin_password"
admin_email: "admin@example.com"
public_baseurl: "https://matrix.example.com"
federation_enabled: true
```

### Network Configuration

The add-on exposes two ports:
- **8008**: Matrix Client-Server API (required)
- **8448**: Matrix Server-Server API for federation (optional, only if federation is enabled)

### Reverse Proxy Setup

For production use, it's recommended to use a reverse proxy (like Nginx Proxy Manager) in front of Synapse. Configure your reverse proxy to:

1. Forward requests to port 8008 for the Client-Server API
2. Forward requests to port 8448 for federation (if enabled)
3. Set proper headers for client IP forwarding

Example Nginx configuration:
```nginx
location /_matrix {
    proxy_pass http://homeassistant:8008;
    proxy_set_header X-Forwarded-For $remote_addr;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header Host $host;
}

# For federation (if enabled)
location /.well-known/matrix/server {
    proxy_pass http://homeassistant:8008;
    proxy_set_header X-Forwarded-For $remote_addr;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header Host $host;
}
```

## Usage

### Accessing Your Matrix Server

Once the add-on is running and configured:

1. **Web Client**: Access via a Matrix client like [Element Web](https://app.element.io)
2. **Server URL**: Use `https://your-domain.com` (or `http://homeassistant:8008` for local access)
3. **Login**: Use the admin credentials you configured

### Creating Additional Users

#### Option 1: Enable Registration
Set `registration_enabled: true` in the configuration (not recommended for public servers).

#### Option 2: Admin Registration
Use the admin interface or registration tokens to create users securely.

#### Option 3: Command Line
Access the add-on container and use Synapse's admin tools:
```bash
# Create a new user
python3 -m synapse.app.homeserver \
  --config-path /config/synapse/homeserver.yaml \
  --generate-missing-configs \
  register_new_matrix_user
```

### Federation

To enable federation with other Matrix servers:

1. Set `federation_enabled: true`
2. Ensure port 8448 is accessible from the internet
3. Configure proper DNS records for your domain
4. Set up SSL/TLS certificates
5. Optionally set `serve_server_wellknown: true` for auto-discovery

## Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `server_name` | string | `homeassistant.local` | Domain name of the homeserver |
| `database_host` | string | `core-postgres` | PostgreSQL hostname |
| `database_port` | int | `5432` | PostgreSQL port |
| `database_name` | string | `synapse` | PostgreSQL database name |
| `database_user` | string | `synapse` | PostgreSQL username |
| `database_password` | string | | PostgreSQL password (required) |
| `registration_enabled` | bool | `false` | Allow new user registration |
| `registration_requires_token` | bool | `true` | Require tokens for registration |
| `admin_username` | string | `admin` | Initial admin username |
| `admin_password` | string | | Initial admin password (required) |
| `admin_email` | string | | Admin email address |
| `federation_enabled` | bool | `true` | Enable federation |
| `public_baseurl` | string | | Public URL for the homeserver |
| `max_upload_size` | string | `50M` | Maximum file upload size |

See the [full configuration documentation](DOCS.md) for all available options.

## Troubleshooting

### Common Issues

**Database Connection Failed**
- Ensure PostgreSQL add-on is running
- Verify database credentials in configuration
- Check that the database and user exist

**Federation Not Working**
- Verify port 8448 is accessible from the internet
- Check DNS configuration for your domain
- Ensure SSL certificates are properly configured

**High Memory Usage**
- Synapse can be memory-intensive with large rooms
- Consider adjusting cache settings in the configuration
- Monitor resource usage in Home Assistant

### Logs

Check the add-on logs in Home Assistant for detailed error messages and debugging information.

### Getting Help

- [Matrix Community](https://matrix.to/#/#synapse:matrix.org)
- [Synapse Documentation](https://element-hq.github.io/synapse/)
- [Home Assistant Community](https://community.home-assistant.io/)

## Security Considerations

- **Use strong passwords** for admin accounts and database
- **Enable registration tokens** instead of open registration
- **Use HTTPS** with valid SSL certificates for production
- **Regularly update** the add-on to get security fixes
- **Monitor logs** for suspicious activity
- **Consider rate limiting** at the reverse proxy level

## Support

This add-on is provided as-is. For issues related to:
- **Synapse functionality**: Check [Synapse documentation](https://element-hq.github.io/synapse/)
- **Add-on specific issues**: Open an issue in this repository
- **Home Assistant integration**: Visit the [Home Assistant Community](https://community.home-assistant.io/)

## License

This add-on is licensed under the AGPL-3.0 license, same as Synapse.

The Synapse Matrix Server is developed by Element (formerly New Vector) and the Matrix.org Foundation.
