// Header-injecting reverse proxy for github-mcp-server's native HTTP mode.
// http mode is multi-tenant: it wants Authorization per request. Home
// Assistant's MCP client cannot send custom headers, so we terminate for it
// here on the LAN and inject the PAT. Streams both directions untouched so
// text/event-stream responses pass through without buffering.
const http = require('http');
const TOKEN = process.env.GITHUB_PERSONAL_ACCESS_TOKEN;
const UPSTREAM_PORT = 8082;

http.createServer((req, res) => {
  if (req.url === '/healthz') { res.writeHead(200); return res.end('ok'); }
  const headers = Object.assign({}, req.headers, {
    authorization: 'Bearer ' + TOKEN,
    host: '127.0.0.1:' + UPSTREAM_PORT,
  });
  delete headers['accept-encoding'];           // never let a proxy buffer SSE
  console.log(new Date().toISOString(), req.method, req.url,
              'accept=' + (req.headers.accept || '-'),
              'sid=' + (req.headers['mcp-session-id'] || '-'));
  const up = http.request(
    { host: '127.0.0.1', port: UPSTREAM_PORT, path: req.url,
      method: req.method, headers }, r => {
      console.log('   <-', r.statusCode, r.headers['content-type'] || '-');
      res.writeHead(r.statusCode, r.headers);
      r.pipe(res);
    });
  up.on('error', e => {
    console.log('   !! upstream error', e.message);
    if (!res.headersSent) res.writeHead(502);
    res.end(JSON.stringify({ error: String(e) }));
  });
  req.pipe(up);
}).listen(8931, '0.0.0.0', () => console.log('proxy listening on 8931 -> 8082'));
