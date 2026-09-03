#!/bin/bash

USER_NAME=$(loginctl list-sessions --no-legend | grep -w seat0 | awk '{print $3}' | head -n 1)
USER_UID=$(id -u "$USER_NAME")

pkill -9 -U "$USER_NAME" steam

sleep 2

rm -f "/home/$USER_NAME/.steam/steam.pid"
rm -f "/home/$USER_NAME/.steam/root/pid"

# Check if Gaming Mode is active
if [ -f /tmp/gamescope-session.pid ]; then
	exit 0
fi

SYS_ENV=$(runuser -u "$USER_NAME" -- env XDG_RUNTIME_DIR="/run/user/$USER_UID" systemctl --user show-environment)
ACTIVE_DISPLAY=$(echo "$SYS_ENV" | grep '^DISPLAY=' | cut -d= -f2)
ACTIVE_WAYLAND=$(echo "$SYS_ENV" | grep '^WAYLAND_DISPLAY=' | cut -d= -f2)
ACTIVE_XAUTH=$(echo "$SYS_ENV" | grep '^XAUTHORITY=' | cut -d= -f2)

if [[ -z "$ACTIVE_XAUTH" ]]; then
	ACTIVE_XAUTH=$(find "/run/user/$USER_UID" -maxdepth 1 -type f -name "xauth_*" 2>/dev/null | head -n 1)
	[[ -z "$ACTIVE_XAUTH" ]] && ACTIVE_XAUTH="/home/$USER_NAME/.Xauthority"
fi

[[ -z "$ACTIVE_DISPLAY" ]] && ACTIVE_DISPLAY=":1"
[[ -z "$ACTIVE_WAYLAND" ]] && ACTIVE_WAYLAND="wayland-0"

runuser -u "$USER_NAME" -- env XDG_RUNTIME_DIR="/run/user/$USER_UID" WAYLAND_DISPLAY="$ACTIVE_WAYLAND" DISPLAY="$ACTIVE_DISPLAY" XAUTHORITY="$ACTIVE_XAUTH" /usr/bin/steam > /dev/null 2>&1 &
