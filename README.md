# Tender Highball

> **Under construction.** This project is not yet deployed.

A self-hosted search relay that transforms SearXNG results into clean JSON for AI agents — the fuel that keeps the train running.

Built to power [Caboose](https://trycaboose.dev), but designed for anyone who wants a free, private alternative to Tavily, Exa or Brave Search.

---

## What it is

In railroad terms:

- **The Tender** is the car behind the locomotive that carries the fuel. This service carries the information that powers your LLM or AI agent.
- **The Highball** was the signal that meant *clear track ahead — proceed at full speed*. This service gives your agent the green light to move forward with real, factual data instead of guessing.

Technically: a self-hosted [SearXNG](https://github.com/searxng/searxng) instance exposed via Cloudflare Tunnel, returning clean JSON for AI agent consumption. No API key required on the consumer side.

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

A clean, stable JSON contract your agent can call without an API key or third-party account. Use it as a free alternative to Tavily or Brave Search, or as a fallback alongside them.

---

## Origin

Tender Highball was built as the search backend for [Caboose](https://trycaboose.dev) ([source](https://github.com/kahanscious/caboose)), a local-first AI coding assistant. Rather than lock it to that project, it's designed as a standalone relay any AI agent or LLM application can use.

---

## Why self-host?

- **No API costs** — runs on a Raspberry Pi 4 or any cheap VPS
- **Privacy** — your queries don't leave your infrastructure
- **No rate limits** — you control the ceiling
- **Portable** — `docker compose up` on any Linux box
