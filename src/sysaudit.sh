#!/bin/bash

# POSIX Exit Code(s)
E_SUCCESS=0
E_GENERIC=1
E_IDENTITY=2
E_CONFIG=3
E_WORKSPACE=4
E_CEILING=5

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_CONFIG="${SCRIPT_DIR}/../config/sysaudit.cfg"
CONFIG_FILE="${CONFIG_FILE:-$DEFAULT_CONFIG}"

get_timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

#detailed help statement and dumpin stuff
display_help() {
  cat <<'EOF'
======================================================================
System Health Monitor & Security Auditing Daemon
======================================================================


INSTRUCTIONS & OPERATIONAL SYNTAX:
  sysaudit [OPTIONS]
 
PARAMETER OPTIONS & EXECUTION EXAMPLES:
  sysaudit 
  sysaudit -h 
  sysaudit --help                  # Display this exhaustive USAGE statement
  sysaudit -r
  sysaudit --run 
  sysaudit --scan                  # Run the manual scan and remove loop
  sysaudit -c 
  sysaudit --cleanup               # Run only the archive pruning and cleanup
  sysaudit -d 
  sysaudit --delegate tom_jones    # Delegate execution rights/file access to user 'tom_jones'
  sysaudit -w 50
  sysaudit --warn 50               # Override baseline storage limit to 50MB for this loop
  sysaudit -m 100                  
  sysaudit --max 100               # Override max storage limit to 100MB for this loop.
  sysaudit --config                # Provide an alternate config file to the default
  sysaudit --workspace             # Provide an alternate audit directory to the default


SAMPLE RESULTS & LOGS:
  [INFO] 2026-10-22 14:00:01 - Scan loop initialized successfully.
  [WARN] 2026-10-22 14:05:00 - Storage envelope at 95MB (Limit: 100MB).
  [ERROR] 2026-10-22 14:10:00 - IDENTITY_VIOLATION triggered.


CONFIGURATION SCHEMA (sysaudit.cfg):
  TARGET_DIR              : Target folder path for workspace (e.g., /course_project/audit/)
  CONFIG_DIR              : Target cfg path for workspace (default: ../config/sysaudit.cfg)
  WARN_DISK_MB            : Log over-warning limit in MB (default: 50MB)
  MAX_DISK_MB             : Over-allocation baseline limit in MB (default: 100MB)
  LOG_FILE                : Path to the dedicated internal auditing trace log (/var/log/sysaudit_daemon.log)
  SCAN_INTERVAL           : Interval for daemon scans (default: 60s)
  ARCHIVE_RETENTION_DAYS  : Number of days to retain archives (default: 14 days)
  CLEANUP_INTERVAL_DAYS   : Number of days between cleanup (default: 3 days)


ERROR CODE DICTIONARY:
  0 | SUCCESS               | Operational task ran to completion without tracking loops faults.
  1 | GENERIC_ERROR         | An unmapped error condition triggered a process escape.
  2 | IDENTITY_VIOLATION    | Process call called by an unverified account other than auditmanager.
  3 | CONFIGURATION_MISSING | The explicit target configuration layout file sysaudit.cfg was not found.
  4 | INVALID_WORKSPACE     | Target mapping path missing or is not a directory.
  5 | DISK_CEILING_REACHED  | Workspace capacity validation failed critical storage envelope margins.
EOF
}

# Function for Exits & Logging
fail_with() {
  local code=$1
  local message=$2
  local ts
  ts=$(get_timestamp)
  echo "[ERROR] $ts - $message" >&2
  if [ -n "$LOG_FILE" ]; then
    echo "[ERROR] ${ts} - Terminated with code $code: $message" >>"$LOG_FILE"
  fi
  exit "$code"
}

#dump USAGE statement if run manually from the command line w/o args or help flag
if [[ "$#" -eq 0 || "$1" == "-h" || "$1" == "--help" ]]; then
  display_help
  exit 0
fi

#auditmanager permissions delegation section
CLI_WARN_DISK_MB=""
CLI_MAX_DISK_MB=""
CLI_AUDIT_DIR=""
CLI_CONFIG_FILE=""
DELEGATED_USER=""
CLEANUP_FLAG=0
RUN_SCAN=0

