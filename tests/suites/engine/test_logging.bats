#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

load '../test_helper'

setup() {
  test_setup
}

teardown() {
  test_cleanup
}

@test "Transcript: creates self-monitoring log file at LOG_FILE path" {
  run "${MOCK_ENGINE}" --scan 

  exit_success "$status"
  log_exists
  log_not_empty
}

@test "Transcript: scan loop init is logged with [INFO]" {
  run "${MOCK_ENGINE}" --scan

  exit_success "$status"
  info_in_log
  timestamp_in_log
}

@test "Handled exceptions are recorded with [ERROR]" {
  rm -rf "${MOCK_AUDIT_DIR}"

  run "${MOCK_ENGINE}" --scan

  exit_invalid_workspace "$status"
  log_exists
  error_in_log
}

@test "Summary Log: total count of compressed archives is being recroded" {
  seed_archive_file "file1.tar.gz" "now" 512
  seed_archive_file "file2.tar.gz" "now" 512

  run "${MOCK_ENGINE}" --scan

  exit_success "$status"
  archive_count "2"
}

@test "Summary log: records exact filename and byte size of largest archive" {
  seed_archive_file "small.tar.gz" "now" 1024
  seed_archive_file "large.tar.gz" "1 Days Ago" 8192

  run "${MOCK_ENGINE}" --scan

  exit_success "$status"
  archive_mentioned "large"
  exact_bytes_recorded "8192"
}

@test "data storage file dump is logged with [INFO]" {
  run "${MOCK_ENGINE}" --scan

  exit_success "$status"
  info_in_log
  timestamp_in_log
  grep -Eq -i "(dump|saved|created|generated|stored).*\.audit" "${MOCK_TRANSCRIPT_LOG}"
}

@test "script sleep cycle config update is logged with [INFO]" {
  run "${MOCK_ENGINE}" --scan
  
  exit_success "$status"
  info_in_log
  timestamp_in_log
  grep -Eq -i "(sleep|interval|cycle).*30" "${MOCK_TRANSCRIPT_LOG}"
}

@test "records modification timestamp of the largest archive" {
  seed_archive_file "small.tar.gz" "2 days ago" 1024
  seed_archive_file "large.tar.gz" "2026-10-15 08:12:34" 8192

  run "${MOCK_ENGINE}" --scan

  exit_success "$status"
  archive_mentioned "large"
  exact_bytes_recorded "8192"
  archive_modtime_recorded "2026-10-15 08:12:34"
}
