.PHONY: setup up down logs health restart

setup:
	@bash setup.sh

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f searxng

restart:
	docker compose down && docker compose up -d

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
