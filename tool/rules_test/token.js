// Mints a short-lived Google access token from the firebase-tools refresh
// token already stored on this machine. Read-only use: the Rules Test API
// evaluates a ruleset, it does not deploy or write anything.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const CONFIG = path.join(
  os.homedir(),
  '.config',
  'configstore',
  'firebase-tools.json',
);

// Public OAuth client shipped inside firebase-tools (lib/api.js).
const CLIENT_ID =
  '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com';
const CLIENT_SECRET = 'j9iVZfS8kkCEFUPaAeJV0sAi';

export async function accessToken() {
  const cfg = JSON.parse(fs.readFileSync(CONFIG, 'utf8'));
  const refresh = cfg?.tokens?.refresh_token;
  if (!refresh) throw new Error('No firebase-tools refresh token found.');

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      client_id: CLIENT_ID,
      client_secret: CLIENT_SECRET,
      refresh_token: refresh,
      grant_type: 'refresh_token',
    }),
  });

  const body = await res.json();
  if (!res.ok) {
    throw new Error(`Token refresh failed (${res.status}): ${JSON.stringify(body)}`);
  }
  return body.access_token;
}
