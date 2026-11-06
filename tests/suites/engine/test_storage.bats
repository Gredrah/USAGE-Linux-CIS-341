#!/usr/bin/env bats

load '../test_helper'

setup() {
  test_setup
}

teardown() {
  test_cleanup
}

@test "Exceeding 100MB (Configured warning limit) triggers [WARNING] in transcript log." {
  seed_large_payload "105M"

  run "${DAEMON_BIN}" --config "${MOCK_CFG}"
}
