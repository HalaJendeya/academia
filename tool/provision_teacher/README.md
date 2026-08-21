# Teacher account provisioning

Creates a Firebase Auth user **and** its `users/{uid}` document with
`role: 'teacher'`, in one idempotent step.

This is the **Version 1 mechanism** for creating teacher accounts, and the
only supported one. It is a developer/administrator tool run from a
terminal — not a feature of the mobile app.

## Why a script and not a button in the admin app

Three independent reasons, any one of which is enough:

1. **`createUserWithEmailAndPassword` signs the caller into the new
   account.** On the default `FirebaseAuth` instance there is no
   client-side way to avoid this. An admin tapping "add teacher" would be
   silently logged out and logged back in as the teacher they just created.

2. **No client may write `role`.** `firestore.rules` omits `role` from both
   `studentSelfEditable()` and `adminEditable()`, and the `create` rule
   forces `role == 'student'`. Role escalation is not reachable from a
   phone at all — by design. Even a successful Auth create could not
   finish the job from the app.

3. **The project runs on the Firebase Spark (free) plan.** Cloud Functions
   requires Blaze billing, so the usual "callable function with the Admin
   SDK" answer is not available here. This script fills that role using
   credentials that already exist on the maintainer's machine.

The admin app therefore manages what it *can* legitimately do: **list**
teachers, view their details, **enable/disable** accounts, and assign
teachers to course offerings.

## The full flow

```
system administrator
  → node tool/provision_teacher/provision_teacher.js
      → Firebase Auth account created
      → users/{uid} document created with role 'teacher'
  → teacher opens the app, taps «نسيت كلمة المرور»
  → teacher sets their own password
  → teacher logs in normally
  → existing role routing opens the teacher experience
```

Nothing in this flow requires the app to create Auth accounts, and no
password is ever handled by a human other than the teacher.

## Prerequisites

- **Node.js 18+** (uses the built-in `fetch` and ES modules).
- **Firebase CLI**, authenticated as a user with Owner/Editor on the
  project:

  ```bash
  firebase login
  ```

  Check who you are currently signed in as:

  ```bash
  firebase login:list
  ```

  If a call later returns `401`, your token expired — run `firebase login`
  again.

No `npm install` is needed: the script has no dependencies.

## Usage

### 1. Dry run first

Reports exactly what would happen and writes nothing:

```bash
node tool/provision_teacher/provision_teacher.js --email teacher@example.edu --name "Example Teacher" --dry-run
```

### 2. Create the account

```bash
node tool/provision_teacher/provision_teacher.js --email teacher@example.edu --name "Example Teacher"
```

`--name` is what students see as the instructor name, so write it as it
should appear (title included).

### 3. Tell the teacher to set their password

They open the app, tap **نسيت كلمة المرور**, enter the same address, and
choose their own password. See [Passwords](#passwords) for why no password
is handed over.

### 4. Verify in the app

Sign in as an admin → **الإعدادات** → **إدارة المعلّمين**. The new account
appears in the list as **نشط**. From there you can disable it, or assign it
to a course offering.

## Credentials

No service-account key is created, stored, or gitignored. The script
borrows the short-lived OAuth token that `firebase login` already stored in
`~/.config/configstore/firebase-tools.json`, exactly like
`tool/rules_test`. Nothing secret enters this repository, and nothing here
ships in the app.

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
| `createdAt` / `updatedAt` | now | `createdAt` preserved on re-runs |

Deliberately **absent**: `studentId`, `major`, `majorId`, `academicLevel`
and study preferences. Those describe a course of study that a teacher does
not have; writing empty placeholders would invent data.

Also deliberately absent: `teacherId`, `employeeId`, `department`. **No
teacher document in this project has ever had them**, nothing in the app
reads them, and adding them here would create a field that only this script
writes and no screen shows. If a future feature needs one, it should be
added to the model, the rules and the UI in the same change.

## Idempotency and failure handling

Re-running the script on the same address is safe, and is the repair path
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

If the rollback itself fails, the script says so and names the uid — delete
it in the Firebase console, or simply re-run the script to finish the job.

## Passwords

None is generated for you to pass on. The script creates the account with a
random password it never prints, and the teacher sets their own through the
app's existing **نسيت كلمة المرور** screen.

This is deliberate, and a temporary-password flag was considered and
rejected: it would put an admin in the position of reading, storing and
transmitting someone else's credential, which is a worse problem than the
one it solves.

## Disabling and re-enabling accounts

Not this script's job. An admin does that in the app
(**إدارة المعلّمين** → teacher → تعطيل/تفعيل الحساب), which writes only
`status` and is permitted by the rules. The script never disables anything
and never deletes an account it did not just create.
