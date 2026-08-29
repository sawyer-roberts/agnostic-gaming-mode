#!/bin/bash
set -e

# Prompt user with Warning before installation
while true; do
	echo -e "\nWarning:\n\nAgnostic Gaming Mode uses a custom version of Gamescope (Required for Gaming Mode).\nIf you already have Gamescope installed, please uninstall it before continuing.\nGamescope will still function normally in your regular Desktop Environment."
	echo -e "\nType 'Y/y' to continue the installation.\nType 'C/c' to cancel the installation."
	read -r continue_installation
	
	case "$continue_installation" in
		[Yy])
			echo -e "\nContinuing installation..."
			
			sleep 1
			
			break
			;;
		
		[Cc])
			exit 1
			;;
		
		*)
			echo -e "\nInvalid input. Please type 'Y/y' or 'C/c'."
			
			sleep 1
			;;
	
	esac
done

# Prompt user with Second Warning before installation
while true; do
	echo -e "\nWarning:\n\nAgnostic Gaming Mode is designed for single user setups.\nOnly the user that installed Agnostic Gaming Mode will be able to use it.\nThe installer can be run again as a different user."
	echo -e "\nType 'U/u' to understand this warning.\nType 'C/c' to cancel the installation."
	read -r understand_warning
	
	case "$understand_warning" in
		[Yy])
			echo -e "\nUnderstood Warning..."
			
			sleep 1
			
			break
			;;
		
		[Cc])
			exit 1
			;;
		
		*)
			echo -e "\nInvalid input. Please type 'U/u' or 'C/c'."
			
			sleep 1
			;;
	
	esac
done

# Install dependencies
sudo apt update
sudo apt install -y git meson ninja-build pkgconf cmake pipewire libpipewire-0.3-dev hwdata libx11-dev libwayland-dev vulkan-headers wayland-protocols libxdamage-dev libxcomposite-dev libxcursor-dev libxxf86vm-dev libxtst-dev libxres-dev libxmu-dev libxkbcommon-dev libcap-dev libsdl2-dev libavif-dev liblcms2-dev libseat-dev libinput-dev xwayland libxcb1-dev libxcb-icccm4-dev libxcb-ewmh-dev glslang-dev glslang-tools libluajit-5.1-dev catch2 wireplumber libwireplumber-0.4-dev libdisplay-info-dev libstb-dev konsole libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-good gstreamer1.0-pipewire v4l2loopback-dkms procps v4l-utils mangohud python3-evdev brightnessctl alsa-utils gawk inotify-tools drm-info jq python3-vdf python3 python3-xlib python3-dbus

# Define the name of the current directory
CUR_DIR=$(pwd)

# keyd is not available in the APT repository
# keyd needs to be compiled from source
git clone https://github.com/rvaiya/keyd.git
cd keyd
make && sudo make install
sudo systemctl enable --now keyd

cd "$CUR_DIR"

# Prompt user with option to install Decky Loader
while true; do
	echo -e "\nWould you like to install Decky Loader?\nDecky Loader allows you to customize Gaming Mode."
	echo -e "\nType 'Y/y' to install Decky Loader.\nType 'N/n' to not install Decky Loader."
	read -r install_decky
	
	case "$install_decky" in
		[Yy])
			# Install Decky Loader
			echo "Installing Decky Loader..."
			;;
			
			sleep 1
			
			rm -f /tmp/user_install_script.sh; if curl -S -s -L -O --output-dir /tmp/ --connect-timeout 60 https://github.com/SteamDeckHomebrew/decky-installer/releases/latest/download/user_install_script.sh; then bash /tmp/user_install_script.sh 2> /dev/null || echo "Decky Loader encountered a non-fatal Warning. Continuing installation..."; else echo "Decky Loader download failed.\nDecky Loader can be installed manually later."; read; fi
		
		[Nn])
			break
			;;
		
		*)
			echo "Invalid input. Please type 'Y/y' or 'N/n'."
			
			sleep 1
			;;
	
	esac
