// Phase 7B — stateless validation of firestore.rules via the Firebase Rules
// Test API (firebaserules.googleapis.com :test). Chosen over the local
// emulator because the Firestore emulator needs JDK 21 and this machine has 17.
//
// Stateless means there is no database: every exists()/get() the rules perform
// must be declared per test case as a function mock. Each test therefore
// states the exact world it assumes.
import fs from 'node:fs';
import { accessToken } from './token.js';

const PROJECT = 'academia-app-7b8ef';
const RULES = 'C:/Users/pc/StudioProjects/academia/firestore.rules';
const DB = '/databases/(default)/documents';
const TIME = '2026-08-08T00:00:00Z';

// ---------------------------------------------------------------- fixtures

const ADMIN = { role: 'admin', status: 'active' };
const STUDENT = { role: 'student', status: 'active' };
const DISABLED_STUDENT = { role: 'student', status: 'disabled' };

const SEM = 'semester_2026_1'; // underscores on purpose: IDs are never parsed
const COURSE = 'c1';
const SECTION = '1';
const OFFERING = `${COURSE}_${SEM}_${SECTION}`;
const ENROLLMENT = `student1_${OFFERING}`;

const OFFERING_DOC = {
  courseId: COURSE,
  semesterId: SEM,
  instructorName: 'م. حمزة السويركي',
  section: SECTION,
  status: 'active',
  source: 'manual',
  createdBy: 'admin1',
};

// The world every academic test assumes exists.
const WORLD = {
  [`users/admin1`]: ADMIN,
  [`users/student1`]: STUDENT,
  [`users/student2`]: STUDENT,
  [`users/disabled1`]: DISABLED_STUDENT,
  [`departments/dep1`]: { name: 'قسم', status: 'active' },
  [`majors/maj1`]: { name: 'تخصص', code: 'MIS', departmentId: 'dep1' },
  [`courses/${COURSE}`]: {
    courseCode: 'BMIS3344',
    title: 'مساق',
    departmentId: 'dep1',
    creditHours: 3,
    status: 'active',
    createdBy: 'admin1',
  },
  [`semesters/${SEM}`]: { status: 'current', semesterNumber: 1 },
  [`courseOfferings/${OFFERING}`]: OFFERING_DOC,
};

// Valid document bodies, cloned and mutated per test.
const VALID = {
  department: { name: 'قسم جديد', code: '', status: 'active', source: 'manual' },
  major: {
    name: 'تخصص جديد',
    code: 'MIS',
    departmentId: 'dep1',
    totalLevels: 8,
    status: 'active',
    source: 'manual',
  },
  course: {
    courseCode: 'BMIS1341',
    title: 'مقدمة في نظم المعلومات الإدارية',
    description: '',
    creditHours: 3,
    departmentId: 'dep1',
    status: 'active',
    source: 'manual',
    createdBy: 'admin1',
  },
  offering: { ...OFFERING_DOC },
  curriculumCourse: {
    majorId: 'maj1',
    entryType: 'course',
    courseId: COURSE,
    academicLevel: 6,
    requirementType: 'major_required',
    prerequisiteCourseIds: [],
    prerequisiteText: 'نظم إدارة قواعد البيانات',
    sequence: 3,
  },
  curriculumSlot: {
    majorId: 'maj1',
    entryType: 'slot',
    slotLabel: 'متطلب جامعة اختياري (1)',
    academicLevel: 2,
    requirementType: 'university_elective',
    creditHours: 2,
    prerequisiteCourseIds: [],
    sequence: 5,
  },
  enrollment: {
    userId: 'student1',
    offeringId: OFFERING,
    courseId: COURSE,
    semesterId: SEM,
    attemptNumber: 1,
    status: 'active',
    assignedBy: 'admin1',
  },
};

const clone = (o) => JSON.parse(JSON.stringify(o));
const withOut = (o, ...keys) => {
  const c = clone(o);
  for (const k of keys) delete c[k];
  return c;
};

// ------------------------------------------------------------------ mocks

