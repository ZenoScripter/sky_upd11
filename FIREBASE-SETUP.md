# Firebase setup for Skyfy accounts

Project ID `skyfy-cea60` - Android package `com.wildan.skyfy`.
`android/app/google-services.json` is already in the repository (it is client
configuration, not a server secret).

The app works normally if Firebase is not reachable or not configured: accounts
are simply disabled.

## Do these steps in order

1. **Register the signing fingerprints.** Firebase console > Project settings >
   Your apps > Skyfy (Android) > **Add fingerprint**. Add both:
   - SHA-1 `D5:25:16:F4:6C:4C:1B:EB:AB:52:CD:54:1B:76:B3:DC:FC:80:4A:5E`
   - SHA-256 `A8:88:B4:A7:12:2C:41:1E:82:19:55:9F:E4:DB:AA:D9:04:5E:A8:AC:24:4E:B8:33:FE:CA:35:EA:F2:75:04:10`
2. **Enable sign-in methods.** Build > Authentication > Get started > Sign-in
   method: enable **Email/Password** and **Google** (pick a support e-mail).
3. **Create Firestore.** Build > Firestore Database > Create database
   (production mode, a region near you). Open **Rules**, paste the content of
   `firestore.rules`, **Publish**.
4. **Download the config again.** Project settings > Your apps > Skyfy >
   `google-services.json`. The current file has an empty `oauth_client` list
   because it was downloaded before steps 1-2. Replace
   `android/app/google-services.json` with the new one and commit it.
5. **Restrict the API key** (Google Cloud console > APIs & Services >
   Credentials > the Android key): Application restriction = Android apps, add
   package `com.wildan.skyfy` + the SHA-1 above.
6. **Add the GitHub secrets** (`GITHUB-SECRETS.md`) and run
   **Build release apk**. Install the resulting `Skyfy.apk`.

## What is different per build

- **Release APK** (`com.wildan.skyfy`): accounts enabled.
- **Debug APK** (`com.wildan.skyfy.debug`) and **F-Droid**: the Google services
  plugin is not applied (those package ids are not in `google-services.json`),
  so accounts are off and everything else works.
- **Windows / Linux**: Firebase has no support here. The desktop workflow swaps
  `lib/services/account_service.dart` for `tool/account_service_stub.dart.txt`
  and removes the Firebase packages before building, so desktop builds never
  download or compile Firebase.

## Google sign-in implementation

The app uses `FirebaseAuth.signInWithProvider(GoogleAuthProvider())`. It needs
no separate `google_sign_in` package. It requires the Google provider enabled
(step 2) and the fingerprints registered (step 1).

See also: `FIRESTORE-STRUCTURE.md`, `FIRESTORE-SECURITY.md`,
`TESTING-CHECKLIST.md`.
