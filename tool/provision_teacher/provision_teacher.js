/*
 * Creates a teacher account: a Firebase Auth user plus its users/{uid}
 * document with role 'teacher'.
 *
 * WHY THIS IS A SCRIPT AND NOT A BUTTON IN THE ADMIN APP
 *
 *   1. createUserWithEmailAndPassword on the default FirebaseAuth instance
 *      SIGNS THE CALLER INTO THE NEW ACCOUNT. An admin tapping "add
 *      teacher" would silently become the teacher. There is no client-side
 *      way around this.
 *   2. firestore.rules forbids EVERY client — admins included — from
 *      writing the `role` field. That is deliberate: role escalation must
 *      not be reachable from a phone. So even a successful Auth create
 *      could not finish the job.
 *
 * Both problems disappear with an owner credential, which is what this
 * script uses. It follows the tool/rules_test precedent: no service-account
 * key file is created, stored, or gitignored — it borrows the short-lived
 * OAuth token that `firebase login` already put on this machine. Nothing
 * secret enters the repository, and nothing here ships in the app.
 *
 * Usage:
 *   node tool/provision_teacher/provision_teacher.js \
 *     --email teacher@example.edu --name "د. سارة قاسم"
 *
 *   --dry-run   report what would happen, write nothing
 *
 * The teacher never receives a password from us: one is generated, used
 * once to create the account, and discarded unread. They set their own via
 * the app's existing "forgot password" screen.
 */
import crypto from 'node:crypto';
import { accessToken } from '../rules_test/token.js';

const PROJECT = 'academia-app-7b8ef';
const IDENTITY = `https://identitytoolkit.googleapis.com/v1/projects/${PROJECT}`;
const FIRESTORE =
  `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents`;

// ------------------------------------------------------------------ args

function parseArgs(argv) {
  const args = { dryRun: false };
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === '--dry-run') args.dryRun = true;
    else if (arg === '--email') args.email = argv[++i];
    else if (arg === '--name') args.name = argv[++i];
    else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }
  return args;
}

function validate(args) {
  const email = (args.email ?? '').trim().toLowerCase();
  const name = (args.name ?? '').trim();

  if (!email || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
    throw new Error('--email is required and must be a valid address.');
  }
  if (!name) {
    throw new Error('--name is required (shown to students as the instructor).');
  }
  return { email, name };
}

// ------------------------------------------------------------------- api

async function api(token, url, { method = 'POST', body } = {}) {
  const res = await fetch(url, {
    method,
    headers: {
      authorization: `Bearer ${token}`,
      'content-type': 'application/json',
    },
    ...(body === undefined ? {} : { body: JSON.stringify(body) }),
  });

  const text = await res.text();
  let parsed = null;
  try {
    parsed = text ? JSON.parse(text) : null;
  } catch {
    parsed = { raw: text };
  }

  return { ok: res.ok, status: res.status, body: parsed };
}

async function lookupByEmail(token, email) {
  const res = await api(token, `${IDENTITY}/accounts:lookup`, {
    body: { email: [email] },
  });
  if (!res.ok) {
    throw new Error(
      `Auth lookup failed (${res.status}): ${JSON.stringify(res.body)}`,
    );
  }
  const users = res.body?.users ?? [];
  return users.length ? users[0] : null;
}

async function createAuthUser(token, { email, name }) {
  /*
   * emailVerified is set by us, not proven by the teacher.
   *
   * The admin vouches for the address out of band, and this is precisely
   * what lets a teacher skip the student email-verification gate at login.
   * It is also why this endpoint must never be reachable from the app.
   */
  const res = await api(token, `${IDENTITY}/accounts`, {
    body: {
      email,
      displayName: name,
      emailVerified: true,
      // Generated, used once, never printed and never stored.
      password: crypto.randomBytes(24).toString('base64url'),
    },
  });

  if (!res.ok) {
    throw new Error(
      `Auth user creation failed (${res.status}): ${JSON.stringify(res.body)}`,
    );
  }
  const uid = res.body?.localId;
  if (!uid) {
    throw new Error(`Auth user created but no uid returned: ${JSON.stringify(res.body)}`);
  }
  return uid;
}

async function deleteAuthUser(token, uid) {
  return api(token, `${IDENTITY}/accounts:delete`, { body: { localId: uid } });
}

async function getUserDoc(token, uid) {
  const res = await api(token, `${FIRESTORE}/users/${uid}`, { method: 'GET' });
  if (res.status === 404) return null;
  if (!res.ok) {
    throw new Error(
      `Firestore read failed (${res.status}): ${JSON.stringify(res.body)}`,
    );
  }
  return res.body;
}

