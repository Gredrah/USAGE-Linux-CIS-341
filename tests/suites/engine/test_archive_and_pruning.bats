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

}
