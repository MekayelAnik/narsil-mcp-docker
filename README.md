# Narsil MCP Server - Docker Image

<p align="center">
  <strong>Unofficial Multi-Architecture Docker Image for Narsil MCP Server</strong>
</p>

<p align="center">
  <a href="https://hub.docker.com/r/mekayelanik/narsil-mcp"><img alt="Docker Pulls" src="https://img.shields.io/docker/pulls/mekayelanik/narsil-mcp?style=flat-square&logo=docker"></a>
  <a href="https://hub.docker.com/r/mekayelanik/narsil-mcp"><img alt="Docker Stars" src="https://img.shields.io/docker/stars/mekayelanik/narsil-mcp?style=flat-square&logo=docker"></a>
  <a href="https://github.com/MekayelAnik/narsil-mcp-docker/pkgs/container/narsil-mcp"><img alt="GHCR" src="https://img.shields.io/badge/GHCR-ghcr.io%2Fmekayelanik%2Fnarsil-mcp-blue?style=flat-square&logo=github"></a>
  <a href="https://github.com/MekayelAnik/narsil-mcp-docker/blob/main/LICENSE"><img alt="License: GPL-3.0" src="https://img.shields.io/badge/License-GPL--3.0-blue?style=flat-square"></a>
  <a href="https://hub.docker.com/r/mekayelanik/narsil-mcp"><img alt="Platforms" src="https://img.shields.io/badge/Platforms-amd64%20%7C%20arm64-lightgrey?style=flat-square"></a>
  <a href="https://github.com/MekayelAnik/narsil-mcp-docker/stargazers"><img alt="GitHub Stars" src="https://img.shields.io/github/stars/MekayelAnik/narsil-mcp-docker?style=flat-square"></a>
  <a href="https://github.com/MekayelAnik/narsil-mcp-docker/forks"><img alt="GitHub Forks" src="https://img.shields.io/github/forks/MekayelAnik/narsil-mcp-docker?style=flat-square"></a>
  <a href="https://github.com/MekayelAnik/narsil-mcp-docker/issues"><img alt="GitHub Issues" src="https://img.shields.io/github/issues/MekayelAnik/narsil-mcp-docker?style=flat-square"></a>
  <a href="https://github.com/MekayelAnik/narsil-mcp-docker/commits/main"><img alt="Last Commit" src="https://img.shields.io/github/last-commit/MekayelAnik/narsil-mcp-docker?style=flat-square"></a>
</p>

## Overview

