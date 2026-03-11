# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

**tender-highball** is a private Docker-based infrastructure project — a self-hosted SearXNG search relay exposed via Cloudflare Tunnel at `search.trycaboose.dev`. It serves as the zero-config built-in web search backend for the [Caboose](../caboose) AI project.

This is not a Rust or Node.js source code project. It is a configuration-as-code service with two primary files:
- `docker-compose.yml` — orchestrates SearXNG, cloudflared, and Redis containers
- `searxng/settings.yml.template` — SearXNG config template; `setup.sh` runs `envsubst` to produce the gitignored `settings.yml`
- `Makefile` — all operator commands (`make setup`, `make up`, `make health`, etc.)
- `setup.sh` — first-time setup wizard (collects config, generates secrets, starts stack)

The full specification lives in `SPEC.md` (gitignored, local only).

## Commands

```bash
# First-time setup (interactive wizard)
make setup

# Start / stop
make up
make down

# Verify the search endpoint is working
make health

# Tail SearXNG logs
make logs

# Restart all containers
make restart
```

## Architecture

```
[Caboose Rust client]
  → reqwest with User-Agent: "Caboose/1.0 (SearchService)"
  → https://search.trycaboose.dev (Cloudflare Tunnel)
    → cloudflared container
      → searxng:8080 container
        → Redis cache (redis:6379)
        → upstream: Google, Bing, DuckDuckGo
```

**API contract** (what Caboose calls):
```
GET /search?q={query}&format=json&language=en
```
Returns `{ "results": [{ "title", "url", "content" }] }`.

## Key configuration notes

- `public_instance: false` in settings.yml — this is private
- `real_ip_header: "CF-Connecting-IP"` is required for Cloudflare Tunnel to pass real IPs
- Redis caching prevents repeated hits to Google/Bing and reduces rate-limiting risk
- The Cloudflare WAF rule blocks requests where User-Agent doesn't contain `APP_USER_AGENT` — whatever client calls this must set this header
- Cloudflare Tunnel token goes in `.env` (written by `setup.sh`, never hardcoded)
- `searxng/settings.yml` requires a randomly generated `secret_key`


## Writing Style

### Commit Messages
- lowercase, no period
- short and direct — describe what changed, not why
- e.g. `circuits data model and sqlite storage`, `scm provider detection from git remotes`

### Pull Requests
- title: lowercase, brief, use em dash to separate scope from summary if needed
- body: lowercase, short bullet points, bold for section/feature names, no filler
- no "## Test plan" or checklist boilerplate — just say what's in the PR

### Attribution
- never add `Co-Authored-By` lines mentioning Claude or any AI
- commit messages can reference product names (e.g. "claude code config reader") when relevant to the actual change
