#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

load '../test_helper'

setup() {
  test_setup
}

teardown() {
  test_cleanup
}

@test "Running without arguments outputs USAGE statement and exits 0" {
  run "${MOCK_ENGINE}"

  assert_usage_statement
}

@test "Running with -h triggers USAGE and exits 0" {
  run "${MOCK_ENGINE}" -h

  assert_usage_statement
}

@test "Running with --help triggers usage and exits 0" {
  run "${MOCK_ENGINE}" --help

  assert_usage_statement
}

# Write the error to stderr, and exit code 1.
@test "Malformed or unknown CLI flags write to STDERR and exit 1" {
  run --separate-stderr "${MOCK_ENGINE}" --scan --im-an-invalid-flag

  exit_generic_error "$status"
  stderr_used
  [[ "$stderr" == *"im-an-invalid-flag"* ]]
}
