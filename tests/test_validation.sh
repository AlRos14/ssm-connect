#!/usr/bin/env bash
# Unit tests for input validation functions.
# Sources ssm-connect in function-only mode — no AWS calls made.

set -euo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/ssm-connect"
PASS=0
FAIL=0

# ── Minimal test harness ──────────────────────────────────────────────────────
pass() { echo "  ✔ $1"; (( ++PASS )) || true; }
fail() { echo "  ✖ $1"; (( ++FAIL )) || true; }

# Run a function call in a subshell; assert its exit code.
assert_exit() {
  local desc="$1" expected="$2"
  shift 2
  local actual=0
  ( _SSMC_SOURCE_ONLY=1 source "$SCRIPT"; "$@" ) > /dev/null 2>&1 || actual=$?
  if [[ "$actual" -eq "$expected" ]]; then
    pass "$desc"
  else
    fail "$desc  (expected exit $expected, got $actual)"
  fi
}

# Run a function call in a subshell; assert stderr contains a pattern.
assert_err() {
  local desc="$1" pattern="$2"
  shift 2
  local output
  output=$( ( _SSMC_SOURCE_ONLY=1 source "$SCRIPT"; "$@" ) 2>&1 ) || true
  if echo "$output" | grep -qF "$pattern"; then
    pass "$desc"
  else
    fail "$desc  (expected stderr to contain '${pattern}', got: ${output})"
  fi
}

# ── validate_user ─────────────────────────────────────────────────────────────
echo ""
echo "validate_user"

assert_exit "accepts 'ubuntu'"              0  validate_user "ubuntu"
assert_exit "accepts 'ec2-user'"            0  validate_user "ec2-user"
assert_exit "accepts 'admin.user'"          0  validate_user "admin.user"
assert_exit "accepts 'deploy_user'"         0  validate_user "deploy_user"
assert_exit "accepts 'root'"               0  validate_user "root"
assert_exit "rejects empty string"         1  validate_user ""
assert_exit "rejects spaces"               1  validate_user "bad user"
assert_exit "rejects semicolon injection"  1  validate_user "ubuntu; ls"
assert_exit "rejects single-quote escape"  1  validate_user "ubuntu'"
assert_exit "rejects newline"              1  validate_user $'user\ninjection'
assert_err  "error message mentions user"  "Invalid user" \
  validate_user "bad user"

# ── validate_port ─────────────────────────────────────────────────────────────
echo ""
echo "validate_port"

assert_exit "accepts 1"      0  validate_port "1"
assert_exit "accepts 80"     0  validate_port "80"
assert_exit "accepts 443"    0  validate_port "443"
assert_exit "accepts 5432"   0  validate_port "5432"
assert_exit "accepts 65535"  0  validate_port "65535"
assert_exit "rejects 0"      1  validate_port "0"
assert_exit "rejects 65536"  1  validate_port "65536"
assert_exit "rejects letters" 1 validate_port "abc"
assert_exit "rejects empty"  1  validate_port ""
assert_exit "rejects float"  1  validate_port "8.8"
assert_exit "rejects negative" 1 validate_port "-1"
assert_err  "error message mentions port"  "Invalid port" \
  validate_port "99999"

# ── validate_host ─────────────────────────────────────────────────────────────
echo ""
echo "validate_host"

assert_exit "accepts 'localhost'"              0  validate_host "localhost"
assert_exit "accepts 'rds.internal'"          0  validate_host "rds.internal"
assert_exit "accepts 'my-server'"             0  validate_host "my-server"
assert_exit "accepts IPv4"                    0  validate_host "192.168.1.1"
assert_exit "accepts FQDN"                    0  validate_host "db.us-east-1.rds.amazonaws.com"
assert_exit "rejects spaces"                  1  validate_host "host name"
assert_exit "rejects double-quote"            1  validate_host 'host"name'
assert_exit "rejects backslash"               1  validate_host 'host\name'
assert_exit "rejects IPv6 (colons)"           1  validate_host "::1"
assert_exit "rejects semicolon"               1  validate_host "host;ls"
assert_err  "error message mentions host"     "Invalid host" \
  validate_host "bad host"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
[[ "$FAIL" -eq 0 ]]