function buildMocks({ world = WORLD, missing = [] } = {}) {
  const out = [];
  for (const [p, data] of Object.entries(world)) {
    out.push({
      function: 'exists',
      args: [{ exactValue: `${DB}/${p}` }],
      result: { value: true },
    });
    out.push({
      function: 'get',
      args: [{ exactValue: `${DB}/${p}` }],
      result: { value: { data } },
    });
  }
  for (const p of missing) {
    out.push({
      function: 'exists',
      args: [{ exactValue: `${DB}/${p}` }],
      result: { value: false },
    });
  }
  return out;
}

// ------------------------------------------------------------------ cases

const cases = [];

function t(name, { expect, uid, path, method, data, existing, world, missing, token }) {
  cases.push({
    name,
    testCase: {
      expectation: expect,
      request: {
        auth: uid
          ? { uid, token: { email_verified: true, email: `${uid}@test.com`, ...(token || {}) } }
          : null,
        path: `${DB}/${path}`,
        method,
        time: TIME,
        ...(data === undefined ? {} : { resource: { data } }),
      },
      ...(existing === undefined ? {} : { resource: { data: existing } }),
      functionMocks: buildMocks({ world, missing }),
    },
  });
}

// --- 1. unauthenticated academic reads denied --------------------------------
for (const [label, path] of [
  ['departments', 'departments/dep1'],
  ['majors', 'majors/maj1'],
  ['courses', `courses/${COURSE}`],
  ['curriculumCourses', 'curriculumCourses/maj1_c1'],
  ['semesters', `semesters/${SEM}`],
  ['courseOfferings', `courseOfferings/${OFFERING}`],
]) {
  t(`1. unauthenticated read ${label} denied`, {
    expect: 'DENY',
    uid: null,
    path,
    method: 'get',
  });
}
t('1b. unauthenticated enrollment read denied', {
  expect: 'DENY',
  uid: null,
  path: `enrollments/${ENROLLMENT}`,
  method: 'get',
  existing: VALID.enrollment,
});
t('1c. unauthenticated course write denied', {
  expect: 'DENY',
  uid: null,
  path: 'courses/newc',
  method: 'create',
  data: VALID.course,
});

// --- 2. active student reads academic structure ------------------------------
for (const [label, path] of [
  ['departments', 'departments/dep1'],
  ['majors', 'majors/maj1'],
  ['courses', `courses/${COURSE}`],
  ['curriculumCourses', 'curriculumCourses/maj1_c1'],
  ['semesters', `semesters/${SEM}`],
  ['courseOfferings', `courseOfferings/${OFFERING}`],
]) {
  t(`2. active student reads ${label} allowed`, {
    expect: 'ALLOW',
    uid: 'student1',
    path,
    method: 'get',
  });
}

// --- 3. student academic writes denied ---------------------------------------
t('3. student creates course denied', {
  expect: 'DENY',
  uid: 'student1',
  path: 'courses/newc',
  method: 'create',
  data: { ...VALID.course, createdBy: 'student1' },
});
t('3. student creates offering denied', {
  expect: 'DENY',
  uid: 'student1',
  path: `courseOfferings/${OFFERING}`,
  method: 'create',
  data: { ...VALID.offering, createdBy: 'student1' },
});
t('3. student creates curriculum entry denied', {
  expect: 'DENY',
  uid: 'student1',
  path: 'curriculumCourses/maj1_c1',
  method: 'create',
  data: VALID.curriculumCourse,
});
t('3. student creates department denied', {
  expect: 'DENY',
  uid: 'student1',
  path: 'departments/dep2',
  method: 'create',
  data: VALID.department,
});
t('3. student creates semester denied', {
  expect: 'DENY',
  uid: 'student1',
  path: 'semesters/semester_2027_1',
  method: 'create',
  data: {
    academicYear: '2027',
    semesterNumber: 1,
    semesterName: 'الفصل الأول 2027',
    status: 'upcoming',
  },
});

