#!/bin/bash

# POSIX Exit Code(s)
E_SUCCESS=0
E_GENERIC=1
E_IDENTITY=2
E_CONFIG=3
E_WORKSPACE=4
E_CEILING=5

CONFIG_FILE="../config/sysaudit.cfg"

# Function for Exits & Logging
fail_with() {
  local code=$1
  local message=$2
  echo "[ERROR] $(date) - $message" >&2
  if [ -f "$LOG_FILE" ]; then
    echo "[ERROR] $(date) - Terminated with code $code: $message" >>"$LOG_FILE"
  fi
  exit "$code"
}

# User Execution Space Sandboxing
USER=$(id -un)
if [ "$USER" != "auditmanager" ]; then
  fail_with "$E_IDENTITY" "Privilege violation: Process must execute as auditmanager."
fi
echo "Security Check passed! Welcome $USER."

# Configuration Loading
if [ ! -f "$CONFIG_FILE" ]; then
  fail_with "$E_CONFIG" "Configuration file $CONFIG_FILE not found."
fi
source "$CONFIG_FILE"

#detailed help statement and dumpin stuff
display_help() {
    cat << 'EOF'
======================================================================
System Health Monitor & Security Auditing Daemon
======================================================================


INSTRUCTIONS & OPERATIONAL SYNTAX:
  sysaudit [OPTIONS]
 
EXECUTION EXAMPLES:
  sysaudit --help                  # Display this exhaustive USAGE statement
  sysaudit --delegate tom_jones     # Delegate execution rights/file access to user 'tom_jones'
  sysaudit --limit 150             # Override baseline storage limit to 150MB for this loop


SAMPLE RESULTS & LOGS:
  [INFO] 2026-10-22 14:00:01 - Scan loop initialized successfully.
  [WARN] 2026-10-22 14:05:00 - Storage envelope at 95MB (Limit: 100MB).
  [ERROR] 2026-10-22 14:10:00 - IDENTITY_VIOLATION triggered.


PARAMETER OPTIONS:
  -h, --help       Intercept execution and dump this Program USAGE Statement.
  --delegate <usr> Explicit functional argument to safely delegate rights to <usr>.
  --limit <size>   Overwrite the max safety constraint envelope value dynamically.


CONFIGURATION SCHEMA (sysaudit.cfg):
  TARGET_DIR       : Target folder path for workspace (e.g., /course_project/audit/)
  STORAGE_LIMIT_MB : Over-allocation baseline limit in MB
  LOG_PATH         : Path to the dedicated internal auditing trace log


ERROR CODE DICTIONARY:
  0 | SUCCESS               | Operational task ran to completion without tracking loops faults.
  1 | GENERIC_ERROR         | An unmapped error condition triggered a process escape.
  2 | IDENTITY_VIOLATION    | Process call called by an unverified account other than auditmanager.
  3 | CONFIGURATION_MISSING | The explicit target configuration layout file sysaudit.cfg was not found.
  4 | INVALID_WORKSPACE     | Target mapping path missing or is not a directory.
  5 | DISK_CEILING_REACHED  | Workspace capacity validation failed critical storage envelope margins.
EOF
}

#dump USAGE statement if run manually from the command line w/o args or help flag
if [[ "$#" -eq 0 || "$1" == "-h" || "$1" == "--help" ]]; then
    display_help
    exit 0
fi

#auditmanager permissions delegation section
DELEGATED_USER=""

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --limit)
            STORAGE_LIMIT_MB="$2"
            shift 2
            ;;
        --delegate)
            #secure role delegation and autonomy allocation bit
            DELEGATED_USER="$2"
            shift 2
            ;;
        *)
            echo "[ERROR] GENERIC_ERROR: Unknown parameter provided: $1" >&2
            exit 1
            ;;
    esac
done

# Apply the delegation logic if the argument was passed
if [[ -n "$DELEGATED_USER" ]]; then
   
    # Verify the user exists on the system
    if id "$DELEGATED_USER" &>/dev/null; then
        echo "[INFO] Valid user found. Delegating file domain group access to: $DELEGATED_USER"
       
        #Change the group ownership of the workspace directory recursively
        chgrp -R "$DELEGATED_USER" "$TARGET_DIR" 2>/dev/null
       
        #Grant read, write, and execute permissions to the new group
        chmod -R g+rwx "$TARGET_DIR" 2>/dev/null
       
       
        echo "[INFO] Delegation successful. Workspace $TARGET_DIR is now accessible by $DELEGATED_USER."
       
    else
        # Trap the issue and document properly
        echo "[ERROR] GENERIC_ERROR: Delegated user '$DELEGATED_USER' does not exist on this system." >&2
       
        exit 1
    fi
fi

# Default log file fallback if not defined in config
LOG_FILE="${LOG_FILE:-/var/log/sysaudit_daemon.log}"

# Workspace Validation
if [ ! -d "$TARGET_FOLDER" ]; then
  fail_with "$E_WORKSPACE" "Target workspace $TARGET_FOLDER missing or not a directory."
fi

echo " $(date) - Daemon execution started." >>"$LOG_FILE"

# Resource Ceiling Warning Check
CURRENT_SIZE_MB=$(du -sm "$TARGET_FOLDER" 2>/dev/null | cut -f1)
if [ -n "$CEILING_LIMIT_MB" ] && [ "$CURRENT_SIZE_MB" -gt "$CEILING_LIMIT_MB" ]; then
  echo "[WARNING] $(date) - Disk ceiling reached: ${CURRENT_SIZE_MB}MB exceeds limit of ${CEILING_LIMIT_MB}MB" >>"$LOG_FILE"
fi

# Compress and Cleanup
ARCHIVE_DIR="${TARGET_FOLDER}archives/"
mkdir -p "$ARCHIVE_DIR"

RAW_COUNT=$(find "$TARGET_FOLDER" -maxdepth 1 -name "*.audit" | wc -l)

if [ "$RAW_COUNT" -gt 0 ]; then
  TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
  ARCHIVE_NAME="${ARCHIVE_DIR}audit_archive_${TIMESTAMP}.tar.gz"

  echo " $(date) - Found $RAW_COUNT raw audit files. Packaging into archive." >>"$LOG_FILE"

  # Compress raw files into tar.gz package
  find "$TARGET_FOLDER" -maxdepth 1 -name "*.audit" -print0 | tar --null -czf "$ARCHIVE_NAME" --files-from -

  if [ $? -eq 0 ]; then
    echo " $(date) - Compression successful. Deleting individual raw source files." >>"$LOG_FILE"
    find "$TARGET_FOLDER" -maxdepth 1 -name "*.audit" -delete
  else
    echo "[ERROR] $(date) - Compression failed. Raw files preserved." >>"$LOG_FILE"
  fi
fi

# Automated Storage Pruning
RETENTION_DAYS=$((${RETENTION_WEEKS:-2} * 7))
echo " $(date) - Pruning archives older than $RETENTION_DAYS days..." >>"$LOG_FILE"
find "$ARCHIVE_DIR" -name "*.tar.gz" -mtime +"$RETENTION_DAYS" -delete

echo " $(date) - Daemon loop completed successfully." >>"$LOG_FILE"
exit "$E_SUCCESS"
