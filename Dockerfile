FROM python:3.12-slim

ARG GH_MCP_VERSION=1.8.0
RUN apt-get update \
 && apt-get install -y --no-install-recommends curl ca-certificates \
 && curl -fsSL -o /tmp/gh.tgz \
      https://github.com/github/github-mcp-server/releases/download/v${GH_MCP_VERSION}/github-mcp-server_Linux_x86_64.tar.gz \
 && tar -xzf /tmp/gh.tgz -C /usr/local/bin github-mcp-server \
 && chmod +x /usr/local/bin/github-mcp-server \
 && rm -rf /tmp/gh.tgz /var/lib/apt/lists/* \
 && apt-get purge -y curl && apt-get autoremove -y

RUN pip install --no-cache-dir mcp-proxy==0.12.0

EXPOSE 8931

# mcp-proxy runs the GitHub server over stdio and exposes it as SSE, which is
# the only transport Home Assistant's MCP client speaks.
ENTRYPOINT ["mcp-proxy", "--pass-environment", "--sse-port=8931", "--sse-host=0.0.0.0", "--", "github-mcp-server", "stdio"]
