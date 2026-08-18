# Teacher account provisioning

Creates a Firebase Auth user **and** its `users/{uid}` document with
`role: 'teacher'`, in one idempotent step.

```bash
node tool/provision_teacher/provision_teacher.js --email teacher@example.edu --name "د. سارة قاسم"
```

Add `--dry-run` to see what would happen without writing anything.

## Why this is not a button in the admin app

Two independent reasons, either of which alone is enough:

1. **`createUserWithEmailAndPassword` signs the caller into the new
   account.** On the default `FirebaseAuth` instance there is no
   client-side way to avoid this. An admin tapping "add teacher" would be
   silently logged out and logged in as the teacher they just created.

2. **No client may write `role`.** `firestore.rules` omits `role` from both
   `studentSelfEditable()` and `adminEditable()`, so role escalation is not
   reachable from a phone at all — by design. Even a successful Auth create
   could not finish the job from the app.

The admin app therefore manages what it *can* legitimately do: enable and
disable teacher accounts, and assign teachers to course offerings.

## Credentials

No service-account key is created, stored, or gitignored. The script
borrows the short-lived OAuth token that `firebase login` already stored in
`~/.config/configstore/firebase-tools.json`, exactly like
`tool/rules_test`. If a call returns 401, run `firebase login` again.

An owner token bypasses Firestore security rules — that is what allows the
`role` write, and why this file must never be reachable from the app.

## What gets written

| Field | Value | Why |
|---|---|---|
| `role` | `teacher` | the whole point; unwritable from any client |
| `status` | `active` | account gates in rules and in `AuthProvider` |
| `fullName` | `--name` | shown to students as the instructor name |
| `email` | `--email` | matches the Auth account |
| `emailVerified` | `true` | admin vouches for the address out of band; this is what lets a teacher skip the student verification gate |
| `onboardingCompleted` | `true` | **required** — without it the splash screen routes the teacher into student onboarding |
| `onboardingStatus` | `completed` | same reason |
| `createdAt` / `updatedAt` | now | preserved on re-runs |

Deliberately **absent**: `studentId`, `major`, `majorId`, `academicLevel`
and study preferences. Those describe a course of study that a teacher does
not have; writing empty placeholders would invent data.

## Passwords

None is generated for you to pass on. The script creates the account with a
random password it never prints, and the teacher sets their own through the
app's existing **نسيت كلمة المرور** screen.

## Idempotency and failure handling

Re-running the script on the same address is safe and is the repair path
when a previous run half-finished.

| Situation | Behaviour |
|---|---|
| Neither Auth user nor document exists | creates both |
| Auth user exists, document missing | reuses the uid, writes the document |
| Both exist, `role == 'teacher'` | refreshes the document, keeps original `createdAt` |
| Both exist, `role != 'teacher'` | **aborts** — will not promote a student or admin |
| Auth created here, document write fails | deletes the Auth user it just created, then reports |
| Auth pre-existed, document write fails | leaves the Auth user alone (not ours to delete) and reports |

The rollback matters because a half-provisioned account is not harmless:
the fail-closed role parser in `AppUserModel` rejects an account with no
recognised role at login, so the teacher would see "unsupported role" with
no way to fix it themselves.
