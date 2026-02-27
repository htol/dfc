#!/bin/sh

# Hyprland Session Start Helper
# This script ensures that the environment is updated and autostart apps are triggered.

# 1. Check if UWSM (or another session manager) has already started the session
if command -v uwsm >/dev/null 2>&1 && uwsm check is-active >/dev/null 2>&1; then
    echo "Session already managed by UWSM. Exiting helper."
    exit 0
fi

# 2. Update DBus and Systemd environment
dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

# 3. Trigger XDG Autostart services
# Since graphical-session.target refuses manual start, we trigger the services directly.
# We find all "generated" autostart units.
AUTOSTART_UNITS=$(systemctl --user list-unit-files --no-legend "app-*@autostart.service" | awk '{print $1}')

if [ -n "$AUTOSTART_UNITS" ]; then
    echo "Starting autostart units: $AUTOSTART_UNITS"
    # We use --no-block to avoid waiting for apps to close
    systemctl --user start --no-block $AUTOSTART_UNITS
else
    echo "No autostart units found."
fi

