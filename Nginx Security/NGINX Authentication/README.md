# NGINX Authentication Summary

## Introduction

Authentication means checking if a user is who they say they are before letting them access your website or application.

NGINX can handle authentication at the server level. This is great because:

- It **reduces the work** on your application servers
- It **stops unauthorized requests** before they reach your app
- It **saves resources** by rejecting bad requests early

## What NGINX Supports

| Feature | Version | What It Does |
|---------|---------|--------------|
| HTTP Basic Auth | Open Source | Simple username/password login |
| Authentication Subrequests | Open Source | Ask another server to check if the user is valid |
| JSON Web Tokens (JWT) | NGINX Plus | Validate modern tokens for API access |
| OpenID Connect (OIDC) | NGINX Plus | Integrate with Google, Okta, and other SSO providers |

---

## Traffic Diagrams

### 1. HTTP Basic Authentication Flow

```mermaid
sequenceDiagram
    participant User
    participant NGINX
    participant PasswordFile as Password File

    User->>NGINX: 1. Request a protected page
    NGINX->>User: 2. "401 Unauthorized" + Login Pop-up
    User->>User: 3. User enters username & password
    User->>NGINX: 4. Sends username & password in Authorization header
    NGINX->>PasswordFile: 5. Check username & password
    PasswordFile-->>NGINX: 6. Valid credentials
    NGINX->>User: 7. Sends the protected page
```

### 2. Authentication Subrequest Flow

```mermaid
sequenceDiagram
    participant User
    participant NGINX
    participant AuthServer as Authentication Server

    User->>NGINX: 1. Request a protected page
    NGINX->>AuthServer: 2. Send subrequest: "Is this user allowed?"
    AuthServer-->>NGINX: 3. Responds: "200 OK" (allowed) or "403 Forbidden"
    alt User is allowed
        NGINX->>User: 4. Sends the protected page
    else User is not allowed
        NGINX->>User: 4. Returns error (403 Forbidden)
    end
```

### 3. JWT Validation Flow (NGINX Plus)

```mermaid
sequenceDiagram
    participant User
    participant NGINX Plus
    participant Upstream

    User->>NGINX Plus: 1. Request with JWT token in header
    NGINX Plus->>NGINX Plus: 2. Validate token signature<br>using JWK file
    alt Token is valid
        NGINX Plus->>Upstream: 3. Forward the request
        Upstream-->>NGINX Plus: 4. Response from upstream
        NGINX Plus->>User: 5. Send response
    else Token is invalid
        NGINX Plus->>User: 3. "401 Unauthorized"
    end
```

### 4. OpenID Connect Flow (NGINX Plus)

```mermaid
sequenceDiagram
    participant User
    participant NGINX Plus
    participant IdP as Identity Provider (Google/Okta)

    User->>NGINX Plus: 1. Request protected page
    NGINX Plus->>User: 2. Redirect to IdP for login
    User->>IdP: 3. Log in
    IdP->>User: 4. Redirect back with auth code
    User->>NGINX Plus: 5. Request with auth code
    NGINX Plus->>IdP: 6. Exchange code for token
    IdP-->>NGINX Plus: 7. Returns ID token (JWT)
    NGINX Plus->>NGINX Plus: 8. Validate token & store in key-value store
    NGINX Plus->>User: 9. Set session cookie & redirect to protected page
    Note over User,NGINX Plus: Subsequent requests use the cookie
```

---

## Problems and Solutions

### 1. Problem: You need simple password protection

You have a small private area of your site that should only be accessed by a few people.

**Solution:** Use HTTP Basic Authentication. Create a password file with usernames and encrypted passwords, and tell NGINX to use it.

---

### 2. Problem: You already have a user database

You have an existing system that handles authentication (like a database or LDAP), and you don't want to create a separate password file.

**Solution:** Use Authentication Subrequests. NGINX will ask your authentication service if each request is allowed.

---

### 3. Problem: You need to secure an API with modern tokens

Your API uses JSON Web Tokens (JWTs) and you need NGINX to validate them.

**Solution (NGINX Plus):** Use the JWT authentication module. NGINX will validate the token signature and extract claims.

---

### 4. Problem: You need to integrate with Google, Okta, or other SSO

Your company uses a single sign-on (SSO) provider and you want NGINX to work with it.

**Solution (NGINX Plus):** Use the OpenID Connect reference implementation. NGINX acts as a relaying party.

---

### 5. Problem: JWT keys change and you don't want to update them manually

JWTs are signed with keys that may rotate. You need NGINX to always have the latest keys.

**Solution (NGINX Plus):** Use `auth_jwt_key_request` to automatically fetch and cache the keys from your identity provider.

---

### 6. Problem: You need to create keys for JWT signing

You need to generate JWK (JSON Web Key) files for NGINX to validate tokens.

**Solution:** Use a key generation tool. The JWK file must follow the RFC standard format.

---

## Configuration Syntax

### 1. HTTP Basic Authentication

**Step 1: Create the password file**
```bash
# Use openssl to generate an encrypted password
openssl passwd MyPassword1234

# Create the password file
# Format: username:encrypted_password
echo "admin:$1$RjZcVb2w$UI4sn9p1y0j2Mh5sXz8yq0" > /etc/nginx/conf.d/passwd
```

**Step 2: Configure NGINX**
```nginx
location /private/ {
    auth_basic          "Private area - Please log in";
    auth_basic_user_file conf.d/passwd;
}
```

**Testing with curl:**
```bash
curl --user admin:MyPassword1234 https://localhost/private/
```

---

### 2. Authentication Subrequests

This makes NGINX ask another server if the user is authorized.

