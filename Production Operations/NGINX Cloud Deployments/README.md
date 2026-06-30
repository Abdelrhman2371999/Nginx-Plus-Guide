# NGINX Cloud Deployments Summary

## Introduction

Cloud providers have changed how we host web applications. You can now create a server with a single click or API call, and pay only for what you use.

### Key Cloud Concepts

| Concept | Description |
|---------|-------------|
| **IaaS** (Infrastructure as a Service) | Virtual machines you can rent (AWS EC2, Azure VMs, Google Compute) |
| **Pay-per-usage** | You only pay for the resources you actually use |
| **Horizontal Scaling** | Adding more servers to handle more traffic |
| **Auto Scaling** | Automatically add/remove servers based on demand |

---

## AWS Architecture Diagram (from your image)

```
┌─────────────────────────────────────────────────────────────────────┐
│                              VPC                                    │
│                                                                     │
│  ┌──────────────────────────┐    ┌──────────────────────────────┐   │
│  │      Public Subnet       │    │       Private Subnet         │   │
│  │                          │    │                              │   │
│  │    ┌──────────────┐      │    │    ┌────────────────────┐    │   │
│  │    │    Users     │      │    │    │  NGINX Public NLB  │    │   │
│  │    └──────┬───────┘      │    │    └────────┬───────────┘    │   │
│  │           │              │    │             │                │   │
│  │           │ Traffic      │    │    ┌────────▼───────────┐    │   │
│  │           ▼              │    │    │  NGINX Auto Scaling│    │   │
│  │    ┌──────────────┐      │    │    │  Group (NLB)       │    │   │
│  │    │   App-1      │      │    │    └────────┬───────────┘    │   │
│  │    │ (Frontend)   │      │    │             │                │   │
│  │    └──────┬───────┘      │    │    ┌────────▼───────────┐    │   │
│  │           │              │    │    │  App-1 Auto Scaling│    │   │
│  │           │ Traffic      │    │    │  Group (NLB)       │    │   │
│  │           ▼              │    │    └────────────────────┘    │   │
│  │    ┌──────────────┐      │    │                              │   │
│  │    │   App-2      │      │    │    ┌────────────────────┐    │   │
│  │    │ (Backend)    │      │    │    │  App-2 Auto Scaling│    │   │
│  │    └──────────────┘      │    │    │  Group (NLB)       │    │   │
│  │                          │    │    └────────────────────┘    │   │
│  └──────────────────────────┘    └──────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

**Flow:**
1. **Users** → Traffic to App-1
2. **App-1** → Traffic to App-2 (through NGINX)

---

## AWS Marketplace NGINX Plus Offerings (from your image)

| Product | Version | Price | OS |
|---------|---------|-------|-----|
| NGINX Plus Basic - Amazon Linux AMI | 1.4 | $0.34/hr or $2,500/yr | Amazon Linux 2017.09 |
| NGINX Plus Basic - Ubuntu AMI | 1.6 | $0.34/hr or $2,500/yr | Ubuntu 18.04 LTS |
| NGINX Plus Basic - RHEL 7 AMI | 1.3 | $0.34/hr or $2,500/yr | Red Hat 7.7 |
| NGINX Plus - Amazon Linux 2 (LTS) | 1.2 | $0.34/hr or $2,500/yr | Amazon Linux 2017.09 |

**Key Findings:**
- **26 results** found for "nginx plus"
- All are **64-bit (x86)** architecture
- Available in multiple regions (Hong Kong, Tokyo, etc.)
- **Free Trial** available
- Average rating: **3.5-4.5 stars**

---

## Problems and Solutions

### 1. Problem: You need to automate NGINX provisioning on AWS

You have many servers and need them to configure themselves automatically.

**Solution:** Use EC2 UserData with pre-baked AMIs. Choose between:
- **Provision at boot:** Start from base Linux, run scripts at boot (slow, error-prone)
- **Fully baked AMIs:** Pre-configure everything, burn an AMI (fast, less flexible)
- **Partially baked AMIs:** Install software in AMI, configure environment at boot (best balance)

---

### 2. Problem: You need to route traffic to NGINX nodes without a load balancer

You want high availability without paying for an AWS ELB.

**Solution:** Use Amazon Route 53 DNS with health checks. Features include:
- Multiple IP addresses on a single A record (round-robin)
- Weighted records (uneven load distribution)
- Health checks (remove unhealthy nodes)
- Geo-routing (route to closest node)

---

### 3. Problem: You need to autoscale NGINX Open Source with load balancing

You want to automatically scale NGINX servers and distribute traffic.

**Solution:** Use the "NLB Sandwich" pattern:
- Put NGINX Auto Scaling group behind a Network Load Balancer (NLB)
- Put application Auto Scaling group behind another NLB
- NLBs automatically register/deregister nodes

---

### 4. Problem: You want to run NGINX Plus on AWS with pay-as-you-go

You don't want to buy annual licenses.

**Solution:** Deploy from AWS Marketplace. Pay $0.34/hour with no commitment.

---

### 5. Problem: You need to create a custom NGINX VM image on Azure

You want to quickly create multiple identical NGINX servers.

**Solution:** Create a VM, install NGINX, generalize it, and capture the image.

---

### 6. Problem: You need to scale NGINX nodes behind an Azure load balancer

You want high availability and dynamic scaling in Azure.

**Solution:** Use Azure Virtual Machine Scale Sets (VMSS) with an Azure Load Balancer.

---

### 7. Problem: You want to deploy NGINX Plus on Azure with pay-as-you-go

**Solution:** Use the Azure Marketplace NGINX Plus image.

---

### 8. Problem: You need to create an NGINX server on Google Compute Engine

**Solution:** Create a VM, install NGINX, configure it.

---

### 9. Problem: You need to create a Google Compute Image with NGINX

**Solution:** Create a VM, install NGINX, detach the boot disk, create an image.

---

### 10. Problem: You need to proxy to Google App Engine with custom HTTPS

Google App Engine doesn't support custom SSL certificates.

**Solution:** Put NGINX in front of App Engine. NGINX handles HTTPS and routing.

---

## Configuration Syntax

### 1. AWS EC2 UserData (Bash Script)

This script runs when the instance first boots.

```bash
#!/bin/bash
# Update system
yum update -y