// --- 4. admin academic writes allowed ----------------------------------------
t('4. admin creates department allowed', {
  expect: 'ALLOW',
  uid: 'admin1',
  path: 'departments/dep2',
  method: 'create',
  data: VALID.department,
});
t('4. admin creates major allowed', {
  expect: 'ALLOW',
  uid: 'admin1',
  path: 'majors/maj2',
  method: 'create',
  data: VALID.major,
});
t('4. admin creates course allowed', {
  expect: 'ALLOW',
  uid: 'admin1',
  path: 'courses/newc',
  method: 'create',
  data: VALID.course,
});
t('4. admin creates offering allowed', {
  expect: 'ALLOW',
  uid: 'admin1',
  path: `courseOfferings/${OFFERING}`,
  method: 'create',
  data: VALID.offering,
});
t('4. admin creates curriculum course entry allowed', {
  expect: 'ALLOW',
  uid: 'admin1',
  path: `curriculumCourses/maj1_${COURSE}`,
  method: 'create',
  data: VALID.curriculumCourse,
});
t('4. admin creates curriculum slot entry allowed', {
  expect: 'ALLOW',
  uid: 'admin1',
  path: 'curriculumCourses/maj1_slot_2_5',
  method: 'create',
  data: VALID.curriculumSlot,
});
t('4. admin archives course (update) allowed', {
  expect: 'ALLOW',
  uid: 'admin1',
  path: `courses/${COURSE}`,
  method: 'update',
  data: { ...VALID.course, status: 'archived' },
  existing: VALID.course,
});

// --- 5. invalid offering references denied -----------------------------------
t('5. offering with missing course denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: `ghost_${SEM}_1`.replace(/^/, 'courseOfferings/'),
  method: 'create',
  data: { ...VALID.offering, courseId: 'ghost' },
  missing: ['courses/ghost'],
});
t('5. offering with missing semester denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: `courseOfferings/${COURSE}_semester_9999_9_1`,
  method: 'create',
  data: { ...VALID.offering, semesterId: 'semester_9999_9' },
  missing: ['semesters/semester_9999_9'],
});

// --- 6. mismatched offering deterministic ID denied --------------------------
t('6. offering ID not matching {courseId}_{semesterId}_{section} denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: 'courseOfferings/arbitrary-id',
  method: 'create',
  data: VALID.offering,
});
t('6b. offering ID with wrong section denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: `courseOfferings/${COURSE}_${SEM}_2`,
  method: 'create',
  data: VALID.offering, // section '1'
});
t('6c. offering semesterId change (breaks ID) denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: `courseOfferings/${OFFERING}`,
  method: 'update',
  data: { ...VALID.offering, semesterId: 'semester_2025_2' },
  existing: OFFERING_DOC,
});

// --- 7. invalid curriculum slot/course shape denied --------------------------
t('7. course entry carrying slotLabel denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: `curriculumCourses/maj1_${COURSE}`,
  method: 'create',
  data: { ...VALID.curriculumCourse, slotLabel: 'متطلب جامعة اختياري (1)' },
});
t('7. course entry without courseId denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: 'curriculumCourses/maj1_',
  method: 'create',
  data: withOut(VALID.curriculumCourse, 'courseId'),
});
t('7. course entry referencing missing course denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: 'curriculumCourses/maj1_ghost',
  method: 'create',
  data: { ...VALID.curriculumCourse, courseId: 'ghost' },
  missing: ['courses/ghost'],
});
t('7. slot entry carrying courseId denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: 'curriculumCourses/maj1_slot_2_5',
  method: 'create',
  data: { ...VALID.curriculumSlot, courseId: COURSE },
});
t('7. slot entry without slotLabel denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: 'curriculumCourses/maj1_slot_2_5',
  method: 'create',
  data: withOut(VALID.curriculumSlot, 'slotLabel'),
});
t('7. slot entry without creditHours denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: 'curriculumCourses/maj1_slot_2_5',
  method: 'create',
  data: withOut(VALID.curriculumSlot, 'creditHours'),
});
t('7. entry with unknown entryType denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: `curriculumCourses/maj1_${COURSE}`,
  method: 'create',
  data: { ...VALID.curriculumCourse, entryType: 'elective' },
});
t('7b. curriculum entry with mismatched ID denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: 'curriculumCourses/some-other-id',
  method: 'create',
  data: VALID.curriculumCourse,
});

