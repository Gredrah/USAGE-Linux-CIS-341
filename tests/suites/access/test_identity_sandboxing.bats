#!/usr/bin/env bats

load '../test_helper'

bats_require_minimum_version 1.5.0

setup() {
  test_setup
}

teardown() {
  test_cleanup
}

@test "Execution successful for the auditmanager user" {
  mock_user "auditmanager" # Redundant, this is done in setup.

  run "${MOCK_ENGINE}" --scan

  exit_success "$status"
  log_exists
}

@test "Execution by unprivileged user rejects immediately and writes to STDERR" {
  mock_user "regular_john"

  run --separate-stderr "${MOCK_ENGINE}" --scan 

  exit_identity_error "$status"
  stderr_used
}

@test "Execution via root rejects access and exits 2" {
  mock_user "root"
  export USER="root"

  run --separate-stderr "${MOCK_ENGINE}" --scan

  exit_identity_error "$status"
  stderr_used
}

@test "Execution via sudo rejects access and exits" {
  run --separate-stderr sudo "${MOCK_ENGINE}" --scan

  exit_identity_error "$status"
  stderr_used
}
