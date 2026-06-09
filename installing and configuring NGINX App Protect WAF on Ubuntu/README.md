# NGINX App Protect WAF Installation Guide for Ubuntu

## Complete Step-by-Step Guide from A to Z

### Table of Contents
1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [Troubleshooting](#troubleshooting)
5. [Testing](#testing)
6. [Maintenance](#maintenance)

---

## Prerequisites

### System Requirements
- Ubuntu 20.04, 22.04, or 24.04 LTS
- NGINX Plus license (JWT file)
- Root or sudo access
- Minimum 4GB RAM, 2 CPU cores
- 10GB free disk space

### Verify Your System
```bash
# Check Ubuntu version
lsb_release -a

# Check available memory
free -h

# Check disk space
df -h

# Update system
sudo apt update && sudo apt upgrade -y
```

---

## Installation

### Step 1: Install NGINX Plus

```bash
# Download NGINX Plus signing key
wget -qO - https://cs.nginx.com/static/keys/nginx_signing.key | \
  sudo gpg --dearmor | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg > /dev/null

# Add NGINX Plus repository
printf "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
https://pkgs.nginx.com/plus/ubuntu $(lsb_release -cs) nginx-plus\n" | \
sudo tee /etc/apt/sources.list.d/nginx-plus.list

# Update package list
sudo apt update

# Install NGINX Plus
sudo apt install nginx-plus -y

# Verify installation
nginx -v
```

### Step 2: Install NGINX App Protect WAF

```bash
# Add F5 WAF signing key
wget -qO - https://cs.nginx.com/static/keys/app-protect-security-updates.key | \
  gpg --dearmor | sudo tee /usr/share/keyrings/app-protect-security-updates.gpg > /dev/null

# Get Ubuntu codename
CODENAME=$(lsb_release -cs)

# Add App Protect repository
printf "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
https://pkgs.nginx.com/app-protect/ubuntu $CODENAME nginx-plus\n" | \
sudo tee /etc/apt/sources.list.d/nginx-app-protect.list

printf "deb [signed-by=/usr/share/keyrings/app-protect-security-updates.gpg] \
https://pkgs.nginx.com/app-protect-security-updates/ubuntu $CODENAME nginx-plus\n" | \
sudo tee /etc/apt/sources.list.d/app-protect-security-updates.list

# Update package list
sudo apt update

# Install App Protect packages
sudo apt install -y app-protect app-protect-common app-protect-plugin

# Verify installation
dpkg -l | grep app-protect
```

### Step 3: Install NGINX Plus License

```bash
# Copy your JWT license file to /etc/nginx/
# Replace <your-license.jwt> with your actual license file
sudo cp /path/to/your-license.jwt /etc/nginx/license.jwt

# Set proper permissions
sudo chmod 644 /etc/nginx/license.jwt
sudo chown nginx:nginx /etc/nginx/license.jwt

# Verify license
sudo cat /etc/nginx/license.jwt | head -c 100
```

---

## Configuration

### Step 4: Configure NGINX with WAF Module

```bash
# Backup original configuration
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup

# Create new nginx.conf with WAF module
sudo tee /etc/nginx/nginx.conf > /dev/null << 'EOF'
# Load App Protect WAF module
load_module modules/ngx_http_app_protect_module.so;

user nginx;
worker_processes auto;

error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # App Protect WAF Configuration
    app_protect_policy_file "/etc/app_protect/conf/NginxDefaultPolicy.json";
    app_protect_security_log_enable on;
    app_protect_security_log "/etc/app_protect/conf/log_default.json" syslog:server=127.0.0.1:515;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;
    
    sendfile on;
    keepalive_timeout 65;

    include /etc/nginx/conf.d/*.conf;
}
EOF
```

### Step 5: Configure Website with WAF Protection

```bash
# Create website directory
sudo mkdir -p /var/www/cybersecurity-portfolio

# Create sample index.html
sudo tee /var/www/cybersecurity-portfolio/index.html > /dev/null << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>WAF Protected Website</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            min-height: 100vh;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        h1 {
            text-align: center;
            font-size: 3em;
            margin-top: 50px;
        }
        .content {
            background: rgba(255,255,255,0.1);
            border-radius: 10px;
            padding: 30px;
            margin-top: 30px;
        }
        .protected {
            background: rgba(0,255,0,0.2);
            border-left: 4px solid #00ff00;
            padding: 10px;
            margin: 20px 0;
        }
        .attack-blocked {
            background: rgba(255,0,0,0.2);
            border-left: 4px solid #ff0000;
            padding: 10px;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🛡️ WAF Protected Website</h1>
        <div class="content">
            <div class="protected">
                <strong>✅ Web Application Firewall Active</strong><br>
                This website is protected by NGINX App Protect WAF
            </div>
            
            <h2>Security Features</h2>
            <ul>
                <li>SQL Injection Prevention</li>
                <li>Cross-Site Scripting (XSS) Protection</li>
                <li>OWASP Top 10 Coverage</li>
                <li>DDoS Mitigation</li>
                <li>Real-time Threat Detection</li>
            </ul>
            
            <h3>Protected Endpoints</h3>
            <ul>
                <li><code>/admin</code> - Administrative access</li>
                <li><code>/api</code> - API endpoints</li>
                <li><code>/login</code> - Authentication</li>
            </ul>
        </div>
    </div>
</body>
</html>
EOF

# Set proper permissions
sudo chown -R nginx:nginx /var/www/cybersecurity-portfolio
sudo chmod -R 755 /var/www/cybersecurity-portfolio
```

### Step 6: Create Server Block Configuration

```bash
# Create main configuration with WAF
sudo tee /etc/nginx/conf.d/default.conf > /dev/null << 'EOF'
# HTTP to HTTPS redirect
server {
    listen 80;
    server_name _;
    return 301 https://$server_name$request_uri;
}

# HTTPS server with WAF
server {
    listen 443 ssl http2;
    server_name _;

    # SSL Configuration (replace with your certificates)
    ssl_certificate /etc/nginx/ssl/selfsigned.crt;
    ssl_certificate_key /etc/nginx/ssl/selfsigned.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    # Enable WAF for this server
    app_protect_enable on;
    app_protect_policy_file "/etc/app_protect/conf/NginxDefaultPolicy.json";
    app_protect_security_log_enable on;
    app_protect_security_log "/etc/app_protect/conf/log_default.json" syslog:server=127.0.0.1:515;

    # Website root
    root /var/www/cybersecurity-portfolio;
    index index.html;

    # Main location
    location / {
        try_files $uri $uri/ =404;
    }

    # Protect admin area
    location /admin {
        app_protect_enable on;
        allow 192.168.0.0/16;
        deny all;
    }

    # Protect API endpoints
    location /api/ {
        app_protect_enable on;
        # Uncomment for proxy to backend
        # proxy_pass http://localhost:3000;
        # proxy_set_header Host $host;
        # proxy_set_header X-Real-IP $remote_addr;
    }

    # Static files caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|pdf)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
EOF
```

### Step 7: Generate Self-Signed SSL Certificate (Development Only)

```bash
# Create SSL directory
sudo mkdir -p /etc/nginx/ssl

# Generate self-signed certificate
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/selfsigned.key \
  -out /etc/nginx/ssl/selfsigned.crt \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"

# Set proper permissions
sudo chmod 600 /etc/nginx/ssl/selfsigned.key
sudo chmod 644 /etc/nginx/ssl/selfsigned.crt
```

### Step 8: Fix Module Path Issue (Important!)

```bash
# Check if module exists with debug suffix
ls -la /usr/lib/nginx/modules/ | grep app_protect

# If you see ngx_http_app_protect_module-debug.so, create symlink
if [ -f /usr/lib/nginx/modules/ngx_http_app_protect_module-debug.so ]; then
    sudo ln -sf /usr/lib/nginx/modules/ngx_http_app_protect_module-debug.so \
                /usr/lib/nginx/modules/ngx_http_app_protect_module.so
fi

# Or update nginx.conf to use debug module
sudo sed -i 's/ngx_http_app_protect_module.so/ngx_http_app_protect_module-debug.so/g' /etc/nginx/nginx.conf
```

### Step 9: Start and Verify Services

```bash
# Test configuration
sudo nginx -t

# If test passes, start NGINX
sudo systemctl start nginx
sudo systemctl enable nginx

# Check status
sudo systemctl status nginx

# Check if bd-socket-plugin is running
ps aux | grep bd-socket-plugin

# If plugin isn't running, restart NGINX
sudo systemctl restart nginx

# Check logs
sudo tail -f /var/log/nginx/error.log
```

### Step 10: Test WAF Functionality

```bash
# Create test script
sudo tee /usr/local/bin/test-waf.sh > /dev/null << 'EOF'
#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Testing WAF Protection${NC}"
echo "========================"

# Test 1: Normal request
echo -e "\n${GREEN}1. Normal Request:${NC}"
curl -s -k https://localhost/ | head -n 5

# Test 2: SQL Injection
echo -e "\n${RED}2. SQL Injection Attempt (Should be blocked):${NC}"
curl -s -k "https://localhost/?id=1' OR '1'='1"

# Test 3: XSS Attack
echo -e "\n${RED}3. XSS Attack Attempt (Should be blocked):${NC}"
curl -s -k "https://localhost/?search=<script>alert('XSS')</script>"

# Test 4: Path Traversal
echo -e "\n${RED}4. Path Traversal Attempt (Should be blocked):${NC}"
curl -s -k "https://localhost/../../../etc/passwd"

echo -e "\n${YELLOW}Check WAF logs:${NC}"
echo "sudo tail -f /var/log/app_protect/bd-socket-plugin.log"
EOF

sudo chmod +x /usr/local/bin/test-waf.sh

# Run the test
sudo /usr/local/bin/test-waf.sh
```

---

## Troubleshooting

### Common Issues and Solutions

#### Issue 1: Module not found error
```bash
# Error: cannot open shared object file: No such file or directory
# Solution:
sudo ln -sf /usr/lib/nginx/modules/ngx_http_app_protect_module-debug.so \
            /usr/lib/nginx/modules/ngx_http_app_protect_module.so
```

#### Issue 2: APP_PROTECT failed to get compilation status
```bash
# Solution 1: Restart NGINX completely
sudo systemctl stop nginx
sudo pkill -f bd-socket-plugin
sudo systemctl start nginx

# Solution 2: Check and fix permissions
sudo chown -R nginx:nginx /etc/app_protect/
sudo chmod -R 755 /etc/app_protect/

# Solution 3: Reinstall App Protect
sudo apt remove --purge app-protect app-protect-common app-protect-plugin
sudo apt install app-protect app-protect-common app-protect-plugin -y
```

#### Issue 3: bd-socket-plugin not starting
```bash
# Check if plugin exists
ls -la /usr/share/ts/bin/bd-socket-plugin

# Start manually
sudo /usr/share/ts/bin/bd-socket-plugin &

# Check for missing dependencies
ldd /usr/share/ts/bin/bd-socket-plugin

# Create systemd service (if missing)
sudo tee /etc/systemd/system/bd-socket-plugin.service > /dev/null << 'EOF'
[Unit]
Description=NGINX App Protect BD Socket Plugin
Before=nginx.service

[Service]
Type=simple
ExecStart=/usr/share/ts/bin/bd-socket-plugin
Restart=always
User=nginx
Group=nginx

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable bd-socket-plugin
sudo systemctl start bd-socket-plugin
```

#### Issue 4: Policy file not found
```bash
# Check if policy exists
ls -la /etc/app_protect/conf/

# If missing, reinstall
sudo apt install --reinstall app-protect-common

# Or download default policy
sudo cp /opt/app-protect/examples/NginxDefaultPolicy.json /etc/app_protect/conf/
```

### Debug Commands

```bash
# Check all logs
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/app_protect/bd-socket-plugin.log

# Check process status
ps aux | grep -E "nginx|bd-socket"

# Test configuration
sudo nginx -t

# Check module dependencies
ldd /usr/lib/nginx/modules/ngx_http_app_protect_module*.so

# Check App Protect version
dpkg -l | grep app-protect
```

---

## Testing

### WAF Attack Simulation Tests

```bash
# Create comprehensive test suite
sudo tee /usr/local/bin/waf-attack-test.sh > /dev/null << 'EOF'
#!/bin/bash

BASE_URL="https://localhost"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}WAF Attack Simulation Test Suite${NC}"
echo "================================="

tests=(
    "SQL Injection|/?id=1' OR '1'='1"
    "XSS Attack|/?search=<script>alert(1)</script>"
    "Path Traversal|/../../../etc/passwd"
    "Command Injection|/?cmd=cat%20/etc/passwd"
    "XXE Attack|/?xml=<!DOCTYPE%20foo%20[<!ENTITY%20xxe%20SYSTEM%20\"file:///etc/passwd\">]>"
)

for test in "${tests[@]}"; do
    IFS='|' read -r name payload <<< "$test"
    echo -e "\n${YELLOW}Testing: ${name}${NC}"
    echo "Payload: $payload"
    
    response=$(curl -s -k -o /dev/null -w "%{http_code}" "${BASE_URL}${payload}")
    
    if [ "$response" = "403" ] || [ "$response" = "406" ]; then
        echo -e "${GREEN}✓ Blocked (HTTP $response)${NC}"
    else
        echo -e "${RED}✗ Not blocked (HTTP $response)${NC}"
    fi
done

echo -e "\n${YELLOW}Check WAF logs for detailed information${NC}"
EOF

sudo chmod +x /usr/local/bin/waf-attack-test.sh
sudo /usr/local/bin/waf-attack-test.sh
```

### Performance Testing

```bash
# Install Apache Bench if not installed
sudo apt install apache2-utils -y

# Test normal traffic
ab -n 1000 -c 10 -k https://localhost/

# Test with attack patterns
ab -n 100 -c 5 -k "https://localhost/?id=1' OR '1'='1"
```

---

## Maintenance

### Regular Updates

```bash
# Update attack signatures
sudo apt update
sudo apt upgrade app-protect-attack-signatures

# Update App Protect
sudo apt update
sudo apt upgrade app-protect app-protect-common

# Reload NGINX after updates
sudo nginx -s reload
```

### Log Rotation Configuration

```bash
# Configure log rotation for WAF logs
sudo tee /etc/logrotate.d/app-protect > /dev/null << 'EOF'
/var/log/app_protect/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0640 nginx nginx
    sharedscripts
    postrotate
        systemctl reload nginx > /dev/null 2>&1 || true
    endscript
}
EOF
```

### Monitoring Script

```bash
# Create monitoring script
sudo tee /usr/local/bin/waf-monitor.sh > /dev/null << 'EOF'
#!/bin/bash

# Check WAF status
if ps aux | grep -v grep | grep bd-socket-plugin > /dev/null; then
    echo "✅ WAF Plugin: Running"
else
    echo "❌ WAF Plugin: Not Running"
fi

# Check NGINX status
if systemctl is-active --quiet nginx; then
    echo "✅ NGINX: Running"
else
    echo "❌ NGINX: Not Running"
fi

# Check recent attacks
echo -e "\nRecent attacks (last 24 hours):"
grep -i "attack" /var/log/app_protect/bd-socket-plugin.log 2>/dev/null | tail -5

# Check WAF blocks
echo -e "\nWAF blocks today:"
grep -c "blocked" /var/log/app_protect/bd-socket-plugin.log 2>/dev/null || echo "0"
EOF

sudo chmod +x /usr/local/bin/waf-monitor.sh

# Run monitor
sudo /usr/local/bin/waf-monitor.sh
```

### Backup Configuration

```bash
# Create backup script
sudo tee /usr/local/bin/backup-waf-config.sh > /dev/null << 'EOF'
#!/bin/bash
BACKUP_DIR="/backup/waf/$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR

# Backup configurations
cp -r /etc/nginx $BACKUP_DIR/
cp -r /etc/app_protect $BACKUP_DIR/

# Backup logs
cp -r /var/log/nginx $BACKUP_DIR/
cp -r /var/log/app_protect $BACKUP_DIR/

# Compress backup
tar -czf ${BACKUP_DIR}.tar.gz $BACKUP_DIR/
rm -rf $BACKUP_DIR

echo "Backup saved to: ${BACKUP_DIR}.tar.gz"
EOF

sudo chmod +x /usr/local/bin/backup-waf-config.sh
```

---

## Security Best Practices

### 1. Production SSL Configuration
```bash
# Use Let's Encrypt for production SSL
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d yourdomain.com
```

### 2. Custom WAF Policy
```bash
# Copy default policy for customization
sudo cp /etc/app_protect/conf/NginxDefaultPolicy.json /etc/app_protect/conf/custom-policy.json

# Edit custom policy
sudo nano /etc/app_protect/conf/custom-policy.json

# Update nginx.conf to use custom policy
sudo sed -i 's/NginxDefaultPolicy.json/custom-policy.json/g' /etc/nginx/nginx.conf
```

### 3. Rate Limiting with WAF
```bash
# Add rate limiting to nginx.conf
sudo tee -a /etc/nginx/nginx.conf > /dev/null << 'EOF'
    # Rate limiting zones
    limit_req_zone $binary_remote_addr zone=waf_limit:10m rate=10r/s;
    limit_conn_zone $binary_remote_addr zone=conn_limit:10m;
EOF

# Apply in server block
sudo sed -i '/app_protect_enable on;/a \    limit_req zone=waf_limit burst=20 nodelay;\n    limit_conn conn_limit 10;' /etc/nginx/conf.d/default.conf
```

---

## Verification Checklist

- [ ] NGINX Plus installed and running
- [ ] App Protect packages installed
- [ ] License file in correct location
- [ ] Module loaded successfully
- [ ] bd-socket-plugin running
- [ ] WAF policy compiled without errors
- [ ] Attack signatures updated
- [ ] SSL certificates configured
- [ ] WAF blocks malicious requests
- [ ] Logs showing WAF activity

---

## Support and Resources

- [NGINX App Protect Documentation](https://docs.nginx.com/nginx-app-protect/)
- [F5 Support Portal](https://support.f5.com/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [NGINX Plus Admin Guide](https://docs.nginx.com/nginx/admin-guide/)

---

## Quick Reference Commands

```bash
# Start/Stop/Reload
sudo systemctl start nginx
sudo systemctl stop nginx
sudo systemctl restart nginx
sudo nginx -s reload

# Check Status
sudo systemctl status nginx
sudo nginx -t
ps aux | grep nginx

# View Logs
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/app_protect/bd-socket-plugin.log

# Update Signatures
sudo apt update && sudo apt upgrade app-protect-attack-signatures

# Test WAF
curl -k "https://localhost/?id=1' OR '1'='1"
curl -k "https://localhost/?search=<script>alert(1)</script>"
```

---

**Note**: This configuration is for educational and testing purposes. For production environments, ensure proper SSL certificates, custom WAF policies, and security hardening based on your specific requirements.
```

This comprehensive README covers everything from initial installation to production deployment, including troubleshooting common issues and maintaining the WAF configuration.