// --- 8. academicLevel outside 1..8 denied ------------------------------------
t('8. academicLevel 0 denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: `curriculumCourses/maj1_${COURSE}`,
  method: 'create',
  data: { ...VALID.curriculumCourse, academicLevel: 0 },
});
t('8. academicLevel 9 denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: `curriculumCourses/maj1_${COURSE}`,
  method: 'create',
  data: { ...VALID.curriculumCourse, academicLevel: 9 },
});
t('8b. academicLevel 8 allowed', {
  expect: 'ALLOW',
  uid: 'admin1',
  path: `curriculumCourses/maj1_${COURSE}`,
  method: 'create',
  data: { ...VALID.curriculumCourse, academicLevel: 8 },
});

// --- 9. invalid requirementType denied ---------------------------------------
t('9. unknown requirementType denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: `curriculumCourses/maj1_${COURSE}`,
  method: 'create',
  data: { ...VALID.curriculumCourse, requirementType: 'elective' },
});
t('9b. college_required allowed (CSW-001 classification)', {
  expect: 'ALLOW',
  uid: 'admin1',
  path: `curriculumCourses/maj1_${COURSE}`,
  method: 'create',
  data: { ...VALID.curriculumCourse, requirementType: 'college_required' },
});

// --- 10/11. enrollment reads --------------------------------------------------
t('10. student reads own enrollment allowed', {
  expect: 'ALLOW',
  uid: 'student1',
  path: `enrollments/${ENROLLMENT}`,
  method: 'get',
  existing: VALID.enrollment,
});
t("11. student reads another student's enrollment denied", {
  expect: 'DENY',
  uid: 'student2',
  path: `enrollments/${ENROLLMENT}`,
  method: 'get',
  existing: VALID.enrollment,
});
t('11b. admin reads any enrollment allowed', {
  expect: 'ALLOW',
  uid: 'admin1',
  path: `enrollments/${ENROLLMENT}`,
  method: 'get',
  existing: VALID.enrollment,
});

// --- 12. student writes own enrollment denied --------------------------------
t('12. student creates own enrollment denied', {
  expect: 'DENY',
  uid: 'student1',
  path: `enrollments/${ENROLLMENT}`,
  method: 'create',
  data: { ...VALID.enrollment, assignedBy: 'student1' },
});
t('12. student updates own enrollment status denied', {
  expect: 'DENY',
  uid: 'student1',
  path: `enrollments/${ENROLLMENT}`,
  method: 'update',
  data: { ...VALID.enrollment, status: 'completed' },
  existing: VALID.enrollment,
});
t('12b. student deletes own enrollment denied', {
  expect: 'DENY',
  uid: 'student1',
  path: `enrollments/${ENROLLMENT}`,
  method: 'delete',
  existing: VALID.enrollment,
});

// --- 13. mismatched courseId / semesterId denied ------------------------------
t('13. enrollment courseId not matching offering denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: `enrollments/${ENROLLMENT}`,
  method: 'create',
  data: { ...VALID.enrollment, courseId: 'other-course' },
});
t('13. enrollment semesterId not matching offering denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: `enrollments/${ENROLLMENT}`,
  method: 'create',
  data: { ...VALID.enrollment, semesterId: 'semester_2024_2' },
});
t('13b. enrollment referencing missing offering denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: 'enrollments/student1_ghost',
  method: 'create',
  data: { ...VALID.enrollment, offeringId: 'ghost' },
  missing: ['courseOfferings/ghost'],
});
t('13c. enrollment ID not matching {userId}_{offeringId} denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: 'enrollments/arbitrary-id',
  method: 'create',
  data: VALID.enrollment,
});
t('13d. enrollment for a non-student target denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: `enrollments/admin1_${OFFERING}`,
  method: 'create',
  data: { ...VALID.enrollment, userId: 'admin1' },
});
t('13e. valid admin enrollment create allowed', {
  expect: 'ALLOW',
  uid: 'admin1',
  path: `enrollments/${ENROLLMENT}`,
  method: 'create',
  data: VALID.enrollment,
});
t('13f. retake attempt 2 create allowed', {
  expect: 'ALLOW',
  uid: 'admin1',
  path: `enrollments/${ENROLLMENT}`,
  method: 'create',
  data: { ...VALID.enrollment, attemptNumber: 2 },
});

