# Firestore security rules (`firestore.rules`)

Why each rule exists:

- **Nothing is public.** There is no rule without `request.auth != null`
  except the owner checks; unknown paths are denied by default.
- **`profiles/{uid}` read**: any signed-in user, because profiles are public
  and will be shown to friends. It contains no e-mail.
- **`profiles/{uid}` create**: only the owner (`request.auth.uid == uid`), only
  with valid fields (`hasOnly` blocks unexpected fields, username pattern,
  display name 1-30, bio up to 160, photo up to 700 KB) and only if the same
  transaction reserves the username for that uid (`existsAfter`/`getAfter`).
- **`profiles/{uid}` update**: owner only, valid fields, and
  `username` must stay equal to the stored one (no renaming, so nobody can free
  or steal usernames).
- **`users/{uid}`**: private. Only the owner can read or write, with a fixed
  shape for `privacy`.
- **`usernames/{name}` create**: valid pattern, `{uid}` only, `uid` must be the
  caller, and the caller's profile written in the same transaction must carry
  this username. Documents are never updated or deleted, so a username cannot be
  re-assigned. **Listing is denied** so nobody can dump all usernames; a single
  `get` is allowed for signed-in users (needed by the transaction and, later,
  the user search).
- **No deletes** of profiles or reservations from the client.

Limits to know:

- Rules cannot rate-limit. Spam protection (for friend requests and chat) needs
  extra measures in the next phase (Firebase App Check, quotas, Cloud Functions).
- Rules were written and reviewed but **not tested** in the Firebase emulator or
  the console simulator yet. Test with the Rules Playground before relying on
  them, especially: a user editing another uid, a duplicate username, listing
  `usernames`.
