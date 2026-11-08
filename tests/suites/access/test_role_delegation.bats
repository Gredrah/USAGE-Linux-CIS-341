#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

load '../test_helper'

setup() {
  test_setup
}

teardown() {
  test_cleanup
}

@test "Auditmanager can delegate execution and file access to a regular user and exit 0" {
  mock_user "auditmanager" # Redundant, action performed in setup

  run "${MOCK_ENGINE}" --delegate "auditor_backup"

  exit_success "$status"
  log_exists
  info_in_log
}

@test "Delegated secondary user can execute scan and access workspace without an access violation" {
  mock_user "auditmanager"
  run "${MOCK_ENGINE}" --delegate "auditor_backup"
  exit_success "$status"

  mock_user "auditor_backup"
  run "${MOCK_ENGINE}" --scan

  exit_success "$status"
  [ -r "${MOCK_AUDIT_DIR}" ]
  [ -w "${MOCK_AUDIT_DIR}" ]
}

@test "Unprivileged wannabe auditmanager is blocked, logged, and written to error" {
  mock_user "the_deviant"

  run --separate-stderr "${MOCK_ENGINE}" --delegate "the_deviant"

  exit_identity_error "$status"
  stderr_used
  info_in_log
}

@test "Non-delegated secondary user is still blocked after another un-related user is delegated" {
  mock_user "auditmanager"
  run "${MOCK_ENGINE}" --delegate "auditor_backup"
  exit_success "$status"

  mock_user "unlisted_user"
  run --separate-stderr "${MOCK_ENGINE}" --scan

  exit_identity_error "$status"
  stderr_used
}
