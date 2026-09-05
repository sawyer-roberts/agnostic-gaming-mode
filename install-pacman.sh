#!/bin/bash
set -e

if [ "$EUID" -eq 0 ]; then
	echo "Error: Do not run this script using sudo."
	
	exit 1

fi

# Array to track installed files
declare -a INSTALLED_FILES

rollback_on_exit() {
	local exit_code=$?
	
	# Trigger rollback only if the script exits with a non-zero error
	if [ "$exit_code" -ne 0 ] && [ "${#INSTALLED_FILES[@]}" -gt 0 ]; then
		echo -e "\n\nInstallation interrupted. Rolling back system changes..."
		
		# Iterate through the array and remove tracked files/directories
		for target_file in "${INSTALLED_FILES[@]}"; do
			if [ -e "$target_file" ]; then
				sudo rm -rf "$target_file"
				echo "Reverted: $target_file"
			fi
		done
		
		echo "Rollback complete."
	fi
	
	exit "$exit_code"
}

trap rollback_on_exit EXIT SIGINT SIGTERM

CUR_DIR=$(dirname "$(readlink -f "$0")")

# Validate required local files exist before starting
if [ ! -d "$CUR_DIR/files" ]; then
        echo "Error: Required asset directory 'files' is missing from $CUR_DIR. Please ensure you have extracted all files."

        exit 1

fi

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
		[Uu])
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

# Detect active kernel to install matching headers for DKMS
KERNEL_PKG=$(pacman -Qqo "/usr/lib/modules/$(uname -r)" 2>/dev/null || echo "linux")
HEADER_PKG="${KERNEL_PKG}-headers"

# Install dependencies
PACKAGES=(
	"$HEADER_PKG" curl git meson ninja pkgconf cmake pipewire hwdata libx11 wayland 
	vulkan-headers wayland-protocols libxdamage libxcomposite libxcursor libxxf86vm 
	libxtst libxres libxmu libxkbcommon libcap sdl2 libavif lcms2 seatd libinput 
	xorg-xwayland libxcb xcb-util-wm glslang luajit catch2 wireplumber libdisplay-info 
	stb konsole gstreamer gst-plugins-base gst-plugins-good gst-plugin-pipewire 
	v4l2loopback-dkms procps-ng v4l-utils mangohud python-evdev brightnessctl alsa-utils 
	gawk keyd inotify-tools drm-info jq python-vdf python python-xlib python-dbus gcc 
	yaml-cpp libxnvctrl dbus python-mako libevdev cargo make bison flex vulkan-icd-loader 
	libglvnd mesa libdrm systemd
)

for pkg in "${PACKAGES[@]}"; do
	sudo pacman -S --needed --noconfirm "$pkg" || echo "Warning: Failed to install $pkg, skipping..."
done

if command -v paru &> /dev/null && ! command -v yay &> /dev/null; then
	paru -S --needed --noconfirm evsieve

elif ! command -v paru &> /dev/null && command -v yay &> /dev/null; then
	yay -S --needed --noconfirm evsieve

elif command -v paru &> /dev/null && command -v yay &> /dev/null; then
	while true; do
		echo -e "\nWould you like to use paru or yay to install the package 'evsieve'"
		echo -e "\nType 'paru' to use paru.\nType 'yay' to use yay."
		read -r paru_or_yay

		case "$paru_or_yay" in
			paru)
				paru -S --needed --noconfirm evsieve
				break
				;;
			
			yay)
				yay -S --needed --noconfirm evsieve
				break
				;;
			
			*)
				echo "Invalid Input. Please type 'paru' or 'yay'."
				;;
		
		esac
	done

