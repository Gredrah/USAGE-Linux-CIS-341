#!/bin/bash

set -euo pipefail

PREFIX="/usr/local/bin/USAGEd"
PURGE=0

if [[ "${1:-}" == "--purge" || "${1:-}" == "-p" ]]; then
  PURGE=1
fi

# Ensure script runs with sudo/root permissions
if [ "$EUID" -ne 0 ]; then
  echo "[Error] This uninstaller must be run with root authority." >&2
  exit 1
fi

echo "Starting sysaudit daemon uninstallation..."

# Stop and disable systemd timer and service
echo "Stopping and disabling systemd timer and service..."
systemctl stop sysaudit.timer sysaudit.service 2>/dev/null || true
systemctl disable sysaudit.timer sysaudit.service 2>/dev/null || true

# Remove systemd unit files and reload daemon
echo "Removing systemd unit files..."
rm -f /etc/systemd/system/sysaudit.service
rm -f /etc/systemd/system/sysaudit.timer
systemctl daemon-reload
systemctl reset-failed 2>/dev/null || true

# Remove installed application files and sudoers rule
echo "Removing installed files at ${PREFIX}..."
rm -rf "${PREFIX}"
rm -f /etc/sudoers.d/sysaudit

# Optionally remove workspace and logs (or preserve them by default)
if [ "$PURGE" -eq 1 ]; then
  echo "Purging audit workspace and log files..."
  rm -rf /course_project/audit/
  rm -f /var/log/sysaudit_daemon.log
else
  echo "Preserving /course_project/audit/ and /var/log/sysaudit_daemon.log (run with --purge to delete)."
fi

# Remove auditmanager user and delegatedmanagers group
if id "auditmanager" &>/dev/null; then
  echo "Removing user: auditmanager"
  pkill -u auditmanager 2>/dev/null || true
  userdel "auditmanager" 2>/dev/null || true
fi

if grep -q "^delegatedmanagers:" /etc/group; then
  echo "Removing group: delegatedmanagers"
  groupdel "delegatedmanagers" 2>/dev/null || true
fi

echo "Uninstallation complete."
