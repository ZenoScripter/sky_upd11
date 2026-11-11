# Android release signing (permanent key)

Every release APK of Skyfy is signed with **one permanent key**. Google Sign-In,
updates over an installed version, and Firebase all depend on this key staying
the same.

| Item | Value |
|---|---|
| Keystore file | `skyfy-release.jks` (private, never in the repository) |
| Alias | `skyfy-release` |
| Package name | `com.wildan.skyfy` |
| Algorithm | RSA 4096, valid until 2056-11-02 |
| SHA-1 | `D5:25:16:F4:6C:4C:1B:EB:AB:52:CD:54:1B:76:B3:DC:FC:80:4A:5E` |
| SHA-256 | `A8:88:B4:A7:12:2C:41:1E:82:19:55:9F:E4:DB:AA:D9:04:5E:A8:AC:24:4E:B8:33:FE:CA:35:EA:F2:75:04:10` |

Fingerprints are public information (you register them in Firebase). The
keystore file and its password are secret.

## How it works in this project

- `android/app/build.gradle.kts` reads `android/app/key.jks` and
  `android/key.properties` (`storePassword`, `keyPassword`, `keyAlias`).
- There is **no fallback to the debug key**. A release build without the key
  stops with a clear error message.
- In GitHub Actions the `Build release apk` workflow restores both files from
  the four secrets (see `GITHUB-SECRETS.md`), builds, checks that the APK
  certificate SHA-256 equals the value above (otherwise the build fails),
  uploads `Skyfy.apk`, and deletes the key files at the end (also on failure).
- `.gitignore` blocks `*.jks`, `*.keystore` and `key.properties`.

## Never recreate the key

Once the fingerprints are in Firebase and users installed the app, a new key
means: Google Sign-In stops working and nobody can update without uninstalling.

## Backup and recovery

1. Keep `skyfy-release.jks` in **two** places (for example a password manager
   file attachment and an offline USB or cloud vault that is not public).
2. Store the password and alias in a password manager.
3. Recovery: the `KEYSTORE_BASE64.txt` content is the same file encoded; to
   get the `.jks` back run `base64 --decode KEYSTORE_BASE64.txt > skyfy-release.jks`
   (Windows PowerShell:
   `[IO.File]::WriteAllBytes("skyfy-release.jks",[Convert]::FromBase64String((Get-Content KEYSTORE_BASE64.txt -Raw)))`).
4. Check any copy: `keytool -list -v -keystore skyfy-release.jks -alias skyfy-release`
   and compare the SHA-1/SHA-256 with the table.

## Change the password without changing the fingerprints

The fingerprints belong to the key, not to the password, so you can (and
should) change the password once you saved the files:

```
keytool -storepasswd -keystore skyfy-release.jks
```

Then update `KEYSTORE_PASSWORD` and `KEY_PASSWORD` (they are the same for a
PKCS12 keystore) and regenerate `KEYSTORE_BASE64`.

## Security note

This keystore was generated during a chat session, so the chat transcript
saw its first password. Changing the password (above) removes the password
risk, but whoever downloaded the file earlier still has the key file. If you
want the highest assurance, generate your own key on your computer instead:

```
keytool -genkeypair -v -keystore skyfy-release.jks -storetype PKCS12 \
  -alias skyfy-release -keyalg RSA -keysize 4096 -validity 10950
```

and register **its** fingerprints and update `EXPECTED_SHA256` in
`.github/workflows/release-apk.yml` before the first public release.