elif ! command -v paru &> /dev/null && ! command -v yay &> /dev/null; then
	while true; do
		echo -e "\nWould you like to use paru or yay to install the package 'evsieve'"
		echo -e "\nType 'paru' to use paru.\nType 'yay' to use yay."
		read -r paru_or_yay

		case "$paru_or_yay" in
			paru)
				if pacman -Ss '^paru$' &> /dev/null; then
					sudo pacman -S --needed --noconfirm paru
					paru -S --needed --noconfirm evsieve
				
				else
					sudo pacman -S --needed --noconfirm base-devel
					rm -rf paru
					git clone https://aur.archlinux.org/paru.git
					cd paru || exit
					makepkg -si --noconfirm
					cd "$CUR_DIR"
					paru -S --needed --noconfirm evsieve
				fi
				
				break
				;;
			
			yay)
				if pacman -Ss '^yay$' &> /dev/null; then
					sudo pacman -S --needed --noconfirm yay
					yay -S --needed --noconfirm evsieve
				
				else
					sudo pacman -S --needed --noconfirm git base-devel
					rm -rf yay
					git clone https://aur.archlinux.org/yay.git
					cd yay || exit
					makepkg -si --noconfirm
					cd "$CUR_DIR"
					yay -S --needed --noconfirm evsieve
				
				fi
				
				break
				;;
			
			*)
				echo "Invalid Input. Please type 'paru' or 'yay'."
				;;
		
		esac
	done
fi

# Prompt user with option to install Decky Loader
while true; do
	echo -e "\nWould you like to install Decky Loader?\nDecky Loader allows you to customize Gaming Mode."
	echo -e "\nType 'Y/y' to install Decky Loader.\nType 'N/n' to not install Decky Loader."
	read -r install_decky
	
	case "$install_decky" in
		[Yy])
			echo "Installing Decky Loader..."
			
			sleep 1
			
			rm -f /tmp/user_install_script.sh
			if curl -S -s -L -O --output-dir /tmp/ --connect-timeout 60 https://github.com/SteamDeckHomebrew/decky-installer/releases/latest/download/user_install_script.sh; then 
				bash /tmp/user_install_script.sh || echo "Decky Loader encountered a non-fatal Warning. Continuing installation..."
			
			else 
				echo -e "Decky Loader download failed.\nDecky Loader can be installed manually later."
				read -r -p "Press Enter to continue..."
			
			fi
			
			break
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

sleep 1

cd "$CUR_DIR"

# Compile Agnostic Gamescope
rm -rf "$CUR_DIR/agnostic-gamescope"
git clone https://github.com/sawyer-roberts/agnostic-gamescope.git
cd "$CUR_DIR/agnostic-gamescope/" || exit
git submodule update --init
meson setup build/
ninja -C build/
sudo meson install -C build/ --skip-subprojects

# Give Gamescope elevated system privileges
if ! getcap /usr/local/bin/gamescope | grep -q "cap_sys_nice=eip"; then
	sudo setcap 'cap_sys_nice=eip' /usr/local/bin/gamescope

fi

INSTALLED_FILES+=("/usr/local/bin/gamescope")

cd "$CUR_DIR"
rm -rf "$CUR_DIR/agnostic-gamescope"

ACTUAL_USER="$USER"
sudo usermod -aG input "$ACTUAL_USER"

echo "uinput" | sudo tee /etc/modules-load.d/uinput.conf > /dev/null
INSTALLED_FILES+=("/etc/modules-load.d/uinput.conf")

sudo modprobe uinput || echo -e "\nWarning: Could not load the uinput module.\nReboot your computer after the installation completes to load it."

echo 'KERNEL=="uinput", GROUP="input", MODE="0660"' | sudo tee /etc/udev/rules.d/99-uinput.rules > /dev/null
INSTALLED_FILES+=("/etc/udev/rules.d/99-uinput.rules")

sudo udevadm control --reload-rules && sudo udevadm trigger

mkdir -p "$HOME/.config/systemd/user"

mkdir -p "$HOME/.local/bin/agnostic-gaming-mode"
INSTALLED_FILES+=("$HOME/.local/bin/agnostic-gaming-mode")

sudo mkdir -p "/usr/local/bin/agnostic-gaming-mode"
INSTALLED_FILES+=("/usr/local/bin/agnostic-gaming-mode")

sudo mkdir -p "/usr/share/wayland-sessions"

# Copy System Files

