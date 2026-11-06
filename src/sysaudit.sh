#!/bin/bash

# POSIX Exit Code(s)
E_SUCCESS=0
E_GENERIC=1
E_IDENTITY=2
E_CONFIG=3
E_WORKSPACE=4
E_CEILING=5

CONFIG_FILE="/usr/local/bin/sysaudit.cfg"

# Function for Exits & Logging
fail_with() {
    local code=$1
    local message=$2
    echo "[ERROR] $(date) - $message" >&2
    if [ -f "$LOG_FILE" ]; then
        echo "[ERROR] $(date) - Terminated with code $code: $message" >> "$LOG_FILE"
    fi
    exit "$code"
}

# User Execution Space Sandboxing
if [ "$USER" != "auditmanager" ]; then
    fail_with "$E_IDENTITY" "Privilege violation: Process must execute as auditmanager."
fi

# Configuration Loading
if [ ! -f "$CONFIG_FILE" ]; then
    fail_with "$E_CONFIG" "Configuration file $CONFIG_FILE not found."
fi
source "$CONFIG_FILE"

# Default log file fallback if not defined in config
LOG_FILE="${LOG_FILE:-/var/log/sysaudit_daemon.log}"

# Workspace Validation
if [ ! -d "$TARGET_FOLDER" ]; then
    fail_with "$E_WORKSPACE" "Target workspace $TARGET_FOLDER missing or not a directory."
fi

echo " $(date) - Daemon execution started." >> "$LOG_FILE"

# Resource Ceiling Warning Check
CURRENT_SIZE_MB=$(du -sm "$TARGET_FOLDER" 2>/dev/null | cut -f1)
if [ -n "$CEILING_LIMIT_MB" ] && [ "$CURRENT_SIZE_MB" -gt "$CEILING_LIMIT_MB" ]; then
    echo "[WARNING] $(date) - Disk ceiling reached: ${CURRENT_SIZE_MB}MB exceeds limit of ${CEILING_LIMIT_MB}MB" >> "$LOG_FILE"
fi

# Compress and Cleanup
ARCHIVE_DIR="${TARGET_FOLDER}archives/"
mkdir -p "$ARCHIVE_DIR"

RAW_COUNT=$(find "$TARGET_FOLDER" -maxdepth 1 -name "*.audit" | wc -l)

if [ "$RAW_COUNT" -gt 0 ]; then
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    ARCHIVE_NAME="${ARCHIVE_DIR}audit_archive_${TIMESTAMP}.tar.gz"

    echo " $(date) - Found $RAW_COUNT raw audit files. Packaging into archive." >> "$LOG_FILE"

    # Compress raw files into tar.gz package
    find "$TARGET_FOLDER" -maxdepth 1 -name "*.audit" -print0 | tar --null -czf "$ARCHIVE_NAME" --files-from -

    if [ $? -eq 0 ]; then
        echo " $(date) - Compression successful. Deleting individual raw source files." >> "$LOG_FILE"
        find "$TARGET_FOLDER" -maxdepth 1 -name "*.audit" -delete
    else
        echo "[ERROR] $(date) - Compression failed. Raw files preserved." >> "$LOG_FILE"
    fi
fi

# Automated Storage Pruning
RETENTION_DAYS=$(( ${RETENTION_WEEKS:-2} * 7 ))
echo " $(date) - Pruning archives older than $RETENTION_DAYS days..." >> "$LOG_FILE"
find "$ARCHIVE_DIR" -name "*.tar.gz" -mtime +"$RETENTION_DAYS" -delete

echo " $(date) - Daemon loop completed successfully." >> "$LOG_FILE"
exit "$E_SUCCESS"
