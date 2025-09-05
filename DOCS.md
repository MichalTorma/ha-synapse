# Home Assistant Add-on: Synapse Matrix Server Documentation

## Table of Contents

1. [Installation](#installation)
2. [Configuration](#configuration)
3. [Advanced Configuration](#advanced-configuration)
4. [Federation Setup](#federation-setup)
5. [Email Configuration](#email-configuration)
6. [TURN Server Configuration](#turn-server-configuration)
7. [Security](#security)
8. [Monitoring](#monitoring)
9. [Troubleshooting](#troubleshooting)

## Installation

### Prerequisites

1. **PostgreSQL Database**: This add-on requires a PostgreSQL database. Install the official PostgreSQL add-on first.

2. **Domain Name**: For federation and proper client access, you should have a domain name pointing to your Home Assistant instance.

### Step-by-Step Installation

1. **Install PostgreSQL Add-on**:
   ```yaml
   databases:
     - synapse
   logins:
     - username: synapse
       password: your_secure_password
   rights:
     - username: synapse
       database: synapse
   ```

2. **Install Synapse Add-on**: Add this repository and install the Synapse add-on.

3. **Configure**: See the configuration section below.

4. **Start**: Start the add-on and monitor the logs.

## Configuration

### Basic Configuration

```yaml
server_name: "matrix.example.com"
database_host: "core-postgres"
database_port: 5432
database_name: "synapse"
database_user: "synapse"
database_password: "your_secure_password"
admin_username: "admin"
admin_password: "your_admin_password"
```

### Security Configuration

```yaml
registration_enabled: false
registration_requires_token: true
enable_registration_without_verification: false
```

### Federation Configuration

```yaml
federation_enabled: true
public_baseurl: "https://matrix.example.com"
serve_server_wellknown: true
```

## Advanced Configuration

### Media Repository

Control file uploads and media handling:

```yaml
enable_media_repo: true
max_upload_size: "100M"  # Maximum file size
```

Media files are stored in `/media/synapse` which is mapped to the Home Assistant `media` directory.

### Logging

```yaml
log_level: "INFO"  # DEBUG, INFO, WARNING, ERROR, CRITICAL
```

Logs are sent to stdout and handled by Home Assistant's logging system.

### Presence and Performance

```yaml
presence_enabled: true  # Show online/offline status
enable_metrics: true    # Prometheus metrics on /_synapse/metrics
```

### Trusted Key Servers

Configure which servers to trust for key verification:

```yaml
trusted_key_servers:
  - "matrix.org"
  - "example.com"
```

## Federation Setup

Federation allows your Matrix server to communicate with other Matrix servers across the internet.

### Requirements

1. **Public Domain**: Your server must be accessible via a public domain name
2. **SSL/TLS**: HTTPS must be properly configured
3. **Port Access**: Port 8448 must be accessible from the internet
4. **DNS Configuration**: Proper SRV records (optional but recommended)

### DNS Configuration

For federation auto-discovery, add these DNS records:

```
_matrix._tcp.example.com. 3600 IN SRV 10 0 8448 matrix.example.com.
```

Or serve a well-known file by setting `serve_server_wellknown: true`.

### Reverse Proxy Configuration

Example Nginx configuration for federation:

```nginx
# Client-Server API
location /_matrix {
    proxy_pass http://homeassistant:8008;
    proxy_set_header X-Forwarded-For $remote_addr;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header Host $host;
    proxy_read_timeout 300s;
}

# Server-Server API (Federation)
server {
    listen 8448 ssl http2;
    server_name matrix.example.com;
    
    # SSL configuration
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://homeassistant:8448;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Host $host;
    }
}

# Well-known delegation (if not using serve_server_wellknown)
location /.well-known/matrix/server {
    return 200 '{"m.server": "matrix.example.com:8448"}';
    add_header Content-Type application/json;
}
```

## Email Configuration

Configure SMTP for email notifications:

```yaml
email_smtp_host: "smtp.gmail.com"
email_smtp_port: 587
email_smtp_user: "your-email@gmail.com"
email_smtp_pass: "your-app-password"
email_smtp_require_transport_security: true
email_from: "matrix@example.com"
email_subject_prefix: "[Matrix] "
```

### Gmail Configuration

For Gmail, you'll need to:
1. Enable 2-factor authentication
2. Generate an app-specific password
3. Use these settings:
   - Host: `smtp.gmail.com`
   - Port: `587`
   - Security: `true`

## TURN Server Configuration

For VoIP and video calls, configure a TURN server:

```yaml
turn_uri: "turn:turn.example.com:3478"
turn_username: "your-turn-username"
turn_password: "your-turn-password"
```

### Setting up Coturn

You can use the Coturn add-on or set up an external TURN server:

```yaml
# Example Coturn configuration
turn_uri: "turn:homeassistant:3478"
turn_username: "matrix"
turn_password: "shared-secret"
```

## Security

### Registration Security

For production servers, disable open registration:

```yaml
registration_enabled: false
registration_requires_token: true
enable_registration_without_verification: false
```

Create users via:
1. Admin interface
2. Registration tokens
3. Command line tools

### Admin User Security

The admin user has full control over the server:

```yaml
admin_username: "admin"
admin_password: "very-secure-password-here"
admin_email: "admin@example.com"
```

### Network Security

- Use strong passwords
- Enable HTTPS with valid certificates
- Consider fail2ban for brute force protection
- Regularly update the add-on
- Monitor logs for suspicious activity

### AppArmor

The add-on includes an AppArmor profile for additional security. This restricts the container's access to the host system.

## Monitoring

### Metrics

Enable Prometheus metrics:

```yaml
enable_metrics: true
```

Metrics are available at `/_synapse/metrics` (admin access required).

### Health Check

The add-on includes a health check that monitors:
- HTTP endpoint availability
- Database connectivity
- Service responsiveness

### Logging

Monitor these log patterns:
- Database connection issues
- Federation errors
- High memory usage warnings
- Authentication failures

## Troubleshooting

### Common Issues

#### Database Connection Failed

**Symptoms**: Add-on fails to start with database connection errors.

**Solutions**:
1. Verify PostgreSQL add-on is running
2. Check database credentials
3. Ensure database and user exist
4. Test connection manually

#### Memory Issues

**Symptoms**: Add-on crashes or becomes unresponsive.

**Solutions**:
1. Increase Home Assistant memory allocation
2. Adjust Synapse cache settings
3. Monitor resource usage
4. Consider server upgrade

#### Federation Issues

**Symptoms**: Cannot communicate with other Matrix servers.

**Solutions**:
1. Check port 8448 accessibility
2. Verify DNS configuration
3. Test SSL certificate validity
4. Check firewall settings

#### Client Connection Issues

**Symptoms**: Matrix clients cannot connect.

**Solutions**:
1. Verify reverse proxy configuration
2. Check SSL/TLS setup
3. Confirm port 8008 accessibility
4. Test with curl or browser

### Log Analysis

#### Database Logs
```
ERROR - Failed to connect to database
INFO - Database connection established
WARNING - Database connection lost
```

#### Federation Logs
```
INFO - Federation sender started
ERROR - Failed to send transaction to server
WARNING - Federation lag detected
```

#### Authentication Logs
```
INFO - User @user:domain logged in
WARNING - Failed login attempt from IP
ERROR - Invalid access token
```

### Performance Tuning

#### Database Optimization

For PostgreSQL, consider:
- Increase `shared_buffers`
- Tune `work_mem`
- Enable connection pooling
- Regular VACUUM operations

#### Cache Settings

Synapse cache settings in homeserver.yaml:
```yaml
caches:
  global_factor: 0.5
  per_cache_factors:
    get_users_who_share_room_with_user: 2.0
```

### Getting Help

1. **Check Logs**: Always start with the add-on logs
2. **Test Components**: Verify database, network, and certificates
3. **Community**: Join #synapse:matrix.org for help
4. **Documentation**: Check [Synapse docs](https://element-hq.github.io/synapse/)
5. **Issues**: Report add-on specific issues on GitHub

### Backup and Recovery

#### Configuration Backup
Configuration is stored in `/config/synapse/` - ensure this is included in Home Assistant backups.

#### Database Backup
Use PostgreSQL backup tools:
```bash
pg_dump -h core-postgres -U synapse synapse > synapse_backup.sql
```

#### Media Backup
Media files in `/media/synapse/` should be backed up separately due to size.

### Migration

To migrate from another Synapse installation:

1. **Database**: Import your existing PostgreSQL database
2. **Signing Keys**: Copy signing keys to `/config/synapse/keys/`
3. **Media**: Copy media store to `/media/synapse/`
4. **Configuration**: Adapt your configuration to the add-on format

### Updates

The add-on will be updated with new Synapse releases. To update:

1. **Backup**: Always backup before updating
2. **Update**: Use Home Assistant's add-on update feature
3. **Check Logs**: Monitor logs after update
4. **Test**: Verify functionality after update

Remember that Synapse database migrations can take time on large instances.
