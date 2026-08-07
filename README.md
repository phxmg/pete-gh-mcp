# pete-gh-mcp

`github-mcp-server` (stdio) wrapped by `mcp-proxy` so it can be consumed over
SSE by the Home Assistant Model Context Protocol integration, which does not
speak stdio or streamable HTTP.

Tools are deliberately cherry-picked via `GITHUB_TOOLS` to keep the per-turn
prompt small - every tool schema is carried on every conversation turn,
including "turn off the lights".
