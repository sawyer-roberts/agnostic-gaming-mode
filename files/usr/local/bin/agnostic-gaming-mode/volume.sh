#!/bin/bash

CURRENT_USER=$(ps -o user= -p "$(cat /tmp/gamescope-session.pid 2>/dev/null)" 2>/dev/null)

if [ -z "$CURRENT_USER" ]; then
    CURRENT_USER=$(loginctl list-sessions --no-legend | grep -w "seat0" | awk '{print $3}' | head -n 1)
fi

case "$1" in
    up) /usr/bin/sudo -u "$CURRENT_USER" XDG_RUNTIME_DIR="/run/user/$(id -u "$CURRENT_USER")" wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ ;;
    down) /usr/bin/sudo -u "$CURRENT_USER" XDG_RUNTIME_DIR="/run/user/$(id -u "$CURRENT_USER")" wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
    mute) /usr/bin/sudo -u "$CURRENT_USER" XDG_RUNTIME_DIR="/run/user/$(id -u "$CURRENT_USER")" wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
esac
