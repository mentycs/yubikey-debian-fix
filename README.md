# Yubikey Chrome Authentication Fix for Debian

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Debian](https://img.shields.io/badge/Debian-13-red.svg)](https://www.debian.org/)
[![Yubikey](https://img.shields.io/badge/Yubikey-4%2F5-green.svg)](https://www.yubico.com/)

**[🇮🇹 Versione Italiana](README.it.md)** | **🇬🇧 English Version**

Complete solution to fix Google authentication issues with Yubikey Touch on Debian 13 and Chrome/Chromium.

## 🔧 Problem

Yubikey 4/5 (ID 1050:0407) is not properly recognized by Chrome on Debian 13 for Google authentication with FIDO2/U2F.

## ⚡ Quick Installation

```bash
git clone https://github.com/yourusername/yubikey-debian-fix.git
cd yubikey-debian-fix
chmod +x install.sh
sudo ./install.sh
```

## 📖 Documentation

- **[Complete Guide (EN)](docs/GUIDE.en.md)** - Detailed step-by-step guide
- **[Complete Guide (IT)](docs/GUIDA_COMPLETA.md)** - Guida dettagliata passo-passo
- **[Troubleshooting (EN)](docs/TROUBLESHOOTING.en.md)** - Common issues resolution
- **[Troubleshooting (IT)](docs/TROUBLESHOOTING.it.md)** - Risoluzione problemi comuni
- **[Automated Scripts](scripts/)** - Installation and configuration scripts

## 🎯 Features

- ✅ Automatic udev rules configuration
- ✅ Installation of required packages
- ✅ Diagnostic script
- ✅ Support for Yubikey 4/5 OTP+U2F+CCID
- ✅ Compatible with Debian 12/13

## 📋 Requirements

- Debian 12 or 13
- Chrome or Chromium
- Yubikey 4 or 5
- Sudo access

## 🚀 Manual Usage

1. **Install required packages:**
   ```bash
   sudo apt update
   sudo apt install libpam-u2f libfido2-1 libu2f-host0 yubikey-manager pcscd scdaemon
   ```

2. **Configure udev:**
   ```bash
   sudo cp config/70-u2f.rules /etc/udev/rules.d/
   sudo udevadm control --reload-rules
   sudo udevadm trigger
   ```

3. **Add user to plugdev group:**
   ```bash
   sudo usermod -a -G plugdev $USER
   ```

4. **Reboot the system or logout/login**

## 🔍 Diagnostics

Run the diagnostic script to verify the configuration:

```bash
./scripts/diagnose.sh
```

## 🤝 Contributing

Contributions are welcome! See **[CONTRIBUTING (EN)](CONTRIBUTING.en.md)** or **[CONTRIBUTING (IT)](CONTRIBUTING.it.md)** for more details.

## 📝 License

This project is released under the MIT License. See the [LICENSE](LICENSE) file for details.

## 👥 Author

- Created for the Debian/Linux community

## 🔗 Useful Links

- [Yubico Official Docs](https://support.yubico.com/hc/en-us)
- [Debian Wiki - Yubikey](https://wiki.debian.org/Yubikey)
- [Chrome U2F Support](https://support.google.com/accounts/answer/6103523)

## ⭐ Support

If this project was helpful to you, consider giving it a star on GitHub!
