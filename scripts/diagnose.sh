#!/bin/bash
#
# Yubikey Diagnostic Script
# Comprehensive diagnostics for Yubikey issues on Debian/Linux
#

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Status icons
PASS="[${GREEN}PASS${NC}]"
FAIL="[${RED}FAIL${NC}]"
WARN="[${YELLOW}WARN${NC}]"
INFO="[${BLUE}INFO${NC}]"

echo "========================================="
echo "     Yubikey Diagnostic Tool v1.0       "
echo "========================================="
echo "Timestamp: $(date)"
echo "Hostname: $(hostname)"
echo "Kernel: $(uname -r)"
echo "Distribution: $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "========================================="
echo

# Function to check command availability
check_command() {
    if command -v "$1" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# 1. USB Detection
echo "1. USB Device Detection"
echo "------------------------"
if lsusb > /dev/null 2>&1; then
    YUBIKEY_USB=$(lsusb | grep -i "yubico")
    if [ -n "$YUBIKEY_USB" ]; then
        echo -e "$PASS Yubikey detected:"
        echo "     $YUBIKEY_USB"
        
        # Extract vendor and product ID
        VENDOR_ID=$(echo "$YUBIKEY_USB" | grep -oP 'ID \K[0-9a-f]{4}(?=:)')
        PRODUCT_ID=$(echo "$YUBIKEY_USB" | grep -oP 'ID [0-9a-f]{4}:\K[0-9a-f]{4}')
        echo -e "$INFO Vendor ID: $VENDOR_ID, Product ID: $PRODUCT_ID"
    else
        echo -e "$FAIL No Yubikey detected via USB"
        echo -e "     Please ensure your Yubikey is properly inserted"
    fi
else
    echo -e "$WARN lsusb command not available"
fi
echo

# 2. HID Device Check
echo "2. HID Device Status"
echo "--------------------"
HIDRAW_DEVICES=$(ls /dev/hidraw* 2>/dev/null)
if [ -n "$HIDRAW_DEVICES" ]; then
    echo -e "$PASS HID raw devices found:"
    for device in $HIDRAW_DEVICES; do
        PERMS=$(ls -l $device | awk '{print $1" "$3":"$4}')
        echo "     $device - $PERMS"
        
        # Check if device is accessible
        if [ -r "$device" ]; then
            echo -e "     ${GREEN}✓${NC} Device is readable"
        else
            echo -e "     ${RED}✗${NC} Device is not readable by current user"
        fi
    done
else
    echo -e "$FAIL No hidraw devices found"
fi
echo

# 3. udev Rules Check
echo "3. udev Rules Configuration"
echo "---------------------------"
UDEV_RULES=$(ls /etc/udev/rules.d/*u2f* /etc/udev/rules.d/*yubi* 2>/dev/null)
if [ -n "$UDEV_RULES" ]; then
    echo -e "$PASS udev rules found:"
    for rule in $UDEV_RULES; do
        echo "     $rule"
        # Check for critical rules
        if grep -q "1050.*0407" "$rule" 2>/dev/null; then
            echo -e "     ${GREEN}✓${NC} Contains rules for Yubikey 4/5"
        fi
        if grep -q "plugdev" "$rule" 2>/dev/null; then
            echo -e "     ${GREEN}✓${NC} Uses plugdev group"
        fi
    done
else
    echo -e "$FAIL No Yubikey udev rules found"
    echo -e "$INFO Run the install script to configure udev rules"
fi
echo

# 4. User Permissions
echo "4. User Permissions"
echo "-------------------"
CURRENT_USER=$(whoami)
USER_GROUPS=$(groups)

echo -e "$INFO Current user: $CURRENT_USER"
echo -e "$INFO Groups: $USER_GROUPS"

if echo "$USER_GROUPS" | grep -q "plugdev"; then
    echo -e "$PASS User is in plugdev group"
else
    echo -e "$FAIL User is not in plugdev group"
    echo -e "     Run: sudo usermod -a -G plugdev $CURRENT_USER"
fi

if getent group scard > /dev/null 2>&1; then
    if echo "$USER_GROUPS" | grep -q "scard"; then
        echo -e "$PASS User is in scard group"
    else
        echo -e "$WARN User is not in scard group (optional)"
    fi
fi
echo

# 5. Required Packages
echo "5. Package Installation Status"
echo "------------------------------"
PACKAGES=(
    "libpam-u2f"
    "libfido2-1"
    "libu2f-host0"
    "yubikey-manager"
    "pcscd"
    "scdaemon"
)

MISSING_PACKAGES=()
for pkg in "${PACKAGES[@]}"; do
    if dpkg -l | grep -q "^ii  $pkg "; then
        echo -e "$PASS $pkg installed"
    else
        echo -e "$FAIL $pkg not installed"
        MISSING_PACKAGES+=("$pkg")
    fi
done

if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
    echo -e "$INFO To install missing packages:"
    echo "     sudo apt install ${MISSING_PACKAGES[*]}"
fi
echo

# 6. Service Status
echo "6. System Services"
echo "------------------"
# Check pcscd
if systemctl list-unit-files | grep -q "pcscd.service"; then
    PCSCD_STATUS=$(systemctl is-active pcscd)
    if [ "$PCSCD_STATUS" = "active" ]; then
        echo -e "$PASS pcscd service is active"
    else
        echo -e "$WARN pcscd service is $PCSCD_STATUS"
        echo -e "     This is okay for U2F/FIDO2 only usage"
    fi
else
    echo -e "$INFO pcscd service not found"
fi

# Check systemd-udevd
UDEVD_STATUS=$(systemctl is-active systemd-udevd)
if [ "$UDEVD_STATUS" = "active" ]; then
    echo -e "$PASS systemd-udevd is active"
else
    echo -e "$FAIL systemd-udevd is $UDEVD_STATUS"
fi
echo

# 7. Yubikey Manager Test
echo "7. Yubikey Manager Communication"
echo "--------------------------------"
if check_command ykman; then
    if ykman info > /dev/null 2>&1; then
        echo -e "$PASS ykman can communicate with device"
        echo -e "$INFO Device info:"
        ykman info 2>&1 | sed 's/^/     /'
    else
        echo -e "$FAIL ykman cannot communicate with device"
        echo -e "     Error: $(ykman info 2>&1 | head -1)"
    fi
else
    echo -e "$WARN ykman not installed"
fi
echo

# 8. Browser Process Check
echo "8. Browser Status"
echo "-----------------"
CHROME_RUNNING=false
FIREFOX_RUNNING=false

if pgrep -x "chrome" > /dev/null || pgrep -x "chromium" > /dev/null; then
    CHROME_RUNNING=true
    echo -e "$INFO Chrome/Chromium is running"
    echo -e "     PID: $(pgrep -x "chrome" || pgrep -x "chromium")"
else
    echo -e "$INFO Chrome/Chromium is not running"
fi

if pgrep -x "firefox" > /dev/null; then
    FIREFOX_RUNNING=true
    echo -e "$INFO Firefox is running"
    echo -e "     PID: $(pgrep -x "firefox")"
else
    echo -e "$INFO Firefox is not running"
fi
echo

# 9. Recent System Logs
echo "9. Recent System Logs"
echo "---------------------"
echo -e "$INFO Checking for Yubikey-related messages..."
LOGS=$(sudo journalctl --since "10 minutes ago" 2>/dev/null | grep -i "yubi\|u2f\|fido\|hidraw" | tail -5)
if [ -n "$LOGS" ]; then
    echo "$LOGS" | sed 's/^/     /'
else
    echo "     No recent Yubikey-related log entries"
fi
echo

# 10. Troubleshooting Suggestions
echo "10. Recommendations"
echo "-------------------"
ISSUES=0

if [ -z "$YUBIKEY_USB" ]; then
    echo -e "$WARN No Yubikey detected - please insert your device"
    ((ISSUES++))
fi

if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
    echo -e "$WARN Install missing packages with:"
    echo "     sudo apt install ${MISSING_PACKAGES[*]}"
    ((ISSUES++))
fi

if ! echo "$USER_GROUPS" | grep -q "plugdev"; then
    echo -e "$WARN Add user to plugdev group:"
    echo "     sudo usermod -a -G plugdev $CURRENT_USER"
    echo "     Then logout and login again"
    ((ISSUES++))
fi

if [ -z "$UDEV_RULES" ]; then
    echo -e "$WARN Configure udev rules by running ./install.sh"
    ((ISSUES++))
fi

if [ $CHROME_RUNNING = true ]; then
    echo -e "$INFO Restart Chrome for changes to take effect:"
    echo "     pkill chrome && google-chrome"
fi

if [ $ISSUES -eq 0 ]; then
    echo -e "$PASS Everything looks good!"
    echo -e "$INFO Test your setup at: https://webauthn.io"
else
    echo -e "$INFO Found $ISSUES issue(s) to address"
fi
echo

echo "========================================="
echo "         Diagnostic Complete             "
echo "========================================="
echo
echo "For additional help, see:"
echo "- Documentation: docs/GUIDA_COMPLETA.md"
echo "- Troubleshooting: docs/TROUBLESHOOTING.md"
echo "- Report issues: https://github.com/yourusername/yubikey-debian-fix"
echo