# gamescope-display-modulation.service
cp "$CUR_DIR/files/.config/systemd/user/gamescope-display-modulation.service" "$HOME/.config/systemd/user/gamescope-display-modulation.service" && echo "Copied gamescope-display-modulation.service -> $HOME/.config/systemd/user/"
INSTALLED_FILES+=("$HOME/.config/systemd/user/gamescope-display-modulation.service")

# gamescope-display-modulation.sh
cp "$CUR_DIR/files/.local/bin/agnostic-gaming-mode/gamescope-display-modulation.sh" "$HOME/.local/bin/agnostic-gaming-mode/gamescope-display-modulation.sh" && echo "Copied gamescope-display-modulation.sh -> $HOME/.local/bin/agnostic-gaming-mode/"
INSTALLED_FILES+=("$HOME/.local/bin/agnostic-gaming-mode/gamescope-display-modulation.sh")

# ScreenRecordingGamingMode.sh
cp "$CUR_DIR/files/.local/bin/agnostic-gaming-mode/ScreenRecordingGamingMode.sh" "$HOME/.local/bin/agnostic-gaming-mode/ScreenRecordingGamingMode.sh" && echo "Copied ScreenRecordingGamingMode.sh -> $HOME/.local/bin/agnostic-gaming-mode/"
INSTALLED_FILES+=("$HOME/.local/bin/agnostic-gaming-mode/ScreenRecordingGamingMode.sh")

# agnostic-gaming-mode-restart.service
sudo cp "$CUR_DIR/files/etc/systemd/system/agnostic-gaming-mode-restart.service" "/etc/systemd/system/agnostic-gaming-mode-restart.service" && echo -e "Copied agnostic-gaming-mode-restart.service -> /etc/systemd/system/"
INSTALLED_FILES+=("/etc/systemd/system/agnostic-gaming-mode-restart.service")

# evsieve.sh
sudo cp "$CUR_DIR/files/usr/local/bin/agnostic-gaming-mode/evsieve.sh" "/usr/local/bin/agnostic-gaming-mode/evsieve.sh" && echo "Copied evsieve.sh -> /usr/local/bin/agnostic-gaming-mode/"
INSTALLED_FILES+=("/usr/local/bin/agnostic-gaming-mode/evsieve.sh")

# gamescope-session
sudo cp "$CUR_DIR/files/usr/local/bin/agnostic-gaming-mode/gamescope-session" "/usr/local/bin/agnostic-gaming-mode/gamescope-session" && echo "Copied gamescope-session -> /usr/local/bin/agnostic-gaming-mode/"
INSTALLED_FILES+=("/usr/local/bin/agnostic-gaming-mode/gamescope-session")

# restart.sh
sudo cp "$CUR_DIR/files/usr/local/bin/agnostic-gaming-mode/restart.sh" "/usr/local/bin/agnostic-gaming-mode/restart.sh" && echo "Copied restart.sh -> /usr/local/bin/agnostic-gaming-mode/"
INSTALLED_FILES+=("/usr/local/bin/agnostic-gaming-mode/restart.sh")

# steam-restart.sh
sudo cp "$CUR_DIR/files/usr/local/bin/agnostic-gaming-mode/steam-restart.sh" "/usr/local/bin/agnostic-gaming-mode/steam-restart.sh" && echo "Copied steam-restart.sh -> /usr/local/bin/agnostic-gaming-mode/"
INSTALLED_FILES+=("/usr/local/bin/agnostic-gaming-mode/steam-restart.sh")

# volume.sh
sudo cp "$CUR_DIR/files/usr/local/bin/agnostic-gaming-mode/volume.sh" "/usr/local/bin/agnostic-gaming-mode/volume.sh" && echo "Copied volume.sh -> /usr/local/bin/agnostic-gaming-mode/"
INSTALLED_FILES+=("/usr/local/bin/agnostic-gaming-mode/volume.sh")

TEMP_SUDOERS=$(mktemp)
INSTALLED_FILES+=("$TEMP_SUDOERS")

