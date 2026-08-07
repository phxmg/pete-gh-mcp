FROM node:22-slim

ARG GH_MCP_VERSION=1.8.0
ARG TARGETARCH=amd64

RUN apt-get update \
 && apt-get install -y --no-install-recommends curl ca-certificates \
 && case "$TARGETARCH" in \
      arm64) GHARCH=arm64 ;; \
      *)     GHARCH=x86_64 ;; \
    esac \
 && curl -fsSL -o /tmp/gh.tgz \
      "https://github.com/github/github-mcp-server/releases/download/v${GH_MCP_VERSION}/github-mcp-server_Linux_${GHARCH}.tar.gz" \
 && tar -xzf /tmp/gh.tgz -C /usr/local/bin github-mcp-server \
 && chmod +x /usr/local/bin/github-mcp-server \
 && rm -f /tmp/gh.tgz \
 && apt-get purge -y curl && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*

# Pre-install the bridge so container start is not blocked on a network fetch.

WORKDIR /app
COPY proxy.js /app/proxy.js
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

EXPOSE 8931

# HA 2026.7's MCP client speaks streamable HTTP only -- its SSE fallback is
# unreachable because nested ExceptionGroups hide the McpError. So we serve
# the official github-mcp-server HTTP transport and inject auth in front of it.
ENTRYPOINT ["/app/entrypoint.sh"]
