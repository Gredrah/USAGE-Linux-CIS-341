#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

load '../test_helper'

setup() {
  test_setup
}

teardown() {
  test_cleanup
}

@test "scanning generates raw *.audit files inside audit workspace" {
  run "${MOCK_ENGINE}" --scan 

  exit_success "$status"
  local audit_count
  audit_count=$(find "${MOCK_AUDIT_DIR}" -maxdepth 1 -name "*.audit" | wc -l)
  [ "$audit_count" -ge 1 ]
}

@test "Maintenance cleanup of raw *.audit files into archives, deletion of raw audits." {
  seed_audit_file "report1.audit" "2019-01-02 12:00:00" 512
  seed_audit_file "report2.audit" "2019-01-01 12:00:00" 1024

  run "${MOCK_ENGINE}" --cleanup

  exit_success "$status"

  local archive_count
  archive_count=$(find "${MOCK_AUDIT_DIR}" -type f \( -name "*.tar.gz" -o -name "*.zip" \) | wc -l)
  [ "$archive_count" -ge 1 ]

  local remaining_raw
  remaining_raw=$(find "${MOCK_AUDIT_DIR}" -maxdepth 1 -name "*.audit" | wc -l)
  [ "$remaining_raw" -eq 0 ]
}

@test "Compression failure preserves raw *.audit files and logs [ERROR]" {
  seed_audit_file "preserve_me_please.audit" "2019-01-01 1:00:00" 512

  tar() {
    return 1
  }
  export -f tar

  run "${MOCK_ENGINE}" --cleanup

  [ -f "${MOCK_AUDIT_DIR}/preserve_me_please.audit" ]
  error_in_log
}

@test "Storage pruning deletes compressed archives older than 14 days old" {
  seed_archive_file "expired_archive.tar.gz" "2020-01-01 12:00:00" 2048

  run "${MOCK_ENGINE}" --cleanup

  exit_success "$status"
  [ ! -f "${MOCK_AUDIT_DIR}/expired_archive.tar.gz" ]
}

@test "Pruning retains archives 14 days old or newer" {
  local d1=$(date -d "13 days ago" "+%Y-%m-%d %H:%M:%S")
  local d2=$(date -d "1 days ago" "+%Y-%m-%d %H:%M:%S")
  local d3=$(date -d "15 days ago" "+%Y-%m-%d %H:%M:%S")

  seed_archive_file "boundary_14d.tar.gz" "${d1}" 2048
  seed_archive_file "fresh.tar.gz" "${d2}" 2048
  seed_archive_file "kill_him.tar.gz" "${d3}" 2048

  run "${MOCK_ENGINE}" --cleanup

  exit_success "$status"

  [ ! -f "${MOCK_AUDIT_DIR}/kill_him.tar.gz" ]

  [ -f "${MOCK_AUDIT_DIR}/boundary_14d.tar.gz" ]
  [ -f "${MOCK_AUDIT_DIR}/fresh.tar.gz" ]
}