while [[ "$#" -gt 0 ]]; do
  case "$1" in
  -h | --help)
    display_help
    exit 0
    ;;
  --config)
    CLI_CONFIG_FILE="$2"
    shift 2
    ;;
  --workspace)
    CLI_AUDIT_DIR="$2"
    shift 2
    ;;
  -w | --warn)
    CLI_WARN_DISK_MB="$2"
    shift 2
    ;;
  -m | --max | --limit)
    #secure role delegation and autonomy allocation bit
    CLI_MAX_DISK_MB="$2"
    shift 2
    ;;
  -d | --delegate)
    DELEGATED_USER="$2"
    shift 2
    ;;
  -r | --run | --scan)
    RUN_SCAN=1
    shift 1
    ;;
  -c | --cleanup)
    CLEANUP_FLAG=1
    shift 1
    ;;
  *)
    display_help
    fail_with "$E_GENERIC" "GENERIC_ERROR: Unknown parameter in args: ${1}"
    ;;
  esac
done

if [ -n "$CLI_CONFIG_FILE" ]; then
  CONFIG_FILE="${CLI_CONFIG_FILE}"
fi

# Configuration Loading
if [ ! -f "$CONFIG_FILE" ] || ! source "$CONFIG_FILE" 2>/dev/null; then
  fail_with "$E_CONFIG" "Configuration file $CONFIG_FILE not found, or invalid configuration."
fi

#Apply remaining CLI Flag overrides over sysaudit.cfg
if [ -n "$CLI_AUDIT_DIR" ]; then
  AUDIT_DIR="$CLI_AUDIT_DIR"
fi
if [ -n "$CLI_WARN_DISK_MB" ]; then
  WARN_DISK_MB="$CLI_WARN_DISK_MB"
fi
if [ -n "$CLI_MAX_DISK_MB" ]; then
  MAX_DISK_MB="$CLI_MAX_DISK_MB"
fi

LOG_FILE="${LOG_FILE:-/var/log/sysaudit_daemon.log}"
TARGET_DIR="$AUDIT_DIR"
TARGET_FOLDER="$TARGET_DIR"

# User Execution Space Sandboxing
USER=$(id -un)
if [ "$USER" == "root" ] || [ "$(id -u)" -eq 0 ] || [ -n "$SUDO_USER" ]; then
  echo "[WARN] $(get_timestamp) - security check blocked root/sudo access attempt by $USER" >>"$LOG_FILE" 2>/dev/null
  fail_with "$E_IDENTITY" "Privilege Violation: Execution as root/sudo is prohibited."
fi

if [ "$USER" != "auditmanager" ]; then
  if ! id -nG "$USER" 2>/dev/null | grep -qw "delegatedmanagers"; then
    echo "[WARN] $(get_timestamp) - security check blocked unauthorized user $USER" >>"$LOG_FILE" 2>/dev/null
    fail_with "$E_IDENTITY" "Privilege violation: Process must execute as auditmanager, or by a delegatedmanager."
  fi
fi
echo "Security Check passed! Welcome $USER."

# Apply the delegation logic if the argument was passed
if [[ -n "$DELEGATED_USER" ]]; then
  if [ "$USER" != "auditmanager" ]; then
    echo "[INFO] $(get_timestamp) - unauthorized delegation attempt by $USER" >>"$LOG_FILE"
    fail_with "$E_IDENTITY" "IDENTITY_VIOLATION: Only auditmanager can delegate access"
  fi

  # Verify the user exists on the system
  if id "$DELEGATED_USER" &>/dev/null; then
    echo "[INFO] $(get_timestamp) Valid user found. Making delegatedmanager: $DELEGATED_USER" | tee -a "$LOG_FILE"

    usermod -aG delegatedmanagers "$DELEGATED_USER" 2>/dev/null

    #Change the group ownership of the workspace directory recursively
    chgrp -R delegatedmanagers "$TARGET_DIR" "$LOG_FILE" 2>/dev/null

    #Grant read, write, and execute permissions to the new group
    chmod -R g+rwx "$TARGET_DIR" "$LOG_FILE" 2>/dev/null

    echo "[INFO] $(get_timestamp) Delegation successful. Workspace $TARGET_DIR is now accessible by $DELEGATED_USER." | tee -a "$LOG_FILE"
    exit "$E_SUCCESS"
  else
    # Failed to find user attempted to delegate to.
    fail_with "$E_GENERIC" "GENERIC_ERROR: Delegated user ""$DELEGATED_USER"" does not exist in delegatedmanagers"
  fi
fi

# Workspace Validation
if [ ! -d "$TARGET_FOLDER" ]; then
  fail_with "$E_WORKSPACE" "Target workspace $TARGET_FOLDER missing or not a directory."
fi

echo "[INFO] $(get_timestamp) - Daemon execution started." >>"$LOG_FILE"
echo "[INFO] $(get_timestamp) - Sleep cycle interval configured to ${SCAN_INTERVAL}s" >>"$LOG_FILE"