/*
 * The minimum shape a teacher document must have.
 *
 * onboardingCompleted / onboardingStatus are NOT optional: the splash
 * screen routes any account without them into the student onboarding flow,
 * and a teacher would be stuck choosing study days.
 *
 * Deliberately absent: studentId, major, majorId, academicLevel and study
 * preferences. Those describe a course of study; a teacher does not have
 * one, and writing empty placeholders would invent data.
 */
function teacherDocumentFields({ email, name, now }) {
  return {
    fullName: { stringValue: name },
    email: { stringValue: email },
    role: { stringValue: 'teacher' },
    status: { stringValue: 'active' },
    emailVerified: { booleanValue: true },
    onboardingCompleted: { booleanValue: true },
    onboardingStatus: { stringValue: 'completed' },
    createdAt: { timestampValue: now },
    updatedAt: { timestampValue: now },
  };
}

async function writeUserDoc(token, uid, fields) {
  const res = await api(token, `${FIRESTORE}/users/${uid}`, {
    method: 'PATCH',
    body: { fields },
  });
  if (!res.ok) {
    throw new Error(
      `Firestore write failed (${res.status}): ${JSON.stringify(res.body)}`,
    );
  }
  return res.body;
}

// ------------------------------------------------------------------ main

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const { email, name } = validate(args);
  const dryRun = args.dryRun;
  const token = await accessToken();

  console.log(`\nProvisioning teacher: ${name} <${email}>`);
  if (dryRun) console.log('(--dry-run: nothing will be written)\n');

  // ---- 1. Auth user: reuse if it already exists ----
  const existing = await lookupByEmail(token, email);
  let uid = existing?.localId ?? null;
  let createdAuthUserHere = false;

  if (uid) {
    console.log(`  auth   : already exists (uid ${uid}) — reusing`);
  } else if (dryRun) {
    console.log('  auth   : would CREATE a new user');
  } else {
    uid = await createAuthUser(token, { email, name });
    createdAuthUserHere = true;
    console.log(`  auth   : created (uid ${uid})`);
  }

  // ---- 2. Firestore document ----
  const doc = uid ? await getUserDoc(token, uid) : null;
  const currentRole = doc?.fields?.role?.stringValue ?? null;

  /*
   * Refuse to convert an existing non-teacher account.
   *
   * Re-running this script on a student's address must not silently
   * promote them. Rerunning it on an existing TEACHER is fine and is what
   * makes the script idempotent — that is the repair path when a previous
   * run created the Auth user but failed before the document landed.
   */
  if (doc && currentRole && currentRole !== 'teacher') {
    if (createdAuthUserHere) await deleteAuthUser(token, uid);
    throw new Error(
      `users/${uid} already exists with role '${currentRole}'. ` +
        'Refusing to overwrite a non-teacher account. Role changes are a ' +
        'separate, deliberate operation.',
    );
  }

  const fields = teacherDocumentFields({
    email,
    name,
    now: new Date().toISOString(),
  });

  // An existing teacher document keeps its original createdAt.
  const existingCreatedAt = doc?.fields?.createdAt?.timestampValue;
  if (existingCreatedAt) {
    fields.createdAt = { timestampValue: existingCreatedAt };
  }

  if (dryRun) {
    console.log(
      `  doc    : would ${doc ? 'UPDATE' : 'CREATE'} users/${uid ?? '<new-uid>'} with role 'teacher'`,
    );
    console.log('\nDry run complete. Nothing was written.\n');
    return;
  }

  try {
    await writeUserDoc(token, uid, fields);
    console.log(`  doc    : ${doc ? 'updated' : 'created'} users/${uid}`);
  } catch (error) {
    /*
     * Rollback, but only over what this run created.
     *
     * A half-provisioned account is not silently harmless: the fail-closed
     * role parser rejects it at login, so the teacher sees "unsupported
     * role" with no way to fix it themselves. Deleting the Auth user we
     * just made returns the system to its previous state and makes a
     * re-run clean. A pre-existing Auth user is left alone — it is not
     * ours to delete.
     */
    if (createdAuthUserHere) {
      const rollback = await deleteAuthUser(token, uid);
      console.error(
        rollback.ok
          ? `  rollback: deleted the auth user created by this run (${uid})`
          : `  rollback FAILED for uid ${uid} — delete it manually in the ` +
              'Firebase console, or re-run this script to finish provisioning.',
      );
    }
    throw error;
  }

  console.log(
    `\nDone. Tell ${name} to open the app, choose "نسيت كلمة المرور",\n` +
      `and set a password for ${email}. No password was generated for you\n` +
      'to pass on, by design.\n',
  );
}

main().catch((error) => {
  console.error(`\nERROR: ${error.message}\n`);
  process.exit(1);
});
