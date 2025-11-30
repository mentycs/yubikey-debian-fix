# Troubleshooting Guide

## Problemi Comuni e Soluzioni

### 1. Chrome non rileva la Yubikey

#### Sintomi
- La Yubikey lampeggia ma Chrome non risponde
- Errore "Security key not detected"
- Il browser si blocca durante l'autenticazione

#### Soluzioni

**Reset completo di Chrome:**
```bash
# Chiudere Chrome completamente
pkill chrome || pkill chromium

# Pulire la cache delle security keys
rm -rf ~/.config/chromium/Default/Web\ Data*
rm -rf ~/.config/google-chrome/Default/Web\ Data*

# Riavviare Chrome
google-chrome || chromium
```

**Verificare i permessi:**
```bash
# Controllare i permessi dei device
ls -la /dev/hidraw*

# Dovrebbero mostrare:
# crw-rw---- 1 root plugdev ... /dev/hidraw0
```

**Riavviare i servizi:**
```bash
sudo systemctl restart systemd-udevd
sudo systemctl restart pcscd
sudo udevadm control --reload-rules
sudo udevadm trigger
```

---

### 2. Errore "Permission denied" su /dev/hidraw

#### Causa
L'utente non è nel gruppo plugdev o le regole udev non sono applicate.

#### Soluzione
```bash
# Aggiungere l'utente al gruppo
sudo usermod -a -G plugdev $USER

# Logout e login necessari!
gnome-session-quit --logout
```

---

### 3. ykman non trova il dispositivo

#### Sintomi
```
Error: No YubiKey detected
```

#### Soluzioni

**Verificare USB:**
```bash
# Controllare se il sistema vede la Yubikey
lsusb | grep Yubico
```

**Riavviare pcscd:**
```bash
sudo systemctl restart pcscd
```

**Provare senza pcscd:**
```bash
# A volte pcscd interferisce con U2F
sudo systemctl stop pcscd
ykman info
```

---

### 4. Conflitto con GPG/GnuPG

#### Sintomi
- GPG blocca l'accesso alla Yubikey
- Impossibile usare U2F mentre GPG è attivo

#### Soluzione
```bash
# Terminare i processi GPG
gpgconf --kill gpg-agent
gpgconf --kill scdaemon

# O disabilitare temporaneamente
systemctl --user stop gpg-agent
```

---

### 5. Yubikey non lampeggia

#### Causa
La richiesta non arriva al dispositivo.

#### Verifiche
1. **Browser supportato?**
   - Chrome/Chromium: ✓ Supporto completo
   - Firefox: Richiede `security.webauth.u2f` abilitato
   - Edge Linux: ✓ Supporto nativo

2. **HTTPS richiesto:**
   - U2F/WebAuthn funziona solo su HTTPS
   - Eccezione: localhost per test

3. **Estensioni browser:**
   ```bash
   # Avviare Chrome senza estensioni
   google-chrome --disable-extensions
   ```

---

### 6. Errore dopo aggiornamento sistema

#### Sintomi
Funzionava prima dell'aggiornamento, ora non più.

#### Soluzione
```bash
# Reinstallare i pacchetti
sudo apt install --reinstall libpam-u2f libfido2-1 libu2f-host0

# Ricreare le regole udev
sudo ./install.sh

# Verificare il kernel
uname -r
# Kernel 5.10+ richiesto per supporto completo
```

---

### 7. Multiple Yubikey simultanee

#### Configurazione
```bash
# Regole udev per supporto multiplo
sudo vi /etc/udev/rules.d/71-yubikeys.rules
```

Aggiungere:
```
# Supporto per multiple Yubikey
ATTRS{idVendor}=="1050", ENV{ID_SECURITY_TOKEN}="1", TAG+="uaccess", MODE="0660", GROUP="plugdev"
```

---

### 8. Debug Mode

#### Abilitare logging verbose

**Chrome:**
```bash
google-chrome \
  --enable-logging=stderr \
  --v=1 \
  2>&1 | grep -i "fido\|u2f\|hid"
```

**System logs:**
```bash
# Monitor real-time
sudo journalctl -f | grep -i "yubikey\|u2f\|fido\|hidraw"
```

**pcscd debug:**
```bash
sudo systemctl stop pcscd
sudo pcscd -f -d
```

---

### 9. Test di verifica

#### Test rapido funzionalità
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

#### Siti di test
- https://webauthn.io - Test FIDO2/WebAuthn
- https://demo.yubico.com/webauthn - Yubico demo
- https://webauthn.me - Alternative test

---

### 10. Rollback modifiche

Se necessario ripristinare la configurazione originale:

```bash
# Ripristinare backup udev
sudo rm /etc/udev/rules.d/70-u2f.rules
sudo rm /etc/udev/rules.d/71-yubikeys.rules
sudo cp -r /etc/udev/rules.d.backup.* /etc/udev/rules.d/

# Rimuovere utente da plugdev
sudo gpasswd -d $USER plugdev

# Disinstallare pacchetti (opzionale)
sudo apt remove yubikey-manager yubikey-personalization

# Riavviare
sudo reboot
```

---

## FAQ

### D: Posso usare la Yubikey su più computer?
**R:** Sì, la stessa Yubikey può essere registrata su account multipli e computer diversi.

### D: È sicuro disabilitare pcscd?
**R:** Sì, se usi solo U2F/FIDO2. È necessario solo per funzionalità smartcard/GPG.

### D: Funziona con Wayland?
**R:** Sì, il supporto Yubikey non dipende dal display server.

### D: Devo installare driver proprietari?
**R:** No, tutto il supporto è open source e incluso nei pacchetti Debian.

### D: La Yubikey funziona in una VM?
**R:** Sì, ma devi passare il dispositivo USB alla VM. In VirtualBox: Devices → USB → Yubico.

---

## Contatti e Supporto

- **GitHub Issues:** https://github.com/yourusername/yubikey-debian-fix/issues
- **Yubico Support:** https://support.yubico.com
- **Debian Wiki:** https://wiki.debian.org/Yubikey

---

Ultimo aggiornamento: 2024