// --- 14. invalid attemptNumber denied ----------------------------------------
t('14. attemptNumber 0 denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: `enrollments/${ENROLLMENT}`,
  method: 'create',
  data: { ...VALID.enrollment, attemptNumber: 0 },
});
t('14. attemptNumber as string denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: `enrollments/${ENROLLMENT}`,
  method: 'create',
  data: { ...VALID.enrollment, attemptNumber: '1' },
});
t('14b. missing attemptNumber denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: `enrollments/${ENROLLMENT}`,
  method: 'create',
  data: withOut(VALID.enrollment, 'attemptNumber'),
});
t('14c. enrollment created with status completed denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: `enrollments/${ENROLLMENT}`,
  method: 'create',
  data: { ...VALID.enrollment, status: 'completed' },
});
t('14d. enrollment created carrying a grade denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: `enrollments/${ENROLLMENT}`,
  method: 'create',
  data: { ...VALID.enrollment, grade: 'A' },
});
t('14e. enrollment assignedBy other than caller denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: `enrollments/${ENROLLMENT}`,
  method: 'create',
  data: { ...VALID.enrollment, assignedBy: 'someone-else' },
});

// --- 15. relationship-field mutation denied ----------------------------------
for (const [field, value] of [
  ['userId', 'student2'],
  ['offeringId', 'c1_semester_2025_2_1'],
  ['courseId', 'other-course'],
  ['semesterId', 'semester_2024_2'],
  ['attemptNumber', 2],
]) {
  t(`15. admin mutating enrollment.${field} denied`, {
    expect: 'DENY',
    uid: 'admin1',
    path: `enrollments/${ENROLLMENT}`,
    method: 'update',
    data: { ...VALID.enrollment, [field]: value },
    existing: VALID.enrollment,
  });
}

// --- 16/17/18. outcome writes -------------------------------------------------
t('16. admin sets completionStatus passed allowed', {
  expect: 'ALLOW',
  uid: 'admin1',
  path: `enrollments/${ENROLLMENT}`,
  method: 'update',
  data: {
    ...VALID.enrollment,
    status: 'completed',
    completionStatus: 'passed',
    grade: 'ممتاز',
  },
  existing: VALID.enrollment,
});
t('16b. admin sets completionStatus failed allowed', {
  expect: 'ALLOW',
  uid: 'admin1',
  path: `enrollments/${ENROLLMENT}`,
  method: 'update',
  data: { ...VALID.enrollment, status: 'completed', completionStatus: 'failed' },
  existing: VALID.enrollment,
});
t('16c. admin soft-removes enrollment allowed', {
  expect: 'ALLOW',
  uid: 'admin1',
  path: `enrollments/${ENROLLMENT}`,
  method: 'update',
  data: { ...VALID.enrollment, status: 'removed' },
  existing: VALID.enrollment,
});
t('17. invalid completionStatus denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: `enrollments/${ENROLLMENT}`,
  method: 'update',
  data: { ...VALID.enrollment, status: 'completed', completionStatus: 'withdrawn' },
  existing: VALID.enrollment,
});
t('17b. invalid enrollment status denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: `enrollments/${ENROLLMENT}`,
  method: 'update',
  data: { ...VALID.enrollment, status: 'archived' },
  existing: VALID.enrollment,
});
t('18. student writing grade denied', {
  expect: 'DENY',
  uid: 'student1',
  path: `enrollments/${ENROLLMENT}`,
  method: 'update',
  data: { ...VALID.enrollment, grade: 'A' },
  existing: VALID.enrollment,
});
t('18b. student writing completionStatus denied', {
  expect: 'DENY',
  uid: 'student1',
  path: `enrollments/${ENROLLMENT}`,
  method: 'update',
  data: { ...VALID.enrollment, completionStatus: 'passed' },
  existing: VALID.enrollment,
});

