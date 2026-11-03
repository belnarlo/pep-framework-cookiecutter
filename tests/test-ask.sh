#!/bin/bash
# Tests for `pep-tools ask` (PEP-PF-FWK-008), run against both pep-tools.sh
# and pep-tools.ps1. The model is a stand-in HTTP server on 127.0.0.1 (Python),
# so no network is needed. Everything is removed on exit.
#
# Usage: tests/test-ask.sh

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS_DIR="${REPO_ROOT}/{{cookiecutter.project_slug}}/tools"

WORK="$(mktemp -d)"
SERVER_PID=""
cleanup() {
    if [ -n "$SERVER_PID" ]; then
        kill "$SERVER_PID" 2>/dev/null
        wait "$SERVER_PID" 2>/dev/null
    fi
    rm -rf "$WORK"
}
trap cleanup EXIT

PASS=0
FAIL=0
ok()  { PASS=$((PASS + 1)); echo "ok   - $1"; }
nok() { FAIL=$((FAIL + 1)); echo "FAIL - $1"; }

# check <description> <expected exit> <grep -E pattern for output, or ""> <command...>
check() {
    local desc="$1" want="$2" pattern="$3"; shift 3
    local out rc
    out=$("$@" 2>&1); rc=$?
    if [ "$rc" -ne "$want" ]; then
        nok "$desc (exit $rc, wanted $want)"; echo "$out" | sed 's/^/       /'; return
    fi
    if [ -n "$pattern" ] && ! printf '%s' "$out" | grep -qE -- "$pattern"; then
        nok "$desc (output didn't match /$pattern/)"; echo "$out" | sed 's/^/       /'; return
    fi
    ok "$desc"
}

if ! command -v python3 >/dev/null 2>&1; then
    echo "skip - python3 not installed, ask tests not run"
    exit 0
fi

# Stand-in model: POST /v1/chat/completions answers with a fixed line that
# says whether the key arrived; POST /broken/... returns 500. Each request
# body is saved to $WORK/last-request.json.
cat > "$WORK/server.py" <<'EOF'
import json, sys
from http.server import BaseHTTPRequestHandler, HTTPServer

work = sys.argv[1]

class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def do_POST(self):
        body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        with open(work + "/last-request.json", "wb") as f:
            f.write(body)
        if self.path.startswith("/broken/"):
            self.send_response(500)
            self.end_headers()
            return
        auth = "key ok" if self.headers.get("Authorization") == "Bearer test-key-123" else "no key"
        reply = {"choices": [{"message": {"content": "PEP-PS-XXX-001 Deploy Ryot (%s)" % auth}}]}
        data = json.dumps(reply).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

server = HTTPServer(("127.0.0.1", 0), Handler)
with open(work + "/port", "w") as f:
    f.write(str(server.server_address[1]))
server.serve_forever()
EOF
python3 -I "$WORK/server.py" "$WORK" &
SERVER_PID=$!
for _ in $(seq 1 50); do [ -s "$WORK/port" ] && break; sleep 0.1; done
PORT=$(cat "$WORK/port" 2>/dev/null)
if [ -z "$PORT" ]; then
    echo "FAIL - stand-in model server didn't start"
    exit 1
fi
URL="http://127.0.0.1:$PORT/v1"

new_repo() {
    local dir="$1"
    mkdir -p "$dir/docs/peps" "$dir/tools" && cd "$dir" || exit 1
    cp "${TOOLS_DIR}/pep-tools.sh" "${TOOLS_DIR}/pep-tools.ps1" tools/
    printf 'PROJECT_CODE="PS"\nREPO_CODE="XXX"\n' > .peprc
    cat > docs/peps/pep-ps-xxx-001-feat-deploy-ryot.md <<'PEP'
# PEP-PS-XXX-001: Deploy Ryot

**ID:** PEP-PS-XXX-001
**Title:** Deploy Ryot
**Status:** Active

## Abstract

Deploy the Ryot media tracker on the docker host.

## Specification

The secret line that must never be sent: hunter2-not-a-match.
PEP
    cat > docs/peps/pep-ps-xxx-002-infra-retire-netbox.md <<'PEP'
# PEP-PS-XXX-002: Retire NetBox

**ID:** PEP-PS-XXX-002
**Title:** Retire NetBox
**Status:** Implemented

## Abstract

Remove NetBox and its database.
PEP
}