done

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
if [ ${#DISPLAYS[@]} -eq 0 ]; then
	echo "No active displays found."
	exit 1

fi

echo -e "\nAvailable Displays:"

# Echo the list of Displays
for i in "${!DISPLAYS[@]}"; do
	# Add the corresponding number to the Display
	echo "$((i + 1))) ${DISPLAYS[$i]}"

done

echo ""

# Prompt user to select a Display
while true; do
	read -p "Select a Display to use for Gaming Mode. Type the id number from the list (1-${#DISPLAYS[@]}): " CHOICE
	
	# Validate the users selection
	if [[ "$CHOICE" =~ ^[0-9]+$ ]] && [ "$CHOICE" -ge 1 ] && [ "$CHOICE" -le "${#DISPLAYS[@]}" ]; then
		
		# Grab the string based on the users choice
		SELECTED_STR="${DISPLAYS[$((CHOICE - 1))]}"
		
		# Parse the string
		if [[ "$SELECTED_STR" =~ ^(.*):\ ([0-9]+)x([0-9]+)\ @\ ([0-9]+)Hz$ ]]; then
			TEMP_DISPLAY="${BASH_REMATCH[1]}"
			TEMP_WIDTH="${BASH_REMATCH[2]}"
			TEMP_HEIGHT="${BASH_REMATCH[3]}"
			TEMP_REFRESH="${BASH_REMATCH[4]}"
			
			# Confirm the users choice
			echo ""
			echo "You selected:"
			echo "Display:      $TEMP_DISPLAY"
			echo "Resolution:   ${TEMP_WIDTH}x${TEMP_HEIGHT}"
			echo "Refresh Rate: ${TEMP_REFRESH}Hz"
			echo ""
			
			read -p "Is this correct? [Y/n] " CONFIRM
			
			# Restart loop if user selected wrong Display
			if [[ "$CONFIRM" =~ ^[Nn] ]]; then
				echo ""
				# Restart loop
				continue
			else
				# Assign the temporary variables to the final variables
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
echo -e "\nConfiguration saved successfully!"

sleep 1

cd "$CUR_DIR"

# Install files

# Compile Gamescope
# This will be replaced by an AUR installation
# AUR currently does not allow new user creation due to bots
git clone https://github.com/sawyer-roberts/agnostic-gamescope.git
cd "$CUR_DIR/agnostic-gamescope/"
git submodule update --init
meson setup build/
ninja -C build/
meson install -C build/ --skip-subprojects

# Give Gamescope elevated system privileges
if ! getcap /usr/local/bin/gamescope | grep -q "cap_sys_nice=eip"; then
	sudo setcap 'cap_sys_nice=eip' /usr/local/bin/gamescope
fi

cd "$CUR_DIR"

rm -rf "$CUR_DIR/agnostic-gamescope"

ACTUAL_USER="${SUDO_USER:-$USER}"
sudo usermod -aG input "$ACTUAL_USER"
echo "uinput" | sudo tee /etc/modules-load.d/uinput.conf > /dev/null
sudo modprobe uinput
echo 'KERNEL=="uinput", GROUP="input", MODE="0660"' | sudo tee /etc/udev/rules.d/99-uinput.rules > /dev/null
sudo udevadm control --reload-rules && sudo udevadm trigger

sudo mv "$CUR_DIR/files/usr/share/wayland-sessions/gaming-mode.desktop" "/usr/share/wayland-sessions/gaming-mode.desktop" && echo -e "\nMoved gaming-mode.desktop -> /usr/share/wayland-sessions/"

sudo mv "$CUR_DIR/files/usr/local/bin/agnostic-gaming-mode/gamescope-session" "/usr/local/bin/agnostic-gaming-mode/gamescope-session" && echo -e "\nMoved gamescope-session -> /usr/local/bin/agnostic-gaming-mode/"
sudo mv "$CUR_DIR/files/usr/local/bin/agnostic-gaming-mode/volume.sh" "/usr/local/bin/agnostic-gaming-mode/volume.sh" && echo -e "\nMoved volume.sh -> /usr/local/bin/agnostic-gaming-mode/"
sudo mv "$CUR_DIR/files/usr/local/bin/agnostic-gaming-mode/exit-session.sh" "/usr/local/bin/agnostic-gaming-mode/exit-session.sh" && echo -e "\nMoved exit-session.sh -> /usr/local/bin/agnostic-gaming-mode/"

echo "$USER ALL=(ALL:ALL) NOPASSWD: /usr/bin/modprobe, /usr/sbin/modprobe" | sudo tee /etc/sudoers.d/agnostic-gaming-mode-modprobe && echo -e "\nCreated sudoers rule 'agnostic-gaming-mode-modprobe' in /etc/sudoers.d/"

# Prompt user with option to enable controller shortuts for their keyboard
while true; do
	echo -e "\nWould you like to enable controller shortcuts on the Keyboard?\n\nThis changes:\nShift + Meta (Windows) -> Steam Button\nShift + Meta (Windows) + Alt -> Quick Access Menu\nShift + Escape -> B Button\n\nNote: Steam Menu and Quick Access Menu can still be accessed with Ctrl + 1/2 without it."
	echo -e "\nType 'Y/y' to enable controller shortcuts.\nType 'N/n' to disable controller shortcuts.
	read -r enable_shortcuts
	
	case "$enable_shortcuts" in
		[Yy])
			sudo mv "$CUR_DIR/files/usr/local/bin/agnostic-gaming-mode/keyboard-mouse-shortcuts.py" "/usr/local/bin/agnostic-gaming-mode/keyboard-mouse-shortcuts.py" && echo "Moved keyboard-mouse-shortcuts.py -> /usr/local/bin/agnostic-gaming-mode/"
			echo "$USER ALL=(root) NOPASSWD: /usr/bin/mv /etc/keyd/agnostic-gaming-mode.conf.disabled /etc/keyd/agnostic-gaming-mode.conf, /usr/bin/mv /etc/keyd/agnostic-gaming-mode.conf /etc/keyd/agnostic-gaming-mode.conf.disabled, /usr/bin/keyd reload" | sudo tee /etc/sudoers.d/agnostic-gaming-mode-keyd && echo -e "\nCreated sudoers rule 'agnostic-gaming-mode-keyd' in /etc/sudoers.d/"
			
			# Confirm file permissions and ownership
			sudo chmod 755 /usr/local/bin/agnostic-gaming-mode/keyboard-mouse-shortcuts.py
			sudo chown root:root /usr/local/bin/agnostic-gaming-mode/keyboard-mouse-shortcuts.py
			
			sudo chmod 0440 /etc/sudoers.d/agnostic-gaming-mode-keyd
			sudo chown root:root /etc/sudoers.d/agnostic-gaming-mode-keyd
			
			# Reload keyd configuration
			sudo keyd reload
			;;
		
		[Nn])
			break
			;;
		
		*)
			echo "Invalid input. Please type 'Y/y' or 'N/n'."
			
			sleep 1
			;;
	
	esac
