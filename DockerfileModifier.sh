#!/bin/bash
set -euxo pipefail
# Set variables first
REPO_NAME='narsil-mcp'
BASE_IMAGE=$(cat ./build_data/base-image 2>/dev/null || echo "ghcr.io/mekayelanik/base-images/node:current-trixie-slim")
HAPROXY_IMAGE=$(cat ./build_data/haproxy-image 2>/dev/null || echo "haproxy:lts")
NARSIL_VERSION=$(cat ./build_data/version 2>/dev/null || exit 1)
RUST_BASE_IMAGE=$(cat ./build_data/rust-image 2>/dev/null || echo "ghcr.io/mekayelanik/base-images/rust:slim-trixie")
NARSIL_REPO='postrv/narsil-mcp'
SUPERGATEWAY_PKG='supergateway@latest'
DOCKERFILE_NAME="Dockerfile.$REPO_NAME"

# ── Determine Cargo feature set based on narsil-mcp version ──
# Upstream feature availability:
#   - frontend:    v1.0.0+   (embedded Vite UI)
#   - neural:      v1.0.0+   (usearch + ndarray)
#   - neural-onnx: v1.0.0+   (neural + ort + tokenizers)
#   - graph:       v1.3.0+   (oxigraph SPARQL/RDF + CCG)
# Earlier versions will fail with:
#   "error: the package 'narsil-mcp' does not contain this feature: graph"
# so we gate `graph` on >=1.3.0.
case "$NARSIL_VERSION" in
    1.0.*|1.1.*|1.2.*)
        NARSIL_FEATURES="frontend,neural-onnx"
        ;;
    *)
        NARSIL_FEATURES="frontend,graph,neural-onnx"
        ;;
esac
echo "Selected Cargo features for narsil-mcp v${NARSIL_VERSION}: ${NARSIL_FEATURES}"

# Create a temporary file safely
TEMP_FILE=$(mktemp "${DOCKERFILE_NAME}.XXXXXX") || {
    echo "Error creating temporary file" >&2
    exit 1
}

# Check if this is a publication build
if [ -e ./build_data/publication ]; then
    # For publication builds, create a minimal Dockerfile that just tags the existing image
    {
        echo "ARG BASE_IMAGE=$BASE_IMAGE"
        echo "ARG NARSIL_VERSION=$NARSIL_VERSION"
        echo "FROM $BASE_IMAGE"
    } > "$TEMP_FILE"
