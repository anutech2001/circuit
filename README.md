# Circuit Breaker Demo 🔧

This repository contains a small demo that shows how Resilience4j circuit breaker, retry, time limiter and bulkhead interact with an external API and how to observe them using Prometheus + Grafana.

## Quick overview ✅
- `external-mock-service` — simple mock service exposing `/external/*` endpoints (OK, slow, timeout, error).
- `adapter-service` — calls the external service using Resilience4j annotations and exposes an `/adapter/{mode}` endpoint.
- `monitoring` — Prometheus + Grafana (and Mailhog) used to scrape and visualize metrics.

## Prerequisites 💡
- Docker & Docker Compose (for Prometheus/Grafana)
- Java 21 and Maven (or use the included `./mvnw` wrappers)
- macOS: Docker provides `host.docker.internal` (used by `prometheus.yml`) — if not, see Troubleshooting below.

## Ports used 🔌
- external mock service: http://localhost:8080
- adapter service: http://localhost:8081
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000 (default: admin/admin)
- MailHog UI: http://localhost:8025

---

## Run the demo (typical workflow — 3 terminals) 🚀

1) Terminal A — Start monitoring (Prometheus + Grafana + Mailhog)

```bash
cd monitoring
docker-compose up -d
# verify
docker-compose ps
```

- Grafana UI: http://localhost:3000 (default user/pass: `admin` / `admin`).
- Prometheus UI: http://localhost:9090

2) Terminal B — Start the external mock service

```bash
cd external-mock-service
# Use the wrapper if you don't have Maven installed:
./mvnw spring-boot:run
# or build and run the jar:
# ./mvnw package
# java -jar target/*.jar
```

- Mock endpoints (examples):
  - GET /external/ok → returns "OK"
  - GET /external/slow → sleeps 3s then returns "SLOW"
  - GET /external/timeout → sleeps 10s then returns "TIMEOUT"
  - GET /external/error → returns HTTP 500

3) Terminal C — Start the adapter service

```bash
cd adapter-service
./mvnw spring-boot:run
# or build & run the jar
# ./mvnw package
# java -jar target/*.jar
```

- Adapter endpoint examples:
  - GET /adapter/ok
  - GET /adapter/slow
  - GET /adapter/timeout
  - GET /adapter/error

The adapter calls the mock at `http://localhost:8080/external/{mode}` and exposes actuator endpoints such as `/actuator/prometheus` for Prometheus scraping.

---

## How to exercise the circuit breaker 🧪
- To make Resilience4j open the circuit, repeatedly call a slow or error endpoint through the adapter to exceed the configured failure/slow-call thresholds.

Example quick loop (zsh):

```bash
# call slow many times to trigger failures
for i in {1..20}; do curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8081/adapter/slow; sleep 0.3; done
```

- Watch adapter logs — logging level for resilience4j is enabled in `adapter-service/src/main/resources/application.properties` (search for "changed state from HALF_OPEN to CLOSED").
- Prometheus scrapes the adapter at `/actuator/prometheus` (configured in `monitoring/prometheus.yml`).
- Import the Grafana dashboard to visualize circuit breaker metrics,
  e.g. use the file `monitoring/grafana/Resilience4j - Circuit Breaker (externalApi)-1769419834926.json`:
  - Grafana → + → Import → Upload JSON file → Select Prometheus data source

---

## Troubleshooting ⚠️
- If metrics do not appear in Prometheus:
  - Confirm Prometheus is running: http://localhost:9090
  - Confirm Adapter is reachable from the Docker container (Prometheus uses `host.docker.internal:8081` by default). If your environment does not support `host.docker.internal`, change `monitoring/prometheus.yml` to use `localhost:8081`.
  - Ensure actuator prometheus is exposed (see `adapter-service/src/main/resources/application.properties` — `management.endpoints.web.exposure.include=health,info,metrics,prometheus`).

- Port conflicts:
  - `external-mock-service` listens on 8080 (default). `adapter-service` is configured to run on 8081.
  - The repo contains a root `docker-compose.yml` that builds both services into containers; if you choose to run services in containers, review port mappings there.

- Logs:
  - The adapter prints Resilience4j state changes when DEBUG is enabled for `io.github.resilience4j.circuitbreaker`.

---

## Clean up 🧹

```bash
# Stop monitoring stack
cd monitoring
docker-compose down
# Stop the services you started (Ctrl+C in the terminal running mvn spring-boot:run)
```

---

## Notes & Tips ✨
- Adjust `resilience4j.circuitbreaker.instances.externalApi.waitDurationInOpenState` in `adapter-service/src/main/resources/application.properties` for faster testing if needed (e.g., use `5s` to get to HALF_OPEN faster).
- If you want to run everything in Docker instead of local JVM:
  - Use the root `docker-compose.yml` (it builds both services and exposes ports). Verify the ports in the compose file match the services' configured ports before using it.

---