done

mv "$CUR_DIR/files/.local/bin/agnostic-gaming-mode/gamescope-display-modulation.sh" "$HOME/.local/bin/agnostic-gaming-mode/gamescope-display-modulation.sh" && echo -e "\nMoved gamescope-display-modulation.sh -> $HOME/.local/bin/agnostic-gaming-mode/"
mv "$CUR_DIR/files/.local/bin/agnostic-gaming-mode/ScreenRecordingGamingMode.sh" "$HOME/.local/bin/agnostic-gaming-mode/ScreenRecordingGamingMode.sh" && echo -e "\nMoved ScreenRecordingGamingMode.sh -> $HOME/.local/bin/agnostic-gaming-mode/"

mv "$CUR_DIR/files/.config/systemd/user/gamescope-display-modulation.service" "$HOME/files/.config/systemd/user/gamescope-display-modulation.service" && echo -e "\nMoved gamescope-display-modulation.service -> $HOME/files/.config/systemd/user/"

# Create Steam Shortcut pointing to the exit-session.sh script
# This allows the user to log out of Gaming Mode
python3 << 'EOF'
import os
import vdf
import zlib
import shutil

APP_NAME = "Log Out"
EXE_PATH = "/usr/local/bin/agnostic-gaming-mode/exit-session.sh"
START_DIR = "/usr/local/bin/agnostic-gaming-mode/"

COVER = "$CUR_DIR/GitHub/Projects/agnostic-gaming-mode/files/steamart/cover.png"
WIDECOVER = "$CUR_DIR/GitHub/Projects/agnostic-gaming-mode/files/steamart/widecover.png"
BACKGROUND = "$CUR_DIR/GitHub/Projects/agnostic-gaming-mode/files/steamart/background.png"
LOGO = "$CUR_DIR/GitHub/Projects/agnostic-gaming-mode/files/steamart/logo.png"
ICON = "$CUR_DIR/GitHub/Projects/agnostic-gaming-mode/files/steamart/icon.png"

quoted_exe = f'"{EXE_PATH}"'
quoted_start = f'"{START_DIR}"'

# Calculate Steam's 32-bit AppID
# The target string MUST perfectly match the concatenated Quoted Exe and AppName.
target_string = f'{quoted_exe}{APP_NAME}'
crc = zlib.crc32(target_string.encode('utf-8'))
appid_32 = (crc & 0xFFFFFFFF) | 0x80000000

# The python-vdf library requires a signed 32-bit integer to correctly write binary data.
signed_appid = appid_32 - 0x100000000 if appid_32 > 0x7FFFFFFF else appid_32

# Artwork filenames always use the unsigned 32-bit string representation.
appid_str = str(appid_32)

steam_paths = [
	os.path.expanduser("~/.local/share/Steam/userdata"),
	os.path.expanduser("~/.var/app/com.valvesoftware.Steam/.local/share/Steam/userdata")
]

userdata_dir = next((path for path in steam_paths if os.path.exists(path)), None)

