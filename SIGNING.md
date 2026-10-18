# Signing Setup

## ⚠️ The current release key is COMPROMISED

The passwords for `release_siratCompanionReleasep12.p12` were committed
to git history in `build-profile.json5`. The `.p12` file itself lived
under `D:/GitHub/SiratCompanion/secrets/release/` — also inside the repo.

**Both the passwords and the keystore must be considered leaked.**

See "Rotation" below before building any release APK.

## Setup

1. Copy `signing.properties.example` → `signing.properties` (gitignored).
2. Fill in real values.
3. Export to shell before building:
   ```bash
   set -a; . ./signing.properties; set +a