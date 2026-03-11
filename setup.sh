#!/usr/bin/env bash
set -euo pipefail

# ── colours ──────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${GREEN}[tender-highball]${NC} $*"; }
warn()    { echo -e "${YELLOW}[tender-highball]${NC} $*"; }
error()   { echo -e "${RED}[tender-highball]${NC} $*" >&2; }

# ── 1. prerequisite check ────────────────────────────────────────────────────
info "Checking prerequisites..."
MISSING=()
command -v docker       >/dev/null 2>&1 || MISSING+=("docker")
docker compose version  >/dev/null 2>&1 || MISSING+=("docker compose (plugin)")
command -v make         >/dev/null 2>&1 || MISSING+=("make")
command -v openssl      >/dev/null 2>&1 || MISSING+=("openssl")
command -v envsubst     >/dev/null 2>&1 || MISSING+=("envsubst (gettext)")

if [ ${#MISSING[@]} -gt 0 ]; then
  error "Missing required tools: ${MISSING[*]}"
  error "Install them and re-run setup."
  exit 1
fi
info "All prerequisites found."

# ── 2. collect inputs ────────────────────────────────────────────────────────
echo ""
info "Configure your deployment:"
echo ""

read -rp "  Public base URL (e.g. https://search.example.com): " SEARXNG_BASE_URL
[[ -z "$SEARXNG_BASE_URL" ]] && { error "Base URL is required."; exit 1; }

read -rp "  Cloudflare Tunnel token: " CLOUDFLARE_TUNNEL_TOKEN
[[ -z "$CLOUDFLARE_TUNNEL_TOKEN" ]] && { error "Tunnel token is required."; exit 1; }

read -rp "  Client User-Agent string (e.g. MyApp): " APP_USER_AGENT
[[ -z "$APP_USER_AGENT" ]] && { error "User-Agent string is required."; exit 1; }

# ── 3. generate secret key ───────────────────────────────────────────────────
SEARXNG_SECRET_KEY=$(openssl rand -hex 32)
info "Generated secret key."

# ── 4. write .env ────────────────────────────────────────────────────────────
# Note: heredoc content must be at column 0 (no leading spaces) so the written
# .env values don't have leading whitespace that could trip up dotenv parsers.
cat > .env <<EOF
SEARXNG_BASE_URL=${SEARXNG_BASE_URL}
SEARXNG_SECRET_KEY=${SEARXNG_SECRET_KEY}
CLOUDFLARE_TUNNEL_TOKEN=${CLOUDFLARE_TUNNEL_TOKEN}
APP_USER_AGENT=${APP_USER_AGENT}
EOF
info ".env written."

# ── 5. generate settings.yml from template ───────────────────────────────────
export SEARXNG_SECRET_KEY SEARXNG_BASE_URL
envsubst '$SEARXNG_SECRET_KEY $SEARXNG_BASE_URL' \
  < searxng/settings.yml.template \
  > searxng/settings.yml
info "searxng/settings.yml generated."

# ── 6. start the stack ───────────────────────────────────────────────────────
info "Starting containers..."
docker compose up -d

# ── 7. readiness probe (poll root until HTTP 200, max 30s) ───────────────────
info "Waiting for SearXNG to be ready..."
READY=false
for i in $(seq 1 30); do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ 2>/dev/null || true)
  if [ "$STATUS" = "200" ]; then
    READY=true
    break
  fi
  sleep 1
done

if [ "$READY" = "false" ]; then
  error "SearXNG did not become ready within 30 seconds."
  error "Check logs with: make logs"
  exit 1
fi

# ── 8. functional health check ───────────────────────────────────────────────
info "Running functional health check..."
rm -f /tmp/searxng_setup_check.json
HTTP_STATUS=$(curl -s -o /tmp/searxng_setup_check.json -w "%{http_code}" \
  "http://localhost:8080/search?q=test&format=json")

if [ "$HTTP_STATUS" != "200" ]; then
  error "Health check failed: HTTP $HTTP_STATUS"
  exit 1
fi

if ! grep -q '"results"' /tmp/searxng_setup_check.json; then
  error "Health check failed: response missing 'results' key"
  cat /tmp/searxng_setup_check.json
  exit 1
fi

echo ""
info "SearXNG is healthy and serving JSON."

# ── 9. cloudflare WAF instructions ───────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  NEXT STEP: Set up Cloudflare WAF rule"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Go to: https://dash.cloudflare.com → Your domain → Security → WAF"
echo "  Create a custom rule:"
echo ""
echo "    If:  Hostname equals $(echo "$SEARXNG_BASE_URL" | sed 's|https\?://||')"
echo "    AND: User-Agent does NOT contain \"${APP_USER_AGENT}\""
echo "    Then: Block"
echo ""
echo "  This prevents public bots from hitting your instance."
echo "  Make sure your client sets:  User-Agent: ${APP_USER_AGENT}"
echo ""

# ── 10. uptimerobot instructions ─────────────────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  OPTIONAL: Set up uptime monitoring"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Go to: https://uptimerobot.com/dashboard"
echo "  Add a new HTTP(s) monitor:"
echo ""
echo "    URL:             ${SEARXNG_BASE_URL}/search?q=test&format=json"
echo "    Expected status: 200"
echo "    Check interval:  5 minutes"
echo ""
echo "  Note: the WAF rule must be set up first, or UptimeRobot will be blocked."
echo "  Add UptimeRobot's IP ranges to an allowlist, or temporarily disable the WAF"
echo "  rule for the monitoring check path."
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
info "Setup complete. Run 'make health' at any time to verify the local stack."
