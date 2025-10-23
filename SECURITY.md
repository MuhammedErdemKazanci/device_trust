# Security Policy

## Reporting a Vulnerability

We take the security of `device_trust` seriously. If you discover a security vulnerability, please report it responsibly.

### How to Report

**Email**: [hello@mikoloyapps.com](mailto:hello@mikoloyapps.com)

**Please include**:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

**Do NOT**:
- Open a public issue for security vulnerabilities
- Share the vulnerability publicly before a fix is available

### What to Expect

- **Acknowledgment**: Within 48 hours
- **Initial assessment**: Within 5 business days
- **Status updates**: Every 7 days until resolved
- **Fix timeline**: Depends on severity (critical: 7-14 days, others: 30-60 days)

### Disclosure Policy

- **90-day disclosure**: We aim to fix and release within 90 days
- **Coordinated disclosure**: We'll coordinate with you on public disclosure timing
- **Credit**: We'll credit you in the release notes (if you wish)

## Scope

This security policy applies to:
- The `device_trust` Flutter plugin (this repository)
- Example app code included in this repository

Out of scope:
- Third-party dependencies (report to their maintainers)
- Social engineering attacks
- Physical access attacks

## Security Considerations

The `device_trust` plugin provides **heuristic detection** of device compromise. It is **not** a security guarantee:

- **Not 100% detection**: Attackers can bypass heuristics
- **False positives**: Some signals may trigger on legitimate devices
- **No cryptographic protection**: This is a detection tool, not an enforcement mechanism

### Recommended Usage

1. **Multi-signal decision**: Don't rely on a single signal
2. **Server-side validation**: Combine with server-side checks
3. **Regular updates**: Keep the plugin updated for latest detections
4. **User transparency**: Inform users about security checks

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

Only the latest stable version receives security updates.

## Known Limitations

- **Bypass techniques**: Root cloaking (Magisk Hide), Frida stealth mode
- **Platform constraints**: Some iOS checks work only on physical devices
- **Performance trade-offs**: Detection speed vs. thoroughness

See [README.md](README.md#limitations--security-notes) for details.

## Contact

For non-security questions:
- [Discussions](https://github.com/MuhammedErdemKazanci/device_trust/discussions)
- [Issues](https://github.com/MuhammedErdemKazanci/device_trust/issues)

For security vulnerabilities: [hello@mikoloyapps.com](mailto:hello@mikoloyapps.com)