// --- 19. courses must not carry offering fields ------------------------------
t('19. course create carrying semesterId denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: 'courses/newc',
  method: 'create',
  data: { ...VALID.course, semesterId: SEM },
});
t('19b. course create carrying instructorName denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: 'courses/newc',
  method: 'create',
  data: { ...VALID.course, instructorName: 'م. أنس' },
});
t('19c. course create without departmentId denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: 'courses/newc',
  method: 'create',
  data: withOut(VALID.course, 'departmentId'),
});
t('19d. course create with missing department denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: 'courses/newc',
  method: 'create',
  data: { ...VALID.course, departmentId: 'ghost' },
  missing: ['departments/ghost'],
});
t('19e. course createdBy mutation denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: `courses/${COURSE}`,
  method: 'update',
  data: { ...VALID.course, createdBy: 'admin1' },
  existing: { ...VALID.course, createdBy: 'KRJvdSTae6VZ3j3XbzqeAmmNTq53' },
});

// --- 20. deletes -------------------------------------------------------------
t('20. course hard delete denied (admin)', {
  expect: 'DENY',
  uid: 'admin1',
  path: `courses/${COURSE}`,
  method: 'delete',
  existing: VALID.course,
});
t('20b. offering hard delete denied (admin)', {
  expect: 'DENY',
  uid: 'admin1',
  path: `courseOfferings/${OFFERING}`,
  method: 'delete',
  existing: OFFERING_DOC,
});
t('20c. department hard delete denied (admin)', {
  expect: 'DENY',
  uid: 'admin1',
  path: 'departments/dep1',
  method: 'delete',
  existing: VALID.department,
});
t('20d. major hard delete denied (admin)', {
  expect: 'DENY',
  uid: 'admin1',
  path: 'majors/maj1',
  method: 'delete',
  existing: VALID.major,
});
t('20e. curriculum entry delete allowed (admin)', {
  expect: 'ALLOW',
  uid: 'admin1',
  path: `curriculumCourses/maj1_${COURSE}`,
  method: 'delete',
  existing: VALID.curriculumCourse,
});

// --- 21. no fail-open on role / status ---------------------------------------
t('21. disabled student reading catalog denied', {
  expect: 'DENY',
  uid: 'disabled1',
  path: `courses/${COURSE}`,
  method: 'get',
});
t('21b. user document missing role denied', {
  expect: 'DENY',
  uid: 'norole',
  path: `courses/${COURSE}`,
  method: 'get',
  world: { ...WORLD, 'users/norole': { status: 'active' } },
});
t('21c. user document missing status denied', {
  expect: 'DENY',
  uid: 'nostatus',
  path: `courses/${COURSE}`,
  method: 'get',
  world: { ...WORLD, 'users/nostatus': { role: 'student' } },
});
t('21d. signed-in user with no user document denied', {
  expect: 'DENY',
  uid: 'ghostuser',
  path: `courses/${COURSE}`,
  method: 'get',
  missing: ['users/ghostuser'],
});
t('21e. disabled admin academic write denied', {
  expect: 'DENY',
  uid: 'disabledadmin',
  path: 'departments/dep2',
  method: 'create',
  data: VALID.department,
  world: {
    ...WORLD,
    'users/disabledadmin': { role: 'admin', status: 'disabled' },
  },
});

