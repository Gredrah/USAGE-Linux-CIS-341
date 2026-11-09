#!/bin/bash

set -euo pipefail

PREFIX="/usr/local/bin/USAGEd"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Makes sure script runs with sudo/root permissions
if [ "$EUID" -ne 0 ]; then
  echo "[Error] This installer should be ran with root authority. " >&2
  exit 1

fi

echo "Starting sysaudit daemon installation..."

# Creates dedicated group if it doesn't exist
if ! grep -q "^delegatedmanagers:" /etc/group; then
  echo "Creating group: delegatedmanagers"
  groupadd --system "delegatedmanagers"
else
  echo "Group 'delegatedmanagers' already exists."

fi

# Creates auditmanager user if it doesn't exist
if ! id "auditmanager" &>/dev/null; then
  echo "Creating user: auditmanager"
  useradd --system --no-create-home --shell /bin/false -g "delegatedmanagers" auditmanager
else
  echo "User 'auditmanager' already exists."
  # Ensures auditmanager belongs to the group if the user already existed.
  usermod -g "delegatedmanagers" auditmanager
fi

# Creates default workspace and log directories with correct ownership
echo "Creating tree at ${PREFIX}"
mkdir -p "${PREFIX}/src" "${PREFIX}/config"
mkdir -p /course_project/audit/ /var/log/
touch /var/log/sysaudit_daemon.log
chown -R auditmanager:delegatedmanagers /course_project/audit/
chown auditmanager:delegatedmanagers /var/log/sysaudit_daemon.log
chmod 750 /course_project/audit/
chmod 640 /var/log/sysaudit_daemon.log

# Copy files to /usr/local/bin + permissions correction
echo "Installing files and configuration"
install -m 755 -o root -g root "${SCRIPT_DIR}/../src/sysaudit.sh" "${PREFIX}/src/sysaudit.sh"
install -m 644 -o root -g root "${SCRIPT_DIR}/../config/sysaudit.cfg" "${PREFIX}/config/sysaudit.cfg"

# Copy systemd files + permissions correction
echo "Installing systemd server and timer files"
install -m 644 -o root -g root "${SCRIPT_DIR}/../systemd/sysaudit.service" "/etc/systemd/system/sysaudit.service"
install -m 644 -o root -g root "${SCRIPT_DIR}/../systemd/sysaudit.timer" "/etc/systemd/system/sysaudit.timer"

# Reload systemd, reset failed states, and enable the timer
echo "Enabling and starting systemd timer "
systemctl daemon-reload
systemctl reset-failed sysaudit.timer sysaudit.service || true
systemctl enable --now sysaudit.timer

echo "Installation complete. Sysaudit daemon is successfully scheduled under ${PREFIX}."
systemctl status sysaudit.timer
