#!/bin/bash
#
# Yubikey Debian Fix - Installation Script
# Configures Debian 13 for proper Yubikey support with Chrome/Chromium
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root directly"
        print_info "Run as regular user with sudo privileges"
        exit 1
    fi
}

check_distro() {
    if ! grep -q "Debian" /etc/os-release; then
        print_error "This script is designed for Debian systems"
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

backup_existing() {
    print_info "Creating backups..."
    if [ -d /etc/udev/rules.d ]; then
        sudo cp -r /etc/udev/rules.d /etc/udev/rules.d.backup.$(date +%Y%m%d)
        print_success "Backed up udev rules"
    fi
}

install_packages() {
    print_info "Installing required packages..."
    
    # Update package list
    sudo apt update || {
        print_error "Failed to update package list"
        exit 1
    }
    
    # Core packages
    local packages=(
        libpam-u2f
        libfido2-1
        libfido2-dev
        libu2f-host0
        libu2f-host-dev
        yubikey-manager
        yubikey-personalization
        yubikey-personalization-gui
        pcscd
        scdaemon
        pcsc-tools
    )
    
    for pkg in "${packages[@]}"; do
        if dpkg -l | grep -q "^ii  $pkg "; then
            print_success "$pkg already installed"
        else
            print_info "Installing $pkg..."
            sudo apt install -y "$pkg" || print_error "Failed to install $pkg"
        fi
    done
    
    print_success "All packages installed"
}

configure_udev() {
    print_info "Configuring udev rules..."
    
    # Create udev rules file
    sudo tee /etc/udev/rules.d/70-u2f.rules > /dev/null << 'EOF'
# Yubico Yubikey 4/5 OTP+U2F+CCID
KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0407", TAG+="uaccess", MODE="0660", GROUP="plugdev"
SUBSYSTEMS=="usb", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0407", TAG+="uaccess", MODE="0660", GROUP="plugdev"

# Additional rules for full compatibility
ACTION=="add|change", SUBSYSTEM=="usb", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0407", ENV{ID_SECURITY_TOKEN}="1", ENV{ID_SMARTCARD_READER}="1"
KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0407", ENV{ID_SECURITY_TOKEN}="1"

# Support for all Yubikey models
KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", TAG+="uaccess", MODE="0660", GROUP="plugdev"
SUBSYSTEMS=="usb", ATTRS{idVendor}=="1050", TAG+="uaccess", MODE="0660", GROUP="plugdev"

# Specific models support
ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0010|0110|0111|0114|0116|0401|0403|0405|0407|0410", \
    ENV{ID_SECURITY_TOKEN}="1", ENV{ID_SMARTCARD_READER}="1", \
    TAG+="uaccess", MODE="0660", GROUP="plugdev"
EOF
    
    if [ $? -eq 0 ]; then
        print_success "udev rules created"
    else
        print_error "Failed to create udev rules"
        exit 1
    fi
    
    # Reload udev
    sudo udevadm control --reload-rules
    sudo udevadm trigger
    print_success "udev rules reloaded"
}

configure_user() {
    print_info "Configuring user permissions..."
    
    # Add user to plugdev group
    if groups $USER | grep -q "plugdev"; then
        print_success "$USER already in plugdev group"
    else
        sudo usermod -a -G plugdev $USER
        print_success "$USER added to plugdev group"
        NEED_RELOGIN=1
    fi
    
    # Optional: add to scard group if it exists
    if getent group scard > /dev/null 2>&1; then
        if ! groups $USER | grep -q "scard"; then
            sudo usermod -a -G scard $USER
            print_success "$USER added to scard group"
        fi
    fi
}

configure_services() {
    print_info "Configuring services..."
    
    # Enable and start pcscd
    if systemctl list-unit-files | grep -q "pcscd.service"; then
        sudo systemctl enable pcscd
        sudo systemctl restart pcscd
        
        if systemctl is-active --quiet pcscd; then
            print_success "pcscd service is active"
        else
            print_error "pcscd service failed to start"
            print_info "This might be normal if you only use U2F/FIDO2"
        fi
    fi
    
    # Restart systemd-udevd
    sudo systemctl restart systemd-udevd
    print_success "systemd-udevd restarted"
}

test_yubikey() {
    print_info "Testing Yubikey connection..."
    
    # Check if Yubikey is connected
    if lsusb | grep -q "Yubico"; then
        print_success "Yubikey detected via USB"
        
        # Try ykman if available
        if command -v ykman &> /dev/null; then
            if ykman info &> /dev/null; then
                print_success "ykman can communicate with Yubikey"
                ykman info
            else
                print_error "ykman cannot communicate with Yubikey"
                print_info "Try removing and reinserting the Yubikey"
            fi
        fi
    else
        print_error "No Yubikey detected"
        print_info "Please insert your Yubikey and run the diagnostic script"
    fi
}

create_diagnostic_script() {
    print_info "Creating diagnostic script..."
    
    cat > diagnose.sh << 'EOF'
#!/bin/bash

echo "=== Yubikey Diagnostic Report ==="
echo "Date: $(date)"
echo "System: $(uname -a)"
echo

echo "=== USB Devices ==="
lsusb | grep -i yubico || echo "No Yubikey found via USB"
echo

echo "=== Hidraw Devices ==="
ls -la /dev/hidraw* 2>/dev/null || echo "No hidraw devices found"
echo

echo "=== udev Rules ==="
ls -la /etc/udev/rules.d/*u2f* /etc/udev/rules.d/*yubi* 2>/dev/null || echo "No Yubikey udev rules found"
echo

echo "=== User Groups ==="
echo "Current user: $USER"
echo "Groups: $(groups)"
echo

echo "=== Service Status ==="
echo "pcscd: $(systemctl is-active pcscd)"
echo

echo "=== Yubikey Manager ==="
if command -v ykman &> /dev/null; then
    ykman info 2>&1 || echo "ykman cannot connect to device"
else
    echo "ykman not installed"
fi
echo

echo "=== Chrome Processes ==="
ps aux | grep -i "chrom" | grep -v grep || echo "Chrome not running"
echo

echo "=== System Logs (last 10 lines) ==="
sudo journalctl -n 10 | grep -i "yubi\|u2f\|fido" || echo "No relevant logs found"
echo

echo "=== Diagnostic Complete ==="
EOF
    
    chmod +x diagnose.sh
    print_success "Diagnostic script created (./diagnose.sh)"
}

show_next_steps() {
    echo
    echo "======================================="
    echo "       Installation Complete!           "
    echo "======================================="
    echo
    
    if [ -n "$NEED_RELOGIN" ]; then
        print_info "IMPORTANT: You need to logout and login again for group changes to take effect"
    fi
    
    echo "Next steps:"
    echo "1. Remove and reinsert your Yubikey"
    echo "2. Close all Chrome/Chromium windows completely"
    echo "3. Restart Chrome and test at https://webauthn.io"
    echo "4. Run ./diagnose.sh if you encounter issues"
    echo
    
    if [ -n "$NEED_RELOGIN" ]; then
        echo "Would you like to logout now? (y/n)"
        read -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            gnome-session-quit --logout --no-prompt 2>/dev/null || \
            pkill -KILL -u $USER
        fi
    fi
}

# Main execution
main() {
    echo "======================================="
    echo "    Yubikey Debian Fix Installer       "
    echo "======================================="
    echo
    
    check_root
    check_distro
    backup_existing
    install_packages
    configure_udev
    configure_user
    configure_services
    test_yubikey
    create_diagnostic_script
    show_next_steps
}

# Run main function
main
