# Secure TLS Setup Guide for MCP (Host Server vs Client Machine)

This guide walks you through everything step by step in plain language.

You will set up:
- A private Certificate Authority (CA) you control
- A server certificate for your MCP host (`103.102.201.202`)
- HTTPS on your MCP container
- System-wide trust on client machines (for VS Code and Claude Code)

The guide is split by machine role so it is easy to follow.

## Quick Roles (Who Runs What)

- **Host Server machine**
  The machine that runs your MCP Docker container.
  Example: `103.102.201.202`

- **Client machine**
  The machine where VS Code / Claude Code connects from.

- **Optional CA Authority machine (recommended for security)**
  A separate secure machine used to store `mcp-ca.key` and sign certs.
  If you do not have one, you can temporarily do CA steps on the host server.

## Important Safety Notes

- Never share `mcp-ca.key`.
- Never copy `mcp-ca.key` to client machines.
- Rotate any API key that was ever pasted into chat, logs, screenshots, or commands.
- Use a placeholder API key in docs and scripts, for example:
  - `ctx7_REPLACE_WITH_A_LONG_RANDOM_SECRET`

---

## Part 1: Create a Shared CA (One Time)

Run these steps on your **CA Authority machine**.

If you do not have one, run on **Host Server** first, then move `mcp-ca.key` to a safer location later.

### 1.1 Create CA directory

```bash
mkdir -p ~/mcp-certs
cd ~/mcp-certs
```

### 1.2 Generate CA private key

```bash
openssl genrsa -out mcp-ca.key 4096
```

### 1.3 Generate CA certificate (valid for 10 years)

```bash
openssl req -x509 -new -nodes \
  -key mcp-ca.key \
  -sha256 \
  -days 3650 \
  -out mcp-ca.crt \
  -subj "/C=US/ST=Local/L=Local/O=mcp-servers/CN=mcp-servers Local CA"
```

### 1.4 Lock permissions

```bash
chmod 600 mcp-ca.key
chmod 644 mcp-ca.crt
```

### 1.5 Verify files

```bash
ls -l ~/mcp-certs/mcp-ca.*
```

Expected:
- `mcp-ca.key` (private, only owner readable)
- `mcp-ca.crt` (safe to distribute)

---

## Part 2: Create and Sign a Server Certificate for the MCP Host

Run on **Host Server machine** (`103.102.201.202`) unless noted.

### 2.1 Create per-host cert folder

```bash
mkdir -p ~/mcp-certs/103.102.201.202
cd ~/mcp-certs/103.102.201.202
```

### 2.2 Generate server private key

```bash
openssl genrsa -out server.key 2048
```

### 2.3 Generate CSR (certificate signing request)

```bash
openssl req -new -key server.key -out server.csr \
  -subj "/C=US/ST=Local/L=Local/O=mcp-servers/CN=103.102.201.202"
```

### 2.4 Create SAN extension file

```bash
cat > server.ext <<'EOF'
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage=digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName=@alt_names

[alt_names]
IP.1=103.102.201.202
IP.2=127.0.0.1
DNS.1=localhost
EOF
```

### 2.5 Sign the CSR with your CA

If CA files are in `~/mcp-certs/` on this same machine:

```bash
sudo openssl x509 -req \
  -in /home/$USER/mcp-certs/103.102.201.202/server.csr \
  -CA /home/$USER/mcp-certs/mcp-ca.crt \
  -CAkey /home/$USER/mcp-certs/mcp-ca.key \
  -CAcreateserial \
  -out /home/$USER/mcp-certs/103.102.201.202/server.crt \
  -days 825 \
  -sha256 \
  -extfile /home/$USER/mcp-certs/103.102.201.202/server.ext
```

If you use a separate CA Authority machine:
- Copy only `server.csr` and `server.ext` to the CA machine
- Sign there with `mcp-ca.key`
- Copy back only `server.crt`

### 2.6 Verify signed certificate

```bash
ls -l ~/mcp-certs/103.102.201.202/server.crt
openssl x509 -in ~/mcp-certs/103.102.201.202/server.crt -noout -issuer -subject -dates
openssl x509 -in ~/mcp-certs/103.102.201.202/server.crt -noout -text | grep -A1 "Subject Alternative Name"
```

Make sure SAN includes `IP Address:103.102.201.202`.

