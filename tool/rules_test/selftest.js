// Harness sanity check: a suite that passes 100/100 is only meaningful if the
// harness can fail. Every case below is deliberately given the WRONG
// expectation, so a healthy harness must report 0/N passed.
import fs from 'node:fs';
import { accessToken } from './token.js';

const PROJECT = 'academia-app-7b8ef';
const RULES = 'C:/Users/pc/StudioProjects/academia/firestore.rules';
const DB = '/databases/(default)/documents';
const TIME = '2026-08-08T00:00:00Z';

const mocks = (world, missing = []) => [
  ...Object.entries(world).flatMap(([p, data]) => [
    { function: 'exists', args: [{ exactValue: `${DB}/${p}` }], result: { value: true } },
    { function: 'get', args: [{ exactValue: `${DB}/${p}` }], result: { value: { data } } },
  ]),
  ...missing.map((p) => ({
    function: 'exists',
    args: [{ exactValue: `${DB}/${p}` }],
    result: { value: false },
  })),
];

const WORLD = {
  'users/admin1': { role: 'admin', status: 'active' },
  'users/student1': { role: 'student', status: 'active' },
  'departments/dep1': { name: 'قسم', status: 'active' },
};

const inverted = [
  {
    name: 'unauthenticated read — WRONGLY expected ALLOW',
    expectation: 'ALLOW',
    request: { auth: null, path: `${DB}/courses/c1`, method: 'get', time: TIME },
    functionMocks: mocks(WORLD),
  },
  {
    name: 'active student read — WRONGLY expected DENY',
    expectation: 'DENY',
    request: {
      auth: { uid: 'student1', token: { email_verified: true } },
      path: `${DB}/courses/c1`,
      method: 'get',
      time: TIME,
    },
    functionMocks: mocks(WORLD),
  },
  {
    name: 'admin department create — WRONGLY expected DENY',
    expectation: 'DENY',
    request: {
      auth: { uid: 'admin1', token: { email_verified: true } },
      path: `${DB}/departments/dep2`,
      method: 'create',
      time: TIME,
      resource: { data: { name: 'قسم', status: 'active', source: 'manual' } },
    },
    functionMocks: mocks(WORLD),
  },
  {
    name: 'student course create — WRONGLY expected ALLOW',
    expectation: 'ALLOW',
    request: {
      auth: { uid: 'student1', token: { email_verified: true } },
      path: `${DB}/courses/newc`,
      method: 'create',
      time: TIME,
      resource: {
        data: {
          courseCode: 'X1',
          title: 'ت',
          creditHours: 3,
          departmentId: 'dep1',
          status: 'active',
          createdBy: 'student1',
        },
      },
    },
    functionMocks: mocks(WORLD),
  },
];

const token = await accessToken();
const res = await fetch(
  `https://firebaserules.googleapis.com/v1/projects/${PROJECT}:test`,
  {
    method: 'POST',
    headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json' },
    body: JSON.stringify({
      source: {
        files: [{ name: 'firestore.rules', content: fs.readFileSync(RULES, 'utf8') }],
      },
      testSuite: {
        testCases: inverted.map(({ name, ...tc }) => tc),
      },
    }),
  },
);

const body = await res.json();
const results = body.testResults ?? [];
const passed = results.filter((r) => r.state === 'SUCCESS').length;

results.forEach((r, i) => {
  console.log(
    `${r.state === 'SUCCESS' ? 'UNEXPECTED PASS' : 'correctly failed'}  ${inverted[i].name}`,
  );
});

console.log(`\n${passed}/${results.length} inverted cases passed (expected 0/${results.length})`);
process.exit(passed === 0 ? 0 : 1);
