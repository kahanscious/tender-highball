# Tender Highball

A self-hosted search relay built on SearXNG, exposed through Cloudflare Tunnel, and ready to serve JSON search results to AI agents and other applications.

Originally designed as the always-on search backend for [Caboose](https://trycaboose.dev), but applicable to any app that needs a private, self-hosted web search backend.

---

## What it is

In railroad terms:

- **The Tender** is the car behind the locomotive that carries the fuel. This service carries the information that powers your LLM or AI agent.
- **The Highball** was the signal that meant *clear track ahead — proceed at full speed*. This service gives your agent the green light to move forward with real, factual data instead of guessing.

Technically: a self-hosted [SearXNG](https://github.com/searxng/searxng) instance exposed via Cloudflare Tunnel, returning SearXNG's native JSON search responses over a stable endpoint. No API key required on the consumer side.

---

## Stack

- **SearXNG** — open source meta-search engine (aggregates Google, Bing, DuckDuckGo)
- **Docker + Docker Compose** — containerized deployment
- **Cloudflare Tunnel** — secure public exposure, no port forwarding or static IP needed
- **Redis** — result caching to reduce upstream rate-limiting

---

## API

```
GET https://{your-domain}/search?q={query}&format=json&language=en
```

```json
{
  "results": [
    {
      "title": "...",
      "url": "...",
      "content": "..."
    }
  ]
}
```

A clean, stable JSON contract your application can call without an API key or third-party account. Use it as a free alternative to Tavily or Brave Search, or as a fallback alongside them.

---

## Getting started

For a first test, run Tender Highball on a MacBook, Linux machine, or WSL distro with Docker access. For a real always-on deployment, use a Raspberry Pi, mini PC, or VPS.

### Local smoke test

Prerequisites:

- Docker Desktop or Docker Engine running, with either the Compose plugin (`docker compose`) or legacy binary (`docker-compose`)
- `bash`, `make`, `openssl`, `curl`, `git`
- `envsubst` from GNU `gettext`

Create a local `.env` and generate `searxng/settings.yml`:

```bash
cat > .env <<EOF
SEARXNG_BASE_URL=http://localhost:8080
SEARXNG_SECRET_KEY=$(openssl rand -hex 32)
CLOUDFLARE_TUNNEL_TOKEN=local-placeholder
APP_USER_AGENT="Caboose/1.0 (SearchService)"
EOF

export SEARXNG_BASE_URL=http://localhost:8080
export SEARXNG_SECRET_KEY="$(grep '^SEARXNG_SECRET_KEY=' .env | cut -d= -f2-)"

envsubst '$SEARXNG_SECRET_KEY $SEARXNG_BASE_URL' \
  < searxng/settings.yml.template \
  > searxng/settings.yml
```

Start only Redis and SearXNG for the local test:

```bash
docker compose up -d redis searxng
docker compose ps
make health
curl "http://localhost:8080/search?q=hello&format=json&language=en"
```

If your machine has the legacy Compose binary instead of the plugin, replace `docker compose` with `docker-compose` in the commands above.

You are up when `make health` passes and the `curl` response contains a `results` array.

Stop the local stack:

```bash
docker compose down
```

If needed, use `docker-compose down` on older Docker installs.

### Raspberry Pi deployment

On a Pi 5 or other always-on Linux host:

1. Install Docker Engine plus either the Docker Compose plugin or `docker-compose`, along with `make`, `openssl`, `curl`, `git`, and `gettext`/`envsubst`.
2. Clone this repo onto the machine.
3. Run `make setup`.
4. Provide your public base URL, Cloudflare Tunnel token, and the `User-Agent` string your app will send.
5. Run `make health` after setup completes.
6. Verify the endpoint from another machine with `https://your-domain/search?q=test&format=json&language=en`.

### Cloudflare setup

1. Create a Cloudflare Tunnel and add a public hostname such as `search.trycaboose.dev`.
2. Point that hostname at `http://searxng:8080`.
3. Set a WAF rule that blocks requests whose `User-Agent` does not contain your chosen app identifier.
4. Make sure your client sends that same `User-Agent` on every request.

---

## Using with Caboose

Caboose has built-in web search support. For quick local use, Caboose's `/search-setup` command spins up its own SearXNG instance with zero configuration. Tender Highball is for when you want an always-on deployment that persists across reboots, runs on a separate machine, or is accessible remotely.

### Setup

1. Deploy Tender Highball on your server (see [Getting started](#getting-started) above)
2. Verify it's working: `curl "https://your-domain/search?q=test&format=json"`
3. Add this to your Caboose config (`~/.config/caboose/config.toml` on Linux, `~/Library/Application Support/caboose/config.toml` on macOS):

```toml
[services.web_search]
provider = "searxng"
base_url = "https://your-domain"
```

4. Restart Caboose. The agent will now use your Tender Highball instance for all web searches.

### Local network

If Tender Highball runs on your local network without Cloudflare Tunnel, use the local IP:

```toml
[services.web_search]
provider = "searxng"
base_url = "http://192.168.1.100:8080"
```

### When to use which

| | `/search-setup` | Tender Highball |
|---|---|---|
| Setup | One command | Clone + deploy |
| Persistence | Stops with Docker | Always-on |
| Access | localhost only | Local network or internet |
| Cloudflare Tunnel | No | Yes |
| Redis caching | No | Yes |
| WAF protection | No | Yes |
| Best for | Development | Production / shared use |

---

## Origin

Tender Highball was originally built as the search backend for [Caboose](https://trycaboose.dev) ([source](https://github.com/kahanscious/caboose)), a terminal-native AI coding agent. The project is intentionally standalone so other AI agents, coding assistants, and search-enabled applications can use it without depending on Caboose.

---

## Why self-host?

- **No API costs** — runs on a Raspberry Pi 4 or any cheap VPS
- **Privacy** — your queries don't leave your infrastructure
- **No rate limits** — you control the ceiling
- **Portable** — runs with `docker compose` or `docker-compose` on any Linux box
