# Firestore rules validation harness

Validates `firestore.rules` **without deploying anything** and without the
local emulator.

## Why not the emulator

The Firestore emulator needs JDK 21; this machine has JDK 17. Instead this
harness uses the **Firebase Rules Test API**
(`firebaserules.googleapis.com/v1/projects/{project}:test`), which compiles a
ruleset and evaluates test cases server-side. It is a read-only validation
call: it never writes data and never publishes a ruleset.

## Stateless — every lookup must be mocked

The Test API has no database. Every `exists()` / `get()` the rules perform must
be declared per test case as a function mock, so each test states the exact
world it assumes. `suite.js` builds those mocks from a single `WORLD` fixture.

This is the main difference from emulator tests, and the main way to get a
false pass: if a `DENY` test forgets a mock, the rule may be denying because
the lookup errored rather than because the validation failed. Keep the world
complete and list intentionally-absent documents in `missing`.

## Running

```bash
node tool/rules_test/suite.js
```

Expected output: `100/100 rules tests passed`.

```bash
node tool/rules_test/selftest.js
```

Runs four cases with deliberately **wrong** expectations and must report
`0/4`. A suite that passes everything is only meaningful if the harness can
fail — run this whenever the suite is changed.

## Authentication

`token.js` mints a short-lived Google access token from the refresh token that
`firebase login` already stored in
`~/.config/configstore/firebase-tools.json`. No secret is stored in this
repository: the OAuth client id/secret are the public ones published inside the
`firebase-tools` package. If the call returns 401, run `firebase login` again.
