#!/bin/bash
set -e

# Prompt user with option to enable controller shortcuts for their keyboard
while true; do
        echo -e "\nWould you like to enable controller shortcuts on the Keyboard?\n\nThis changes:\nShift + Meta (Windows) -> Steam Button\nShift + Meta (Windows) + Alt -> Quick Access Menu\nShift + Escape -> B Button\n\nNote: Steam Menu and Quick Access Menu can still be accessed with Ctrl + 1/2 without it."
        echo -e "\nType 'Y/y' to enable controller shortcuts.\nType 'N/n' to not enable controller shortcuts."
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

                        cat <<-EOF > "$TEMP_KEYD"
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

                        cat <<-EOF > "$TEMP_KEYD"
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

                        sleep 2

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