pep() {
    if [ "$CLI" = "ps1" ]; then
        pwsh -NoProfile -File ./tools/pep-tools.ps1 "$@" </dev/null
    else
        bash ./tools/pep-tools.sh "$@" </dev/null
    fi
}

ask_tests() {
CLI="$1"
echo "# --- ask via $CLI"
new_repo "$WORK/ask-$CLI"
rm -f .peprc.local "$WORK/last-request.json"

check "[$CLI] no URL: prints the matching PEP and its lines" 0 "PEP-PS-XXX-001" \
    pep ask ryot
check "[$CLI] no URL: other PEPs aren't listed" 0 "" \
    bash -c '! ( cd "$1" && if [ "$2" = ps1 ]; then pwsh -NoProfile -File ./tools/pep-tools.ps1 ask ryot; else bash ./tools/pep-tools.sh ask ryot; fi ) | grep -q "XXX-002"' _ "$PWD" "$CLI"
check "[$CLI] no URL: the network is never called" 0 "" \
    test ! -e "$WORK/last-request.json"
check "[$CLI] case-insensitive" 0 "Retire NetBox" \
    pep ask NETBOX
check "[$CLI] no match: exit 1" 1 "No PEP mentions" \
    pep ask zabbix
check "[$CLI] no term: exit 1" 1 "Usage" \
    pep ask

# Settings in the shared .peprc are ignored
printf 'PEP_ASK_URL="%s"\n' "$URL" >> .peprc
check "[$CLI] PEP_ASK_URL in .peprc is ignored (matches only)" 0 "^== pep-ps-xxx-001" \
    pep ask ryot
check "[$CLI] ...and nothing was sent" 0 "" \
    test ! -e "$WORK/last-request.json"
sed -i.bak '/PEP_ASK_URL/d' .peprc && rm -f .peprc.bak

# Model configured in .peprc.local, key from the named env var
printf 'PEP_ASK_URL="%s"\nPEP_ASK_KEY_ENV="TEST_ASK_KEY"\n' "$URL" > .peprc.local
check "[$CLI] model answer printed, key sent from the env var" 0 "Deploy Ryot \(key ok\)" \
    env TEST_ASK_KEY=test-key-123 bash -c 'cd "$1" && if [ "$2" = ps1 ]; then pwsh -NoProfile -File ./tools/pep-tools.ps1 ask ryot; else bash ./tools/pep-tools.sh ask ryot; fi' _ "$PWD" "$CLI"
check "[$CLI] ...the matched files are listed under the answer" 0 "" \
    bash -c 'cd "$1" && TEST_ASK_KEY=x; if [ "$2" = ps1 ]; then pwsh -NoProfile -File ./tools/pep-tools.ps1 ask ryot; else bash ./tools/pep-tools.sh ask ryot; fi | grep -q "pep-ps-xxx-001-feat-deploy-ryot.md"' _ "$PWD" "$CLI"
check "[$CLI] only matched lines are sent, not the whole file" 0 "" \
    bash -c 'grep -q "Ryot" "$1" && ! grep -q "hunter2" "$1"' _ "$WORK/last-request.json"
check "[$CLI] model defaults to local, temperature 0" 0 "" \
    bash -c 'grep -q "\"local\"" "$1" && grep -qE "\"temperature\": ?0" "$1"' _ "$WORK/last-request.json"
check "[$CLI] no key set: request goes without one" 0 "\(no key\)" \
    env -u TEST_ASK_KEY bash -c 'cd "$1" && if [ "$2" = ps1 ]; then pwsh -NoProfile -File ./tools/pep-tools.ps1 ask ryot; else bash ./tools/pep-tools.sh ask ryot; fi' _ "$PWD" "$CLI"

printf 'PEP_ASK_URL="%s"\nPEP_ASK_KEY_ENV="not a name"\n' "$URL" > .peprc.local
check "[$CLI] PEP_ASK_KEY_ENV must be a variable name" 1 "environment variable name" \
    pep ask ryot

# Endpoint failure: matches shown, warning, exit 2
printf 'PEP_ASK_URL="http://127.0.0.1:%s/broken/v1"\n' "$PORT" > .peprc.local
check "[$CLI] endpoint error: matches shown and exit 2" 2 "PEP-PS-XXX-001" \
    pep ask ryot
}

ask_tests sh
if command -v pwsh >/dev/null 2>&1; then
    ask_tests ps1
else
    echo "skip - pwsh not installed, PowerShell ask tests not run"
fi

echo
echo "passed: $PASS  failed: $FAIL"
[ "$FAIL" -eq 0 ]
