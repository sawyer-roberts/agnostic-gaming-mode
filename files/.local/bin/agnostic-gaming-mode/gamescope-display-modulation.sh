#!/bin/bash

CONFIG_FILE="$HOME/.config/gamescope/modes.cfg"
CONFIG_DIR="$(dirname "$CONFIG_FILE")"

mkdir -p "$CONFIG_DIR"
touch "$CONFIG_FILE"

inotifywait -m -q -e close_write "$CONFIG_FILE" | \
while read -r path action file; do
    gamescopectl backend_set_dirty
done
