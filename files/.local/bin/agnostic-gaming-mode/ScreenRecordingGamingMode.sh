#!/bin/bash

CONFIG_FILE="$HOME/.config/gamescope/modes.cfg"
CONFIG_DIR="$(dirname "$CONFIG_FILE")"

mkdir -p "$CONFIG_DIR"
touch "$CONFIG_FILE"

cleanup() {
    # Ensure gst-launch-1.0 is killed on exit
    pkill -9 gst-launch-1.0 > /dev/null 2>&1
    exit
}

trap cleanup INT TERM HUP EXIT

start_recording() {
    if [ -s "$CONFIG_FILE" ]; then
        # Get only the resolution from the modes.cfg file
        RESOLUTION=$(head -n 1 "$CONFIG_FILE" | cut -d':' -f2 | cut -d'@' -f1)
        
        # Separate the width and height variables
        RECORDING_WIDTH=$(echo "$RESOLUTION" | cut -d'x' -f1)
        RECORDING_HEIGHT=$(echo "$RESOLUTION" | cut -d'x' -f2)
    fi

    # Set fallbacks just in case the variables are empty
    RECORDING_WIDTH=${RECORDING_WIDTH:-1920}
    RECORDING_HEIGHT=${RECORDING_HEIGHT:-1080}

    pkill -9 gst-launch-1.0 > /dev/null 2>&1
    sleep 1

    echo "Starting recording at ${RECORDING_WIDTH}x${RECORDING_HEIGHT}..."

    gst-launch-1.0 \
        pipewiresrc target-object=gamescope do-timestamp=true always-copy=true ! \
        queue max-size-buffers=5 leaky=2 ! \
        videorate drop-only=true ! \
        video/x-raw,framerate=60/1 ! \
        videoscale n-threads=4 ! \
        video/x-raw,width=${RECORDING_WIDTH},height=${RECORDING_HEIGHT} ! \
        videoconvert n-threads=4 ! \
        video/x-raw,format=YUY2,colorimetry=bt709 ! \
        identity drop-allocation=true ! \
        v4l2sink device=/dev/video10 sync=false async=false qos=false &
}

# Start recording before monitoring starts
start_recording

# Wait for Recording to initialize
sleep 2

# Monitor the config file and restart the recording on close_write events
inotifywait -m -q -e close_write "$CONFIG_FILE" | \
while read -r path action file; do
    start_recording
done