cat << EOF > "$TEMP_SUDOERS"
${ACTUAL_USER} ALL=(ALL:ALL) NOPASSWD: /usr/bin/systemctl restart plugin_loader.service, \\
	/usr/bin/keyd reload, \\
	/usr/bin/systemctl enable --now keyd, \\
	/usr/bin/modprobe, \\
	/usr/sbin/modprobe, \\
	/usr/bin/systemctl enable --now agnostic-gaming-mode-restart.service, \\
	/usr/bin/systemctl restart agnostic-gaming-mode-restart.service
EOF

if sudo visudo -cf "$TEMP_SUDOERS" > /dev/null 2>&1; then
	if [ -f /etc/sudoers.d/agnostic-gaming-mode ]; then
		sudo rm -f /etc/sudoers.d/agnostic-gaming-mode
	fi
	
	# agnostic-gaming-mode
	sudo cp "$TEMP_SUDOERS" /etc/sudoers.d/agnostic-gaming-mode
	INSTALLED_FILES+=("/etc/sudoers.d/agnostic-gaming-mode")
	
	sudo chmod 0440 /etc/sudoers.d/agnostic-gaming-mode
	sudo chown root:root /etc/sudoers.d/agnostic-gaming-mode
	
	echo "Created sudoers rule 'agnostic-gaming-mode' in /etc/sudoers.d/"

else
	echo "Error: Invalid syntax. Aborting..."
	
	rm -f "$TEMP_SUDOERS"
	
	exit 1

fi

rm -f "$TEMP_SUDOERS"

if [ -f /etc/sudoers.d/agnostic-gaming-mode-modprobe ]; then
	sudo rm -f /etc/sudoers.d/agnostic-gaming-mode-modprobe

fi

# agnostic-gaming-mode.desktop
sudo cp "$CUR_DIR/files/usr/share/wayland-sessions/agnostic-gaming-mode.desktop" "/usr/share/wayland-sessions/agnostic-gaming-mode.desktop" && echo "Copied agnostic-gaming-mode.desktop -> /usr/share/wayland-sessions/"
INSTALLED_FILES+=("/usr/share/wayland-sessions/agnostic-gaming-mode.desktop")

# Prompt user with option to enable controller shortcuts for their keyboard
while true; do
	echo -e "\nWould you like to enable controller shortcuts on the Keyboard?\n\nThis changes:\nShift + Meta (Windows) -> Steam Button\nShift + Meta (Windows) + Alt -> Quick Access Menu\nShift + Escape -> B Button\n\nNote: Steam Menu and Quick Access Menu can still be accessed with Ctrl + 1/2 without it."
	echo -e "\nType 'Y/y' to enable controller shortcuts.\nType 'N/n' to disable controller shortcuts."
	read -r enable_shortcuts

	case "$enable_shortcuts" in
		[Yy])
			# keyboard-mouse-shortcuts.py
			sudo cp "$CUR_DIR/files/usr/local/bin/agnostic-gaming-mode/keyboard-mouse-shortcuts.py" "/usr/local/bin/agnostic-gaming-mode/keyboard-mouse-shortcuts.py" && echo "Copied keyboard-mouse-shortcuts.py -> /usr/local/bin/agnostic-gaming-mode/"
			INSTALLED_FILES+=("/usr/local/bin/agnostic-gaming-mode/keyboard-mouse-shortcuts.py")

			# agnostic-gaming-mode.conf.disabled
			sudo cp "$CUR_DIR/files/etc/keyd/agnostic-gaming-mode.conf.disabled" "/etc/keyd/agnostic-gaming-mode.conf.disabled" && echo "Copied agnostic-gaming-mode.conf.disabled -> /etc/keyd/"
			INSTALLED_FILES+=("/etc/keyd/agnostic-gaming-mode.conf.disabled")

			TEMP_KEYD=$(mktemp)
			
			cat << EOF > "$TEMP_KEYD"
