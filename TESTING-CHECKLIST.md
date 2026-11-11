# Testing checklist and status

Status meaning: **Implemented** = code written. **Build passed** = compiled in CI.
**Tested** = tried on a real device. **Not tested** = never run.

| Item | Implemented | Build passed | Tested |
|---|---|---|---|
| Register with e-mail | yes | not yet | Not tested |
| Login with e-mail | yes | not yet | Not tested |
| Google login | yes | not yet | Not tested |
| Logout | yes | not yet | Not tested |
| Reset password | yes | not yet | Not tested |
| Session persistence (Firebase default) | yes | not yet | Not tested |
| Unique username (transaction + rules) | yes | not yet | Not tested |
| Edit profile (name, bio, photo) | yes | not yet | Not tested |
| Profile sync to a second device | yes (name, photo, bio) | not yet | Not tested |
| Firestore rules | written | n/a | Not tested |
| Release APK signing + fingerprint check | yes | not yet | Not tested |
| SHA-1 / SHA-256 registered in Firebase | manual step | n/a | pending |
| Build Android (release) | yes | not yet | Not tested |
| Build Windows (stub, no Firebase) | yes | not yet | Not tested |
| Build Linux (stub, no Firebase) | yes | not yet | Not tested |
| Music, playlists, lyrics unchanged | untouched | not yet | Not tested |

How to test:

1. Register an account, close the app fully, open it again (still signed in).
2. Sign out, sign in again; try "Forgot password" (check the e-mail).
3. Register a second account with the same username: it must be refused.
4. Edit name/bio/photo, then sign in on another phone: same profile.
5. Google login: needs the fingerprints (FIREBASE-SETUP.md step 1) and the new
   `google-services.json`.
6. Run `Build release apk`; the "Verify the signing certificate" step must pass.
7. Run `Desktop builds`; Windows and Linux must finish.
