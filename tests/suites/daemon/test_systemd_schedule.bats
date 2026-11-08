#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

load '../test_helper'

setup() {
  test_setup

  export SYSTEMD_DIR="${PROJECT_ROOT}/systemd"
  export SYSTEMD_TIMER="${SYSTEMD_DIR}/sysaudit.timer"
  export SYSTEMD_SERVICE="${SYSTEMD_DIR}/sysaudit.service"
}

teardown() {
  test_cleanup
}

@test "systemd/sysaudit.timer exists and contains [Timer] and [Install] Section" {
  [ -f "${SYSTEMD_TIMER}" ]
  [ -s "${SYSTEMD_TIMER}" ]
  grep -Eq "^\[Timer\]" "${SYSTEMD_TIMER}"
  grep -Eq "^\[Install\]" "${SYSTEMD_TIMER}"
}

@test "sysaudit.timer schedules execution at midnight every 3 days" {
  # Matches 3 possible formats: OnCalendar, 3d intervals, or 0 0 */3 * *
  grep -Eq "(OnCalendar=.*(\*-\*-1/3|\*/3).*00:00(:00)?|OnUnitActiveSec=3d|0 0 \*/3 \* \*)" "${SYSTEMD_TIMER}"
}

@test "sysaudit.timer is enabled for automatic timer target setup" {
  grep -Eq "^[[:space:]]*WantedBy=(timers|multi-user)\.target([[:space:]]|$" "${SYSTEMD_TIMER}"
}

@test "sysaudit.timer and .service target the audit workspace" {
  if grep -Eq "^[[:space:]]*Unit=" "${SYSTEMD_TIMER}"; then 
    grep -Eq "^[[:space:]]*Unit=sysaudit\.service" "${SYSTEMD_TIMER}"
  else 
    [ -f "${SYSTEMD_SERVICE}" ]
  fi 
}
