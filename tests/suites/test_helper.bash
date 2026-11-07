#!/usr/bin/env bash

# Project Exit Codes / Standardized from project file.
export EXIT_SUCCESS=0
export EXIT_GENERIC_ERROR=1
export EXIT_USER_VIOLATION=2
export EXIT_CONFIG_MISSING=3
export EXIT_INVALID_WORKSPACE=4
export EXIT_DISK_MAX_CAP=5

# Mock CFG Variables
MOCK_WARN_DISK="100"
MOCK_MAX_DISK="150"
MOCK_SCAN_INTERVAL="60"
MOCK_INTERVAL_DAYS="3"
MOCK_RETENTION_DAYS="14"

# Common set up helper
test_setup() {
  # Filesystem set up in bats tmpdir
  #
  # Set up our mock "Project root"
  export MOCK_ROOT="${BATS_TEST_TMPDIR}"
  # Sets project root to the directory above /tests/ (real root)
  export PROJECT_ROOT
  PROJECT_ROOT="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"

  # cfg, Log, src dir
  export MOCK_LOG_DIR="${MOCK_ROOT}/var/log/"
  export MOCK_SRC="${MOCK_ROOT}/src/"
  export MOCK_CFG_DIR="${MOCK_ROOT}/config/"
  export MOCK_AUDIT_DIR="${MOCK_ROOT}/audit/"

  # transcript log, mock cfg
  export MOCK_TRANSCRIPT_LOG="${MOCK_LOG_DIR}/USAGE_daemon.log"
  export MOCK_CFG="${MOCK_ROOT}/config/sysaudit.cfg"

  # make directory

  mkdir -p "${MOCK_LOG_DIR}" "${MOCK_CFG_DIR}" "${MOCK_AUDIT_DIR}" "${MOCK_SRC}"

  # Copy engine to test directory
  export MOCK_ENGINE="${MOCK_SRC}/sysaudit.sh"
  cp "${PROJECT_ROOT}/src/sysaudit.sh" "${MOCK_ENGINE}"

  # Default config for testing
  cat <<EOF >"${MOCK_CFG}"
AUDIT_DIR=${MOCK_AUDIT_DIR}
LOG_FILE=${MOCK_TRANSCRIPT_LOG}
WARN_DISK_MB=${MOCK_WARN_DISK}
MAX_DISK_MB=${MOCK_MAX_DISK}
SCAN_INTERVAL=${MOCK_SCAN_INTERVAL}
CLEANUP_INTERVAL_DAYS=${MOCK_INTERVAL_DAYS}
ARCHIVE_RETENTION_DAYS=${MOCK_RETENTION_DAYS}
EOF

  # enters the user as our fake auditmanager
  mock_user "auditmanager"
  # cd to the test root to ensure correct files are used
  cd "${MOCK_ROOT}" || exit 1
  # compatibility: add a symlink from /config/sysaudit.cfg to /src/sysaudit.cfg for early script
  ln -sf "${MOCK_CFG}" "${MOCK_SRC}/sysaudit.cfg"
}

# Cleanup of the temporary test directory
test_cleanup() {
  # Add true to prevent failed permission changes in cleanup failing tests
  # Add :? to prevent catastrophic failure of glob if MOCK_ROOT is not set.
  chmod -R u+rwX "${MOCK_ROOT}" 2>/dev/null || true
  rm -rf "${MOCK_ROOT:?}"/*
}

# User Identity Faking - Overrides whoami and id -un in BATS
# Requires an argument: the user being overriden
mock_user() {
  if [[ "$#" -ne 1 ]]; then
    echo "Please provide a username to mock as the first and only argument."
    exit 1
  elif [[ -z "$1" ]]; then
    echo "Requires a target string of username to mock as first and only argument."
    exit 1
  fi

  local target_user="$1"
  export MOCKED_USER="${target_user}"

  # Return Mocked User in the two scenarios identities may be commonly called
  whoami() { echo "${MOCKED_USER}"; }
  id() {
    if [[ "$*" == *"-un"* || "$*" == *"-u"* ]]; then
      echo "${MOCKED_USER}"
    else
      command id "$@"
    fi
  }

  export -f whoami id
}

# File & Archive seeding helper
# seed_audit_file "name_of.audit"(report.audit) "# Days Ago"(Now) <sizeInBytes>(512)
seed_audit_file() {
  #Set to argument, or default
  local filename="${1:-report.audit}"
  local age="${2:-now}"
  local size_bytes="${3:-512}"
  local filepath="${MOCK_AUDIT_DIR}/${filename}"

  # Pull enough zeroes from /dev/zero to fill the file with the requested amount of data.
  # Use dd instead of truncate so that du reports real sizes and space is assigned.
  dd if=/dev/zero of="${filepath}" bs=1 count="${size_bytes}" status=none
  # Touch the file and set the date modified to the given date.
  touch -d "${age}" "${filepath}"
}

# seed_archive_file "name_of.tar.gz"(archive.tar.gz) "# Days Ago"(Now) <sizeInBytes>(2048)
seed_archive_file() {
  local filename="${1:-archive.tar.gz}"
  local age="${2:-now}"
  local size_bytes="${3:-2048}"
  local filepath="${MOCK_AUDIT_DIR}/${filename}"

  dd if=/dev/zero of="${filepath}" bs=1 count="${size_bytes}" status=none
  touch -d "${age}" "${filepath}"
}

# Quick seeding for large audit files.
# seed_large_files "105M"
seed_large_files() {
  local size="${1:-105M}"
  local filepath="${MOCK_AUDIT_DIR}/oversized_dump.audit"

  dd if=/dev/zero of="${filepath}" bs=1M count="${size//M/}" status=none
}