---

## Part 3: Run MCP Container with HTTPS

Run on **Host Server machine**.

### 3.1 Start/restart container with TLS enabled

```bash
docker rm -f context7-mcp 2>/dev/null || true

docker run -d \
  --name context7-mcp \
  --restart unless-stopped \
  -p 7010:7010 \
  -e PORT=7010 \
  -e ENABLE_HTTPS=true \
  -e TLS_CERT_PATH=/certs/server.crt \
  -e TLS_KEY_PATH=/certs/server.key \
  -e HTTP_VERSION_MODE=auto \
  -e API_KEY=ctx7_REPLACE_WITH_A_LONG_RANDOM_SECRET \
  -v /home/$USER/mcp-certs/103.102.201.202:/certs:ro \
  mekayelanik/context7-mcp:stable
```

### 3.2 Check runtime logs

```bash
docker logs -f context7-mcp
```

You want to see HTTPS enabled and no certificate path errors.

---

## Part 4: Install CA Globally on Client Machine (System Trust)

Run on **each Client machine** (where VS Code / Claude Code runs).

Copy `mcp-ca.crt` to client first (never copy `mcp-ca.key`).

### 4.1 Debian/Ubuntu clients

```bash
sudo cp /path/to/mcp-ca.crt /usr/local/share/ca-certificates/mcp-ca.crt
sudo update-ca-certificates
```

Verify:

```bash
ls -l /etc/ssl/certs | grep -i mcp-ca
```

### 4.2 macOS clients

- Open **Keychain Access**
- Import `mcp-ca.crt` into **System** keychain
- Open certificate details and set trust to **Always Trust**
- Restart VS Code / Claude app

### 4.3 Windows clients

- Run `certmgr.msc`
- Import `mcp-ca.crt` into **Trusted Root Certification Authorities**
- Restart VS Code / Claude app

---

## Part 5: Test From Client Machine

Run on **Client machine**.

### 5.1 TLS + API key test

```bash
curl -v --cacert /path/to/mcp-ca.crt \
  -H "Authorization: Bearer ctx7_REPLACE_WITH_A_LONG_RANDOM_SECRET" \
  https://103.102.201.202:7010/healthz
```

Expected:
- `SSL certificate verify ok`
- HTTP status `200`

### 5.2 MCP endpoint to configure in clients

```text
https://103.102.201.202:7010/mcp
```

---

## Part 6: VS Code and Claude Code Notes

### VS Code / Claude Code trust model

Most Node-based apps rely on OS trust store. If trust still fails, launch with:

```bash
NODE_EXTRA_CA_CERTS=/path/to/mcp-ca.crt code
```

or

```bash
NODE_EXTRA_CA_CERTS=/path/to/mcp-ca.crt claude
```

Do not use `NODE_TLS_REJECT_UNAUTHORIZED=0` in normal operation.

---

## Part 7: Troubleshooting Quick Map

### Problem: `SSL certificate problem` / `unable to verify` on client

- CA not installed on client trust store
- wrong CA file
- app not restarted after trust change

Fix:
- reinstall `mcp-ca.crt` in global trust
- restart app
- use `NODE_EXTRA_CA_CERTS` as fallback

### Problem: TLS is good but request returns `403`

- API key mismatch

Fix:
- confirm exact key in container env
- avoid copy/paste mistakes
- rotate key and update both server/client config

### Problem: cert mismatch for IP/hostname

- SAN does not include the exact host you use in URL

Fix:
- reissue server certificate with correct SAN entries

---

## Part 8: Rotation and Good Hygiene

- Rotate API keys periodically.
- Rotate server certificate before expiry.
- If `mcp-ca.key` is ever exposed, create a new CA and reissue all server certs.
- Keep one shared CA for many MCP servers, but use unique `server.key`/`server.crt` per server.

---

## Friendly Final Checklist

On Host Server:
- [ ] `server.crt` exists and SAN includes host IP
- [ ] container runs with `ENABLE_HTTPS=true`
- [ ] API key set to a strong secret

On Client Machine:
- [ ] `mcp-ca.crt` installed globally
- [ ] app restarted after trust installation
- [ ] MCP URL uses `https://103.102.201.202:7010/mcp`
- [ ] correct Bearer token configured

If all boxes are checked, your MCP connection should be secure and stable.
