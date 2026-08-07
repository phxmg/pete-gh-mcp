#!/bin/sh
set -e
github-mcp-server http --port 8082 --listen-host 127.0.0.1 &
sleep 2
exec node /app/proxy.js
