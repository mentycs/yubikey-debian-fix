# Troubleshooting Guide

**🇬🇧 English Version** | **[🇮🇹 Versione Italiana](TROUBLESHOOTING.it.md)**

## Common Issues and Solutions

### 1. Chrome Doesn't Detect the Yubikey

#### Symptoms
- Yubikey blinks but Chrome doesn't respond
- "Security key not detected" error
- Browser freezes during authentication

#### Solutions

**Complete Chrome reset:**
```bash
# Close Chrome completely
pkill chrome || pkill chromium

# Clear security keys cache
rm -rf ~/.config/chromium/Default/Web\ Data*
rm -rf ~/.config/google-chrome/Default/Web\ Data*

# Restart Chrome
google-chrome || chromium
```

**Verify permissions:**
```bash
# Check device permissions
ls -la /dev/hidraw*

# Should show:
# crw-rw---- 1 root plugdev ... /dev/hidraw0
```

**Restart services:**
```bash
sudo systemctl restart systemd-udevd
sudo systemctl restart pcscd
sudo udevadm control --reload-rules
sudo udevadm trigger
```

---

### 2. "Permission denied" Error on /dev/hidraw

#### Cause
User is not in the plugdev group or udev rules are not applied.

#### Solution
```bash
# Add user to the group
sudo usermod -a -G plugdev $USER

# Logout and login required!
gnome-session-quit --logout
```

---

### 3. ykman Doesn't Find the Device

#### Symptoms
```
Error: No YubiKey detected
```

#### Solutions

**Verify USB:**
```bash
# Check if the system sees the Yubikey
lsusb | grep Yubico
```

**Restart pcscd:**
```bash
sudo systemctl restart pcscd
```

**Try without pcscd:**
```bash
# Sometimes pcscd interferes with U2F
sudo systemctl stop pcscd
ykman info
```

---

### 4. Conflict with GPG/GnuPG

#### Symptoms
- GPG blocks access to the Yubikey
- Cannot use U2F while GPG is active

#### Solution
```bash
# Terminate GPG processes
gpgconf --kill gpg-agent
gpgconf --kill scdaemon

# Or temporarily disable
systemctl --user stop gpg-agent
```

---

### 5. Yubikey Doesn't Blink

#### Cause
The request doesn't reach the device.

#### Checks
1. **Supported browser?**
   - Chrome/Chromium: ✓ Full support
   - Firefox: Requires `security.webauth.u2f` enabled
   - Edge Linux: ✓ Native support

2. **HTTPS required:**
   - U2F/WebAuthn only works on HTTPS
   - Exception: localhost for testing

3. **Browser extensions:**
   ```bash
   # Start Chrome without extensions
   google-chrome --disable-extensions
   ```

---

### 6. Error After System Update

#### Symptoms
It was working before the update, now it doesn't.

#### Solution
```bash
# Reinstall packages
sudo apt install --reinstall libpam-u2f libfido2-1 libu2f-host0

# Recreate udev rules
sudo ./install.sh

# Check kernel
uname -r
# Kernel 5.10+ required for full support
```

---

### 7. Multiple Simultaneous Yubikeys

#### Configuration
```bash
# udev rules for multiple support
sudo vi /etc/udev/rules.d/71-yubikeys.rules
```

Add:
```
# Support for multiple Yubikeys
ATTRS{idVendor}=="1050", ENV{ID_SECURITY_TOKEN}="1", TAG+="uaccess", MODE="0660", GROUP="plugdev"
```

---

### 8. Debug Mode

#### Enable Verbose Logging

**Chrome:**
```bash
google-chrome \
  --enable-logging=stderr \
  --v=1 \
  2>&1 | grep -i "fido\|u2f\|hid"
```

**System logs:**
```bash
# Real-time monitoring
sudo journalctl -f | grep -i "yubikey\|u2f\|fido\|hidraw"
```

**pcscd debug:**
```bash
sudo systemctl stop pcscd
sudo pcscd -f -d
```

---

### 9. Verification Test

#### Quick Functionality Test
```bash
# 1. USB detection
lsusb | grep Yubico && echo "✓ USB OK" || echo "✗ USB FAIL"

# 2. Permissions
groups | grep plugdev && echo "✓ Groups OK" || echo "✗ Groups FAIL"

# 3. Device access
ls -la /dev/hidraw* | grep plugdev && echo "✓ Device OK" || echo "✗ Device FAIL"

# 4. ykman communication
ykman info > /dev/null 2>&1 && echo "✓ ykman OK" || echo "✗ ykman FAIL"
```

#### Test Sites
- https://webauthn.io - Test FIDO2/WebAuthn
- https://demo.yubico.com/webauthn - Yubico demo
- https://webauthn.me - Alternative test

---

### 10. Rollback Changes

If necessary, restore the original configuration:

```bash
# Restore udev backup
sudo rm /etc/udev/rules.d/70-u2f.rules
sudo rm /etc/udev/rules.d/71-yubikeys.rules
sudo cp -r /etc/udev/rules.d.backup.* /etc/udev/rules.d/

# Remove user from plugdev
sudo gpasswd -d $USER plugdev

# Uninstall packages (optional)
sudo apt remove yubikey-manager yubikey-personalization

# Reboot
sudo reboot
```

---

## FAQ

### Q: Can I use the Yubikey on multiple computers?
**A:** Yes, the same Yubikey can be registered on multiple accounts and different computers.

### Q: Is it safe to disable pcscd?
**A:** Yes, if you only use U2F/FIDO2. It's only necessary for smartcard/GPG functionality.

### Q: Does it work with Wayland?
**A:** Yes, Yubikey support doesn't depend on the display server.

### Q: Do I need to install proprietary drivers?
**A:** No, all support is open source and included in Debian packages.

### Q: Does the Yubikey work in a VM?
**A:** Yes, but you must pass the USB device to the VM. In VirtualBox: Devices → USB → Yubico.

---

## Contact and Support

- **GitHub Issues:** https://github.com/yourusername/yubikey-debian-fix/issues
- **Yubico Support:** https://support.yubico.com
- **Debian Wiki:** https://wiki.debian.org/Yubikey

---

Last update: 2024
