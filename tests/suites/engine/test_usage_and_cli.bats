#!/usr/bin/env bats

load '../test_helper'

setup() {
  test_setup
}

teardown() {
  test_cleanup
}

assert_usage_statement() {
  # Assert exit code is 0
  [ "$status" -eq "$EXIT_SUCCESS" ]

  # Assert baseline USAGE string
  [[ "$output" == *"USAGE"* ]]

  # Content checks:
  # sysaudit log path present
  [[ "$output" == *"sysaudit.cfg"* ]]

  # Flags
  [[ "$output" == *"-h"* ]] || [[ "$output" == *"--help" ]]

  # Sample logs
  [[ "$output" == *"[INFO]"* ]] || [[ "$output" == *"[WARN"* ]]

  # Error code dict
  [[ "$output" == *"0"* && "$output" == *"1"* && "$output" == *"2"* ]]
  [[ "$output" == *"3"* && "$output" == *"4"* && "$output" == *"5"* ]]
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
  run --seperate-stderr "${MOCK_ENGINE}" --im-an-invalid-flag

  [ "$status" -eq "$EXIT_GENERIC_ERROR" ]

  [[ "$stderr" == *"im-an-invalid-flag"* ]]

  assert_usage_statement
}
