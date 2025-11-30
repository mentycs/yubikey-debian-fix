# Contributing to Yubikey Debian Fix

Grazie per il tuo interesse nel contribuire a questo progetto! 

## Come Contribuire

### Segnalare Bug

1. **Verifica che il bug non sia già stato segnalato** cercando nelle [Issues](https://github.com/yourusername/yubikey-debian-fix/issues)
2. **Crea una nuova Issue** includendo:
   - Versione di Debian
   - Modello di Yubikey
   - Output dello script `diagnose.sh`
   - Passi per riprodurre il problema
   - Comportamento atteso vs. osservato

### Suggerire Miglioramenti

1. Apri una [Issue](https://github.com/yourusername/yubikey-debian-fix/issues) con tag `enhancement`
2. Descrivi chiaramente il miglioramento proposto
3. Spiega perché sarebbe utile alla community

### Pull Requests

1. **Fork** il repository
2. **Crea un branch** per la tua feature (`git checkout -b feature/AmazingFeature`)
3. **Commit** le tue modifiche (`git commit -m 'Add some AmazingFeature'`)
4. **Push** al branch (`git push origin feature/AmazingFeature`)
5. **Apri una Pull Request**

#### Linee Guida per il Codice

- **Script Bash:**
  - Usa `set -e` per uscire su errori
  - Commenta il codice complesso
  - Usa funzioni per codice riutilizzabile
  - Testa su Debian 12 e 13

- **Documentazione:**
  - Usa Markdown formattato correttamente
  - Includi esempi pratici
  - Mantieni un tono chiaro e conciso
  - Aggiorna il changelog

### Testing

Prima di inviare una PR:

1. **Testa gli script:**
   ```bash
   shellcheck install.sh
   shellcheck scripts/*.sh
   ```

2. **Verifica su sistema pulito:**
   - Debian 13 fresh install
   - Debian 12 (se possibile)

3. **Testa diversi modelli Yubikey:**
   - Yubikey 4
   - Yubikey 5 NFC
   - Yubikey 5C

### Documentazione

- Aggiorna `README.md` per nuove features
- Aggiungi casi a `TROUBLESHOOTING.md` per problemi risolti
- Documenta nuovi script in `docs/`

### Stile del Codice

#### Bash
```bash
# Buono
function check_root() {
    if [[ $EUID -eq 0 ]]; then
        echo "Error: Don't run as root"
        exit 1
    fi
}

# Evitare
check_root() {
if [ $EUID -eq 0 ]; then
echo "Error: Don't run as root"
exit 1
fi
}
```

#### Markdown
- Usa `###` per sottosezioni
- Code blocks con linguaggio specificato
- Liste con `-` non `*`

### Community

- Sii rispettoso e costruttivo
- Aiuta altri utenti nelle Issues
- Condividi le tue esperienze

### Licenza

Contribuendo, accetti che il tuo contributo sia rilasciato sotto la stessa [Licenza MIT](LICENSE) del progetto.

## Riconoscimenti

Tutti i contributori saranno riconosciuti nel file [CONTRIBUTORS.md](CONTRIBUTORS.md).

## Domande?

Se hai domande, apri una [Issue](https://github.com/yourusername/yubikey-debian-fix/issues) con tag `question`.

Grazie per rendere questo progetto migliore! 🔑
