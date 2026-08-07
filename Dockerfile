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
RUN npm install -g supergateway@latest

EXPOSE 8931

# HA's MCP client speaks SSE only; github-mcp-server speaks stdio only.
# supergateway bridges the two. GITHUB_TOOLS cherry-picks 4 tools out of 44 -
# every tool schema rides along on every conversation turn, so this matters.
ENTRYPOINT ["supergateway", "--stdio", "github-mcp-server stdio", \
            "--port", "8931", "--ssePath", "/sse", "--messagePath", "/message", \
            "--healthEndpoint", "/healthz"]
