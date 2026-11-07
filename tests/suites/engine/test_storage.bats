#!/usr/bin/env bats

load '../test_helper'

setup() {
  test_setup
}

teardown() {
  test_cleanup
}

exit_success() {
  [ "$1" -eq "$EXIT_SUCCESS" ]
}

exit_invalid_workspace() {
  [ "$1" -eq "$EXIT_INVALID_WORKSPACE"]
}

log_exists() {
  [ -f ${MOCK_TRANSCRIPT_LOG} ]
}

warning_in_log() {
  grep -Eq "\[WARN(ING)?\]" "${MOCK_TRANSCRIPT_LOG}"
}

error_in_log() {
  grep -Eq "\[ERR(OR)?\]" "${MOCK_TRANSCRIPT_LOG}"
}

@test "Missing AUDIT_DIR workspace writes to log and exits 4 (INVALID_WORKSPACE)" {
  rm -rf "${MOCK_AUDIT_DIR}"

  run "${MOCK_ENGINE}"

  exit_invalid_workspace "$status"
  error_in_log
}

@test "Check that AUDIT_DIR not pointing to a directory exits 4" {
  rm -rf "${MOCK_AUDIT_DIR}"
  touch "${MOCK_AUDIT_DIR%/}"

  run "${MOCK_ENGINE}"

  exit_invalid_workspace "$status"
  error_in_log
}

@test "Normal workspace under WARN_DISK_MB baseline cfg runs cleanly" {
  seed_audit_file "test_audit" "1 Days Ago" 512

  run "${MOCK_ENGINE}"

  exit_success "$status"
  log_exists
  ! warning_in_log
}

@test "Exceeding WARN_DISK_MB logs warning and exits 0" {
  seed_large_file "$(( WARN_DISK_MB + 1 ))"

  run "${MOCK_ENGINE}"

  exit_success "$status"
  log_exists
  warning_in_log
}

@test "Custom WARN_DISK_MB in cfg dynamically alters warning threshold" {
  sed -i 's/WARN_DISK_MB=100/WARN_DISK_MB=5/' "${MOCK_CFG}"
  seed_large_file "6M"

  run "${MOCK_ENGINE}"

  exit_success "$status"
  log_exists
  warning_in_log
}

@test "Exceeding the MAX_DISK_MB ceiling writes to log and exits 5." {
  seed_large_file "${MOCK_MAX_DISK}M" && seed_large_file "${MOCK_MAX_DISK}"

  run ${MOCK_ENGINE}

  [ "$status" == "$EXIT_DISK_MAX_CAP" ]
  log_exists
  error_in_log
} 
