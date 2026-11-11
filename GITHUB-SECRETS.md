# GitHub secrets for release signing

You need four repository secrets. You can do all of this from a phone browser.

## 1. Get the values

- `KEYSTORE_BASE64`: the whole text inside `KEYSTORE_BASE64.txt` (one long line,
  no spaces, no line breaks).
- `KEYSTORE_PASSWORD`: the keystore password (from `SKYFY-SIGNING-PRIVATE.txt`).
- `KEY_PASSWORD`: the key password (the same value for this PKCS12 keystore).
- `KEY_ALIAS`: `skyfy-release`

To create the Base64 yourself:

- Linux / macOS: `base64 -w0 skyfy-release.jks > KEYSTORE_BASE64.txt`
- Windows PowerShell:
  `[Convert]::ToBase64String([IO.File]::ReadAllBytes("skyfy-release.jks")) | Set-Content KEYSTORE_BASE64.txt`

## 2. Add them to GitHub

Repository > **Settings** > **Secrets and variables** > **Actions** >
**New repository secret**. Add each name exactly as written above and paste the
value. Secrets cannot be read again after saving; you can only replace them.

## 3. How the workflow uses them

`Build release apk` (Actions tab > Run workflow):

1. Fails immediately with a clear error if any secret is missing.
2. Decodes `KEYSTORE_BASE64` into `android/app/key.jks` and writes
   `android/key.properties` (secrets are masked automatically in logs).
3. Opens the keystore to confirm the password and alias are right.
4. Builds, verifies the APK certificate SHA-256, uploads `Skyfy.apk`.
5. Deletes `key.jks` and `key.properties` (also when the build fails).

## Rules

- Never print, commit, or paste the Base64 or the passwords in issues, logs,
  or pull requests.
- Never put the keystore in the repository or in a public artifact.
- If a secret leaks, change the keystore password (see `ANDROID-SIGNING.md`) and
  update the secrets.
