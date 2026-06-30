# NGINX Complete Guide - Master README

## 📚 Overview

This comprehensive guide covers everything you need to know about NGINX and NGINX Plus - from basic installation to advanced production deployments, security, performance tuning, and high-availability configurations. Whether you're a developer, DevOps engineer, or system administrator, this guide will help you master NGINX.

---

## 📂 Directory Structure

```
NGINX-Complete-Guide/
│
├── HA-setup-for-Nginx/
│   ├── Backup Configuration/
│   └── Master Configuration/
│
├── NGINX Controller/
│
├── Nginx Performance/
│   ├── NGINX Caching/
│   ├── NGINX HTTP2/
│   ├── NGINX Load Balancing/
│   ├── NGINX Performance Tuning/
│   └── NGINX Sophisticated Media Streaming/
│
├── NGINX Practical Ops Tips and Conclusion/
│
├── Nginx Security/
│   ├── NGINX App Protect WAF on Ubuntu/
│   ├── NGINX Authentication/
│   └── Security Controls/
│
├── NGINX Traffic Management/
│
├── Production Operations/
│   ├── NGINX Advanced Activity Monitoring/
│   ├── NGINX Cloud Deployments/
│   ├── NGINX Containers and Microservices/
│   └── NGINX High-Availability Deployment Modes/
│
├── Programmability and Automation/
│
└── Troubleshooting/
    └── NGINX Debugging and Troubleshooting/
```

---

## 📖 Quick Navigation