#Resource Warning & Ceiling Check
CEILING_LIMIT_MB=${MAX_DISK_MB}
CURRENT_SIZE_MB=$(du -sm "$TARGET_FOLDER" 2>/dev/null | cut -f1)

if [ -n "$CEILING_LIMIT_MB" ] && [ "$CURRENT_SIZE_MB" -gt "$CEILING_LIMIT_MB" ]; then
  fail_with "$E_CEILING" "Disk ceiling reached: ${CURRENT_SIZE_MB}MB exceeds limit of ${CEILING_LIMIT_MB}MB"
elif [ -n "$WARN_DISK_MB" ] && [ "$CURRENT_SIZE_MB" -gt "$WARN_DISK_MB" ]; then
  echo "[WARNING] $(get_timestamp) - Storage size at ${CURRENT_SIZE_MB}MB (Limit: ${WARN_DISK_MB}MB)" >>"$LOG_FILE"
fi

if [ $RUN_SCAN -eq 0 ]; then
  filets=$(date +"%Y%m%d_%H%M%S")
  AUDIT_NAME="${TARGET_FOLDER%/}/sysaudit_${filets}_$$.audit"
  echo "System audit scan by $USER at $(get_timestamp) - Disk usage: ${CURRENT_SIZE_MB}MB" >"$AUDIT_NAME"
  echo "[INFO] $(get_timestamp) - Data dump generated and saved to ${AUDIT_NAME}" >>"$LOG_FILE"
fi
if [ $CLEANUP_FLAG -eq 1 ]; then
  RAW_COUNT=$(find "$TARGET_FOLDER" -maxdepth 1 -name "*.audit" 2>/dev/null | wc -l)

  if [ "$RAW_COUNT" -gt 0 ]; then
    ARCHIVE_NAME="${TARGET_FOLDER%/}/audit_archive_${filets}.tar.gz"

    echo "[INFO] $(get_timestamp) - Found $RAW_COUNT raw audit files. Packaging into $ARCHIVE_NAME" >>"$LOG_FILE"

    if find "$TARGET_FOLDER" -maxdepth 1 -name "*.audit" -print0 | tar --null -czf "$ARCHIVE_NAME" --files-from - 2>/dev/null; then
      echo "[INFO] $(get_timestamp) - Compression successful. Deleting individual raw .audit logs." >>"$LOG_FILE"
      find "$TARGET_FOLDER" -maxdepth 1 -name "*.audit" -delete
    else
      rm -rf "$ARCHIVE_NAME" 2>/dev/null
      echo "[ERROR] $(get_timestamp) - Compression failed. Raw files preserved." >>"$LOG_FILE"
    fi
  fi
fi

# Automated Storage Pruning
RETENTION_DAYS=${ARCHIVE_RETENTION_DAYS}
echo "[INFO] $(get_timestamp) - Pruning archives older than $RETENTION_DAYS days..." >>"$LOG_FILE"
find "$TARGET_FOLDER" -maxdepth 1 -name "*.tar.gz" -mtime +"$RETENTION_DAYS" -delete

ARCHIVE_COUNT=$(find "$TARGET_FOLDER" -maxdepth 1 -name "*.tar.gz" 2>/dev/null | wc -l | tr -d ' ')
echo "[INFO] $(get_timestamp) - Summary: Total compressed archives count: ${ARCHIVE_COUNT}" >>"$LOG_FILE"

if [ "$ARCHIVE_COUNT" -gt 0 ]; then
  LARGEST_ENTRY=$(find "$TARGET_FOLDER" -maxdepth 1 -name "*.tar.gz" -printf "%s %p\n" 2>/dev/null | sort -nr | head -n 1)
  LARGEST_BYTES=$(echo "$LARGEST_ENTRY" | awk '{print $1}')
  LARGEST_PATH=$(echo "$LARGEST_ENTRY" | cut -d' ' -f2-)
  LARGEST_NAME=$(basename "$LARGEST_PATH")
  LARGEST_MTIME=$(stat -c "%y" "$LARGEST_PATH" 2>/dev/null | cut -d'.' -f1)
  echo "[INFO] $(get_timestamp) - Summary: Largest archive ${LARGEST_NAME} is ${LARGEST_BYTES} bytes (modified: ${LARGEST_MTIME})." >>"$LOG_FILE"
fi

echo "[INFO] $(get_timestamp) - Daemon loop completed successfully." >>"$LOG_FILE"
exit "$E_SUCCESS"
