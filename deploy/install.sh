#!/bin/bash

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


# Creates workspace and log directories with correct ownership
echo "Creating directories"
mkdir -p /course_project/audit
mkdir -p /var/log
touch /var/log/sysaudit_daemon.log

chown -R auditmanager:auditmanager /course_project/audit
chown auditmanager:auditmanager /var/log/sysaudit_daemon.log
chmod 750 /course_project/audit


# Copy files to /usr/local/bin + permissions correction
echo "Installing files and configuration"
cp ../src/sysaudit.sh /usr/local/bin/sysaudit.sh
cp ../config/sysaudit.cfg /usr/local/bin/sysaudit.cfg
cp ../src/usage.readme /usr/local/bin/usage.readme

chown root:root /usr/local/bin/sysaudit.sh
chmod 755 /usr/local/bin/sysaudit.sh

chown root:root /usr/local/bin/sysaudit.cfg
chmod 644 /usr/local/bin/sysaudit.cfg

chown root:root /usr/local/bin/usage.readme
chmod 644 /usr/local/bin/usage.readme

# Copy systemd files + permissions correction
echo "Installing systemd server and timer files"
cp ../systemd/sysaudit.service /etc/systemd/system/sysaudit.service
cp ../systemd/sysaudit.timer /etc/systemd/system/sysaudit.timer

chmod 644 /etc/systemd/system/sysaudit.service
chmod 644 /etc/systemd/system/sysaudit.timer

# Reload systemd, reset failed states, and enable the timer
echo "Enabling and starting systemd timer "
systemctl daemon-reload
systemctl reset-failed sysaudit.timer sysaudit.service || true
systemctl enable --now sysaudit.timer

echo "Installation complete. Sysaudit daemon is successfully scheduled."
systemctl status sysaudit.timer

