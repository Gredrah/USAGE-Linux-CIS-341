#!/bin/bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/sysaudit.cfg"
if [[ ! -f "$CONFIG_FILE" ]]; then
echo "ERROR: configuration file not found." >&2
exit 3
fi
source "$CONFIG_FILE"

main() {
    echo "System health monitor starting..."
    echo "basic core script running."

    echo "audit directory: $AUDIT_DIR"
    echo "maximun disk usage: $MAX_DISK_MB MB"
    echo "Log file: $LOG_FILE"
    echo "scan interval: $SCAN_INTERVAL seconds"
    echo "clean up interval: $CLEANUP_INTERVAL_DAYS days" 
    echo "archive retention: $ARCHIVE_RETENTION_DAYS days"



} 
main