#!/usr/bin/env bash
# CLI integration tests.
# Exercises the script as a black box using mock aws/jq commands.
# No real AWS credentials or network access required.

set -euo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/ssm-connect"
PASS=0
FAIL=0

# ── Mock setup ────────────────────────────────────────────────────────────────
MOCK_DIR=$(mktemp -d)
trap 'rm -rf "$MOCK_DIR"' EXIT

# aws mock: satisfy require_cmd; for describe-instances return empty list
cat > "$MOCK_DIR/aws" << 'AWSMOCK'
#!/usr/bin/env bash
# Shift past any global flags (--profile, --region) before parsing subcommand
while [[ "${1:-}" == --profile || "${1:-}" == --region ]]; do shift 2; done
case "${1:-}.${2:-}" in
  ec2.describe-instances)
    # Return valid empty response for both JSON and text output modes
    if [[ "${*}" =~ "--output text" ]]; then
      echo "None"
    else
      echo '{"Reservations":[]}'
    fi ;;
  *) echo '{}' ;;
esac
exit 0
AWSMOCK
chmod +x "$MOCK_DIR/aws"

# jq mock: just run the real jq (it's a dev dependency)
# If real jq is unavailable, fall back to a stub
if ! command -v jq &>/dev/null; then
  printf '#!/usr/bin/env bash\necho "[]"\n' > "$MOCK_DIR/jq"
  chmod +x "$MOCK_DIR/jq"
fi

export PATH="$MOCK_DIR:$PATH"

# ── Harness ───────────────────────────────────────────────────────────────────
pass() { echo "  ✔ $1"; (( ++PASS )) || true; }
fail() { echo "  ✖ $1"; (( ++FAIL )) || true; }

assert_exit() {
  local desc="$1" expected="$2"
  shift 2
  local actual=0
  "$@" > /dev/null 2>&1 || actual=$?
  if [[ "$actual" -eq "$expected" ]]; then
    pass "$desc"
  else
    fail "$desc  (expected exit $expected, got $actual)"
  fi
}

assert_output() {
  local desc="$1" pattern="$2"
  shift 2
  local output
  output=$("$@" 2>&1) || true
  if echo "$output" | grep -qF "$pattern"; then
    pass "$desc"
  else
    fail "$desc  (expected output to contain '${pattern}', got: ${output})"
  fi
}

# ── --version / --help ────────────────────────────────────────────────────────
echo ""
echo "Flags: --version / --help"

assert_exit   "--version exits 0"              0  "$SCRIPT" --version
assert_output "--version prints version"       "0.1.1"  "$SCRIPT" --version
assert_exit   "-V exits 0"                     0  "$SCRIPT" -V
assert_exit   "--help exits 0"                 0  "$SCRIPT" --help
assert_exit   "-h exits 0"                     0  "$SCRIPT" -h
assert_output "--help mentions Usage"          "Usage:"  "$SCRIPT" --help

# ── Unknown options ───────────────────────────────────────────────────────────
echo ""
echo "Unknown options"

assert_exit   "unknown long option exits 1"   1  "$SCRIPT" --notanoption
assert_exit   "unknown short option exits 1"  1  "$SCRIPT" -Z
assert_output "unknown option prints error"   "Unknown option"  "$SCRIPT" --notanoption

# ── SSM_USER validation ───────────────────────────────────────────────────────
echo ""
echo "SSM_USER validation (via -u flag)"

assert_exit   "-u with valid user exits before API (no instances = exit 1)"  1 \
  "$SCRIPT" -u ubuntu some-server
assert_output "-u with injection attempt is rejected"  "Invalid user" \
  "$SCRIPT" -u "ubuntu'; ls" some-server
assert_exit   "-u with injection attempt exits 1"  1 \
  "$SCRIPT" -u "ubuntu'; ls" some-server
assert_output "-u with spaces is rejected"  "Invalid user" \
  "$SCRIPT" -u "bad user" some-server

# ── -L spec validation ────────────────────────────────────────────────────────
echo ""
echo "-L spec validation (fail fast, before API calls)"

assert_exit   "valid 2-part spec proceeds past validation (fails at resolution)" 1 \
  "$SCRIPT" -L "8080:8080" some-server
assert_output "invalid port 0 is rejected"       "Invalid port" \
  "$SCRIPT" -L "0:8080" some-server
assert_exit   "invalid port 0 exits 1"           1 \
  "$SCRIPT" -L "0:8080" some-server
assert_output "port > 65535 is rejected"         "Invalid port" \
  "$SCRIPT" -L "8080:99999" some-server
assert_output "non-numeric port is rejected"     "Invalid port" \
  "$SCRIPT" -L "abc:8080" some-server
assert_output "host with quotes is rejected"     "Invalid host" \
  "$SCRIPT" -L '8080:host"x":5432' some-server
assert_output "host with spaces is rejected"     "Invalid host" \
  "$SCRIPT" -L "8080:bad host:5432" some-server
assert_output "too few parts in spec"  "Invalid -L spec" \
  "$SCRIPT" -L "8080" some-server
assert_output "too many parts in spec" "Invalid -L spec" \
  "$SCRIPT" -L "8080:host:5432:extra" some-server

# ── Instance ID regex ─────────────────────────────────────────────────────────
echo ""
echo "Instance ID format"

assert_output "short ID (8 hex) routed to connect, not name search" "Connecting to" \
  "$SCRIPT" i-1234abcd
assert_output "long ID (17 hex) routed to connect, not name search" "Connecting to" \
  "$SCRIPT" i-1234567890abcdef0
assert_output "too-short ID treated as name search"  "No running instance" \
  "$SCRIPT" i-abc
assert_output "too-long ID treated as name search"   "No running instance" \
  "$SCRIPT" i-1234567890abcdef01234

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
[[ "$FAIL" -eq 0 ]]