else
    # Write the Dockerfile content to the temporary file first
    {
        echo "ARG BASE_IMAGE=$BASE_IMAGE"
        echo "ARG NARSIL_VERSION=$NARSIL_VERSION"
        cat << EOF
FROM $HAPROXY_IMAGE AS haproxy-src
FROM $BASE_IMAGE AS node-src

# ── Rust build stage: compile narsil-mcp with embedded frontend ──
FROM $RUST_BASE_IMAGE AS rust-builder
RUN apt-get update && \\
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \\
    git ca-certificates pkg-config libssl-dev build-essential cmake && \\
    rm -rf /var/lib/apt/lists/*
# Copy Node.js from base image (need modern Node for Vite frontend build)
COPY --from=node-src /usr/local/bin/node /usr/local/bin/node
COPY --from=node-src /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -sf /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm && \\
    ln -sf /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx
WORKDIR /build
RUN git clone --depth 1 --branch v${NARSIL_VERSION} https://github.com/${NARSIL_REPO}.git .
# Build frontend assets (embedded into binary via rust-embed)
RUN cd frontend && npm install --no-audit --no-fund && npm run build
# Compile release binary with all non-default compile-time features:
#   - frontend    : embedded Vite visualization UI (implies 'native': LSP,
#                   call-graph, remote/octocrab, watch/notify, streaming, axum)
#   - graph       : SPARQL/RDF knowledge graph + CCG (oxigraph + flate2).
#                   Without this, NARSIL_GRAPH=true logs "binary was built
#                   without the 'graph' feature" and SPARQL/CCG tools vanish.
#   - neural-onnx : local ONNX-based embedding backend (implies 'neural':
#                   usearch + ndarray vector search). Enables
#                   NARSIL_NEURAL=true with NARSIL_NEURAL_BACKEND=onnx
#                   (no VOYAGE_API_KEY required). Pulls ort + tokenizers.
# 'wasm' is deliberately excluded — it's browser-only and mutually exclusive
# with the native runtime.
RUN --mount=type=cache,target=/usr/local/cargo/registry \\
    --mount=type=cache,target=/build/target \\
    cargo build --release --features ${NARSIL_FEATURES} && \\
    cp target/release/narsil-mcp /usr/local/bin/narsil-mcp

# ── Final runtime stage ──
FROM $BASE_IMAGE AS build

# Author info:
LABEL org.opencontainers.image.authors="MOHAMMAD MEKAYEL ANIK <mekayel.anik@gmail.com>"
LABEL org.opencontainers.image.description="Narsil MCP Server - Deep Code Intelligence for AI Agents"
LABEL org.opencontainers.image.source="https://github.com/mekayelanik/narsil-mcp-docker"
LABEL org.opencontainers.image.licenses="GPL-3.0-only"

# Copy the entrypoint script into the container and make it executable
COPY ./resources/ /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/banner.sh \\
    && if [ -f /usr/local/bin/build-timestamp.txt ]; then chmod +r /usr/local/bin/build-timestamp.txt; fi \\
    && mkdir -p /etc/haproxy \\
    && mv -vf /usr/local/bin/haproxy.cfg.template /etc/haproxy/haproxy.cfg.template \\
    && ls -la /etc/haproxy/haproxy.cfg.template

# Install runtime packages
RUN apt-get update && \\
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \\
    bash haproxy gosu netcat-openbsd openssl ca-certificates iproute2 tzdata git wget procps && \\
    rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man /usr/share/info /usr/share/locale /usr/share/lintian

# HAProxy with native QUIC/H3 support from official image
COPY --from=haproxy-src /usr/local/sbin/haproxy /usr/sbin/haproxy
RUN mkdir -p /usr/local/sbin && ln -sf /usr/sbin/haproxy /usr/local/sbin/haproxy

# Copy narsil-mcp binary from Rust builder (includes embedded frontend)
COPY --from=rust-builder /usr/local/bin/narsil-mcp /usr/local/bin/narsil-mcp
RUN chmod +x /usr/local/bin/narsil-mcp

# Install Supergateway
RUN --mount=type=cache,target=/root/.npm \\
    echo "Installing Supergateway..." && \\
    npm install -g ${SUPERGATEWAY_PKG} --omit=dev --no-audit --no-fund --loglevel error && \\
    rm -rf /tmp/* /var/tmp/* && \\
    rm -rf /usr/local/lib/node_modules/npm/man /usr/local/lib/node_modules/npm/docs /usr/local/lib/node_modules/npm/html && \\
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# Create default data directory for repository mounting and state directory for lifecycle sentinels
RUN mkdir -p /data /state && chown node:node /data /state

# Use an ARG for the default port
ARG PORT=8010

# Add ARG for API key
ARG API_KEY=""

# NVIDIA GPU support (used when host passes --gpus or NVIDIA container runtime)
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all

# Set an ENV variable from the ARG for runtime
ENV PORT=\${PORT}
ENV API_KEY=\${API_KEY}
ENV DATA_DIR=/data

# L7 health check: auto-detects HTTP/HTTPS via ENABLE_HTTPS env var.
# start-period is generous because the entrypoint now blocks HAProxy startup
# until narsil finishes initial repo indexing (WAIT_FOR_INDEX=true by default,
# INDEX_READY_TIMEOUT=300s). Tune via INDEX_READY_TIMEOUT at runtime.
HEALTHCHECK --interval=30s --timeout=10s --start-period=450s --retries=3 \\
    CMD sh -c 'wget -q --spider --no-check-certificate \$([ "\$ENABLE_HTTPS" = "true" ] && echo https || echo http)://127.0.0.1:\${PORT:-8010}/healthz'

# Set the entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

EOF
    } > "$TEMP_FILE"
fi

# Atomically replace the target file with the temporary file
if mv -f "$TEMP_FILE" "$DOCKERFILE_NAME"; then
    echo "Dockerfile for $REPO_NAME created successfully."
else
    echo "Error: Failed to create Dockerfile for $REPO_NAME" >&2
    rm -f "$TEMP_FILE"
    exit 1
fi