# Install NGINX
amazon-linux-extras enable nginx1
yum install -y nginx

# Set environment variables
export APP_DNS_ENDPOINT="${app_dns_endpoint}"
export API_KEY="${api_key}"

# Configure NGINX from template
cat > /etc/nginx/conf.d/app.conf << EOF
server {
    listen 80;
    server_name ${server_name};
    
    location / {
        proxy_pass http://${app_dns_endpoint};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

# Start NGINX
systemctl enable nginx
systemctl start nginx
```

**UserData in AWS Console:**
- Base64 encoded
- Can be a script or environment file
- Downloaded and run at first boot

---

### 2. Packer Template (Hashicorp)

Packer automates building AMIs.

```json
{
  "builders": [{
    "type": "amazon-ebs",
    "region": "us-east-1",
    "source_ami": "ami-0abcdef1234567890",
    "instance_type": "t2.micro",
    "ssh_username": "ec2-user",
    "ami_name": "nginx-ami-{{timestamp}}"
  }],
  "provisioners": [{
    "type": "shell",
    "inline": [
      "sudo yum update -y",
      "sudo amazon-linux-extras enable nginx1",
      "sudo yum install -y nginx",
      "sudo systemctl enable nginx"
    ]
  }]
}
```

---

### 3. Route 53 DNS Configuration

**Multiple A Records (Round Robin):**
```
example.com.  A  10.0.1.10
example.com.  A  10.0.1.11
example.com.  A  10.0.1.12
```

**Weighted A Records (Uneven Distribution):**
```
example.com.  A  10.0.1.10  weight=70
example.com.  A  10.0.1.11  weight=20
example.com.  A  10.0.1.12  weight=10
```

**Health Check Configuration:**
```bash
# Create a health check
aws route53 create-health-check \
    --caller-reference "nginx-health" \
    --health-check-config \
    "IPAddress=10.0.1.10,Port=80,Type=HTTP,ResourcePath=/health"
```

---

### 4. NGINX Configuration for AWS NLB Sandwich

**NGINX Configuration (proxying to application NLB):**
```nginx
http {
    # Upstream to the application NLB (internal)
    upstream app_backend {
        # Use the application NLB DNS name
        server app-nlb-123.elb.amazonaws.com:80;
    }

    server {
        listen 80;

        location / {
            proxy_pass http://app_backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
```

**NGINX with Internal NLB for Service-to-Service Calls:**
```nginx
http {
    upstream app1_backend {
        server app1-nlb.internal.elb.amazonaws.com:80;
    }

    upstream app2_backend {
        server app2-nlb.internal.elb.amazonaws.com:80;
    }

    server {
        listen 80;

        # Route to different services based on path
        location /api/v1/ {
            proxy_pass http://app1_backend;
        }

        location /api/v2/ {
            proxy_pass http://app2_backend;
        }
    }
}
```

---

### 5. Azure VM Image Creation

**Step 1: Generalize the VM**
```bash
# SSH into the VM
ssh azureuser@myvm.westus.cloudapp.azure.com

# Deprovision the user
sudo waagent -deprovision+user -force

# Exit the session
exit
```

**Step 2: Deallocate and Capture**
```bash
# Deallocate the VM
azure vm deallocate -g MyResourceGroup -n MyVM

# Generalize the VM
azure vm generalize -g MyResourceGroup -n MyVM

# Capture the image
azure vm capture MyResourceGroup MyVM MyImage -t MyTemplate.json
```

**Step 3: Create a New VM from the Image**
```bash
# Create network interface
azure network nic create MyResourceGroup MyNIC westus \
    --subnet-name MySubnet \
    --subnet-vnet-name MyVNet

# Create deployment from template
azure group deployment create MyResourceGroup MyDeployment \
    -f MyTemplate.json
```

---

### 6. Azure Scale Set with NGINX

**NGINX Configuration for Azure Scale Set:**
```nginx
http {
    # Upstream to Azure Load Balancer (internal)
    upstream app_backend {
        server app-internal-lb.westus.cloudapp.azure.com:80;
    }

    server {
        listen 80;

        location / {
            proxy_pass http://app_backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
}
```

**Azure Load Balancer Configuration:**
- **Backend Pool:** VMSS containing NGINX nodes
- **Load Balancing Rules:** Port 80/443
- **Health Probes:** Check `/health` endpoint

---

### 7. Google Compute Engine Startup Script

```bash
#!/bin/bash
# Update system
apt-get update -y

# Install NGINX
apt-get install -y nginx

# Create configuration
cat > /etc/nginx/sites-available/default << EOF
server {
    listen 80;
    server_name ${SERVER_NAME};

    location / {
        proxy_pass http://${APP_ENDPOINT};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

# Start NGINX
systemctl enable nginx
systemctl start nginx
```

---

### 8. Google Compute Image Creation

**Step 1: Create and Configure VM**
```bash
# Create VM
gcloud compute instances create my-nginx-vm \
    --zone us-central1-a \
    --machine-type n1-standard-1 \
    --image-family ubuntu-1804-lts \
    --image-project ubuntu-os-cloud

# SSH into VM
gcloud compute ssh my-nginx-vm

# Install NGINX
sudo apt-get update && sudo apt-get install -y nginx
# Configure NGINX...
```

**Step 2: Disable Auto-Delete and Delete Instance**
```bash
# Set disk to not auto-delete
gcloud compute instances detach-disk my-nginx-vm \
    --disk my-nginx-vm \
    --zone us-central1-a

# Delete instance (keep disk)
gcloud compute instances delete my-nginx-vm \
    --keep-disks boot \
    --zone us-central1-a
```

**Step 3: Create Image from Disk**
```bash
gcloud compute images create my-nginx-image \
    --source-disk my-nginx-vm \
    --source-disk-zone us-central1-a
```

---

### 9. Google App Engine Proxy with NGINX

```nginx
http {
    # DNS resolver (Google's public DNS)
    resolver 8.8.8.8 valid=30s;

    server {
        listen 443 ssl;
        server_name custom-domain.com;

        ssl_certificate /etc/nginx/ssl/custom-domain.crt;
        ssl_certificate_key /etc/nginx/ssl/custom-domain.key;

        location /app1/ {
            # Use a variable so DNS is resolved on every request
            set $app1_endpoint "app1.appspot.com";
            proxy_pass https://$app1_endpoint;
            proxy_set_header Host app1.appspot.com;
            proxy_set_header X-Real-IP $remote_addr;
        }

        location /app2/ {
            set $app2_endpoint "app2.appspot.com";
            proxy_pass https://$app2_endpoint;
            proxy_set_header Host app2.appspot.com;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
}
```

**Important:** Use variables in `proxy_pass` so NGINX resolves DNS on every request.

---

## Comparison: Cloud Providers

| Feature | AWS | Azure | Google Cloud |
|---------|-----|-------|--------------|
| **VM Service** | EC2 | Virtual Machines | Compute Engine |
| **Auto Scaling** | Auto Scaling Groups | VM Scale Sets | Instance Groups |
| **Load Balancer** | ELB/ALB/NLB | Load Balancer | Cloud Load Balancing |
| **DNS Service** | Route 53 | Azure DNS | Cloud DNS |
| **Marketplace** | AWS Marketplace | Azure Marketplace | GCP Marketplace |
| **NGINX Plus AMI** | ✅ Available | ✅ Available | ❌ Not Available |

---

## AWS NLB Sandwich Configuration Example

```nginx
# /etc/nginx/conf.d/app.conf
http {
    # Upstream to the application NLB
    upstream app_backend {
        server app-nlb-1234567890.elb.amazonaws.com:80;
    }

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }

    # Main application routing
    server {
        listen 80;

        location / {
            proxy_pass http://app_backend;
            
            # Pass real client info
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # Timeouts
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
        }
    }
}
```

---

## Summary Table

| Use Case | AWS Solution | Azure Solution | Google Solution |
|----------|--------------|----------------|-----------------|
| Single NGINX VM | EC2 with UserData | VM with custom image | Compute Engine VM |
| Auto Scaling NGINX | Auto Scaling Group + NLB | VM Scale Set + LB | Instance Group + LB |
| NGINX Plus On-Demand | AWS Marketplace | Azure Marketplace | N/A (use self-install) |
| DNS Load Balancing | Route 53 | Azure DNS | Cloud DNS |
| Custom Images | AMI + Packer | Custom Image | Compute Image |
| Proxy to App Engine | N/A | N/A | Compute Engine + App Engine |

---

## Key Takeaways

1. **AWS**:
   - Use **NLB Sandwich** pattern for NGINX Open Source
   - Use **AWS Marketplace** for NGINX Plus with pay-as-you-go
   - Use **UserData** and **Packer** for automation

2. **Azure**:
   - Use **VM Scale Sets** for autoscaling
   - Use **Azure Marketplace** for NGINX Plus
   - Use **ARM templates** for repeatable deployments

3. **Google Cloud**:
   - Use **Compute Engine** for NGINX VMs
   - Use **startup scripts** for configuration
   - Use **Custom Images** for consistent deployments

4. **Best Practices**:
   - Use **partially baked AMIs** (balance speed and flexibility)
   - Use **health checks** to remove unhealthy nodes
   - Use **DNS** for load balancing when you don't need a full LB
   - Always use **variables** when proxying to dynamic endpoints
