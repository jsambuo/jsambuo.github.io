#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-http://127.0.0.1:4173}"

check() {
  local path="$1"
  local note="$2"
  local hdr code loc
  hdr="$(curl -sSI "${BASE_URL}${path}")"
  code="$(printf '%s\n' "$hdr" | awk '/^HTTP\//{c=$2} END{print c}')"
  loc="$(printf '%s\n' "$hdr" | sed -n 's/^location: //Ip' | tr -d '\r')"
  printf '%-38s %-4s %s\n' "$path" "$code" "$note"
  if [[ -n "$loc" ]]; then
    printf '  -> %s\n' "$loc"
  fi
}

echo "Checking compatibility routes against ${BASE_URL}"
check "/" "Expected 200"
check "/about/" "Expected 200"
check "/about" "Expected 301/308 redirect to /about/"
check "/feed.xml" "Expected 200"
check "/financial-independence.html" "Expected 200"
check "/financial-independence" "Expected 301/308 redirect to /financial-independence/"
check "/global-game-jam-2018.html" "Expected 200"
check "/global-game-jam-2018" "Expected 301/308 redirect to /global-game-jam-2018/"
check "/my-experience-with-gcp.html" "Expected 200"
check "/my-experience-with-gcp" "Expected 301/308 redirect to /my-experience-with-gcp/"
check "/bitcoin.html" "Expected 200"
check "/bitcoin" "Expected 301/308 redirect to /bitcoin/"
check "/happy-2018.html" "Expected 200"
check "/happy-2018" "Expected 301/308 redirect to /happy-2018/"
check "/hello-everybody.html" "Expected 200"
check "/hello-everybody" "Expected 301/308 redirect to /hello-everybody/"
check "/css/main.css" "Expected 200"
check "/assets/GCP_Functions_Tester.png" "Expected 200"
