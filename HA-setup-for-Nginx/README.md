# High Availability Nginx Cluster with Keepalived

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Keepalived](https://img.shields.io/badge/Keepalived-2.2+-green.svg)](https://www.keepalived.org/)
[![Nginx](https://img.shields.io/badge/Nginx-1.18+-brightgreen.svg)](https://nginx.org/)

This repository provides a complete high-availability (HA) solution for Nginx using Keepalived, featuring automatic failover between master and backup servers with Virtual IP (VIP) management.

## 📋 Table of Contents

- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration Files](#configuration-files)
- [Installation Steps](#installation-steps)
- [Testing Failover](#testing-failover)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)
- [Production Checklist](#production-checklist)

## 🏗 Architecture Overview

```
                    ┌─────────────────────────────────────┐
                    │         Client Requests             │
                    │      http://172.20.20.51            │
                    └──────────────┬──────────────────────┘
                                   │
                                   ▼
                    ┌─────────────────────────────────────┐
                    │      Virtual IP (VIP)               │
                    │        172.20.20.51/16              │
                    └──────────────┬──────────────────────┘
                                   │
                    ┌──────────────┴──────────────┐
                    │                             │
                    ▼                             ▼
        ┌──────────────────────┐      ┌──────────────────────┐
        │   Master Server      │◄────►│   Backup Server      │
        │   172.20.20.50/16    │ VRRP │   172.20.2.55/16     │
        │   Priority: 101      │      │   Priority: 100      │
        │   State: MASTER      │      │   State: BACKUP      │
        └──────────────────────┘      └──────────────────────┘
                    │                              │
                    └──────────┬───────────────────┘
                               │
                    ┌──────────▼──────────┐
                    │   Nginx Service     │
                    │   Port 80/443       │
                    └─────────────────────┘
```

### IP Address Plan

| Component | IP Address | Role | Priority |
|-----------|------------|------|----------|
| Master Server | `172.20.20.50/16` | Active/Primary | 101 |
| Backup Server | `172.20.2.55/16` | Passive/Standby | 100 |
| Virtual IP (VIP) | `172.20.20.51/16` | Floating IP | N/A |

## 📋 Prerequisites

- Two Ubuntu/Debian or RHEL/CentOS servers
- Root or sudo access on both servers
- Nginx installed and configured
- Network connectivity between servers (VRRP protocol allowed)
- Static IP addresses configured

## 🚀 Quick Start

Clone this repository and deploy the configuration:

```bash
git clone https://github.com/yourusername/nginx-keepalived-ha.git
cd nginx-keepalived-ha
```

## 📁 Configuration Files

This repository contains the following configuration files:

| File Path | Description | Server |
|-----------|-------------|--------|
| [`/etc/keepalived/keepalived.conf`](#master-configuration) | Keepalived master configuration | Master |
| [`/etc/keepalived/keepalived-backup.conf`](#backup-configuration) | Keepalived backup configuration | Backup |
| [`/etc/keepalived/notify.sh`](#notification-script) | State change notification script | Both |
| [`/etc/nginx/sites-available/cybersecurity-portfolio`](#nginx-configuration) | Nginx site configuration | Both |
| [`/var/www/cybersecurity-portfolio/health`](#health-check) | Health check endpoint | Both |

### Master Configuration

👉 **[Download `/etc/keepalived/keepalived.conf`](configs/keepalived-master.conf)**

```nginx

```

### Backup Configuration

👉 **[Download `/etc/keepalived/keepalived.conf`](configs/keepalived-backup.conf)**

```nginx

```

### Notification Script

👉 **[Download `/etc/keepalived/notify.sh`](scripts/notify.sh)**

```bash

```

### Nginx Configuration

👉 **[Download `/etc/nginx/sites-available/cybersecurity-portfolio`](configs/nginx-site.conf)**

```nginx

```

### Health Check File

👉 **[Download `/var/www/html/health`](www/health)**

```json
{"status": "healthy", "server": "hostname"}
```

## 📝 Installation Steps

### Step 1: Install Keepalived

Run on both Nginx servers:

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install keepalived curl -y

# RHEL/CentOS
sudo yum install keepalived curl -y
```

### Step 2: Identify Network Interface

```bash
ip addr show
# Look for interface with your server's IP
# Common names: eth0, ens160, enp0s3, eno1
```

### Step 3: Deploy Configuration Files

#### On Master Server (172.20.20.50)

```bash
# Download configuration
curl -o /etc/keepalived/keepalived.conf \
  https://raw.githubusercontent.com/yourusername/nginx-keepalived-ha/main/configs/keepalived-master.conf

# Edit interface name and passwords
sudo nano /etc/keepalived/keepalived.conf
```

#### On Backup Server (172.20.2.55)

```bash
# Download configuration
curl -o /etc/keepalived/keepalived.conf \
  https://raw.githubusercontent.com/yourusername/nginx-keepalived-ha/main/configs/keepalived-backup.conf

# Edit interface name (must match master)
sudo nano /etc/keepalived/keepalived.conf
```

### Step 4: Setup Notification Script (Both Servers)

```bash
# Download script
sudo curl -o /etc/keepalived/notify.sh \
  https://raw.githubusercontent.com/yourusername/nginx-keepalived-ha/main/scripts/notify.sh

# Make executable
sudo chmod +x /etc/keepalived/notify.sh
```

### Step 5: Configure Nginx

```bash
# Create web directory
sudo mkdir -p /var/www/html

# Create health check file
echo '{"status": "healthy", "server": "'$(hostname)'"}' | \
  sudo tee /var/www/html/health

# Download Nginx configuration
sudo curl -o /etc/nginx/sites-available/html \
  https://raw.githubusercontent.com/yourusername/nginx-keepalived-ha/main/configs/nginx-site.conf

# Enable site
sudo ln -s /etc/nginx/sites-available/html \
  /etc/nginx/sites-enabled/

# Test and reload Nginx
sudo nginx -t
sudo systemctl reload nginx
```

### Step 6: Start Services

```bash
# Enable and start keepalived
sudo systemctl enable keepalived
sudo systemctl start keepalived

# Check status
sudo systemctl status keepalived

# Verify VIP
ip addr show | grep 172.20.20.51
```

## 🧪 Testing Failover

### Test 1: Nginx Failure on Master

```bash
# Terminal 1 - Monitor on backup server
watch -n 1 'ip addr show | grep 172.20.20.51'

# Terminal 2 - Stop Nginx on master
sudo systemctl stop nginx

# Expected: VIP moves to backup within 2-3 seconds
```

### Test 2: Nginx Recovery on Master

```bash
# Start Nginx on master
sudo systemctl start nginx

# Expected: VIP returns to master after 30 seconds (preempt_delay)
```

### Test 3: Complete Master Failure

```bash
# Stop keepalived on master
sudo systemctl stop keepalived

# Expected: Immediate failover to backup (< 3 seconds)
```

### Test 4: Network Partition

```bash
# Simulate network failure on master
sudo iptables -A INPUT -p vrrp -j DROP

# Expected: Backup takes over after missed advertisements
sleep 5
ip addr show | grep 172.20.20.51  # On backup server

# Restore
sudo iptables -D INPUT -p vrrp -j DROP
```

## 📊 Monitoring

### Check Cluster Status

```bash
# View VIP assignment
ip addr show | grep 172.20.20.51

# Check keepalived process
ps aux | grep keepalived

# View state change logs
sudo tail -f /var/log/keepalived-state.log

# Monitor VRRP advertisements
sudo tcpdump -i eth0 vrrp -n

# Check service logs
sudo journalctl -u keepalived -f
```

### Prometheus Metrics (Optional)

Add to keepalived configuration for monitoring:

```nginx
# Include in keepalived.conf
vrrp_instance VI_1 {
    # ... existing configuration ...
    
    # Expose metrics
    vrrp_stats_file /var/run/keepalived.stats
}
```

## 🔧 Troubleshooting

### VIP Not Appearing

```bash
# Check interface name mismatch
ip addr show

# Verify configuration syntax
sudo keepalived -t -f /etc/keepalived/keepalived.conf

# Check service logs
sudo journalctl -u keepalived -n 50 --no-pager

# Manual VIP assignment test
sudo ip addr add 172.20.20.51/16 dev eth0
sudo ip addr del 172.20.20.51/16 dev eth0
```

### Failover Not Working

```bash
# Verify VRRP communication
sudo tcpdump -i eth0 vrrp -n

# Check authentication mismatch
grep auth_pass /etc/keepalived/keepalived.conf

# Verify virtual_router_id matches on both servers
grep virtual_router_id /etc/keepalived/keepalived.conf

# Check firewall
sudo iptables -L -n | grep vrrp
sudo firewall-cmd --list-all
```

### Health Check Failing

```bash
# Test health endpoint
curl -v http://localhost/health

# Check Nginx error logs
sudo tail -f /var/log/nginx/error.log

# Verify killall command works
/usr/bin/killall -0 nginx
echo $?  # Should return 0

# Test nginx process existence
pgrep nginx
```

## 🔒 Security Considerations

### Change Default Passwords

```bash
# Generate secure password
openssl rand -base64 32

# Update auth_pass in both keepalived.conf files
```

### Restrict VRRP Traffic

```bash
# Allow VRRP only from your subnet
sudo iptables -A INPUT -p vrrp -s 172.20.0.0/16 -j ACCEPT
sudo iptables -A INPUT -p vrrp -j DROP

# Save rules
sudo iptables-save > /etc/iptables/rules.v4
```

### Secure Configuration Files

```bash
# Restrict permissions
sudo chmod 640 /etc/keepalived/keepalived.conf
sudo chown root:keepalived /etc/keepalivid/keepalived.conf
```

## ✅ Production Checklist

- [ ] Change default passwords (`auth_pass`)
- [ ] Update email addresses for notifications
- [ ] Verify network interface names match
- [ ] Test failover scenarios thoroughly
- [ ] Configure monitoring alerts
- [ ] Set up log rotation
- [ ] Document recovery procedures
- [ ] Backup configuration files
- [ ] Test with actual traffic load
- [ ] Configure firewall rules
- [ ] Set up SSL certificates
- [ ] Enable metrics collection

## 📚 References

- [Keepalived Documentation](https://www.keepalived.org/documentation.html)
- [Nginx High Availability Guide](https://docs.nginx.com/nginx/admin-guide/high-availability/)
- [VRRP Protocol Specification (RFC 5798)](https://tools.ietf.org/html/rfc5798)


## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📧 Support

For issues, please:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review [GitHub Issues](https://github.com/yourusername/nginx-keepalived-ha/issues)
3. Contact: abdelrhmanhamedmousaa@gmail.com

---

**✅ Your Nginx HA cluster with VIP 172.20.20.51 should now be fully operational!**
```

To use this as a GitHub repository, you'll also want to create these additional files in your repo:

### `configs/keepalived-master.conf`
```nginx
# Same content as master configuration above
```

### `configs/keepalived-backup.conf`
```nginx
# Same content as backup configuration above
```

### `configs/nginx-site.conf`
```nginx
# Same content as Nginx configuration above
```

### `scripts/notify.sh`
```bash
# Same content as notify script above
```

### `www/health`
```json
{"status": "healthy"}
```


Your Nginx HA cluster with VIP 172.20.20.51 should now be fully operational! Users will always connect to 172.20.20.51, and traffic will automatically failover if either server or Nginx goes down.
