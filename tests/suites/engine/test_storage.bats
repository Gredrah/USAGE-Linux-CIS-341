#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

load '../test_helper'

setup() {
  test_setup
}

teardown() {
  test_cleanup
}

@test "Missing AUDIT_DIR workspace writes to log and exits 4 (INVALID_WORKSPACE)" {
  rm -rf "${MOCK_AUDIT_DIR}"

  run "${MOCK_ENGINE}" --scan

  exit_invalid_workspace "$status"
  error_in_log
}

@test "Check that AUDIT_DIR not pointing to a directory exits 4" {
  rm -rf "${MOCK_AUDIT_DIR}"
  touch "${MOCK_AUDIT_DIR%/}"

  run "${MOCK_ENGINE}" --scan

  exit_invalid_workspace "$status"
  error_in_log
}

@test "Normal workspace under WARN_DISK_MB baseline cfg runs cleanly" {
  seed_audit_file "test_audit" "1 Days Ago" 512

  run "${MOCK_ENGINE}" --scan

  exit_success "$status"
  log_exists
  ! warning_in_log
}

@test "Exceeding WARN_DISK_MB logs warning and exits 0" {
  seed_large_files "$(( WARN_DISK_MB + 1 ))"

  run "${MOCK_ENGINE}" --scan

  exit_success "$status"
  log_exists
  warning_in_log
}

@test "Exceeding the MAX_DISK_MB ceiling writes to log and exits 5." {
  seed_large_files "${MOCK_MAX_DISK}M" && seed_large_files "${MOCK_MAX_DISK}"

  run ${MOCK_ENGINE} --scan

  exit_disk_ceiling "$status"
  log_exists
  error_in_log
} 
