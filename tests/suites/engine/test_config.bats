#!/usr/bin/env bash

bats_require_minimum_version 1.5.0

load '../test_helper'

setup() {
  test_setup
}

teardown() {
  test_cleanup
}

@test "Custom WARN_DISK_MB in cfg dynamically alters warning threshold" {
  sed -i 's/WARN_DISK_MB=100/WARN_DISK_MB=5/' "${MOCK_CFG}"
  seed_large_files "6M"

  run "${MOCK_ENGINE}"

  exit_success "$status"
  log_exists
  warning_in_log
}

@test "Missing sysaudit.cfg writes diagnostic to STDERR and exits 3" {
  # Removal of MOCK_SRC/sysaudit is for a redunandt symlink used in dev
  rm -f "${MOCK_CFG}" "${MOCK_SRC}/sysaudit.cfg"

  run --separate-stderr "${MOCK_ENGINE}" --scan

  exit_config_missing
  stderr_used
  configerr_in_stderr
}

@test "Malformed sysaudit.cfg (invalid syntax) writes to STDERR, exits 3" {
  cat << 'EOF' > "${MOCK_CFG}"
IM A MALFORMED CONFIG SYNTAX!
INVALID LINE WITH NO ASSIGNMENTS ARE BAD :(
EOF

  run --separate-stderr "${MOCK_ENGINE}" --scan

  exit_config_missing
  stderr_used
}

@test "Malformed sysaudit.cfg (invalid assignment) writes to STDERR, exit 3" {
  sed -i "s/SCAN_INTERVAL=${MOCK_SCAN_INTERVAL}/SCAN_INTERVAL=two" "${MOCK_CFG}"

  run --separate-stderr "${MOCK_ENGINE}" --scan

  exit_config_missing
  stderr_used
}

@test "CLI flag overrides config path && audit path" {
  export ALT_WORKSPACE="${MOCK_ROOT}/custom_audit/"
  export ALT_CFG="${MOCK_ROOT}/custom_audit/custaudit.cfg"

  mkdir -p "${ALT_WORKSPACE}"
  touch "${ALT_CFG}"

  populate_config "${ALT_CFG}"

  exit_success
  # Check that the alternate workspace exists in the log
  grep -q "${ALT_WORKSPACE}" "${MOCK_TRANSCRIPT_LOG}"
}
