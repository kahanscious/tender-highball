# Tender Highball

> **Under construction.** This project is not yet deployed.

A self-hosted search relay built on SearXNG, exposed through Cloudflare Tunnel, and ready to serve JSON search results to AI agents and other applications.

Originally designed as a search add-on for [Caboose](https://trycaboose.dev), but applicable to any app that needs a private, self-hosted web search backend.

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

## Origin

Tender Highball was first built to plug into [Caboose](https://trycaboose.dev) ([source](https://github.com/kahanscious/caboose)), a local-first AI coding assistant. The project is intentionally standalone so other AI agents, coding assistants, and search-enabled applications can adapt it without depending on Caboose.

---

## Why self-host?

- **No API costs** — runs on a Raspberry Pi 4 or any cheap VPS
- **Privacy** — your queries don't leave your infrastructure
- **No rate limits** — you control the ceiling
- **Portable** — `docker compose up` on any Linux box
