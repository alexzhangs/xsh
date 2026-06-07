# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 0.5.x   | ✅ |
| < 0.5   | ❌ |

## Reporting a Vulnerability

Please do **not** open a public GitHub issue for security matters.

Use [GitHub Private Security Advisories](https://github.com/alexzhangs/xsh/security/advisories/new) to report privately. You will receive a response within 7 days.

## Scope

xsh loads and executes shell code from user-provided library repositories. Library authors are responsible for validating inputs within their utilities. The xsh framework itself does not sanitize arguments passed to library utilities.