This is an unofficial, community-maintained Docker image that packages the [Narsil MCP Server](https://github.com/postrv/narsil-mcp) for containerized deployment. It enables AI agents (Claude Code, VS Code Copilot, Cursor, Windsurf, etc.) to perform deep code intelligence via the Model Context Protocol (MCP).

**Upstream:** [github.com/postrv/narsil-mcp](https://github.com/postrv/narsil-mcp) (MIT OR Apache-2.0)

### Key Features

- **Multi-Architecture Support** - Native support for x86-64 and ARM64
- **Multiple Transport Protocols** - Streamable HTTP, SSE, and WebSocket support (selectable via env var)
- **90 Code Intelligence Tools** - Symbol search, call graphs, security analysis, SBOM, and more
- **32 Language Support** - Rust, Python, TypeScript, Go, Java, C#, and 26 more via Tree-sitter
- **Secure by Design** - API key auth (case-insensitive Bearer), CORS, TLS termination, security headers
- **High Performance** - HAProxy with QUIC/HTTP3 support, ZSTD compression

### Available Narsil MCP Tool Categories

| Category | Examples |
|:---------|:--------|
| **Repository & File Management** | `list_repos`, `get_project_structure`, `get_file`, `reindex` |
| **Symbol Search & Navigation** | `find_symbols`, `get_symbol_definition`, `find_references` |
| **Code Search** | `search_code`, `semantic_search`, `hybrid_search`, `find_similar_code` |
| **Call Graph Analysis** | `get_call_graph`, `get_callers`, `get_callees`, `get_complexity` |
| **Security Analysis** | `find_injection_vulnerabilities`, `scan_security`, `check_owasp_top10` |
| **Supply Chain Security** | `generate_sbom`, `check_dependencies`, `check_licenses` |
| **Git Integration** | `get_blame`, `get_file_history`, `get_hotspots`, `get_contributors` |
| **Neural Semantic Search** | `neural_search`, `find_semantic_clones` |
| **Type Inference** | `infer_types`, `check_type_errors` |
| **Data Flow Analysis** | `get_data_flow`, `find_dead_code`, `find_dead_stores` |
| **SPARQL / Knowledge Graph** | `sparql_query`, `get_ccg_manifest`, `export_ccg` |

---

## Buy Me a Coffee
**Your support encourages me to keep creating/supporting my open-source projects.** If you found value in this project, you can buy me a coffee to keep me inspired.

<p align="center">
<a href="https://07mekayel07.gumroad.com/coffee" target="_blank">
<img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" width="217" height="60">
</a>
</p>

## Quick Start

### Prerequisites

- **Docker Engine:** 23.0+

> **CRITICAL:** Do NOT expose this container directly to the internet without proper security measures (reverse proxy, SSL/TLS, authentication, firewall rules).

---

### Docker Compose (Recommended)

```yaml
services:
  narsil-mcp:
    image: mekayelanik/narsil-mcp:latest
    container_name: narsil-mcp
    restart: unless-stopped
    ports:
      - "8010:8010"
    volumes:
      - /path/to/your/repos:/data:ro
    environment:
      - PORT=8010
      - INTERNAL_PORT=38011
      - PUID=1000
      - PGID=1000
      - TZ=UTC
      - NODE_ENV=production
      - PROTOCOL=SHTTP
      - ENABLE_HTTPS=false
      - HTTP_VERSION_MODE=auto
      - DATA_DIR=/data
      - NARSIL_GIT=true
      - NARSIL_CALL_GRAPH=true
      - NARSIL_PERSIST=true
      - NARSIL_STREAMING=true
      # Optional: Neural semantic search
      # - NARSIL_NEURAL=true
      # - VOYAGE_API_KEY=your-voyage-key
      # Optional: require Bearer token auth at HAProxy layer
      # - API_KEY=replace-with-strong-secret
      # Optional: CORS origins
      # - CORS=*
```

### Docker Run

```bash
docker run -d \
  --name=narsil-mcp \
  --restart=unless-stopped \
  -p 8010:8010 \
  -v /path/to/your/repos:/data:ro \
  -e PORT=8010 \
  -e PROTOCOL=SHTTP \
  -e NARSIL_GIT=true \
  -e NARSIL_CALL_GRAPH=true \
  -e NARSIL_PERSIST=true \
  mekayelanik/narsil-mcp:latest
```

### Access Endpoints

| Service | Endpoint | Description |
|:--------|:---------|:------------|
| **MCP (SHTTP)** | `http://host-ip:8010/mcp` | Streamable HTTP MCP endpoint (recommended) |
| **MCP (SSE)** | `http://host-ip:8010/sse` | Server-Sent Events MCP endpoint |
| **MCP (WS)** | `ws://host-ip:8010/message` | WebSocket MCP endpoint |
| **Health** | `http://host-ip:8010/healthz` | Health check endpoint |

When HTTPS is enabled (`ENABLE_HTTPS=true`), use TLS endpoints:

| Service | Endpoint |
|:--------|:---------|
| **MCP (SHTTP)** | `https://host-ip:8010/mcp` |
| **MCP (SSE)** | `https://host-ip:8010/sse` |
| **MCP (WS)** | `wss://host-ip:8010/message` |

> **Security Warning:** The container defaults to HTTP (`ENABLE_HTTPS=false`) for easier local setup. Use `ENABLE_HTTPS=true` with your own certificates for production. See [CERTIFICATE_SETUP_GUIDE.md](CERTIFICATE_SETUP_GUIDE.md) for instructions.

---

## Configuration

### Complete Environment Variables Reference

#### Core Settings

| Variable | Default | Possible Values | Description |
|:---------|:-------:|:----------------|:------------|
| `PORT` | `8010` | `1`-`65535` | External HAProxy listening port |
| `INTERNAL_PORT` | `38011` | `1`-`65535` | Internal supergateway port (do not expose) |
| `PROTOCOL` | `SHTTP` | `SHTTP`, `SSE`, `WS` | MCP transport protocol |
| `PUID` | `1000` | Any valid UID | Process user ID |
| `PGID` | `1000` | Any valid GID | Process group ID |
| `TZ` | `UTC` | Any timezone | Container timezone |
| `NODE_ENV` | *(empty)* | `production`, etc. | Node.js environment |
| `DATA_DIR` | `/data` | Any path | Directory for mounted repositories |

#### Narsil MCP Feature Flags

| Variable | Default | Possible Values | Description |
|:---------|:-------:|:----------------|:------------|
| `NARSIL_GIT` | `false` | `true`, `false` | Enable git blame, history, contributors |
| `NARSIL_CALL_GRAPH` | `false` | `true`, `false` | Enable function call graph analysis |
| `NARSIL_PERSIST` | `false` | `true`, `false` | Save index to disk for fast startup |
| `NARSIL_WATCH` | `false` | `true`, `false` | Auto-reindex on file changes |
| `NARSIL_LSP` | `false` | `true`, `false` | Enable LSP for hover, go-to-definition |
| `NARSIL_STREAMING` | `false` | `true`, `false` | Stream large result sets |
| `NARSIL_REMOTE` | `false` | `true`, `false` | Enable GitHub remote repo support |
| `NARSIL_NEURAL` | `false` | `true`, `false` | Enable neural semantic embeddings |
| `NARSIL_GRAPH` | `false` | `true`, `false` | Enable SPARQL/RDF knowledge graph and CCG tools |
| `NARSIL_VERBOSE` | `false` | `true`, `false` | Enable verbose logging |
| `NARSIL_REINDEX` | `false` | `true`, `false` | Force re-index on startup (once per container lifecycle) |
| `NARSIL_HTTP` | `false` | `true`, `false` | Enable visualization frontend HTTP server |

#### Narsil MCP String Settings

| Variable | Default | Possible Values | Description |
|:---------|:-------:|:----------------|:------------|
| `NARSIL_NEURAL_BACKEND` | *(empty)* | `api`, `onnx` | Neural embedding backend |
| `NARSIL_NEURAL_MODEL` | *(empty)* | `voyage-code-2`, `text-embedding-3-large`, etc. | Neural model to use |
| `NARSIL_NEURAL_DIMENSION` | *(empty)* | Integer (e.g. `3072`) | Override embedding dimensions |
| `NARSIL_PRESET` | *(empty)* | `minimal`, `balanced`, `full`, `security-focused` | Tool preset profile |
| `NARSIL_ENABLED_CATEGORIES` | *(empty)* | Comma-separated | Enable specific tool categories |
| `NARSIL_DISABLED_TOOLS` | *(empty)* | Comma-separated | Disable specific tools |

#### Neural Embedding API Keys

| Variable | Default | Description |
|:---------|:-------:|:------------|
| `EMBEDDING_API_KEY` | *(empty)* | Generic API key for any embedding provider |
| `VOYAGE_API_KEY` | *(empty)* | Voyage AI specific API key |
| `OPENAI_API_KEY` | *(empty)* | OpenAI specific API key |
| `EMBEDDING_SERVER_ENDPOINT` | *(empty)* | Custom embedding API endpoint URL |

#### Narsil MCP Presets

| Preset | Tools | Description |
|:-------|:-----:|:------------|
| `minimal` | 26 | Fast, lightweight (Zed, Cursor) |
| `balanced` | 51 | Good defaults (VS Code, IntelliJ) |
| `full` | 75+ | All features (Claude Desktop, comprehensive analysis) |
| `security-focused` | varies | Security and supply chain tools |

#### Security Settings

| Variable | Default | Possible Values | Description |
|:---------|:-------:|:----------------|:------------|
| `API_KEY` | *(empty)* | 5-256 printable chars | Bearer token for HAProxy authentication |
| `CORS` | *(empty)* | Origins (comma-separated) or `*` | Allowed CORS origins |
| `ENABLE_HTTPS` | `false` | `true`, `false` | Enable TLS termination |
| `TLS_CERT_PATH` | `/etc/haproxy/certs/server.crt` | File path | TLS certificate path |
| `TLS_KEY_PATH` | `/etc/haproxy/certs/server.key` | File path | TLS private key path |
| `TLS_MIN_VERSION` | `TLSv1.3` | `TLSv1.2`, `TLSv1.3` | Minimum TLS version |
| `HTTP_VERSION_MODE` | `auto` | `auto`, `h1`, `h2`, `h3`, `h1+h2`, `all` | HTTP version negotiation |

> **Boolean values:** `true`, `1`, `yes`, `on` are all accepted as truthy. Everything else is falsy.

> **Once per container lifecycle:** `NARSIL_REINDEX` runs only once after the container is created. It is skipped on subsequent restarts (e.g., crash recovery, `docker restart`). To re-trigger, recreate the container (`docker compose down && docker compose up -d`).

#### One-Shot Operations

For ad-hoc operations without setting env vars, use `docker exec`:

```bash
docker exec narsil-mcp narsil-mcp --repos /data --reindex   # Force full re-index
```

---

## Mounting Repositories for Analysis

Mount your repository directories to `/data` (or the path specified by `DATA_DIR`). Each subdirectory becomes an indexable repository.

```yaml
volumes:
  # Mount entire projects directory
  - /home/user/projects:/data:ro
  # Or mount individual repositories
  - /home/user/my-rust-app:/data/my-rust-app:ro
  - /home/user/my-node-app:/data/my-node-app:ro
```

Then tell your AI agent to analyze using the mounted path:
- "Search for symbols in `/data/my-rust-app`"
- "Find injection vulnerabilities in `/data/my-node-app`"
- "Generate an SBOM for `/data/my-rust-app`"
- "Get the call graph for `main` in `/data/my-node-app`"

---

## MCP Client Configuration

### Claude Code

Add to `~/.claude.json` under `mcpServers`:

```json
{
  "mcpServers": {
    "narsil": {
      "type": "sse",
      "url": "http://host-ip:8010/sse"
    }
  }
}
```

Or for Streamable HTTP:

```json
{
  "mcpServers": {
    "narsil": {
      "type": "http",
      "url": "http://host-ip:8010/mcp"
    }
  }
}
```

### VS Code / Codex / Cursor / Windsurf

All use the same JSON format. Configure in the respective config file:
- **VS Code**: `.vscode/settings.json` (key: `mcp.servers`)
- **Codex**: `~/.codex/config.json` (key: `mcpServers`)
- **Cursor**: `~/.cursor/mcp.json` (key: `mcpServers`)
- **Windsurf**: `.codeium/mcp_settings.json` (key: `mcpServers`)

```json
{
  "mcpServers": {
    "narsil": {
      "transport": "http",
      "url": "http://host-ip:8010/mcp"
    }
  }
}
```

---

## Available Tags

| Tag | Platform | Description |
|:----|:---------|:------------|
| `latest` | `amd64`, `arm64` | Latest stable release |
| `1.6.1` | `amd64`, `arm64` | Specific version |

---

## License

This Docker image packaging is licensed under the [GNU General Public License v3.0](LICENSE).

### Upstream Licenses

- **Narsil MCP Server**: [MIT License](https://github.com/postrv/narsil-mcp/blob/main/LICENSE-MIT) OR [Apache License 2.0](https://github.com/postrv/narsil-mcp/blob/main/LICENSE-APACHE) - Copyright (c) 2024 postrv
- **Supergateway**: MIT License
- **HAProxy**: GNU General Public License v2.0

This is an **unofficial** community packaging. It is NOT affiliated with, endorsed by, or supported by the narsil-mcp authors. See [NOTICE](NOTICE) for full attribution.

---

## Buy Me a Coffee
**Your support encourages me to keep creating/supporting my open-source projects.** If you found value in this project, you can buy me a coffee to keep me inspired.

<p align="center">
  <a href="https://07mekayel07.gumroad.com/coffee" target="_blank">
    <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" width="217" height="60">
  </a>
</p>

---

## Maintainer

**Mohammad Mekayel Anik**

- Docker Hub: [mekayelanik](https://hub.docker.com/u/mekayelanik)
- GitHub: [MekayelAnik](https://github.com/MekayelAnik)