// --- 22. users collection (preserved behaviour) ------------------------------
const STUDENT_DOC = {
  fullName: 'حلا',
  email: 'student1@test.com',
  role: 'student',
  status: 'active',
  emailVerified: true,
  onboardingCompleted: true,
  academicLevel: 4,
};
t('22. student edits own profile allowed', {
  expect: 'ALLOW',
  uid: 'student1',
  path: 'users/student1',
  method: 'update',
  data: { ...STUDENT_DOC, fullName: 'حلا جندية' },
  existing: STUDENT_DOC,
});
t('22b. student escalating own role denied', {
  expect: 'DENY',
  uid: 'student1',
  path: 'users/student1',
  method: 'update',
  data: { ...STUDENT_DOC, role: 'admin' },
  existing: STUDENT_DOC,
});
t('22c. student setting own majorId denied', {
  expect: 'DENY',
  uid: 'student1',
  path: 'users/student1',
  method: 'update',
  data: { ...STUDENT_DOC, majorId: 'maj1' },
  existing: STUDENT_DOC,
});
t('22d. admin assigning majorId allowed', {
  expect: 'ALLOW',
  uid: 'admin1',
  path: 'users/student1',
  method: 'update',
  data: { ...STUDENT_DOC, majorId: 'maj1' },
  existing: STUDENT_DOC,
});
t('22e. student reading another student profile denied', {
  expect: 'DENY',
  uid: 'student2',
  path: 'users/student1',
  method: 'get',
  existing: STUDENT_DOC,
});
t('22f. user delete denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: 'users/student1',
  method: 'delete',
  existing: STUDENT_DOC,
});

// --- 23. semesters + supportRequests (preserved behaviour) --------------------
t('23. admin creates semester allowed', {
  expect: 'ALLOW',
  uid: 'admin1',
  path: 'semesters/semester_2027_1',
  method: 'create',
  data: {
    academicYear: '2027',
    semesterNumber: 1,
    semesterName: 'الفصل الأول 2027',
    status: 'upcoming',
  },
});
t('23b. active user creates supportRequest allowed', {
  expect: 'ALLOW',
  uid: 'student1',
  path: 'supportRequests/req1',
  method: 'create',
  data: {
    uid: 'student1',
    subject: 'سؤال',
    message: 'نص',
    status: 'open',
  },
});
t('23c. student reads supportRequests denied', {
  expect: 'DENY',
  uid: 'student1',
  path: 'supportRequests/req1',
  method: 'get',
  existing: { uid: 'student1', status: 'open' },
});
t('23d. unmatched collection denied for admin', {
  expect: 'DENY',
  uid: 'admin1',
  path: 'randomCollection/doc1',
  method: 'get',
});

// ------------------------------------------------------------------- runner

const source = {
  files: [{ name: 'firestore.rules', content: fs.readFileSync(RULES, 'utf8') }],
};

const token = await accessToken();
const res = await fetch(
  `https://firebaserules.googleapis.com/v1/projects/${PROJECT}:test`,
  {
    method: 'POST',
    headers: {
      authorization: `Bearer ${token}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      source,
      testSuite: { testCases: cases.map((c) => c.testCase) },
    }),
  },
);

const body = await res.json();

if (!res.ok) {
  console.error('HTTP', res.status);
  console.error(JSON.stringify(body, null, 2).slice(0, 4000));
  process.exit(1);
}

if (body.issues?.length) {
  console.error('RULES COMPILATION ISSUES:');
  console.error(JSON.stringify(body.issues, null, 2));
  process.exit(1);
}

const results = body.testResults ?? [];
let pass = 0;
const failures = [];

results.forEach((r, i) => {
  const name = cases[i]?.name ?? `case ${i}`;
  if (r.state === 'SUCCESS') {
    pass++;
  } else {
    failures.push({
      name,
      expected: cases[i].testCase.expectation,
      debugMessages: r.debugMessages,
      errorPosition: r.errorPosition,
    });
  }
});

console.log(`\n${pass}/${results.length} rules tests passed\n`);

if (failures.length) {
  for (const f of failures) {
    console.log(`FAIL  ${f.name}  (expected ${f.expected})`);
    if (f.debugMessages) console.log(`      ${f.debugMessages.join('\n      ')}`);
    if (f.errorPosition) console.log(`      at line ${f.errorPosition.line}`);
  }
  process.exit(1);
}
