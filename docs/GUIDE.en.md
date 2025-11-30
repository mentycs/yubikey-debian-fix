# Complete Guide: Yubikey on Debian 13 with Chrome

**🇬🇧 English Version** | **[🇮🇹 Versione Italiana](GUIDA_COMPLETA.md)**

## Table of Contents
1. [Introduction](#introduction)
2. [Problem Identification](#problem-identification)
3. [Prerequisites](#prerequisites)
4. [Package Installation](#package-installation)
5. [udev Configuration](#udev-configuration)
6. [Permission Configuration](#permission-configuration)
7. [Service Management](#service-management)
8. [Testing and Verification](#testing-and-verification)
9. [Troubleshooting](#troubleshooting)
10. [Advanced Configurations](#advanced-configurations)

---

## Introduction

This guide solves the common issue where Chrome/Chromium on Debian 13 does not properly detect the Yubikey touch for Google authentication with FIDO2/U2F.

### Affected Device
```
Bus 002 Device 003: ID 1050:0407 Yubico.com Yubikey 4/5 OTP+U2F+CCID
```

## Problem Identification

### Common Symptoms
- Chrome does not show the request to touch the Yubikey
- Authentication gets stuck without response
- Yubikey blinks but Chrome doesn't respond
- "Security key not detected" error

### Initial Verification
```bash
# Verify that the Yubikey is recognized by the system
lsusb | grep Yubico

# Expected output:
# Bus 002 Device 003: ID 1050:0407 Yubico.com Yubikey 4/5 OTP+U2F+CCID
```

## Prerequisites

### System Requirements
- Debian 13 (Trixie) or Debian 12 (Bookworm)
- Linux Kernel 5.10 or higher
- Chrome/Chromium version 90+
- Sudo/root access

### Configuration Backups
```bash
# Backup existing udev rules
sudo cp -r /etc/udev/rules.d /etc/udev/rules.d.backup
```

## Package Installation

### Essential Packages
```bash
# Update the system
sudo apt update
sudo apt upgrade

# Install required packages
sudo apt install -y \
    libpam-u2f \
    libfido2-1 \
    libfido2-dev \
    libu2f-host0 \
    libu2f-host-dev \
    yubikey-manager \
    yubikey-personalization \
    pcscd \
    scdaemon \
    pcsc-tools
```

### Package Descriptions
- **libpam-u2f**: PAM module for U2F authentication
- **libfido2-1**: Library for FIDO2/WebAuthn
- **libu2f-host0**: Host library for U2F
- **yubikey-manager**: CLI tool to manage Yubikey
- **pcscd**: PC/SC daemon for smartcards
- **scdaemon**: GnuPG daemon for smartcards

## udev Configuration

### Create udev Rules

```bash
# Create the rules file
sudo vi /etc/udev/rules.d/70-u2f.rules
```

File content:
```udev
# Yubico Yubikey 4/5
KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0407", TAG+="uaccess", MODE="0660", GROUP="plugdev"
SUBSYSTEMS=="usb", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0407", TAG+="uaccess", MODE="0660", GROUP="plugdev"

# Additional rules for full compatibility
ACTION=="add|change", SUBSYSTEM=="usb", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0407", ENV{ID_SECURITY_TOKEN}="1"
KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0407", ENV{ID_SECURITY_TOKEN}="1"

# Support for all Yubikey models
KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", TAG+="uaccess", MODE="0660", GROUP="plugdev"
SUBSYSTEMS=="usb", ATTRS{idVendor}=="1050", TAG+="uaccess", MODE="0660", GROUP="plugdev"
```

### Apply Changes
```bash
# Reload udev rules
sudo udevadm control --reload-rules
sudo udevadm trigger

# Verify that rules are applied
udevadm test $(udevadm info -q path -n /dev/hidraw0) 2>&1 | grep "70-u2f"
```

## Permission Configuration

### User Group Management
```bash
# Add user to necessary groups
sudo usermod -a -G plugdev $USER
sudo usermod -a -G scard $USER  # Optional for smartcard

# Verify groups
groups $USER
```

### File System Permissions
```bash
# Ensure devices have correct permissions
ls -la /dev/hidraw*
# Should show 'plugdev' group and 660 permissions
```

## Service Management

### pcscd Configuration
```bash
# Enable and start pcscd
sudo systemctl enable pcscd
sudo systemctl start pcscd

# Check status
sudo systemctl status pcscd
```

### U2F/FIDO2 Optimization
If you experience conflicts with pcscd:
```bash
# Disable pcscd if it causes issues with U2F
sudo systemctl stop pcscd
sudo systemctl disable pcscd

# NOTE: Disable only if not using smartcard functionality
```

## Testing and Verification

### Test with yubikey-manager
```bash
# Yubikey information
ykman info

# List available applications
ykman list

# Test FIDO2
ykman fido info
```

### Test with Chrome
1. Close Chrome completely:
   ```bash
   pkill chrome || pkill chromium
   ```

2. Restart Chrome and navigate to: https://webauthn.io/

3. Test registration and authentication

### Complete Test Script
```bash
#!/bin/bash
echo "=== Yubikey Diagnostic Test ==="
echo

echo "1. Checking USB device..."
lsusb | grep Yubico || echo "ERROR: Yubikey not detected via USB"

echo -e "\n2. Checking hidraw devices..."
ls -la /dev/hidraw* 2>/dev/null || echo "ERROR: No hidraw devices found"

echo -e "\n3. Checking udev rules..."
ls -la /etc/udev/rules.d/*u2f* 2>/dev/null || echo "WARNING: No U2F udev rules found"

echo -e "\n4. Checking user groups..."
groups | grep plugdev || echo "WARNING: User not in plugdev group"

echo -e "\n5. Checking pcscd status..."
systemctl is-active pcscd

echo -e "\n6. Checking ykman..."
ykman info 2>/dev/null || echo "ERROR: ykman cannot communicate with device"

echo -e "\n=== Test Complete ==="
```

## Troubleshooting

### Issue: Chrome doesn't detect the Yubikey

**Solution 1: Complete reset**
```bash
# Remove and reinsert the Yubikey
# Restart services
sudo systemctl restart systemd-udevd
sudo systemctl restart pcscd

# Clear Chrome security key cache
rm -rf ~/.config/chromium/Default/Web\ Data*
rm -rf ~/.config/google-chrome/Default/Web\ Data*
```

**Solution 2: Debug mode**
```bash
# Start Chrome with verbose logging
google-chrome --enable-logging=stderr --v=1 2>&1 | grep -i "fido\|u2f\|hid"
```

### Issue: Insufficient permissions

```bash
# Verify and fix permissions
sudo chmod 660 /dev/hidraw*
sudo chown root:plugdev /dev/hidraw*
```

### Issue: Conflict with other services

```bash
# Identify processes using the Yubikey
sudo lsof | grep hidraw

# Terminate conflicting processes
sudo killall gpg-agent scdaemon  # If necessary
```

## Advanced Configurations

### Configuration for Multiple Yubikeys
```bash
# udev rules for multiple Yubikeys
cat << 'EOF' | sudo tee /etc/udev/rules.d/71-yubikeys.rules
# Support for multiple simultaneous Yubikeys
ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0010|0110|0111|0114|0116|0401|0403|0405|0407|0410", \
    ENV{ID_SECURITY_TOKEN}="1", ENV{ID_SMARTCARD_READER}="1", \
    TAG+="uaccess", MODE="0660", GROUP="plugdev"
EOF
```

### GPG Integration
```bash
# Configure GPG to use the Yubikey
echo "reader-port Yubico Yubikey" >> ~/.gnupg/scdaemon.conf
gpgconf --reload scdaemon
```

### Advanced Logging
```bash
# Enable detailed logging
echo "log-level debug" | sudo tee -a /etc/libccid_Info.conf

# Real-time monitoring
sudo journalctl -f | grep -i "yubikey\|u2f\|fido"
```

## Automated Installation Script

```bash
#!/bin/bash
# auto-install.sh

set -e

echo "Installing Yubikey support for Debian 13..."

# Install packages
sudo apt update
sudo apt install -y libpam-u2f libfido2-1 libu2f-host0 yubikey-manager pcscd scdaemon

# Setup udev rules
sudo tee /etc/udev/rules.d/70-u2f.rules > /dev/null << 'EOF'
KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0407", TAG+="uaccess", MODE="0660", GROUP="plugdev"
SUBSYSTEMS=="usb", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0407", TAG+="uaccess", MODE="0660", GROUP="plugdev"
EOF

# Add user to plugdev
sudo usermod -a -G plugdev $USER

# Reload services
sudo udevadm control --reload-rules
sudo udevadm trigger
sudo systemctl restart pcscd

echo "Installation complete! Please logout and login again."
```

## Final Notes

### Security
- Never share the output of `ykman oath accounts list`
- Backup recovery keys
- Always test the configuration before fully relying on it

### Browser Compatibility
- **Chrome/Chromium**: Full support
- **Firefox**: Requires additional configuration
- **Edge**: Native support on Linux

### Useful Resources
- [Yubico Linux Documentation](https://support.yubico.com/hc/en-us/articles/360016649039)
- [Debian Wiki - Yubikey](https://wiki.debian.org/Yubikey)
- [FIDO2 Project](https://fidoalliance.org/fido2/)

---

**Version**: 1.0.0
**Last update**: 2024
**Compatibility**: Debian 12/13, Ubuntu 22.04+
