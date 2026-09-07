#!/bin/bash
set -e

# Prompt user to select a display for Gamescope
echo "Scanning for connected displays..."

sleep 1

# Store output from jq in DISPLAYS array
mapfile -t DISPLAYS < <(drm_info -j | jq -r '
        .[] |
        (.crtcs // [] | map({(.id|tostring): (.mode // .properties?.MODE_ID?.data)}) | add // {}) as $crtcs |
        (.encoders // [] | map({(.id|tostring): (.crtc // .crtc_id)}) | add // {}) as $encoders |
        (
                .connectors // []
                | group_by(.type)
                | map(to_entries | map(.value + {type_idx: (.key + 1)}))
                | flatten
        )[] |
        select(.status == 1 or .status == "connected") |
        (
                (.properties?.CRTC_ID?.value) //
                ($encoders[(.encoder_id // .encoder)|tostring]) //
                0
        ) as $crtc_id |
        select($crtc_id != null and $crtc_id != 0) |
        $crtcs[$crtc_id|tostring] as $mode |
        select($mode != null and $mode.name != null) |
        (
                {
                        "1":"VGA-", "2":"DVI-I-", "3":"DVI-D-", "4":"DVI-A-", "5":"Composite-",
                        "6":"SVIDEO-", "7":"LVDS-", "8":"Component-", "9":"DIN-", "10":"DP-",
                        "11":"HDMI-A-", "12":"HDMI-B-", "13":"TV-", "14":"eDP-", "15":"Virtual-",
                        "16":"DSI-", "17":"DPI-", "18":"Writeback-"
                }[.type|tostring] // "Port-"
        ) as $port |
        "\($port)\(.type_idx): \($mode.name) @ \($mode.vrefresh)Hz"
')

# Check if any displays were found
if [ "${#DISPLAYS[@]}" -eq 0 ]; then
        echo "No active displays found."

        exit 1

fi

echo -e "\nAvailable Displays:"
for i in "${!DISPLAYS[@]}"; do
        echo "$((i + 1))) ${DISPLAYS[$i]}"

done

echo ""

# Prompt user to select a Display
while true; do
        read -r -p "Select a Display to use for Gaming Mode. Type the id number from the list (1-${#DISPLAYS[@]}): " CHOICE

        if [[ "$CHOICE" =~ ^[0-9]+$ ]] && [ "$CHOICE" -ge 1 ] && [ "$CHOICE" -le "${#DISPLAYS[@]}" ]; then
                SELECTED_STR="${DISPLAYS[$((CHOICE - 1))]}"
                if [[ "$SELECTED_STR" =~ ^(.*):\ ([0-9]+)x([0-9]+)\ @\ ([0-9]+)Hz$ ]]; then
                        TEMP_DISPLAY="${BASH_REMATCH[1]}"
                        TEMP_WIDTH="${BASH_REMATCH[2]}"
                        TEMP_HEIGHT="${BASH_REMATCH[3]}"
                        TEMP_REFRESH="${BASH_REMATCH[4]}"

                        echo ""
                        echo "You selected:"
                        echo "Display:      $TEMP_DISPLAY"
                        echo "Resolution:   ${TEMP_WIDTH}x${TEMP_HEIGHT}"
                        echo "Refresh Rate: ${TEMP_REFRESH}Hz"
                        echo ""

                        read -r -p "Is this correct? [Y/n] " CONFIRM
                        if [[ "$CONFIRM" =~ ^[Nn] ]]; then
                                echo ""
                                continue
                        else
                                CHOSEN_DISPLAY="$TEMP_DISPLAY"
                                CHOSEN_WIDTH="$TEMP_WIDTH"
                                CHOSEN_HEIGHT="$TEMP_HEIGHT"
                                CHOSEN_REFRESH="$TEMP_REFRESH"
                                break

                        fi
                else
                        echo "Error parsing the selected display data."

                        exit 1

                fi
        else
                echo "Invalid selection."

        fi
done

# Save user choice to file
echo -e "GAMESCOPE_DISPLAY=\"$CHOSEN_DISPLAY\"\nGAMESCOPE_WIDTH=\"$CHOSEN_WIDTH\"\nGAMESCOPE_HEIGHT=\"$CHOSEN_HEIGHT\"\nGAMESCOPE_REFRESH=\"$CHOSEN_REFRESH\"" | sudo tee /etc/gamescope-display.env > /dev/null
INSTALLED_FILES+=("/etc/gamescope-display.env")

echo -e "\nConfiguration saved successfully!"
