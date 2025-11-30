# Guida Completa: Yubikey su Debian 13 con Chrome

## Indice
1. [Introduzione](#introduzione)
2. [Identificazione del Problema](#identificazione-del-problema)
3. [Prerequisiti](#prerequisiti)
4. [Installazione Pacchetti](#installazione-pacchetti)
5. [Configurazione udev](#configurazione-udev)
6. [Configurazione Permessi](#configurazione-permessi)
7. [Gestione Servizi](#gestione-servizi)
8. [Test e Verifica](#test-e-verifica)
9. [Troubleshooting](#troubleshooting)
10. [Configurazioni Avanzate](#configurazioni-avanzate)

---

## Introduzione

Questa guida risolve il problema comune in cui Chrome/Chromium su Debian 13 non rileva correttamente il touch sulla Yubikey per l'autenticazione Google con FIDO2/U2F.

### Dispositivo Interessato
```
Bus 002 Device 003: ID 1050:0407 Yubico.com Yubikey 4/5 OTP+U2F+CCID
```

## Identificazione del Problema

### Sintomi Comuni
- Chrome non mostra la richiesta di toccare la Yubikey
- L'autenticazione si blocca senza risposta
- La Yubikey lampeggia ma Chrome non risponde
- Errore "Security key not detected"

### Verifica Iniziale
```bash
# Verificare che la Yubikey sia riconosciuta dal sistema
lsusb | grep Yubico

# Output atteso:
# Bus 002 Device 003: ID 1050:0407 Yubico.com Yubikey 4/5 OTP+U2F+CCID
```

## Prerequisiti

### Requisiti di Sistema
- Debian 13 (Trixie) o Debian 12 (Bookworm)
- Kernel Linux 5.10 o superiore
- Chrome/Chromium versione 90+
- Accesso sudo/root

### Backup Configurazioni
```bash
# Backup delle regole udev esistenti
sudo cp -r /etc/udev/rules.d /etc/udev/rules.d.backup
```

## Installazione Pacchetti

### Pacchetti Essenziali
```bash
# Aggiornare il sistema
sudo apt update
sudo apt upgrade

# Installare i pacchetti necessari
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

### Descrizione Pacchetti
- **libpam-u2f**: Modulo PAM per autenticazione U2F
- **libfido2-1**: Libreria per FIDO2/WebAuthn
- **libu2f-host0**: Libreria host per U2F
- **yubikey-manager**: Tool CLI per gestire Yubikey
- **pcscd**: PC/SC daemon per smartcard
- **scdaemon**: Daemon GnuPG per smartcard

## Configurazione udev

### Creare le Regole udev

```bash
# Creare il file delle regole
sudo vi /etc/udev/rules.d/70-u2f.rules
```

Contenuto del file:
```udev
# Yubico Yubikey 4/5
KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0407", TAG+="uaccess", MODE="0660", GROUP="plugdev"
SUBSYSTEMS=="usb", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0407", TAG+="uaccess", MODE="0660", GROUP="plugdev"

# Regole aggiuntive per compatibilità completa
ACTION=="add|change", SUBSYSTEM=="usb", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0407", ENV{ID_SECURITY_TOKEN}="1"
KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0407", ENV{ID_SECURITY_TOKEN}="1"

# Supporto per tutti i modelli Yubikey
KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", TAG+="uaccess", MODE="0660", GROUP="plugdev"
SUBSYSTEMS=="usb", ATTRS{idVendor}=="1050", TAG+="uaccess", MODE="0660", GROUP="plugdev"
```

### Applicare le Modifiche
```bash
# Ricaricare le regole udev
sudo udevadm control --reload-rules
sudo udevadm trigger

# Verificare che le regole siano applicate
udevadm test $(udevadm info -q path -n /dev/hidraw0) 2>&1 | grep "70-u2f"
```

## Configurazione Permessi

### Gestione Gruppi Utente
```bash
# Aggiungere l'utente ai gruppi necessari
sudo usermod -a -G plugdev $USER
sudo usermod -a -G scard $USER  # Opzionale per smartcard

# Verificare i gruppi
groups $USER
```

### Permessi File System
```bash
# Assicurarsi che i device abbiano i permessi corretti
ls -la /dev/hidraw*
# Dovrebbero mostrare gruppo 'plugdev' e permessi 660
```

## Gestione Servizi

### Configurazione pcscd
```bash
# Abilitare e avviare pcscd
sudo systemctl enable pcscd
sudo systemctl start pcscd

# Verificare lo stato
sudo systemctl status pcscd
```

### Ottimizzazione per U2F/FIDO2
Se si verificano conflitti con pcscd:
```bash
# Disabilitare pcscd se causa problemi con U2F
sudo systemctl stop pcscd
sudo systemctl disable pcscd

# NOTA: Disabilitare solo se non si usa la funzionalità smartcard
```

## Test e Verifica

### Test con yubikey-manager
```bash
# Informazioni sulla Yubikey
ykman info

# Lista delle applicazioni disponibili
ykman list

# Test FIDO2
ykman fido info
```

### Test con Chrome
1. Chiudere completamente Chrome:
   ```bash
   pkill chrome || pkill chromium
   ```

2. Riavviare Chrome e navigare su: https://webauthn.io/

3. Testare la registrazione e l'autenticazione

### Script di Test Completo
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

### Problema: Chrome non rileva la Yubikey

**Soluzione 1: Reset completo**
```bash
# Rimuovere e reinserire la Yubikey
# Riavviare i servizi
sudo systemctl restart systemd-udevd
sudo systemctl restart pcscd

# Clear Chrome security key cache
rm -rf ~/.config/chromium/Default/Web\ Data*
rm -rf ~/.config/google-chrome/Default/Web\ Data*
```

**Soluzione 2: Modalità debug**
```bash
# Avviare Chrome con log verbose
google-chrome --enable-logging=stderr --v=1 2>&1 | grep -i "fido\|u2f\|hid"
```

### Problema: Permessi insufficienti

```bash
# Verificare e correggere i permessi
sudo chmod 660 /dev/hidraw*
sudo chown root:plugdev /dev/hidraw*
```

### Problema: Conflitto con altri servizi

```bash
# Identificare processi che usano la Yubikey
sudo lsof | grep hidraw

# Terminare processi conflittuali
sudo killall gpg-agent scdaemon  # Se necessario
```

## Configurazioni Avanzate

### Configurazione per più Yubikey
```bash
# Regole udev per multiple Yubikey
cat << 'EOF' | sudo tee /etc/udev/rules.d/71-yubikeys.rules
# Supporto per multiple Yubikey simultanee
ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0010|0110|0111|0114|0116|0401|0403|0405|0407|0410", \
    ENV{ID_SECURITY_TOKEN}="1", ENV{ID_SMARTCARD_READER}="1", \
    TAG+="uaccess", MODE="0660", GROUP="plugdev"
EOF
```

### Integrazione con GPG
```bash
# Configurare GPG per usare la Yubikey
echo "reader-port Yubico Yubikey" >> ~/.gnupg/scdaemon.conf
gpgconf --reload scdaemon
```

### Logging Avanzato
```bash
# Abilitare logging dettagliato
echo "log-level debug" | sudo tee -a /etc/libccid_Info.conf

# Monitor real-time
sudo journalctl -f | grep -i "yubikey\|u2f\|fido"
```

## Script di Installazione Automatica

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

## Note Finali

### Sicurezza
- Mai condividere l'output di `ykman oath accounts list`
- Fare backup delle chiavi di recupero
- Testare sempre la configurazione prima di affidarsi completamente

### Compatibilità Browser
- **Chrome/Chromium**: Supporto completo
- **Firefox**: Richiede configurazione aggiuntiva
- **Edge**: Supporto nativo su Linux

### Risorse Utili
- [Yubico Linux Documentation](https://support.yubico.com/hc/en-us/articles/360016649039)
- [Debian Wiki - Yubikey](https://wiki.debian.org/Yubikey)
- [FIDO2 Project](https://fidoalliance.org/fido2/)

---

**Versione**: 1.0.0  
**Ultimo aggiornamento**: 2024  
**Compatibilità**: Debian 12/13, Ubuntu 22.04+
