.PHONY: setup up down logs health restart

COMPOSE := $(shell if docker compose version >/dev/null 2>&1; then echo "docker compose"; elif command -v docker-compose >/dev/null 2>&1; then echo "docker-compose"; fi)

ifndef COMPOSE
$(error Docker Compose is required. Install the `docker compose` plugin or the `docker-compose` binary.)
endif

setup:
	@bash setup.sh

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

logs:
	$(COMPOSE) logs -f searxng

restart:
	$(COMPOSE) down && $(COMPOSE) up -d

health:
	@echo "Checking SearXNG health..."
	@rm -f /tmp/searxng_health.json; \
	STATUS=$$(curl -s -o /tmp/searxng_health.json -w "%{http_code}" \
		"http://localhost:8080/search?q=test&format=json"); \
	if [ "$$STATUS" != "200" ]; then \
		echo "FAIL: HTTP $$STATUS (expected 200)"; \
		exit 1; \
	fi; \
	if ! grep -q '"results"' /tmp/searxng_health.json; then \
		echo "FAIL: response missing 'results' key"; \
		cat /tmp/searxng_health.json; \
		exit 1; \
	fi; \
	echo "PASS: SearXNG is healthy"
