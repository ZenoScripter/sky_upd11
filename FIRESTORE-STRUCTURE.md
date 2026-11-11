# Firestore structure

Data is split by who may read it.

| Collection | Document id | Who reads | Content |
|---|---|---|---|
| `profiles` | user uid | any signed-in user | `username`, `displayName`, `bio`, `photo` (small avatar data URL, max 700 KB), `createdAt`, `updatedAt` |
| `users` | user uid | the owner only | `createdAt`, `updatedAt`, `privacy` (`showActivity`, `showOnline`, both false by default) |
| `usernames` | the username (lowercase) | `get` only, signed in; no listing | `uid` of the owner |

Notes:

- The e-mail address and password are **never** written to Firestore. They live
  only in Firebase Authentication (passwords are stored hashed by Firebase).
- Username rule: 3-20 characters, `a-z 0-9 _`, stored lowercase, never changes.
- A `usernames/{name}` document and its `profiles/{uid}` + `users/{uid}`
  documents are created in **one transaction**, so a username can never be
  reserved twice or without a profile.
- Future social collections (friend requests, chat, rooms) will be added next to
  these, keyed by uid, and will use `profiles` for public info.