| Category | Section | Description |
|----------|---------|-------------|
| 🚀 **Getting Started** | [NGINX Traffic Management](#nginx-traffic-management) | Load balancing, rate limiting, and traffic control |
| 🔒 **Security** | [Nginx Security](#nginx-security) | Authentication, WAF, SSL/TLS, security controls |
| ⚡ **Performance** | [Nginx Performance](#nginx-performance) | Caching, HTTP/2, performance tuning, media streaming |
| 🏗️ **HA & Production** | [Production Operations](#production-operations) | High availability, cloud, containers, monitoring |
| 🤖 **Automation** | [Programmability and Automation](#programmability-and-automation) | API, automation, infrastructure as code |
| 🔧 **Troubleshooting** | [Troubleshooting](#troubleshooting) | Debugging, logging, error handling |
| 🎯 **Ops** | [Practical Ops Tips](#practical-ops-tips) | Best practices, includes, debugging |

---

## 🚀 NGINX Traffic Management

### Overview
This section covers core traffic management features including load balancing, rate limiting, and request routing.

### Topics Covered

| Topic | Description |
|-------|-------------|
| **HTTP Load Balancing** | Round-robin, least connections, IP hash, random |
| **TCP/UDP Load Balancing** | Stream module for non-HTTP traffic |
| **Rate Limiting** | Prevent DDoS attacks and abuse |
| **Request Routing** | Location blocks, rewrite rules |
| **Session Persistence** | Sticky sessions, cookie-based affinity |
| **Health Checks** | Active and passive health monitoring |
| **Traffic Shaping** | Bandwidth limiting, connection limits |

### Key Configuration Examples

```nginx
# HTTP Load Balancing
upstream backend {
    least_conn;
    server 10.0.0.1:80 weight=3;
    server 10.0.0.2:80 weight=2;
    server 10.0.0.3:80 backup;
}

# Rate Limiting
limit_req_zone $binary_remote_addr zone=mylimit:10m rate=10r/s;
location /api/ {
    limit_req zone=mylimit burst=20 nodelay;
}

# Session Persistence
upstream backend {
    ip_hash;
    server 10.0.0.1:80;
    server 10.0.0.2:80;
}
```

---

## 🔒 Nginx Security

### Overview
Comprehensive security guide covering authentication, authorization, SSL/TLS, and Web Application Firewall (WAF) protection.

### Sub-Sections

| Section | Description |
|---------|-------------|
| **NGINX App Protect WAF on Ubuntu** | Install and configure WAF, security policies, attack signatures |
| **NGINX Authentication** | Basic auth, JWT validation, OIDC integration |
| **Security Controls** | SSL/TLS, CORS, IP access control, HSTS, security headers |

### Key Configuration Examples

```nginx
# SSL/TLS Configuration
server {
    listen 443 ssl http2;
    ssl_certificate /etc/nginx/ssl/server.crt;
    ssl_certificate_key /etc/nginx/ssl/server.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
}

# HTTP Basic Authentication
location /admin/ {
    auth_basic "Admin Area";
    auth_basic_user_file /etc/nginx/.htpasswd;
}

# IP Access Control
location /internal/ {
    allow 10.0.0.0/24;
    allow 192.168.1.100;
    deny all;
}

# CORS Configuration
location /api/ {
    add_header 'Access-Control-Allow-Origin' '*';
    add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
}
```

---

## ⚡ Nginx Performance

### Overview
Optimize NGINX for maximum performance with caching, HTTP/2, media streaming, and system tuning.

### Sub-Sections

| Section | Description |
|---------|-------------|
| **NGINX Caching** | Cache zones, cache locking, purging, slicing |
| **NGINX HTTP2** | HTTP/2 configuration, server push, gRPC |
| **NGINX Load Balancing** | Advanced load balancing algorithms, health checks |
| **NGINX Performance Tuning** | OS tuning, buffering, connection management |
| **NGINX Sophisticated Media Streaming** | MP4, FLV, HLS, HDS streaming |

### Key Configuration Examples

```nginx
# Cache Configuration
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=mycache:10m max_size=10g;
proxy_cache mycache;
proxy_cache_valid 200 1h;
proxy_cache_key $host$request_uri;

# HTTP/2 with Server Push
server {
    listen 443 ssl http2;
    location /page.html {
        http2_push /style.css;
        http2_push /script.js;
    }
    http2_push_preload on;
}

# gRPC Load Balancing
upstream grpc_backend {
    server 10.0.0.1:50051;
    server 10.0.0.2:50051;
}
location /grpc/ {
    grpc_pass grpc://grpc_backend;
}

# Media Streaming
location /videos/ {
    mp4;
    mp4_limit_rate_after 15s;
    mp4_limit_rate 1.2;
}
```

---

## 🏗️ Production Operations

### Overview
Production-ready configurations for high availability, cloud deployments, containers, and monitoring.

### Sub-Sections

| Section | Description |
|---------|-------------|
| **NGINX Advanced Activity Monitoring** | Dashboard, API metrics, monitoring integration |
| **NGINX Cloud Deployments** | AWS, Azure, Google Cloud deployment patterns |
| **NGINX Containers and Microservices** | Docker, Kubernetes, Ingress Controller |
| **NGINX High-Availability Deployment Modes** | Active-passive, active-active, zone sync |

### Key Configuration Examples

```nginx
# NGINX Plus Monitoring Dashboard
location /api {
    api write=on;
}
location /dashboard.html {
    root /usr/share/nginx/html;
}

# Kubernetes Ingress Controller
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
spec:
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        backend:
          service:
            name: app-service
            port:
              number: 80

# NGINX Plus HA with Zone Sync
stream {
    server {
        listen 9000;
        zone_sync;
        zone_sync_server peer1.example.com:9000;
        zone_sync_server peer2.example.com:9000;
    }
}
```

---

## HA Setup for Nginx

### Overview
High-availability configurations for NGINX deployments.

### Sub-Sections

| Section | Description |
|---------|-------------|
| **Master Configuration** | Primary node settings |
| **Backup Configuration** | Failover node settings |

### Key Concepts

- **VRRP (Virtual Router Redundancy Protocol)** with Keepalived
- **Active-Passive** failover
- **Virtual IP** management
- **Health checks** and monitoring

---

## NGINX Controller

### Overview
Centralized management and monitoring platform for NGINX Plus instances.

### Features

| Feature | Description |
|---------|-------------|
| **Application-Centric Management** | Manage by applications, not servers |
| **Fleet Management** | Control all NGINX instances from one place |
| **WAF Integration** | App Protect security management |
| **API-Driven** | Everything configurable via REST API |
| **Analytics** | Metrics and dashboards for all instances |
| **Multi-Environment** | Dev, staging, production in one view |

---

## 🤖 Programmability and Automation

### Overview
Automate NGINX configuration and management using APIs, dynamic configuration, and infrastructure as code.

### Topics Covered

| Topic | Description |
|-------|-------------|
| **NGINX Plus API** | Dynamic upstream management, health checks, metrics |
| **Key-Value Store** | Dynamic traffic decisions, blocklists |
| **NGINScript (njs)** | JavaScript extensions |
| **Lua Module** | Lua scripting for custom logic |
| **Perl Module** | Perl-based extensions |
| **Configuration Management** | Puppet, Chef, Ansible, SaltStack |
| **Consul Integration** | Service discovery, dynamic configuration |

### Key Configuration Examples

```nginx
# NGINX Plus API
location /api {
    api write=on;
}

# Dynamic Upstream Management
upstream backend {
    zone backend 64k;
}

# Key-Value Store
keyval_zone zone=blocklist:1M;
keyval $remote_addr $blocked zone=blocklist;

if ($blocked) {
    return 403 "Forbidden";
}
```

---

## 🔧 Troubleshooting

### Overview
Debugging and troubleshooting NGINX issues effectively.

### Sub-Sections

| Section | Description |
|---------|-------------|
| **NGINX Debugging and Troubleshooting** | Access logs, error logs, request tracing, OpenTracing |

### Key Configuration Examples

```nginx
# Debug Logging
error_log /var/log/nginx/error.log debug;

# Debug Specific Connections
events {
    debug_connection 192.168.1.100;
}

# Request Tracing
log_format trace '$remote_addr - $remote_user [$time_local] '
                 '"$request" $status $body_bytes_sent '
                 '"$http_referer" "$http_user_agent" '
                 '$request_id';

proxy_set_header X-Request-ID $request_id;
add_header X-Request-ID $request_id;

# OpenTracing
opentracing on;
opentracing_load_tracer /path/to/tracer.so config.json;
```

---

## Practical Ops Tips

### Overview
Essential operational tips and best practices for NGINX.

### Key Tips

| Tip | Description |
|-----|-------------|
| **Clean Configs** | Use `include` for modular configuration |
| **Debugging** | Logging, debug connections, rewrite log |
| **Testing** | Always test configs with `nginx -t` |
| **Version Control** | Store configurations in Git |
| **Automation** | Use CI/CD for config deployment |

### Configuration Example

```nginx
# Clean Configuration Structure
http {
    include conf.d/*.conf;
    include sites-enabled/*.conf;
    include modules/*.conf;
    include upstreams/*.conf;
}
```

---

## 🔧 Installation Guides

### NGINX Open Source

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install nginx

# CentOS/RHEL
sudo yum install epel-release
sudo yum install nginx

# Alpine Linux
apk add nginx
```

### NGINX Plus

```bash
# Add NGINX Plus repository
# Download certificate and key from customer portal
# Install
sudo apt install nginx-plus
```

---

## 📊 Performance Tuning Checklist

| Area | Setting | Recommended Value |
|------|---------|-------------------|
| **Worker Processes** | `worker_processes` | `auto` |
| **Worker Connections** | `worker_connections` | `50000` |
| **Keep-Alive** | `keepalive_requests` | `320` |
| **Keep-Alive Timeout** | `keepalive_timeout` | `300s` |
| **Client Buffer** | `client_body_buffer_size` | `128k` |
| **Proxy Buffers** | `proxy_buffers` | `8 32k` |
| **Access Log Buffer** | `buffer` | `32k` |
| **Gzip** | `gzip on` | Enabled |
| **Sendfile** | `sendfile on` | Enabled |

---

## 🔐 Security Checklist

| Area | Action |
|------|--------|
| **SSL/TLS** | Use TLS 1.2 or higher, disable weak ciphers |
| **Headers** | Set security headers (HSTS, X-Frame-Options) |
| **Authentication** | Implement JWT or basic auth for sensitive areas |
| **WAF** | Enable App Protect or ModSecurity |
| **Rate Limiting** | Implement to prevent DDoS |
| **IP Access** | Restrict access to admin areas |
| **HTTP to HTTPS** | Redirect all HTTP to HTTPS |
| **HSTS** | Enable Strict-Transport-Security |

---

## 🐳 Docker Commands

```bash
# Run NGINX
docker run -d -p 80:80 nginx

# Run with custom config
docker run -d -p 80:80 -v /path/to/nginx.conf:/etc/nginx/nginx.conf:ro nginx

# Build custom image
docker build -t custom-nginx .

# Run NGINX Plus (with license)
docker run -d -p 80:80 nginxplus

# Run NGINX Controller Agent
docker run -d --name controller-agent \
    -e CONTROLLER_ENDPOINT=https://controller.example.com:8443 \
    -e API_KEY=your-api-key \
    nginx/controller-agent
```

---

## 📚 Resources

| Resource | Link |
|----------|------|
| **Official NGINX Documentation** | https://nginx.org/en/docs/ |
| **NGINX Plus Documentation** | https://docs.nginx.com/nginx/ |
| **NGINX Blog** | https://www.nginx.com/blog/ |
| **NGINX GitHub** | https://github.com/nginx/ |
| **NGINX Controller Docs** | https://docs.nginx.com/nginx-controller/ |
| **NGINX Docker Hub** | https://hub.docker.com/_/nginx |
| **NGINX Ingress Controller** | https://github.com/nginxinc/kubernetes-ingress |
| **NGINX App Protect** | https://docs.nginx.com/nginx-app-protect/ |

---

## 🎯 Quick Reference

### Common Directives

| Directive | Context | Purpose |
|-----------|---------|---------|
| `listen` | server | Set port and protocol |
| `server_name` | server | Domain name matching |
| `location` | server/location | URI routing |
| `proxy_pass` | location | Proxy to upstream |
| `upstream` | http | Define server group |
| `proxy_cache` | http/server/location | Enable caching |
| `limit_req` | http/server/location | Rate limiting |
| `auth_basic` | server/location | Basic authentication |
| `ssl_certificate` | server | SSL certificate path |
| `gzip` | http/server/location | Enable compression |

### Common Status Codes

| Code | Meaning | Action |
|------|---------|--------|
| 200 | OK | Success |
| 301 | Moved Permanently | Check redirect |
| 302 | Found | Check redirect |
| 400 | Bad Request | Check client request |
| 401 | Unauthorized | Check authentication |
| 403 | Forbidden | Check permissions |
| 404 | Not Found | Check file path |
| 429 | Too Many Requests | Rate limiting in effect |
| 500 | Internal Server Error | Check error logs |
| 502 | Bad Gateway | Check upstream |
| 503 | Service Unavailable | Check upstream |
| 504 | Gateway Timeout | Check upstream timeouts |

---

## 📝 License

This guide is for educational and reference purposes. NGINX and NGINX Plus are products of F5 Networks, Inc.

---

## 🤝 Contributing

Feel free to contribute to this guide by submitting pull requests or opening issues for corrections and improvements.

---

**Last Updated:** 2026-06-30