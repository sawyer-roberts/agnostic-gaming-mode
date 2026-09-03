#!/bin/bash
declare -A KBD_PATHS

for dev in /dev/input/by-id/*-kbd /dev/input/by-path/*-kbd; do
    if [[ -e "$dev" ]]; then
        real_path=$(readlink -f "$dev")
        KBD_PATHS["$real_path"]=1
    fi
done

for sysdev in /sys/class/input/event*; do
    if [[ -f "$sysdev/device/name" ]] && grep -qi "keyd" "$sysdev/device/name"; then
        KBD_PATHS["/dev/input/$(basename "$sysdev")"]=1
    fi
done

if [[ ${#KBD_PATHS[@]} -eq 0 ]]; then
    echo "Fatal: No keyboard devices found."
    exit 1
fi

EVS_ARGS=()
for dev in "${!KBD_PATHS[@]}"; do
    EVS_ARGS+=("--input" "$dev")
done

exec /usr/bin/evsieve "${EVS_ARGS[@]}" --hook key:leftmeta key:leftalt key:leftctrl key:backspace exec-shell="/usr/local/bin/agnostic-gaming-mode/restart.sh"