```nginx
location /private/ {
    # Send a subrequest to /auth to check authentication
    auth_request /auth;

    # Store the status code from the auth request
    auth_request_set $auth_status $upstream_status;
}

# Internal location for authentication
location = /auth {
    internal;  # This location can only be accessed by NGINX internally

    # Send the request to your authentication server
    proxy_pass http://auth-server:8080/verify;

    # Don't send the request body (saves time)
    proxy_pass_request_body off;

    # Set content-length to empty since we're not sending a body
    proxy_set_header Content-Length "";

    # Pass the original URI so the auth server knows what's being accessed
    proxy_set_header X-Original-URI $request_uri;
}
```

**How it works:**
- If the auth server returns `200 OK` → access is granted
- If the auth server returns `401` or `403` → access is denied

---

### 3. Validating JWTs (NGINX Plus)

This validates JSON Web Tokens for API access.

```nginx
location /api/ {
    # Require JWT validation
    auth_jwt "API Access";

    # Path to the JWK file (contains the public key)
    auth_jwt_key_file conf/keys.json;

    # Optional: Validate specific claims
    # auth_jwt_claim_set $user_id sub;  # Extract user ID from token
}
```

**Token in the request:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**If you want to use a cookie instead of the Authorization header:**
```nginx
location /private/ {
    auth_jwt "Google Oauth" token=$cookie_auth_token;
    auth_jwt_key_file /etc/nginx/google_certs.jwk;
}
```

---

### 4. JSON Web Key (JWK) File Format

NGINX Plus needs a JWK file to validate tokens. Here are examples of each key type:

```json
{
  "keys": [
    {
      "kty": "oct",           // Octet Sequence (symmetric key)
      "kid": "0001",          // Key ID
      "k": "OctetSequenceKeyValue"
    },
    {
      "kty": "EC",            // Elliptic Curve
      "kid": "0002",
      "crv": "P-256",
      "x": "XCoordinateValue",
      "y": "YCoordinateValue",
      "d": "PrivateExponent",
      "use": "sig"
    },
    {
      "kty": "RSA",           // RSA
      "kid": "0003",
      "n": "ModulusValue",
      "e": "ExponentValue",
      "d": "PrivateExponent"
    }
  ]
}
```

**Key Types:**
- **oct**: Symmetric key (HS256 algorithm)
- **EC**: Elliptic Curve key (ES256 algorithm)
- **RSA**: RSA key (RS256 algorithm)

---

### 5. Auto-Updating JWKs (NGINX Plus)

This automatically fetches the latest JSON Web Key Set (JWKS) from your provider.

```nginx
# Create a cache zone for storing the JWKS
proxy_cache_path /data/nginx/cache levels=1 keys_zone=jwks_cache:10m;

server {
    # ...

    location / {
        # Require JWT authentication
        auth_jwt "closed site";

        # Fetch the JWKS from an internal location
        auth_jwt_key_request /jwks_uri;
    }

    # Internal location for fetching JWKS
    location = /jwks_uri {
        internal;  # Only NGINX can access this

        # Cache the JWKS response
        proxy_cache jwks_cache;

        # Forward to the identity provider's JWKS endpoint
        proxy_pass https://idp.example.com/keys;
    }
}
```

**How it works:**
1. NGINX receives a request with a JWT
2. If the key is not cached, it fetches it from the identity provider
3. The key is cached for 10 minutes (default)
4. The token is validated

---

### 6. OpenID Connect Integration (NGINX Plus)

**This is the most complex setup.** NGINX Inc. provides a reference implementation.

**Files you need:**
1. `oidc_config.js` - njs script for OIDC logic
2. `oidc_trust.jwk` - JWK file for the identity provider
3. NGINX configuration

**Simplified NGINX configuration:**
```nginx
# Load JavaScript module
load_module modules/ngx_http_js_module.so;

http {
    # Cache for OIDC tokens
    proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=oidc_cache:10m;

    # Key-value store for sharing tokens across NGINX nodes
    keyval_zone zone=oidc_tokens:1M;

    # Include the OIDC JavaScript code
    js_include /etc/nginx/oidc/oidc_config.js;

    server {
        listen 443 ssl;

        location / {
            # JWT authentication
            auth_jwt "OIDC Login" token=$cookie_auth_token;

            # The key can be fetched dynamically
            auth_jwt_key_request /jwks_uri;

            # Pass to the upstream application
            proxy_pass http://app_server;
        }

        # OIDC endpoints for login and logout
        location /_oauth {
            js_content oidc_config.oauth;
        }

        location /_code_exchange {
            js_content oidc_config.code_exchange;
        }

        location /_logout {
            js_content oidc_config.logout;
        }

        # JWKS endpoint
        location = /jwks_uri {
            internal;
            proxy_cache oidc_cache;
            proxy_pass https://your-idp.com/keys;
        }
    }
}
```

**Key Points:**
- NGINX Plus acts as a **relaying party** (RP)
- Uses **authorization code flow** (most secure)
- Stores session data in the **key-value store** for high availability
- The `njs` script handles the OIDC logic

---

## Summary Table

| Authentication Method | Complexity | Best For | Version |
|----------------------|------------|----------|---------|
| HTTP Basic Auth | Simple | Small private areas | Open Source |
| Authentication Subrequests | Medium | When you have an existing auth service | Open Source |
| JWT Validation | Medium | API security with tokens | NGINX Plus |
| OpenID Connect | Complex | Enterprise SSO (Google, Okta, etc.) | NGINX Plus |

## Security Notes

1. **Always use HTTPS** with Basic Authentication (passwords are just base64-encoded)
2. **Secure your JWK files** with proper file permissions
3. **Rotate your JWKs regularly** for JWT-based authentication
4. **Store JWKs in memory** (using ramfs) for best performance
5. **Use strong hashing algorithms** for Basic Auth passwords