${ACTUAL_USER} ALL=(root) NOPASSWD: /usr/bin/mv /etc/keyd/agnostic-gaming-mode.conf.disabled /etc/keyd/agnostic-gaming-mode.conf, /usr/bin/mv /etc/keyd/agnostic-gaming-mode.conf /etc/keyd/agnostic-gaming-mode.conf.disabled
EOF
			
			if sudo visudo -cf "$TEMP_KEYD" > /dev/null 2>&1; then
				sudo rm -f /etc/sudoers.d/agnostic-gaming-mode-keyd
				
				# agnostic-gaming-mode-keyd
				sudo cp "$TEMP_KEYD" /etc/sudoers.d/agnostic-gaming-mode-keyd
				INSTALLED_FILES+=("/etc/sudoers.d/agnostic-gaming-mode-keyd")

				sudo chmod 0440 /etc/sudoers.d/agnostic-gaming-mode-keyd
				sudo chown root:root /etc/sudoers.d/agnostic-gaming-mode-keyd
				
				echo "Created sudoers rule 'agnostic-gaming-mode-keyd' in /etc/sudoers.d/"
			
			else
				echo "Error: Invalid syntax."
				
				rm -f "$TEMP_KEYD"
				
				exit 1
			fi
			
			rm -f "$TEMP_KEYD"
			
			TEMP_KEYD=$(mktemp)
			
			cat << EOF > "$TEMP_KEYD"
${ACTUAL_USER} ALL=(root) NOPASSWD: /usr/local/bin/keyd reload
EOF
			
			if sudo visudo -cf "$TEMP_KEYD" > /dev/null 2>&1; then
				sudo rm -f /etc/sudoers.d/agnostic-gaming-mode-keyd-compat
				
				# agnostic-gaming-mode-keyd-compat
				sudo cp "$TEMP_KEYD" /etc/sudoers.d/agnostic-gaming-mode-keyd-compat
				INSTALLED_FILES+=("/etc/sudoers.d/agnostic-gaming-mode-keyd-compat")

				sudo chmod 0440 /etc/sudoers.d/agnostic-gaming-mode-keyd-compat
				sudo chown root:root /etc/sudoers.d/agnostic-gaming-mode-keyd-compat
				
				echo "Created sudoers rule 'agnostic-gaming-mode-keyd-compat' in /etc/sudoers.d/"
			
			else
				echo "Error: Invalid syntax."
				
				rm -f "$TEMP_KEYD"
				
				exit 1
			fi
			
			rm -f "$TEMP_KEYD"

			sudo chmod 644 /etc/keyd/agnostic-gaming-mode.conf.disabled
			sudo chown root:root /etc/keyd/agnostic-gaming-mode.conf.disabled

			sudo chmod 755 /usr/local/bin/agnostic-gaming-mode/keyboard-mouse-shortcuts.py
			sudo chown root:root /usr/local/bin/agnostic-gaming-mode/keyboard-mouse-shortcuts.py

			sudo systemctl enable --now keyd
			sudo keyd reload

			break
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

python3 << 'EOF'
import os
import vdf
import zlib
import shutil

APP_NAME = "Exit Agnostic Gaming Mode"
EXE_PATH = "/usr/local/bin/agnostic-gaming-mode/steam-restart.sh"
START_DIR = "/usr/local/bin/agnostic-gaming-mode/"

CUR_DIR = os.getcwd()
COVER = f"{CUR_DIR}/files/steamart/cover.png"
WIDECOVER = f"{CUR_DIR}/files/steamart/widecover.png"
BACKGROUND = f"{CUR_DIR}/files/steamart/background.png"
LOGO = f"{CUR_DIR}/files/steamart/logo.png"
ICON = f"{CUR_DIR}/files/steamart/icon.png"

quoted_exe = f'"{EXE_PATH}"'
quoted_start = f'"{START_DIR}"'

target_string = f'{quoted_exe}{APP_NAME}'
crc = zlib.crc32(target_string.encode('utf-8'))
appid_32 = (crc & 0xFFFFFFFF) | 0x80000000
signed_appid = appid_32 - 0x100000000 if appid_32 > 0x7FFFFFFF else appid_32
appid_str = str(appid_32)

