# NGINX App Protect WAF Installation Guide for Ubuntu

## Complete Step-by-Step Guide from A to Z

### Table of Contents
1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [Creating and Managing WAF Policies](#creating-and-managing-waf-policies)
5. [Troubleshooting](#troubleshooting)
6. [Testing](#testing)
7. [Maintenance](#maintenance)

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

---

## Creating and Managing WAF Policies

### Understanding WAF Policy Basics

NGINX App Protect uses JSON files to define security policies. The WAF comes with two pre-built reference policies:

| Policy | Description | Blocking Mode Path | Transparent Mode Path |
|--------|-------------|-------------------|----------------------|
| **Default** | OWASP Top 10 protection with minimal false positives | `/etc/app_protect/conf/NginxDefaultPolicy.json` | `/etc/app_protect/conf/NginxDefaultPolicy_transparent.json` |
| **Strict** | More restrictive, higher security with possible false positives | `/etc/app_protect/conf/NginxStrictPolicy.json` | `/etc/app_protect/conf/NginxStrictPolicy_transparent.json` |

### Step 1: Start with an Existing Policy

The easiest way to create a custom policy is to copy and modify an existing one:

```bash
# Copy the default policy as your starting template
sudo cp /etc/app_protect/conf/NginxDefaultPolicy.json /etc/app_protect/conf/my-custom-policy.json

# Set proper permissions
sudo chown nginx:nginx /etc/app_protect/conf/my-custom-policy.json
sudo chmod 644 /etc/app_protect/conf/my-custom-policy.json
```

### Step 2: Understand the Policy Structure

A basic policy JSON looks like this:

```json
{
    "policy": {
        "name": "my_custom_policy",
        "template": { "name": "POLICY_TEMPLATE_NGINX_BASE" },
        "applicationLanguage": "utf-8",
        "enforcementMode": "blocking"
    }
}
```

**Key fields explained:**

| Field | Description | Options |
|-------|-------------|---------|
| `name` | Unique identifier for your policy | Any string (no spaces recommended) |
| `template` | Base security template | `POLICY_TEMPLATE_NGINX_BASE` |
| `applicationLanguage` | Character encoding | `utf-8`, `iso-8859-1`, etc. |
| `enforcementMode` | How the WAF responds | `blocking` (blocks attacks) or `transparent` (alarms only) |

### Step 3: Customize Protection Features

Here are the main security features you can configure:

#### 1. **Enforcement by Violation Rating** (Default Behavior)
By default, the policy blocks requests with a violation rating of 4-5 (threats):
```json
{
    "policy": {
        "name": "my_custom_policy",
        "template": { "name": "POLICY_TEMPLATE_NGINX_BASE" },
        "applicationLanguage": "utf-8",
        "enforcementMode": "blocking",
        "blocking-settings": {
            "violations": [
                {
                    "name": "VIOL_RATING_THREAT",
                    "alarm": true,
                    "block": true
                }
            ]
        }
    }
}
```

#### 2. **Data Guard** (Mask Credit Cards & SSNs)
Enable protection for sensitive data in responses:
```json
{
    "policy": {
        "name": "my_custom_policy",
        "template": { "name": "POLICY_TEMPLATE_NGINX_BASE" },
        "data-guard": {
            "enabled": true,
            "maskData": true,
            "creditCardNumbers": true,
            "usSocialSecurityNumbers": true
        }
    }
}
```

#### 3. **Allow/Deny IP Lists**
Restrict access by IP address:
```json
{
    "policy": {
        "name": "my_custom_policy",
        "template": { "name": "POLICY_TEMPLATE_NGINX_BASE" },
        "ip-address-lists": {
            "ip-addresses": [
                {
                    "ipAddress": "192.168.1.0/24",
                    "block": false
                },
                {
                    "ipAddress": "10.0.0.5",
                    "block": true
                }
            ]
        }
    }
}
```

#### 4. **Allowed HTTP Methods**
Restrict which HTTP methods are permitted:
```json
{
    "policy": {
        "name": "my_custom_policy",
        "template": { "name": "POLICY_TEMPLATE_NGINX_BASE" },
        "methods": {
            "allowed-methods": [
                "GET",
                "POST",
                "PUT",
                "DELETE"
            ]
        }
    }
}
```

#### 5. **Request Size Limits**
Block overly large requests:
```json
{
    "policy": {
        "name": "my_custom_policy",
        "template": { "name": "POLICY_TEMPLATE_NGINX_BASE" },
        "request-length": {
            "max-length": 10240,
            "check-length": true
        }
    }
}
```

#### 6. **File Upload Restrictions**
Control file uploads by type and size:
```json
{
    "policy": {
        "name": "my_custom_policy",
        "template": { "name": "POLICY_TEMPLATE_NGINX_BASE" },
        "file-upload-policy": {
            "maximum-file-size": 1048576,
            "allowed-extensions": [
                "jpg", "jpeg", "png", "gif", "pdf", "txt"
            ],
            "disallowed-extensions": [
                "exe", "bat", "sh", "php", "jsp"
            ]
        }
    }
}
```

#### 7. **Parameter Validation**
Validate specific parameters in requests:
```json
{
    "policy": {
        "name": "my_custom_policy",
        "template": { "name": "POLICY_TEMPLATE_NGINX_BASE" },
        "parameters": [
            {
                "name": "email",
                "type": "email",
                "required": true,
                "maxLength": 255,
                "allowEmpty": false
            },
            {
                "name": "age",
                "type": "integer",
                "minValue": 0,
                "maxValue": 120
            }
        ]
    }
}
```

#### 8. **URL Protection**
Define allowed URL patterns:
```json
{
    "policy": {
        "name": "my_custom_policy",
        "template": { "name": "POLICY_TEMPLATE_NGINX_BASE" },
        "urls": [
            {
                "name": "homepage",
                "method": "GET",
                "protocol": "https",
                "host": "www.example.com",
                "path": "/",
                "performStoring": true
            },
            {
                "name": "login",
                "method": "POST",
                "path": "/login",
                "performStoring": true,
                "description": "Login endpoint"
            }
        ]
    }
}
```

### Step 4: Complete Policy Example

Here's a comprehensive custom policy that combines multiple security features:

```json
{
    "policy": {
        "name": "production_waf_policy",
        "description": "Production WAF policy with enhanced security",
        "template": { "name": "POLICY_TEMPLATE_NGINX_BASE" },
        "applicationLanguage": "utf-8",
        "enforcementMode": "blocking",
        
        "blocking-settings": {
            "violations": [
                {
                    "name": "VIOL_RATING_THREAT",
                    "alarm": true,
                    "block": true
                },
                {
                    "name": "VIOL_RATING_NEED_EXAMINATION",
                    "alarm": true,
                    "block": false
                },
                {
                    "name": "VIOR_JSON_MALFORMED",
                    "alarm": true,
                    "block": true
                },
                {
                    "name": "VIOR_GRAPHQL_MALFORMED", 
                    "alarm": true,
                    "block": true
                }
            ]
        },
        
        "data-guard": {
            "enabled": true,
            "maskData": true,
            "creditCardNumbers": true,
            "usSocialSecurityNumbers": true,
            "usBankAccountNumbers": true
        },
        
        "methods": {
            "allowed-methods": [
                "GET",
                "POST",
                "PUT",
                "DELETE",
                "HEAD",
                "PATCH"
            ]
        },
        
        "request-length": {
            "max-length": 10485760,
            "check-length": true,
            "check-url-length": true,
            "check-header-length": true,
            "check-query-length": true
        },
        
        "file-upload-policy": {
            "maximum-file-size": 5242880,
            "maximum-uploads": 5,
            "allowed-extensions": [
                "jpg", "jpeg", "png", "gif", "pdf", "doc", "docx", "txt", "zip"
            ],
            "disallowed-extensions": [
                "exe", "bat", "sh", "php", "jsp", "asp", "aspx", "cgi", "pl"
            ]
        },
        
        "ip-address-lists": {
            "ip-addresses": [
                {
                    "ipAddress": "10.0.0.0/8",
                    "block": false,
                    "description": "Internal network"
                },
                {
                    "ipAddress": "192.168.0.0/16", 
                    "block": false,
                    "description": "Corporate network"
                }
            ]
        },
        
        "session-management": {
            "sessionTracking": true,
            "sessionExpiration": 3600,
            "maxSessionsPerUser": 3
        },
        
        "brute-force-protection": {
            "loginAttempts": 5,
            "blockTime": 300,
            "trackingPeriod": 60
        }
    }
}
```

### Step 5: Validate Your Policy

Before using your custom policy, validate its JSON format:

```bash
# Install jq for JSON validation (if not installed)
sudo apt install jq -y

# Validate your policy file
jq . /etc/app_protect/conf/my-custom-policy.json

# Check if validation was successful
echo $?  # Should return 0 if valid

# Or use Python to validate
python3 -m json.tool /etc/app_protect/conf/my-custom-policy.json

# Use the App Protect JSON schema validator (if installed)
sudo /opt/app_protect/bin/generate_json_schema.pl

# Check for schema compliance
cat /etc/app_protect/conf/my-custom-policy.json | \
  python3 -c "import sys, json; json.load(sys.stdin); print('✅ JSON is valid')"
```

### Step 6: Apply the Policy to NGINX

Edit your NGINX configuration to use the custom policy:

```bash
sudo nano /etc/nginx/conf.d/default.conf
```

Add the policy file path in your server or location block:

```nginx
server {
    listen 443 ssl;
    server_name www.nginxlababdo.com;

    ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;

    # Apply your custom policy
    app_protect_enable on;
    app_protect_policy_file "/etc/app_protect/conf/my-custom-policy.json";
    app_protect_security_log_enable on;
    app_protect_security_log "/etc/app_protect/conf/log_default.json" syslog:server=127.0.0.1:515;

    location / {
        proxy_pass http://your-backend:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Step 7: Test Your Custom Policy

```bash
# Test the configuration
sudo nginx -t

# If test passes, reload NGINX
sudo nginx -s reload

# Check for any policy compilation errors
sudo tail -f /var/log/nginx/error.log | grep -i "policy\|app_protect"

# Test your policy with various attack patterns
curl -k "https://localhost/?id=1' OR '1'='1"  # SQL Injection
curl -k "https://localhost/?search=<script>alert(1)</script>"  # XSS
curl -k "https://localhost/../../../etc/passwd"  # Path Traversal
```

### Step 8: Advanced Policy Management

#### Create Policy Templates for Different Environments

```bash
# Create different policies for different environments
sudo cp /etc/app_protect/conf/NginxDefaultPolicy.json /etc/app_protect/conf/dev-policy.json
sudo cp /etc/app_protect/conf/NginxDefaultPolicy.json /etc/app_protect/conf/staging-policy.json
sudo cp /etc/app_protect/conf/NginxStrictPolicy.json /etc/app_protect/conf/production-policy.json

# Customize each environment
# Dev: transparent mode with logging
sudo sed -i 's/"enforcementMode": "blocking"/"enforcementMode": "transparent"/g' /etc/app_protect/conf/dev-policy.json

# Staging: blocking with specific IP whitelist
sudo sed -i '/"enforcementMode"/a \    "ip-address-lists": {"ip-addresses": [{"ipAddress": "YOUR_IP/32","block": false}]},' /etc/app_protect/conf/staging-policy.json
```

#### Rotate Policies Dynamically

```bash
# Create symbolic links for active policy
sudo ln -sf /etc/app_protect/conf/production-policy.json /etc/app_protect/conf/active-policy.json

# Update nginx.conf to use active-policy.json
sudo sed -i 's|app_protect_policy_file "/etc/app_protect/conf/.*"|app_protect_policy_file "/etc/app_protect/conf/active-policy.json"|g' /etc/nginx/conf.d/default.conf

# Reload to apply new policy
sudo nginx -s reload
```

#### Monitor Policy Effectiveness

```bash
# Create monitoring script for policy violations
sudo tee /usr/local/bin/policy-monitor.sh > /dev/null << 'EOF'
#!/bin/bash

echo "Policy Violation Report - $(date)"
echo "================================"

# Count blocked requests by violation type
if [ -f /var/log/app_protect/bd-socket-plugin.log ]; then
    echo -e "\nTop Violations:"
    grep -i "violation" /var/log/app_protect/bd-socket-plugin.log | \
        tail -1000 | cut -d'"' -f4 | sort | uniq -c | sort -rn | head -10
fi

# Check policy compilation status
echo -e "\nPolicy Status:"
sudo nginx -t 2>&1 | grep -i "policy\|app_protect"

# Show active policy
echo -e "\nActive Policy:"
grep "app_protect_policy_file" /etc/nginx/conf.d/default.conf

# Show enforcement mode
echo -e "\nEnforcement Mode:"
grep "enforcementMode" /etc/app_protect/conf/active-policy.json 2>/dev/null
EOF

sudo chmod +x /usr/local/bin/policy-monitor.sh
sudo /usr/local/bin/policy-monitor.sh
```

### Quick Policy Commands Reference

| Task | Command |
|------|---------|
| List available policies | `ls -la /etc/app_protect/conf/*.json` |
| Copy default policy | `sudo cp /etc/app_protect/conf/NginxDefaultPolicy.json /etc/app_protect/conf/mypolicy.json` |
| Validate JSON | `jq . /etc/app_protect/conf/mypolicy.json` |
| Apply policy in NGINX | `app_protect_policy_file "/path/to/policy.json";` |
| Switch to transparent mode | `sed -i 's/blocking/transparent/g' policy.json` |
| Test configuration | `nginx -t` |
| Reload WAF | `nginx -s reload` |
| View policy errors | `tail -f /var/log/nginx/error.log \| grep policy` |
| Check active policy | `grep app_protect_policy_file /etc/nginx/conf.d/*.conf` |

### Best Practices for Policy Management

1. **Start in transparent mode** - Set `enforcementMode: "transparent"` initially to monitor without blocking
2. **Test before production** - Validate policies in a staging environment first
3. **Keep backups** - Save working policy versions before making changes
4. **Monitor logs** - Watch `/var/log/app_protect/bd-socket-plugin.log` for errors
5. **Use version control** - Track policy changes in Git
6. **Document customizations** - Comment any changes made to policies
7. **Regular reviews** - Review policy effectiveness monthly
8. **Update attack signatures** - Keep attack signatures current for maximum protection
9. **Test with real traffic** - Use traffic replay tools to test policies before deployment
10. **Create environment-specific policies** - Different policies for dev, staging, and production

### Troubleshooting Policies

| Issue | Solution |
|-------|----------|
| Policy not compiling | Check JSON syntax: `jq . policy.json` |
| Module not loading | Verify module path in nginx.conf |
| Too many false positives | Switch to transparent mode first, then adjust |
| Attacks not blocked | Check enforcementMode is "blocking" |
| Performance issues | Reduce logging, optimize rules |
| Policy file not found | Verify path and permissions |
| Compilation timeout | Check policy size and complexity |

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

#### Issue 4: Policy file not found or invalid
```bash
# Check if policy exists
ls -la /etc/app_protect/conf/

# If missing, reinstall
sudo apt install --reinstall app-protect-common

# Validate JSON syntax
python3 -m json.tool /etc/app_protect/conf/your-policy.json

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

# Check policy compilation status in real-time
sudo journalctl -u nginx -f | grep -i "app_protect\|policy"
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
    "XXE Attack|/?xml=<!DOCTYPE%20foo[<!ENTITY%20xxe%20SYSTEM%20\"file:///etc/passwd\">]>"
    "HTTP Method Tampering|/?_method=DELETE"
    "Response Splitting|/%0d%0aHeader:%20Injected"
    "LDAP Injection|/?user=*)(uid=*"
    "NoSQL Injection|/?search[$ne]=1"
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
echo "sudo tail -f /var/log/app_protect/bd-socket-plugin.log"
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

# Test with WAF enabled vs disabled
echo "WAF Performance Impact Test"
time curl -s -k https://localhost/ > /dev/null
```

---

## Maintenance

### Regular Updates

```bash
# Update attack signatures
sudo apt update
sudo apt upgrade app-protect-attack-signatures app-protect-bot-signatures

# Update App Protect
sudo apt update
sudo apt upgrade app-protect app-protect-common

# Update NGINX Plus
sudo apt upgrade nginx-plus

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

echo "WAF Status Report - $(date)"
echo "==========================="

# Check WAF plugin
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

# Check active policy
echo -e "\nActive Policy:"
grep "app_protect_policy_file" /etc/nginx/conf.d/*.conf 2>/dev/null | head -1

# Check recent attacks
echo -e "\nRecent attacks (last 24 hours):"
sudo grep -i "attack\|violation\|blocked" /var/log/app_protect/bd-socket-plugin.log 2>/dev/null | tail -5

# Count blocks today
echo -e "\nWAF blocks today:"
sudo grep -c "blocked" /var/log/app_protect/bd-socket-plugin.log 2>/dev/null || echo "0"

# Check policy compilation
echo -e "\nPolicy Status:"
sudo nginx -t 2>&1 | grep -i "policy\|app_protect" || echo "✅ Policy OK"
EOF

sudo chmod +x /usr/local/bin/waf-monitor.sh

# Run monitor
sudo /usr/local/bin/waf-monitor.sh

# Add to crontab for regular monitoring
echo "0 * * * * /usr/local/bin/waf-monitor.sh >> /var/log/waf-monitor.log 2>&1" | sudo crontab -
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

# Backup logs (last 7 days)
mkdir -p $BACKUP_DIR/logs
cp /var/log/nginx/access.log $BACKUP_DIR/logs/
cp /var/log/nginx/error.log $BACKUP_DIR/logs/
cp /var/log/app_protect/bd-socket-plugin.log $BACKUP_DIR/logs/

# Backup policy files specifically
cp /etc/app_protect/conf/*.json $BACKUP_DIR/policies/ 2>/dev/null

# Compress backup
tar -czf ${BACKUP_DIR}.tar.gz $BACKUP_DIR/
rm -rf $BACKUP_DIR

echo "Backup saved to: ${BACKUP_DIR}.tar.gz"
echo "Size: $(du -h ${BACKUP_DIR}.tar.gz | cut -f1)"
EOF

sudo chmod +x /usr/local/bin/backup-waf-config.sh
sudo /usr/local/bin/backup-waf-config.sh

# Schedule daily backups
echo "0 2 * * * /usr/local/bin/backup-waf-config.sh" | sudo crontab -
```

---

## Security Best Practices

### 1. Production SSL Configuration
```bash
# Use Let's Encrypt for production SSL
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d yourdomain.com

# Or use strong SSL configuration
sudo tee /etc/nginx/conf.d/ssl-params.conf > /dev/null << 'EOF'
ssl_session_timeout 1d;
ssl_session_cache shared:SSL:50m;
ssl_session_tickets off;
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
ssl_prefer_server_ciphers off;
ssl_stapling on;
ssl_stapling_verify on;
EOF
```

### 2. Custom WAF Policy for Production
```bash
# Create production policy with enhanced security
sudo tee /etc/app_protect/conf/production-policy.json > /dev/null << 'EOF'
{
    "policy": {
        "name": "production_strict_policy",
        "template": { "name": "POLICY_TEMPLATE_NGINX_BASE" },
        "enforcementMode": "blocking",
        "blocking-settings": {
            "violations": [
                {"name": "VIOL_RATING_THREAT", "alarm": true, "block": true},
                {"name": "VIOL_ATTACK_SIGNATURE", "alarm": true, "block": true},
                {"name": "VIOR_JSON_MALFORMED", "alarm": true, "block": true}
            ]
        },
        "brute-force-protection": {
            "loginAttempts": 5,
            "blockTime": 900,
            "trackingPeriod": 60
        }
    }
}
EOF
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

### 4. GeoIP Blocking (Optional)
```bash
# Install GeoIP module
sudo apt install nginx-plus-module-geoip2

# Add to nginx.conf
echo "load_module modules/ngx_http_geoip2_module.so;" | sudo tee -a /etc/nginx/nginx.conf

# Configure GeoIP blocking
sudo tee -a /etc/nginx/conf.d/geoip.conf > /dev/null << 'EOF'
geoip2 /etc/nginx/geoip/GeoLite2-Country.mmdb {
    $geoip2_data_country_code country iso_code;
}

map $geoip2_data_country_code $allowed_country {
    default 0;
    US 1;
    CA 1;
    GB 1;
}
EOF
```

### 5. Security Headers Enhancement
```bash
# Add comprehensive security headers
sudo tee -a /etc/nginx/conf.d/security-headers.conf > /dev/null << 'EOF'
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline';" always;
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
EOF
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
- [ ] Custom policy created and applied
- [ ] Logs showing WAF activity
- [ ] Performance testing completed
- [ ] Backups configured
- [ ] Monitoring in place
- [ ] Security headers enabled

---

## Support and Resources

- [NGINX App Protect Documentation](https://docs.nginx.com/nginx-app-protect/)
- [F5 Support Portal](https://support.f5.com/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [NGINX Plus Admin Guide](https://docs.nginx.com/nginx/admin-guide/)
- [NGINX App Protect Policy Reference](https://docs.nginx.com/nginx-app-protect/configuration/)
- [F5 DevCentral Community](https://devcentral.f5.com/)

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

# Policy Management
ls /etc/app_protect/conf/*.json
sudo cp /etc/app_protect/conf/NginxDefaultPolicy.json /etc/app_protect/conf/mycustom.json
jq . /etc/app_protect/conf/mycustom.json
sudo nginx -s reload

# Update Signatures
sudo apt update && sudo apt upgrade app-protect-attack-signatures

# Test WAF
curl -k "https://localhost/?id=1' OR '1'='1"
curl -k "https://localhost/?search=<script>alert(1)</script>"

# Monitor
sudo /usr/local/bin/waf-monitor.sh
sudo journalctl -u nginx -f
```
