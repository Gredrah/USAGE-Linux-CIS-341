#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

load '../test_helper'

setup() {
  test_setup

  export SYSTEMD_DIR="${PROJECT_ROOT}/systemd/"
  export SERVICE_FILE="${SYSTEMD_DIR}/sysaudit.service"
}

teardown() {
  test_cleanup
}

@test "systemd/sysaudit.service unit file exists and is not empty." {
  [ -f "${SERVICE_FILE}" ]
  [ -s "${SERVICE_FILE}" ]
}

@test "sysaudit.service contains required [Unit] [Service] and [Install] sections" {
  grep -Eq "^\[Unit\]" "${SERVICE_FILE}"
  grep -Eq "^\[Service\]" "${SERVICE_FILE}"
  grep -Eq "^\[Install\]" "${SERVICE_FILE}"
}

@test "sysaudit.service enforces execution as auditmanager" {
  grep -Eq "^[[:space:]]*User=auditmanager([[:space:]]|$)" "${SERVICE_FILE}"
}

@test "sysaudit.service points ExecStart to sysaudit.sh daemon" {
  grep -Eq "^[[:space:]]*ExecStart=.*sysaudit\.sh" "${SERVICE_FILE}"
}

@test "sysaudit.service launches in background multi-user mode" {
  grep -Eq "^[[:space:]]*ExecStart=.*sysaudit\.sh" "${SERVICE_FILE}"
}
