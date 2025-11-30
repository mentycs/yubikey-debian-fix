# Yubikey Chrome Authentication Fix for Debian

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Debian](https://img.shields.io/badge/Debian-13-red.svg)](https://www.debian.org/)
[![Yubikey](https://img.shields.io/badge/Yubikey-4%2F5-green.svg)](https://www.yubico.com/)

Soluzione completa per risolvere i problemi di autenticazione Google con Yubikey Touch su Debian 13 e Chrome/Chromium.

## 🔧 Problema

La Yubikey 4/5 (ID 1050:0407) non viene riconosciuta correttamente da Chrome su Debian 13 per l'autenticazione Google con FIDO2/U2F.

## ⚡ Installazione Rapida

```bash
git clone https://github.com/yourusername/yubikey-debian-fix.git
cd yubikey-debian-fix
chmod +x install.sh
sudo ./install.sh
```

## 📖 Documentazione

- [Guida Completa](docs/GUIDA_COMPLETA.md) - Guida dettagliata passo-passo
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Risoluzione problemi comuni
- [Script Automatici](scripts/) - Script di installazione e configurazione

## 🎯 Caratteristiche

- ✅ Configurazione automatica delle regole udev
- ✅ Installazione dei pacchetti necessari
- ✅ Script di diagnostica
- ✅ Supporto per Yubikey 4/5 OTP+U2F+CCID
- ✅ Compatibile con Debian 12/13

## 📋 Requisiti

- Debian 12 o 13
- Chrome o Chromium
- Yubikey 4 o 5
- Accesso sudo

## 🚀 Uso Manuale

1. **Installare i pacchetti necessari:**
   ```bash
   sudo apt update
   sudo apt install libpam-u2f libfido2-1 libu2f-host0 yubikey-manager pcscd scdaemon
   ```

2. **Configurare udev:**
   ```bash
   sudo cp config/70-u2f.rules /etc/udev/rules.d/
   sudo udevadm control --reload-rules
   sudo udevadm trigger
   ```

3. **Aggiungere l'utente al gruppo plugdev:**
   ```bash
   sudo usermod -a -G plugdev $USER
   ```

4. **Riavviare il sistema o fare logout/login**

## 🔍 Diagnostica

Eseguire lo script di diagnostica per verificare la configurazione:

```bash
./scripts/diagnose.sh
```

## 🤝 Contribuire

Le contribuzioni sono benvenute! Vedere [CONTRIBUTING.md](CONTRIBUTING.md) per maggiori dettagli.

## 📝 Licenza

Questo progetto è rilasciato sotto licenza MIT. Vedere il file [LICENSE](LICENSE) per i dettagli.

## 👥 Autore

- Creato per la community Debian/Linux

## 🔗 Link Utili

- [Yubico Official Docs](https://support.yubico.com/hc/en-us)
- [Debian Wiki - Yubikey](https://wiki.debian.org/Yubikey)
- [Chrome U2F Support](https://support.google.com/accounts/answer/6103523)

## ⭐ Supporto

Se questo progetto ti è stato utile, considera di dargli una stella su GitHub!
