#!/usr/bin/env bash
# set -euo pipefail÷

set -u

# ===============================
# Endpoint configuration
# ===============================
SLOW_URL="http://localhost:8081/adapter/slow"
FAST_URL="http://localhost:8081/adapter/ok"

# ===============================
# Circuit Breaker config mapping
# ===============================
WINDOW_SECONDS=15                  # slidingWindowSize (TIME_BASED)
MIN_CALLS=10                       # minimumNumberOfCalls
WAIT_OPEN_SECONDS=30               # waitDurationInOpenState
SLOW_THRESHOLD_MS=1500             # slowCallDurationThreshold
HALF_OPEN_CALLS=1                  # permittedNumberOfCallsInHalfOpenState

echo "================================================="
echo " TIME-BASED Circuit Breaker Demo (Resilience4j)"
echo "================================================="

while true; do
  echo
  echo "🔥 PHASE 1: FORCE OPEN"
  echo "   - >= ${MIN_CALLS} calls within ${WINDOW_SECONDS}s"
  echo "   - slow > ${SLOW_THRESHOLD_MS}ms (expect slow / timeout)"
  echo "   -> Expect CLOSED → OPEN"

  START=$(date +%s)
  while (( $(date +%s) - START < WINDOW_SECONDS )); do
    curl -s -o /dev/null "$SLOW_URL" &
    sleep 1
  done
  wait

  echo
  echo "⏸ PHASE 2: OPEN STATE (cool-down)"
  echo "   - Circuit remains OPEN for ${WAIT_OPEN_SECONDS}s"
  echo "   - All calls are short-circuited"
  echo "   -> Expect OPEN (no downstream call)"
  sleep $((WAIT_OPEN_SECONDS + 2))

  echo
  echo "🧪 PHASE 3: HALF_OPEN PROBE"
  echo "   - permittedNumberOfCallsInHalfOpenState = ${HALF_OPEN_CALLS}"
  echo "   - Using FAST endpoint (< ${SLOW_THRESHOLD_MS}ms)"
  echo "   -> Expect OPEN → HALF_OPEN → CLOSED (very brief HALF_OPEN)"

  curl -s -o /dev/null "$FAST_URL"

  echo
  echo "⏳ PHASE 4: HOLD CLOSED (observe state)"
  echo "   - No traffic"
  echo "   -> Expect CLOSED"
  sleep 5

  echo
  echo "✅ PHASE 5: CONFIRM CLOSED (gentle traffic)"
  echo "   - Low concurrency"
  echo "   - Fast response only"
  echo "   -> Expect CLOSED remains CLOSED"

  for i in {1..5}; do
    curl -s -o /dev/null "$FAST_URL"
    sleep 0.5
  done

  echo
  echo "🔁 LOOP AGAIN"
  echo "-------------------------------------------------"
  sleep 10
done