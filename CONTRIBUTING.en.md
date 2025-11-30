# Contributing to Yubikey Debian Fix

**🇬🇧 English Version** | **[🇮🇹 Versione Italiana](CONTRIBUTING.it.md)**

Thank you for your interest in contributing to this project!

## How to Contribute

### Reporting Bugs

1. **Check if the bug has already been reported** by searching in [Issues](https://github.com/yourusername/yubikey-debian-fix/issues)
2. **Create a new Issue** including:
   - Debian version
   - Yubikey model
   - Output of the `diagnose.sh` script
   - Steps to reproduce the problem
   - Expected vs. observed behavior

### Suggesting Improvements

1. Open an [Issue](https://github.com/yourusername/yubikey-debian-fix/issues) with the `enhancement` tag
2. Clearly describe the proposed improvement
3. Explain why it would be useful to the community

### Pull Requests

1. **Fork** the repository
2. **Create a branch** for your feature (`git checkout -b feature/AmazingFeature`)
3. **Commit** your changes (`git commit -m 'Add some AmazingFeature'`)
4. **Push** to the branch (`git push origin feature/AmazingFeature`)
5. **Open a Pull Request**

#### Code Guidelines

- **Bash Scripts:**
  - Use `set -e` to exit on errors
  - Comment complex code
  - Use functions for reusable code
  - Test on Debian 12 and 13

- **Documentation:**
  - Use properly formatted Markdown
  - Include practical examples
  - Maintain a clear and concise tone
  - Update the changelog

### Testing

Before submitting a PR:

1. **Test the scripts:**
   ```bash
   shellcheck install.sh
   shellcheck scripts/*.sh
   ```

2. **Verify on a clean system:**
   - Debian 13 fresh install
   - Debian 12 (if possible)

3. **Test different Yubikey models:**
   - Yubikey 4
   - Yubikey 5 NFC
   - Yubikey 5C

### Documentation

- Update `README.md` for new features
- Add cases to `TROUBLESHOOTING.md` for resolved issues
- Document new scripts in `docs/`

### Code Style

#### Bash
```bash
# Good
function check_root() {
    if [[ $EUID -eq 0 ]]; then
        echo "Error: Don't run as root"
        exit 1
    fi
}

# Avoid
check_root() {
if [ $EUID -eq 0 ]; then
echo "Error: Don't run as root"
exit 1
fi
}
```

#### Markdown
- Use `###` for subsections
- Code blocks with specified language
- Lists with `-` not `*`

### Community

- Be respectful and constructive
- Help other users in Issues
- Share your experiences

### License

By contributing, you agree that your contribution will be released under the same [MIT License](LICENSE) as the project.

## Recognition

All contributors will be recognized in the [CONTRIBUTORS.md](CONTRIBUTORS.md) file.

## Questions?

If you have questions, open an [Issue](https://github.com/yourusername/yubikey-debian-fix/issues) with the `question` tag.

Thank you for making this project better! 🔑