steam_paths = [
	os.path.expanduser("~/.local/share/Steam/userdata"),
	os.path.expanduser("~/.var/app/com.valvesoftware.Steam/.local/share/Steam/userdata")
]

valid_steam_dirs = [path for path in steam_paths if os.path.exists(path)]

for userdata_dir in valid_steam_dirs:
	for user_id in os.listdir(userdata_dir):
		if not user_id.isdigit() or user_id == "0":
			continue

		shortcuts_path = os.path.join(userdata_dir, user_id, "config", "shortcuts.vdf")
		grid_dir = os.path.join(userdata_dir, user_id, "config", "grid")

		if os.path.exists(shortcuts_path):
			with open(shortcuts_path, 'rb') as f:
				data = vdf.binary_load(f)
		else:
			data = {'shortcuts': {}}

		shortcuts = data.get('shortcuts', {})
		target_idx = None
		for idx, s in shortcuts.items():
			if isinstance(s, dict) and s.get('AppName') == APP_NAME:
				target_idx = idx
				break

		if target_idx is None:
			existing_indices = [int(k) for k in shortcuts.keys() if str(k).isdigit()]
			target_idx = str(max(existing_indices + [-1]) + 1)

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

		print(f"Added 'Exit Agnostic Gaming Mode' Shortcut for Steam ID: {user_id}")
		os.makedirs(grid_dir, exist_ok=True)

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

		print(f"Applied Artwork to 'Exit Agnostic Gaming Mode' Shortcut for Steam ID: {user_id}")
EOF

sudo chmod 644 "$HOME/.config/systemd/user/gamescope-display-modulation.service"
sudo chown "$ACTUAL_USER":"$ACTUAL_USER" "$HOME/.config/systemd/user/gamescope-display-modulation.service"

sudo chmod 755 "$HOME/.local/bin/agnostic-gaming-mode/gamescope-display-modulation.sh"
sudo chown "$ACTUAL_USER":"$ACTUAL_USER" "$HOME/.local/bin/agnostic-gaming-mode/gamescope-display-modulation.sh"

sudo chmod 755 "$HOME/.local/bin/agnostic-gaming-mode/ScreenRecordingGamingMode.sh"
sudo chown "$ACTUAL_USER":"$ACTUAL_USER" "$HOME/.local/bin/agnostic-gaming-mode/ScreenRecordingGamingMode.sh"

sudo chmod 644 /etc/systemd/system/agnostic-gaming-mode-restart.service
sudo chown root:root /etc/systemd/system/agnostic-gaming-mode-restart.service

sudo chmod 755 /usr/local/bin/agnostic-gaming-mode/evsieve.sh
sudo chown root:root /usr/local/bin/agnostic-gaming-mode/evsieve.sh

sudo chmod 755 /usr/local/bin/agnostic-gaming-mode/gamescope-session
sudo chown root:root /usr/local/bin/agnostic-gaming-mode/gamescope-session

sudo chmod 755 /usr/local/bin/agnostic-gaming-mode/restart.sh
sudo chown root:root /usr/local/bin/agnostic-gaming-mode/restart.sh

sudo chmod 755 /usr/local/bin/agnostic-gaming-mode/steam-restart.sh
sudo chown root:root /usr/local/bin/agnostic-gaming-mode/steam-restart.sh

sudo chmod 755 /usr/local/bin/agnostic-gaming-mode/volume.sh
sudo chown root:root /usr/local/bin/agnostic-gaming-mode/volume.sh

sudo chmod 644 /usr/share/wayland-sessions/agnostic-gaming-mode.desktop
sudo chown root:root /usr/share/wayland-sessions/agnostic-gaming-mode.desktop

sudo systemctl daemon-reload
systemctl --user daemon-reload || true

trap - EXIT SIGINT SIGTERM

echo -e "\n\nAgnostic Gaming Mode is now installed!\nTip: Use the new 'Exit Agnostic Gaming Mode' shortcut in Steam to return to the Log-In Screen.\nLog Out or Restart your Computer to apply all changes."