if userdata_dir:
	for user_id in os.listdir(userdata_dir):
		if not user_id.isdigit() or user_id == "0":
			continue

		shortcuts_path = os.path.join(userdata_dir, user_id, "config", "shortcuts.vdf")
		grid_dir = os.path.join(userdata_dir, user_id, "config", "grid")

		# Parse existing shortcuts
		if os.path.exists(shortcuts_path):
			with open(shortcuts_path, 'rb') as f:
				data = vdf.binary_load(f)
		else:
			data = {'shortcuts': {}}

		shortcuts = data.get('shortcuts', {})

		# Find the existing 'Log Out' shortcut to overwrite, or calculate a new index
		target_idx = None
		for idx, s in shortcuts.items():
			if isinstance(s, dict) and s.get('AppName') == APP_NAME:
				target_idx = idx
				break

		if target_idx is None:
			existing_indices = [int(k) for k in shortcuts.keys() if str(k).isdigit()]
			target_idx = str(max(existing_indices + [-1]) + 1)

		# Create Shortcut
		shortcuts[target_idx] = {
			'appid': signed_appid,
			'AppName': APP_NAME,
			'Exe': quoted_exe,
			'StartDir': quoted_start,
			'icon': ICON if os.path.exists(ICON) else '',
			'ShortcutPath': '',
			'LaunchOptions': '',
			'IsHidden': 0,
			'AllowDesktopConfig': 1,
			'AllowOverlay': 1,
			'OpenVR': 0,
			'Devkit': 0,
			'DevkitGameID': '',
			'DevkitOverrideAppID': 0,
			'LastPlayTime': 0,
			'FlatpakAppID': '',
			'tags': {}
		}
		data['shortcuts'] = shortcuts

		os.makedirs(os.path.dirname(shortcuts_path), exist_ok=True)
		with open(shortcuts_path, 'wb') as f:
			vdf.binary_dump(data, f)

		print(f"Added 'Log Out' Shortcut for Steam ID: {user_id}")

		# Add Artwork to the Shortcut
		os.makedirs(grid_dir, exist_ok=True)

		# Use the 32-bit AppID string for ALL artwork
		if os.path.exists(COVER):
			ext = os.path.splitext(COVER)[1]
			shutil.copy(COVER, os.path.join(grid_dir, f"{appid_str}p{ext}"))

		if os.path.exists(WIDECOVER):
			ext = os.path.splitext(WIDECOVER)[1]
			shutil.copy(WIDECOVER, os.path.join(grid_dir, f"{appid_str}{ext}"))

		if os.path.exists(BACKGROUND):
			ext = os.path.splitext(BACKGROUND)[1]
			shutil.copy(BACKGROUND, os.path.join(grid_dir, f"{appid_str}_hero{ext}"))

		if os.path.exists(LOGO):
			ext = os.path.splitext(LOGO)[1]
			shutil.copy(LOGO, os.path.join(grid_dir, f"{appid_str}_logo{ext}"))

		print(f"Applied Artwork to 'Log Out' Shortcut for Steam ID: {user_id}")
EOF

# Confirm file permissions and ownership
sudo chmod 644 /usr/share/wayland-sessions/gaming-mode.desktop
sudo chown root:root /usr/share/wayland-sessions/gaming-mode.desktop

sudo chmod 755 /usr/local/bin/agnostic-gaming-mode/gamescope-session
sudo chown root:root /usr/local/bin/agnostic-gaming-mode/gamescope-session

sudo chmod 755 /usr/local/bin/agnostic-gaming-mode/volume.sh
sudo chown root:root /usr/local/bin/agnostic-gaming-mode/volume.sh

sudo chmod 0440 /etc/sudoers.d/agnostic-gaming-mode-modprobe
sudo chown root:root /etc/sudoers.d/agnostic-gaming-mode-modprobe

sudo chmod 755 $HOME/.local/bin/agnostic-gaming-mode/gamescope-display-modulation.sh
sudo chown $USER:$USER $HOME/.local/bin/agnostic-gaming-mode/gamescope-display-modulation.sh

sudo chmod 755 $HOME/.local/bin/agnostic-gaming-mode/ScreenRecordingGamingMode.sh
sudo chown $USER:$USER $HOME/.local/bin/agnostic-gaming-mode/ScreenRecordingGamingMode.sh

sudo chmod 644 $HOME/.config/systemd/user/gamescope-display-modulation.service
sudo chown $USER:$USER $HOME/.config/systemd/user/gamescope-display-modulation.service

# Closing Statement
echo -e "\n\nAgnostic Gaming Mode is now installed!\nTip: Use the new 'Log Out' shortcut in Steam to Log Out of Gaming Mode.\nRestart Steam for the changes to take effect."
