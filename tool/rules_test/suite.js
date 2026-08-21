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

// Phase 8A: the third role, plus the shapes that must grant nothing.
const TEACHER = { role: 'teacher', status: 'active' };
const DISABLED_TEACHER = { role: 'teacher', status: 'disabled' };
const UNKNOWN_ROLE = { role: 'professor', status: 'active' };
const EMPTY_ROLE = { role: '', status: 'active' };
const NO_ROLE = { status: 'active' };

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

/*
 * Phase 8.1 fixtures: the same course, one section owned by teacher1 and
 * one (OFFERING above) left unassigned. Keeping both is the point — the
 * unassigned one is what every pre-8.1 offering looks like, and it must
 * grant nothing to anyone.
 */
const OWNED_SECTION = '2';
const OWNED_OFFERING = `${COURSE}_${SEM}_${OWNED_SECTION}`;
const OWNED_OFFERING_DOC = {
  ...OFFERING_DOC,
  section: OWNED_SECTION,
  teacherId: 'teacher1',
};

const OTHER_SECTION = '3';
const OTHER_OFFERING = `${COURSE}_${SEM}_${OTHER_SECTION}`;
const OTHER_OFFERING_DOC = {
  ...OFFERING_DOC,
  section: OTHER_SECTION,
  teacherId: 'teacher2',
};

const OWNED_ENROLLMENT_DOC = {
  userId: 'student1',
  offeringId: OWNED_OFFERING,
  courseId: COURSE,
  semesterId: SEM,
  attemptNumber: 1,
  status: 'active',
  assignedBy: 'admin1',
};
const OTHER_ENROLLMENT_DOC = {
  ...OWNED_ENROLLMENT_DOC,
  offeringId: OTHER_OFFERING,
};
const UNASSIGNED_ENROLLMENT_DOC = {
  ...OWNED_ENROLLMENT_DOC,
  offeringId: OFFERING,
};

// The world every academic test assumes exists.
const WORLD = {
  [`users/admin1`]: ADMIN,
  [`users/student1`]: STUDENT,
  [`users/student2`]: STUDENT,
  [`users/disabled1`]: DISABLED_STUDENT,
  [`users/teacher1`]: TEACHER,
  [`users/teacher2`]: TEACHER,
  [`users/teacherOff`]: DISABLED_TEACHER,
  [`users/unknown1`]: UNKNOWN_ROLE,
  [`users/emptyrole1`]: EMPTY_ROLE,
  [`users/norole1`]: NO_ROLE,
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
  [`courseOfferings/${OWNED_OFFERING}`]: OWNED_OFFERING_DOC,
  [`courseOfferings/${OTHER_OFFERING}`]: OTHER_OFFERING_DOC,
  [`enrollments/student1_${OFFERING}`]: { userId: 'student1', offeringId: OFFERING, courseId: COURSE, semesterId: SEM, attemptNumber: 1, status: 'active', assignedBy: 'admin1' },
  [`enrollments/student2_${OFFERING}`]: { userId: 'student2', offeringId: OFFERING, courseId: COURSE, semesterId: SEM, attemptNumber: 1, status: 'active', assignedBy: 'admin1' },
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
  task: {
    userId: 'student1',
    title: 'تسليم واجب',
    description: 'تفاصيل الواجب',
    priority: 'medium',
    status: 'pending',
    type: 'study',
    createdAt: TIME,
    updatedAt: TIME,
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

// --- 23e-23n. supportRequests admin inbox (Phase 7H5) -------------------------
//
// The inbox may move a request through open <-> resolved and nothing else.
// What the student wrote is the record; only its handling state is the
// admin's to change.
//
// These pin the hardened update rule that is live in production — without
// them a branch can silently ship the older, looser version, which is
// exactly what happened once already.
const SUPPORT_OPEN = {
  uid: 'student1',
  fullName: 'حلا جندية',
  email: 's@test.com',
  subject: 'مشكلة في تسجيل المساقات',
  message: 'لا أستطيع رؤية مساقات الفصل الحالي.',
  status: 'open',
  source: 'mobile_app',
};

t('23e. admin reads a supportRequest allowed', {
  expect: 'ALLOW',
  uid: 'admin1',
  path: 'supportRequests/req1',
  method: 'get',
  existing: SUPPORT_OPEN,
});
t('23f. admin marks a request resolved allowed', {
  expect: 'ALLOW',
  uid: 'admin1',
  path: 'supportRequests/req1',
  method: 'update',
  data: { ...SUPPORT_OPEN, status: 'resolved' },
  existing: SUPPORT_OPEN,
});
t('23g. admin reopens a resolved request allowed', {
  expect: 'ALLOW',
  uid: 'admin1',
  path: 'supportRequests/req1',
  method: 'update',
  data: { ...SUPPORT_OPEN, status: 'open' },
  existing: { ...SUPPORT_OPEN, status: 'resolved' },
});
t('23h. student updating a request status denied', {
  expect: 'DENY',
  uid: 'student1',
  path: 'supportRequests/req1',
  method: 'update',
  data: { ...SUPPORT_OPEN, status: 'resolved' },
  existing: SUPPORT_OPEN,
});
t('23i. admin rewriting the student message denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: 'supportRequests/req1',
  method: 'update',
  data: { ...SUPPORT_OPEN, status: 'resolved', message: 'نص مختلف' },
  existing: SUPPORT_OPEN,
});
t('23j. admin rewriting the subject denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: 'supportRequests/req1',
  method: 'update',
  data: { ...SUPPORT_OPEN, subject: 'موضوع آخر' },
  existing: SUPPORT_OPEN,
});
t('23k. admin reassigning the request owner denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: 'supportRequests/req1',
  method: 'update',
  data: { ...SUPPORT_OPEN, status: 'resolved', uid: 'student2' },
  existing: SUPPORT_OPEN,
});
t('23l. an unknown status value denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: 'supportRequests/req1',
  method: 'update',
  data: { ...SUPPORT_OPEN, status: 'escalated' },
  existing: SUPPORT_OPEN,
});
t('23m. supportRequest hard delete denied for admin', {
  expect: 'DENY',
  uid: 'admin1',
  path: 'supportRequests/req1',
  method: 'delete',
  existing: SUPPORT_OPEN,
});
// Kept from the develop side of the merge: the incoming branch covered
// student but not teacher. A teacher is an active user, so without this the
// isActiveAdmin() gate is only half proven.
t('23n. teacher updating a support request denied', {
  expect: 'DENY',
  uid: 'teacher1',
  path: 'supportRequests/req1',
  method: 'update',
  data: { ...SUPPORT_OPEN, status: 'resolved' },
  existing: SUPPORT_OPEN,
});

// --- 24. student tasks (Phase 7T1A) --------------------
t('24a. active student reads own task allowed', {
  expect: 'ALLOW',
  uid: 'student1',
  path: 'tasks/task1',
  method: 'get',
  existing: VALID.task,
});

t('24b. student reads another student task denied', {
  expect: 'DENY',
  uid: 'student2',
  path: 'tasks/task1',
  method: 'get',
  existing: VALID.task,
});

t('24c. admin reads student task denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: 'tasks/task1',
  method: 'get',
  existing: VALID.task,
});

t('24d. disabled student reads own task denied', {
  expect: 'DENY',
  uid: 'disabled1',
  path: 'tasks/task1',
  method: 'get',
  existing: { ...VALID.task, userId: 'disabled1' },
});

t('24e. active student creates valid task (no course) allowed', {
  expect: 'ALLOW',
  uid: 'student1',
  path: 'tasks/task1',
  method: 'create',
  data: VALID.task,
});

t('24f. student creating task for other student denied', {
  expect: 'DENY',
  uid: 'student1',
  path: 'tasks/task1',
  method: 'create',
  data: { ...VALID.task, userId: 'student2' },
});

t('24g. student creates task with valid course linkage allowed', {
  expect: 'ALLOW',
  uid: 'student1',
  path: 'tasks/task1',
  method: 'create',
  data: {
    ...VALID.task,
    enrollmentId: `student1_${OFFERING}`,
    offeringId: OFFERING,
    courseId: COURSE,
  },
});

t('24h. student creates task with another student enrollment denied', {
  expect: 'DENY',
  uid: 'student1',
  path: 'tasks/task1',
  method: 'create',
  data: {
    ...VALID.task,
    enrollmentId: `student2_${OFFERING}`,
    offeringId: OFFERING,
    courseId: COURSE,
  },
});

t('24i. student creates task with incomplete course linkage denied', {
  expect: 'DENY',
  uid: 'student1',
  path: 'tasks/task1',
  method: 'create',
  data: {
    ...VALID.task,
    enrollmentId: `student1_${OFFERING}`,
  },
});

t('24j. student creates task with invalid priority denied', {
  expect: 'DENY',
  uid: 'student1',
  path: 'tasks/task1',
  method: 'create',
  data: { ...VALID.task, priority: 'super-urgent' },
});

t('24k. student creates task with invalid status denied', {
  expect: 'DENY',
  uid: 'student1',
  path: 'tasks/task1',
  method: 'create',
  data: { ...VALID.task, status: 'started' },
});

t('24l. student creates task with invalid type denied', {
  expect: 'DENY',
  uid: 'student1',
  path: 'tasks/task1',
  method: 'create',
  data: { ...VALID.task, type: 'leisure' },
});

t('24m. student updates own task (valid) allowed', {
  expect: 'ALLOW',
  uid: 'student1',
  path: 'tasks/task1',
  method: 'update',
  data: { ...VALID.task, title: 'عنوان جديد' },
  existing: VALID.task,
});

t('24n. student updates own task mutating userId denied', {
  expect: 'DENY',
  uid: 'student1',
  path: 'tasks/task1',
  method: 'update',
  data: { ...VALID.task, userId: 'student2' },
  existing: VALID.task,
});

t('24o. student deletes own task allowed', {
  expect: 'ALLOW',
  uid: 'student1',
  path: 'tasks/task1',
  method: 'delete',
  existing: VALID.task,
});

t('24p. student deletes another student task denied', {
  expect: 'DENY',
  uid: 'student2',
  path: 'tasks/task1',
  method: 'delete',
  existing: VALID.task,
});

t('24q. admin deletes student task denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: 'tasks/task1',
  method: 'delete',
  existing: VALID.task,
});

// --- 25. course files (Phase 7F1A) -------------------------------------------
//
// Files belong to an OFFERING. Read access follows enrollment in that
// offering; writes are admin-only.

const FILE_DOC = {
  offeringId: OFFERING,
  courseId: COURSE,
  semesterId: SEM,
  title: 'المحاضرة الأولى',
  description: 'مقدمة',
  category: 'lecture',
  fileName: 'lecture1.pdf',
  fileExtension: 'pdf',
  mimeType: 'application/pdf',
  fileSize: 2048,
  cloudinaryUrl: 'https://res.cloudinary.com/xmrgiypo/image/upload/v1/a.pdf',
  cloudinaryPublicId: 'academia/course_files/off/a',
  cloudinaryResourceType: 'image',
  uploadedBy: 'admin1',
  status: 'active',
};

// Enrollment documents keyed the deterministic way the rules look them up.
const ENROLL_ACTIVE = { ...VALID.enrollment, status: 'active' };
const ENROLL_COMPLETED = { ...VALID.enrollment, status: 'completed' };
const ENROLL_REMOVED = { ...VALID.enrollment, status: 'removed' };

t('25. admin creates course file allowed', {
  expect: 'ALLOW',
  uid: 'admin1',
  path: 'courseFiles/file1',
  method: 'create',
  data: FILE_DOC,
});

t('25a. student creating a course file denied', {
  expect: 'DENY',
  uid: 'student1',
  path: 'courseFiles/file1',
  method: 'create',
  data: { ...FILE_DOC, uploadedBy: 'student1' },
});

t('25b. file whose courseId disagrees with the offering denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: 'courseFiles/file1',
  method: 'create',
  data: { ...FILE_DOC, courseId: 'other-course' },
});

t('25c. file whose semesterId disagrees with the offering denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: 'courseFiles/file1',
  method: 'create',
  data: { ...FILE_DOC, semesterId: 'semester_2024_2' },
});

t('25d. file referencing a missing offering denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: 'courseFiles/file1',
  method: 'create',
  data: { ...FILE_DOC, offeringId: 'ghost' },
  missing: ['courseOfferings/ghost'],
});

t('25e. uploadedBy other than the caller denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: 'courseFiles/file1',
  method: 'create',
  data: { ...FILE_DOC, uploadedBy: 'someone-else' },
});

t('25f. unknown category denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: 'courseFiles/file1',
  method: 'create',
  data: { ...FILE_DOC, category: 'exam' },
});

t('25g. file above the 10 MB limit denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: 'courseFiles/file1',
  method: 'create',
  data: { ...FILE_DOC, fileSize: 10485761 },
});

t('25h. file with no Cloudinary reference denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: 'courseFiles/file1',
  method: 'create',
  data: { ...FILE_DOC, cloudinaryUrl: '', cloudinaryPublicId: '' },
});

// ---- reads follow enrollment ----
t('25i. actively enrolled student reads the file', {
  expect: 'ALLOW',
  uid: 'student1',
  path: 'courseFiles/file1',
  method: 'get',
  existing: FILE_DOC,
  world: { ...WORLD, [`enrollments/${ENROLLMENT}`]: ENROLL_ACTIVE },
});

t('25j. student with a COMPLETED enrollment still reads historical files', {
  expect: 'ALLOW',
  uid: 'student1',
  path: 'courseFiles/file1',
  method: 'get',
  existing: FILE_DOC,
  world: { ...WORLD, [`enrollments/${ENROLLMENT}`]: ENROLL_COMPLETED },
});

t('25k. student with a REMOVED enrollment denied', {
  expect: 'DENY',
  uid: 'student1',
  path: 'courseFiles/file1',
  method: 'get',
  existing: FILE_DOC,
  world: { ...WORLD, [`enrollments/${ENROLLMENT}`]: ENROLL_REMOVED },
});

// student1/student2 are already enrolled in OFFERING in WORLD, so a genuine
// "not enrolled" case needs an active student with no enrollment document.
t('25l. student not enrolled in the offering denied', {
  expect: 'DENY',
  uid: 'student3',
  path: 'courseFiles/file1',
  method: 'get',
  existing: FILE_DOC,
  world: { ...WORLD, 'users/student3': STUDENT },
  missing: [`enrollments/student3_${OFFERING}`],
});

t('25m. unauthenticated file read denied', {
  expect: 'DENY',
  uid: null,
  path: 'courseFiles/file1',
  method: 'get',
  existing: FILE_DOC,
});

t('25n. admin reads any course file', {
  expect: 'ALLOW',
  uid: 'admin1',
  path: 'courseFiles/file1',
  method: 'get',
  existing: FILE_DOC,
});

// ---- updates ----
t('25o. admin edits title/description/category allowed', {
  expect: 'ALLOW',
  uid: 'admin1',
  path: 'courseFiles/file1',
  method: 'update',
  data: { ...FILE_DOC, title: 'عنوان محدَّث', category: 'summary' },
  existing: FILE_DOC,
});

t('25p. admin archives the file allowed', {
  expect: 'ALLOW',
  uid: 'admin1',
  path: 'courseFiles/file1',
  method: 'update',
  data: { ...FILE_DOC, status: 'archived' },
  existing: FILE_DOC,
});

for (const [field, value] of [
  ['offeringId', 'other-offering'],
  ['courseId', 'other-course'],
  ['semesterId', 'semester_2024_2'],
  ['cloudinaryUrl', 'https://evil.example/x.pdf'],
  ['cloudinaryPublicId', 'other/public/id'],
  ['cloudinaryResourceType', 'raw'],
  ['uploadedBy', 'student1'],
]) {
  t(`25q. mutating courseFile.${field} denied`, {
    expect: 'DENY',
    uid: 'admin1',
    path: 'courseFiles/file1',
    method: 'update',
    data: { ...FILE_DOC, [field]: value },
    existing: FILE_DOC,
  });
}

t('25r. enrolled student updating a course file denied', {
  expect: 'DENY',
  uid: 'student1',
  path: 'courseFiles/file1',
  method: 'update',
  data: { ...FILE_DOC, title: 'عبث' },
  existing: FILE_DOC,
  world: { ...WORLD, [`enrollments/${ENROLLMENT}`]: ENROLL_ACTIVE },
});

t('25s. student deleting a course file denied', {
  expect: 'DENY',
  uid: 'student1',
  path: 'courseFiles/file1',
  method: 'delete',
  existing: FILE_DOC,
  world: { ...WORLD, [`enrollments/${ENROLLMENT}`]: ENROLL_ACTIVE },
});

// Archive-only: the unsigned preset means the client cannot delete the
// Cloudinary binary, so deleting metadata would orphan the file.
t('25t. admin hard-deleting a course file denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: 'courseFiles/file1',
  method: 'delete',
  existing: FILE_DOC,
});

// --- 26. Phase 8A: teacher role foundation ------------------------------
//
// A teacher is a recognised account that can READ the shared academic
// catalogue and nothing more. Every write path stays admin-only until the
// later teacher phases add offering ownership.

t('26a. active teacher is a valid account and may read courses', {
  expect: 'ALLOW',
  uid: 'teacher1',
  path: `courses/${COURSE}`,
  method: 'get',
  existing: WORLD[`courses/${COURSE}`],
});
t('26b. active teacher may read semesters', {
  expect: 'ALLOW',
  uid: 'teacher1',
  path: `semesters/${SEM}`,
  method: 'get',
  existing: WORLD[`semesters/${SEM}`],
});
t('26c. active teacher may read offerings', {
  expect: 'ALLOW',
  uid: 'teacher1',
  path: `courseOfferings/${OFFERING}`,
  method: 'get',
  existing: OFFERING_DOC,
});
t('26d. DISABLED teacher is not a valid account', {
  expect: 'DENY',
  uid: 'teacherOff',
  path: `courses/${COURSE}`,
  method: 'get',
  existing: WORLD[`courses/${COURSE}`],
});

// ---- teacher holds no write capability anywhere in Phase 8A ----
t('26e. teacher creating a course denied', {
  expect: 'DENY',
  uid: 'teacher1',
  path: 'courses/newCourse',
  method: 'create',
  data: VALID.course,
});
t('26f. teacher updating a course denied', {
  expect: 'DENY',
  uid: 'teacher1',
  path: `courses/${COURSE}`,
  method: 'update',
  data: { ...VALID.course, title: 'عنوان آخر' },
  existing: WORLD[`courses/${COURSE}`],
});
t('26g. teacher creating a department denied', {
  expect: 'DENY',
  uid: 'teacher1',
  path: 'departments/dep2',
  method: 'create',
  data: VALID.department,
});
t('26h. teacher creating a major denied', {
  expect: 'DENY',
  uid: 'teacher1',
  path: 'majors/maj2',
  method: 'create',
  data: VALID.major,
});
t('26i. teacher creating a curriculum row denied', {
  expect: 'DENY',
  uid: 'teacher1',
  path: `curriculumCourses/maj1_${COURSE}`,
  method: 'create',
  data: VALID.curriculumCourse,
});
t('26j. teacher creating a semester denied', {
  expect: 'DENY',
  uid: 'teacher1',
  path: 'semesters/semester_2027_1',
  method: 'create',
  data: {
    academicYear: '2027',
    semesterNumber: 1,
    semesterName: 'الفصل الأول 2027',
    status: 'upcoming',
  },
});
t('26k. teacher creating an offering denied', {
  expect: 'DENY',
  uid: 'teacher1',
  path: `courseOfferings/${COURSE}_${SEM}_2`,
  method: 'create',
  data: { ...VALID.offering, section: '2' },
});
t('26l. teacher creating an enrollment denied', {
  expect: 'DENY',
  uid: 'teacher1',
  path: `enrollments/student1_${OFFERING}`,
  method: 'create',
  data: {
    userId: 'student1',
    offeringId: OFFERING,
    courseId: COURSE,
    semesterId: SEM,
    attemptNumber: 1,
    status: 'active',
    assignedBy: 'teacher1',
  },
});

// Course files stay admin-only until the teacher Files phase.
t('26m. teacher creating a course file denied (deferred to a later phase)', {
  expect: 'DENY',
  uid: 'teacher1',
  path: 'courseFiles/file2',
  method: 'create',
  data: { ...FILE_DOC, uploadedBy: 'teacher1' },
});
t('26n. teacher updating a course file denied', {
  expect: 'DENY',
  uid: 'teacher1',
  path: 'courseFiles/file1',
  method: 'update',
  data: { ...FILE_DOC, title: 'عنوان آخر' },
  existing: FILE_DOC,
});
t('26o. teacher reading a course file denied — no enrollment grants it', {
  expect: 'DENY',
  uid: 'teacher1',
  path: 'courseFiles/file1',
  method: 'get',
  existing: FILE_DOC,
  missing: [`enrollments/teacher1_${OFFERING}`],
});

// Personal tasks are a student-only feature.
t('26p. teacher creating a personal task denied', {
  expect: 'DENY',
  uid: 'teacher1',
  path: 'tasks/task2',
  method: 'create',
  data: { ...VALID.task, userId: 'teacher1' },
});
t('26q. teacher reading a student task denied', {
  expect: 'DENY',
  uid: 'teacher1',
  path: 'tasks/task1',
  method: 'get',
  existing: VALID.task,
});

// ---- role is immutable from every client ----
t('26r. teacher changing own role to admin denied', {
  expect: 'DENY',
  uid: 'teacher1',
  path: 'users/teacher1',
  method: 'update',
  data: { ...TEACHER, role: 'admin' },
  existing: TEACHER,
});
t('26s. student changing own role to teacher denied', {
  expect: 'DENY',
  uid: 'student1',
  path: 'users/student1',
  method: 'update',
  data: { ...STUDENT, role: 'teacher' },
  existing: STUDENT,
});
t('26t. admin changing a student into a teacher denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: 'users/student1',
  method: 'update',
  data: { ...STUDENT, role: 'teacher' },
  existing: STUDENT,
});
t('26u. self-registration as teacher denied', {
  expect: 'DENY',
  uid: 'newuser',
  path: 'users/newuser',
  method: 'create',
  data: {
    fullName: 'معلّم',
    email: 'new@test.com',
    role: 'teacher',
    status: 'active',
    emailVerified: false,
  },
  token: { email: 'new@test.com', email_verified: false },
});
/*
 * 26v changed policy in Phase 8.1 and is now three tests.
 *
 * A teacher may resolve a STUDENT document — without it a class roster
 * shows uids instead of names. Staff documents stay closed, and the
 * enumeration path (list) stays admin-only; see section 27.
 */
t('26v. teacher reading an ADMIN user document denied', {
  expect: 'DENY',
  uid: 'teacher1',
  path: 'users/admin1',
  method: 'get',
  existing: ADMIN,
});
t('26v2. teacher reading ANOTHER TEACHER user document denied', {
  expect: 'DENY',
  uid: 'teacher1',
  path: 'users/teacher2',
  method: 'get',
  existing: TEACHER,
});

// ---- unknown roles fail closed ----
t('26w. an unrecognised role grants no read access', {
  expect: 'DENY',
  uid: 'unknown1',
  path: `courses/${COURSE}`,
  method: 'get',
  existing: WORLD[`courses/${COURSE}`],
});
t('26x. an empty role grants no read access', {
  expect: 'DENY',
  uid: 'emptyrole1',
  path: `courses/${COURSE}`,
  method: 'get',
  existing: WORLD[`courses/${COURSE}`],
});
t('26y. a missing role field grants no read access', {
  expect: 'DENY',
  uid: 'norole1',
  path: `courses/${COURSE}`,
  method: 'get',
  existing: WORLD[`courses/${COURSE}`],
});
t('26z. unauthenticated read remains denied', {
  expect: 'DENY',
  uid: null,
  path: `courses/${COURSE}`,
  method: 'get',
  existing: WORLD[`courses/${COURSE}`],
});

// --- 27. Phase 8.1: teacher ownership via courseOfferings.teacherId -----
//
// The whole phase rests on one invariant: a teacher's access is never
// granted by their role, only by teacherId on a specific offering. These
// tests exist to make that invariant expensive to break by accident.

// ---- who a teacher may resolve in users ----
t('27a. teacher may get a STUDENT user document (roster names)', {
  expect: 'ALLOW',
  uid: 'teacher1',
  path: 'users/student1',
  method: 'get',
  existing: STUDENT,
});
t('27b. teacher may NOT list users (no directory dump)', {
  expect: 'DENY',
  uid: 'teacher1',
  path: 'users/student1',
  method: 'list',
  existing: STUDENT,
});
/*
 * Control for 27b. Without it a DENY on `list` proves nothing: it could
 * mean the harness rejects the method rather than the rule rejecting the
 * teacher. Admin must ALLOW on the identical shape.
 */
t('27b2. admin CAN list users (control for 27b)', {
  expect: 'ALLOW',
  uid: 'admin1',
  path: 'users/student1',
  method: 'list',
  existing: STUDENT,
});
t('27c. DISABLED teacher may not get a student document', {
  expect: 'DENY',
  uid: 'teacherOff',
  path: 'users/student1',
  method: 'get',
  existing: STUDENT,
});

// ---- roster reads follow offering ownership ----
t('27d. teacher reads enrollment of an offering they OWN', {
  expect: 'ALLOW',
  uid: 'teacher1',
  path: `enrollments/student1_${OWNED_OFFERING}`,
  method: 'get',
  existing: OWNED_ENROLLMENT_DOC,
});
t('27e. teacher reads enrollment of ANOTHER teacher offering denied', {
  expect: 'DENY',
  uid: 'teacher1',
  path: `enrollments/student1_${OTHER_OFFERING}`,
  method: 'get',
  existing: OTHER_ENROLLMENT_DOC,
});
t('27f. teacher reads enrollment of an UNASSIGNED offering denied', {
  expect: 'DENY',
  uid: 'teacher1',
  path: `enrollments/student1_${OFFERING}`,
  method: 'get',
  existing: UNASSIGNED_ENROLLMENT_DOC,
});
t('27g. DISABLED teacher reads enrollment of own offering denied', {
  expect: 'DENY',
  uid: 'teacherOff',
  path: `enrollments/student1_${OWNED_OFFERING}`,
  method: 'get',
  // teacherOff is not the owner either; the point is the role gate fires first.
  existing: OWNED_ENROLLMENT_DOC,
});
t('27h. student still cannot read another student enrollment', {
  expect: 'DENY',
  uid: 'student2',
  path: `enrollments/student1_${OWNED_OFFERING}`,
  method: 'get',
  existing: OWNED_ENROLLMENT_DOC,
});

// ---- reading a roster grants NO write on it ----
t('27i. teacher recording a result on own offering denied', {
  expect: 'DENY',
  uid: 'teacher1',
  path: `enrollments/student1_${OWNED_OFFERING}`,
  method: 'update',
  data: {
    ...OWNED_ENROLLMENT_DOC,
    status: 'completed',
    completionStatus: 'passed',
  },
  existing: OWNED_ENROLLMENT_DOC,
});
t('27j. teacher deleting an enrollment on own offering denied', {
  expect: 'DENY',
  uid: 'teacher1',
  path: `enrollments/student1_${OWNED_OFFERING}`,
  method: 'delete',
  existing: OWNED_ENROLLMENT_DOC,
});
t('27k. teacher enrolling a student into own offering denied', {
  expect: 'DENY',
  uid: 'teacher1',
  path: `enrollments/student2_${OWNED_OFFERING}`,
  method: 'create',
  data: { ...OWNED_ENROLLMENT_DOC, userId: 'student2', assignedBy: 'teacher1' },
});

// ---- owning an offering is not owning the offering document ----
t('27l. teacher updating own offering denied', {
  expect: 'DENY',
  uid: 'teacher1',
  path: `courseOfferings/${OWNED_OFFERING}`,
  method: 'update',
  data: { ...OWNED_OFFERING_DOC, status: 'archived' },
  existing: OWNED_OFFERING_DOC,
});
t('27m. teacher assigning an offering to THEMSELVES denied', {
  expect: 'DENY',
  uid: 'teacher1',
  path: `courseOfferings/${OFFERING}`,
  method: 'update',
  data: { ...OFFERING_DOC, teacherId: 'teacher1' },
  existing: OFFERING_DOC,
});
/*
 * Phase 8.2 boundary: owning an offering grants write permission over its files.
 */
t('27n. teacher writing courseFiles for own offering allowed (Phase 8.2)', {
  expect: 'ALLOW',
  uid: 'teacher1',
  path: 'courseFiles/f9',
  method: 'create',
  data: {
    offeringId: OWNED_OFFERING,
    courseId: COURSE,
    semesterId: SEM,
    title: 'ملف',
    fileName: 'a.pdf',
    fileExtension: 'pdf',
    mimeType: 'application/pdf',
    fileSize: 1000,
    cloudinaryUrl: 'https://res.cloudinary.com/x/image/upload/a.pdf',
    cloudinaryPublicId: 'a',
    cloudinaryResourceType: 'image',
    category: 'lecture',
    uploadedBy: 'teacher1',
    status: 'active',
  },
});

// ---- admin assignment writes are validated, not trusted ----
t('27o. admin creates offering assigned to a real teacher allowed', {
  expect: 'ALLOW',
  uid: 'admin1',
  path: `courseOfferings/${OWNED_OFFERING}`,
  method: 'create',
  data: OWNED_OFFERING_DOC,
});
t('27p. admin creates offering with NO teacherId allowed (legacy shape)', {
  expect: 'ALLOW',
  uid: 'admin1',
  path: `courseOfferings/${OFFERING}`,
  method: 'create',
  data: OFFERING_DOC,
});
t('27q. admin assigning an offering to a STUDENT denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: `courseOfferings/${OWNED_OFFERING}`,
  method: 'create',
  data: { ...OWNED_OFFERING_DOC, teacherId: 'student1' },
});
t('27r. admin assigning an offering to ANOTHER ADMIN denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: `courseOfferings/${OWNED_OFFERING}`,
  method: 'create',
  data: { ...OWNED_OFFERING_DOC, teacherId: 'admin1' },
});
t('27s. admin assigning an offering to a NONEXISTENT user denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: `courseOfferings/${OWNED_OFFERING}`,
  method: 'create',
  data: { ...OWNED_OFFERING_DOC, teacherId: 'ghost' },
  missing: ['users/ghost'],
});
t('27t. admin writing an EMPTY teacherId denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: `courseOfferings/${OWNED_OFFERING}`,
  method: 'create',
  data: { ...OWNED_OFFERING_DOC, teacherId: '' },
});
/*
 * A DISABLED teacher may still be assigned. Assignment must survive a
 * temporary suspension — the read gate is what stops them, not the field.
 */
t('27u. admin assigning an offering to a DISABLED teacher allowed', {
  expect: 'ALLOW',
  uid: 'admin1',
  path: `courseOfferings/${OWNED_OFFERING}`,
  method: 'create',
  data: { ...OWNED_OFFERING_DOC, teacherId: 'teacherOff' },
});
t('27v. admin reassigning an offering to another teacher allowed', {
  expect: 'ALLOW',
  uid: 'admin1',
  path: `courseOfferings/${OWNED_OFFERING}`,
  method: 'update',
  data: { ...OWNED_OFFERING_DOC, teacherId: 'teacher2' },
  existing: OWNED_OFFERING_DOC,
});
t('27w. admin UNASSIGNING an offering allowed', {
  expect: 'ALLOW',
  uid: 'admin1',
  path: `courseOfferings/${OWNED_OFFERING}`,
  method: 'update',
  data: withOut(OWNED_OFFERING_DOC, 'teacherId'),
  existing: OWNED_OFFERING_DOC,
});
t('27x. admin still cannot move an offering to another semester', {
  expect: 'DENY',
  uid: 'admin1',
  path: `courseOfferings/${OWNED_OFFERING}`,
  method: 'update',
  data: { ...OWNED_OFFERING_DOC, semesterId: 'semester_2027_1' },
  existing: OWNED_OFFERING_DOC,
});

// ---- an unassigned offering is owned by nobody ----
t('27y. teacher2 reads enrollment of unassigned offering denied', {
  expect: 'DENY',
  uid: 'teacher2',
  path: `enrollments/student1_${OFFERING}`,
  method: 'get',
  existing: UNASSIGNED_ENROLLMENT_DOC,
});
t('27z. admin retains full roster read on any offering', {
  expect: 'ALLOW',
  uid: 'admin1',
  path: `enrollments/student1_${OWNED_OFFERING}`,
  method: 'get',
  existing: OWNED_ENROLLMENT_DOC,
});

// ---- Phase 8.2 — Teacher Course Files Tests ----

const TEST_OWNED_FILE_DOC = {
  offeringId: OWNED_OFFERING,
  courseId: COURSE,
  semesterId: SEM,
  title: 'المساق المالك',
  fileName: 'file.pdf',
  fileExtension: 'pdf',
  mimeType: 'application/pdf',
  fileSize: 1000,
  cloudinaryUrl: 'https://res.cloudinary.com/x/image/upload/file.pdf',
  cloudinaryPublicId: 'file',
  cloudinaryResourceType: 'image',
  category: 'lecture',
  uploadedBy: 'teacher1',
  status: 'active',
};

t('28a. active teacher READ own-offering file allowed', {
  expect: 'ALLOW',
  uid: 'teacher1',
  path: 'courseFiles/f9',
  method: 'get',
  existing: TEST_OWNED_FILE_DOC,
});

t('28b. teacher READ another teacher\'s file denied', {
  expect: 'DENY',
  uid: 'teacher1',
  path: 'courseFiles/f9',
  method: 'get',
  existing: { ...TEST_OWNED_FILE_DOC, offeringId: OTHER_OFFERING },
});

t('28c. teacher READ file belonging to unassigned legacy offering denied', {
  expect: 'DENY',
  uid: 'teacher1',
  path: 'courseFiles/f9',
  method: 'get',
  existing: { ...TEST_OWNED_FILE_DOC, offeringId: OFFERING },
});

t('28d. admin READ remains ALLOW', {
  expect: 'ALLOW',
  uid: 'admin1',
  path: 'courseFiles/f9',
  method: 'get',
  existing: TEST_OWNED_FILE_DOC,
});

t('28e. active enrolled student READ remains ALLOW', {
  expect: 'ALLOW',
  uid: 'student1',
  path: 'courseFiles/f9',
  method: 'get',
  existing: TEST_OWNED_FILE_DOC,
  world: {
    ...WORLD,
    [`enrollments/student1_${OWNED_OFFERING}`]: { ...OWNED_ENROLLMENT_DOC, status: 'active' },
  },
});

t('28f. completed enrolled student READ remains ALLOW', {
  expect: 'ALLOW',
  uid: 'student1',
  path: 'courseFiles/f9',
  method: 'get',
  existing: TEST_OWNED_FILE_DOC,
  world: {
    ...WORLD,
    [`enrollments/student1_${OWNED_OFFERING}`]: { ...OWNED_ENROLLMENT_DOC, status: 'completed' },
  },
});

t('28g. removed enrollment READ remains DENY', {
  expect: 'DENY',
  uid: 'student1',
  path: 'courseFiles/f9',
  method: 'get',
  existing: TEST_OWNED_FILE_DOC,
  world: {
    ...WORLD,
    [`enrollments/student1_${OWNED_OFFERING}`]: { ...OWNED_ENROLLMENT_DOC, status: 'removed' },
  },
});

t('28h. unauthenticated READ remains DENY', {
  expect: 'DENY',
  path: 'courseFiles/f9',
  method: 'get',
  existing: TEST_OWNED_FILE_DOC,
});

t('28i. teacher can upload to own offering', {
  expect: 'ALLOW',
  uid: 'teacher1',
  path: 'courseFiles/f9',
  method: 'create',
  data: TEST_OWNED_FILE_DOC,
});

t('28j. teacher upload to foreign offering denied', {
  expect: 'DENY',
  uid: 'teacher1',
  path: 'courseFiles/f9',
  method: 'create',
  data: { ...TEST_OWNED_FILE_DOC, offeringId: OTHER_OFFERING },
});

t('28k. teacher can edit metadata on own file', {
  expect: 'ALLOW',
  uid: 'teacher1',
  path: 'courseFiles/f9',
  method: 'update',
  data: { ...TEST_OWNED_FILE_DOC, title: 'عنوان جديد' },
  existing: TEST_OWNED_FILE_DOC,
});

t('28l. teacher cannot mutate immutable file relation fields', {
  expect: 'DENY',
  uid: 'teacher1',
  path: 'courseFiles/f9',
  method: 'update',
  data: { ...TEST_OWNED_FILE_DOC, offeringId: OTHER_OFFERING },
  existing: TEST_OWNED_FILE_DOC,
});

t('28m. teacher can archive own file', {
  expect: 'ALLOW',
  uid: 'teacher1',
  path: 'courseFiles/f9',
  method: 'update',
  data: { ...TEST_OWNED_FILE_DOC, status: 'archived' },
  existing: TEST_OWNED_FILE_DOC,
});

t('28n. teacher cannot hard delete own file', {
  expect: 'DENY',
  uid: 'teacher1',
  path: 'courseFiles/f9',
  method: 'delete',
  existing: TEST_OWNED_FILE_DOC,
});

const TEST_ASSIGNMENT_DOC = {
  offeringId: OWNED_OFFERING,
  courseId: COURSE,
  semesterId: SEM,
  title: 'واجب البرمجة الأول',
  description: 'قم بحل التمارين المرفقة في ملف المحاضرة',
  dueAt: TIME,
  priority: 'medium',
  createdBy: 'teacher1',
  status: 'active',
};

// --- 29. Phase 8.3: Teacher Assignments ----------------------------

t('29a. teacher can read owned assignment', {
  expect: 'ALLOW',
  uid: 'teacher1',
  path: 'assignments/assign1',
  method: 'get',
  existing: TEST_ASSIGNMENT_DOC,
});

t('29b. teacher cannot read foreign assignment', {
  expect: 'DENY',
  uid: 'teacher2',
  path: 'assignments/assign1',
  method: 'get',
  existing: TEST_ASSIGNMENT_DOC,
});

t('29c. teacher cannot read assignment for unassigned offering', {
  expect: 'DENY',
  uid: 'teacher1',
  path: 'assignments/assign1',
  method: 'get',
  existing: { ...TEST_ASSIGNMENT_DOC, offeringId: OTHER_OFFERING },
});

t('29d. teacher can create assignment for owned offering', {
  expect: 'ALLOW',
  uid: 'teacher1',
  path: 'assignments/assign1',
  method: 'create',
  data: TEST_ASSIGNMENT_DOC,
});

t('29e. teacher cannot create assignment for foreign offering', {
  expect: 'DENY',
  uid: 'teacher1',
  path: 'assignments/assign1',
  method: 'create',
  data: { ...TEST_ASSIGNMENT_DOC, offeringId: OTHER_OFFERING, createdBy: 'teacher1' },
});

t('29f. teacher cannot create assignment with forged courseId', {
  expect: 'DENY',
  uid: 'teacher1',
  path: 'assignments/assign1',
  method: 'create',
  data: { ...TEST_ASSIGNMENT_DOC, courseId: 'wrong_course' },
});

t('29g. teacher cannot create assignment with forged semesterId', {
  expect: 'DENY',
  uid: 'teacher1',
  path: 'assignments/assign1',
  method: 'create',
  data: { ...TEST_ASSIGNMENT_DOC, semesterId: 'wrong_semester' },
});

t('29h. teacher cannot create assignment with createdBy != uid', {
  expect: 'DENY',
  uid: 'teacher1',
  path: 'assignments/assign1',
  method: 'create',
  data: { ...TEST_ASSIGNMENT_DOC, createdBy: 'teacher2' },
});

t('29i. teacher can update mutable fields on own assignment', {
  expect: 'ALLOW',
  uid: 'teacher1',
  path: 'assignments/assign1',
  method: 'update',
  data: { ...TEST_ASSIGNMENT_DOC, title: 'عنوان جديد', description: 'وصف جديد' },
  existing: TEST_ASSIGNMENT_DOC,
});

t('29j. teacher cannot update immutable offeringId on own assignment', {
  expect: 'DENY',
  uid: 'teacher1',
  path: 'assignments/assign1',
  method: 'update',
  data: { ...TEST_ASSIGNMENT_DOC, offeringId: OTHER_OFFERING },
  existing: TEST_ASSIGNMENT_DOC,
});

t('29k. teacher cannot update immutable createdBy on own assignment', {
  expect: 'DENY',
  uid: 'teacher1',
  path: 'assignments/assign1',
  method: 'update',
  data: { ...TEST_ASSIGNMENT_DOC, createdBy: 'teacher2' },
  existing: TEST_ASSIGNMENT_DOC,
});

t('29l. teacher can archive own assignment', {
  expect: 'ALLOW',
  uid: 'teacher1',
  path: 'assignments/assign1',
  method: 'update',
  data: { ...TEST_ASSIGNMENT_DOC, status: 'archived' },
  existing: TEST_ASSIGNMENT_DOC,
});

t('29m. teacher cannot hard delete own assignment', {
  expect: 'DENY',
  uid: 'teacher1',
  path: 'assignments/assign1',
  method: 'delete',
  existing: TEST_ASSIGNMENT_DOC,
});

t('29n. student with active enrollment can read assignment', {
  expect: 'ALLOW',
  uid: 'student1',
  path: 'assignments/assign1',
  method: 'get',
  existing: TEST_ASSIGNMENT_DOC,
  world: {
    ...WORLD,
    [`enrollments/student1_${OWNED_OFFERING}`]: { ...OWNED_ENROLLMENT_DOC, status: 'active' },
  },
});

t('29o. student with completed enrollment can read assignment', {
  expect: 'ALLOW',
  uid: 'student1',
  path: 'assignments/assign1',
  method: 'get',
  existing: TEST_ASSIGNMENT_DOC,
  world: {
    ...WORLD,
    [`enrollments/student1_${OWNED_OFFERING}`]: { ...OWNED_ENROLLMENT_DOC, status: 'completed' },
  },
});

t('29p. student with removed enrollment cannot read assignment', {
  expect: 'DENY',
  uid: 'student1',
  path: 'assignments/assign1',
  method: 'get',
  existing: TEST_ASSIGNMENT_DOC,
  world: {
    ...WORLD,
    [`enrollments/student1_${OWNED_OFFERING}`]: { ...OWNED_ENROLLMENT_DOC, status: 'removed' },
  },
});

t('29q. student cannot read assignment for unrelated offering', {
  expect: 'DENY',
  uid: 'student2',
  path: 'assignments/assign1',
  method: 'get',
  existing: TEST_ASSIGNMENT_DOC,
});

t('29r. student cannot create assignment', {
  expect: 'DENY',
  uid: 'student1',
  path: 'assignments/assign1',
  method: 'create',
  data: TEST_ASSIGNMENT_DOC,
});

t('29s. admin can read all assignments', {
  expect: 'ALLOW',
  uid: 'admin1',
  path: 'assignments/assign1',
  method: 'get',
  existing: TEST_ASSIGNMENT_DOC,
});

t('29t. admin can update status to archived (moderation)', {
  expect: 'ALLOW',
  uid: 'admin1',
  path: 'assignments/assign1',
  method: 'update',
  data: { ...TEST_ASSIGNMENT_DOC, status: 'archived' },
  existing: TEST_ASSIGNMENT_DOC,
});

t('29u. admin cannot update other fields (moderation)', {
  expect: 'DENY',
  uid: 'admin1',
  path: 'assignments/assign1',
  method: 'update',
  data: { ...TEST_ASSIGNMENT_DOC, status: 'archived', title: 'تعديل المشرف' },
  existing: TEST_ASSIGNMENT_DOC,
});

t('29v. admin cannot create assignment', {
  expect: 'DENY',
  uid: 'admin1',
  path: 'assignments/assign1',
  method: 'create',
  data: TEST_ASSIGNMENT_DOC,
});

t('29w. unauthenticated access is denied', {
  expect: 'DENY',
  path: 'assignments/assign1',
  method: 'get',
  existing: TEST_ASSIGNMENT_DOC,
});

// --- 30. Phase 8.3: completing the assignment permission boundary -------
//
// Section 29 pins the common paths. This section closes the rest of the
// matrix so that no single edit can quietly widen the surface: every
// forgeable field, every moderation limit, and every unauthenticated verb.

// ---- create: remaining forgery and validity paths ----
t('30a. teacher creating for an UNASSIGNED offering denied', {
  expect: 'DENY',
  uid: 'teacher1',
  path: 'assignments/new1',
  method: 'create',
  data: { ...TEST_ASSIGNMENT_DOC, offeringId: OFFERING },
});
t('30b. teacher creating with an invalid priority denied', {
  expect: 'DENY',
  uid: 'teacher1',
  path: 'assignments/new1',
  method: 'create',
  data: { ...TEST_ASSIGNMENT_DOC, priority: 'urgent' },
});
/*
 * An assignment cannot be born archived. Creating one already hidden would
 * be a way to write content that never passes through the active state the
 * students' and teacher's queries observe.
 */
t('30c. teacher creating an ARCHIVED assignment denied', {
  expect: 'DENY',
  uid: 'teacher1',
  path: 'assignments/new1',
  method: 'create',
  data: { ...TEST_ASSIGNMENT_DOC, status: 'archived' },
});
t('30d. teacher creating with a missing title denied', {
  expect: 'DENY',
  uid: 'teacher1',
  path: 'assignments/new1',
  method: 'create',
  data: { ...TEST_ASSIGNMENT_DOC, title: '' },
});

// ---- teacher update: each mutable field individually ----
t('30e. teacher updating own description allowed', {
  expect: 'ALLOW',
  uid: 'teacher1',
  path: 'assignments/assign1',
  method: 'update',
  data: { ...TEST_ASSIGNMENT_DOC, description: 'تعليمات محدَّثة' },
  existing: TEST_ASSIGNMENT_DOC,
});
t('30f. teacher updating own dueAt allowed', {
  expect: 'ALLOW',
  uid: 'teacher1',
  path: 'assignments/assign1',
  method: 'update',
  data: { ...TEST_ASSIGNMENT_DOC, dueAt: '2026-09-30T12:00:00Z' },
  existing: TEST_ASSIGNMENT_DOC,
});
t('30g. teacher updating own priority allowed', {
  expect: 'ALLOW',
  uid: 'teacher1',
  path: 'assignments/assign1',
  method: 'update',
  data: { ...TEST_ASSIGNMENT_DOC, priority: 'high' },
  existing: TEST_ASSIGNMENT_DOC,
});
t('30h. teacher setting an invalid priority denied', {
  expect: 'DENY',
  uid: 'teacher1',
  path: 'assignments/assign1',
  method: 'update',
  data: { ...TEST_ASSIGNMENT_DOC, priority: 'urgent' },
  existing: TEST_ASSIGNMENT_DOC,
});

// ---- teacher update: the remaining immutable relational fields ----
t('30i. teacher changing courseId denied', {
  expect: 'DENY',
  uid: 'teacher1',
  path: 'assignments/assign1',
  method: 'update',
  data: { ...TEST_ASSIGNMENT_DOC, courseId: 'c2' },
  existing: TEST_ASSIGNMENT_DOC,
});
t('30j. teacher changing semesterId denied', {
  expect: 'DENY',
  uid: 'teacher1',
  path: 'assignments/assign1',
  method: 'update',
  data: { ...TEST_ASSIGNMENT_DOC, semesterId: 'semester_2027_1' },
  existing: TEST_ASSIGNMENT_DOC,
});
t('30k. teacher changing createdAt denied', {
  expect: 'DENY',
  uid: 'teacher1',
  path: 'assignments/assign1',
  method: 'update',
  data: { ...TEST_ASSIGNMENT_DOC, createdAt: '2020-01-01T00:00:00Z' },
  existing: TEST_ASSIGNMENT_DOC,
});
/*
 * The ownership check reads the ORIGINAL offeringId, so a teacher editing
 * somebody else's assignment is rejected even though the payload is
 * otherwise perfectly valid.
 */
t('30l. teacher updating a FOREIGN assignment denied', {
  expect: 'DENY',
  uid: 'teacher2',
  path: 'assignments/assign1',
  method: 'update',
  data: { ...TEST_ASSIGNMENT_DOC, title: 'عنوان من معلّم آخر' },
  existing: TEST_ASSIGNMENT_DOC,
});

// ---- student: reads only, never writes ----
t('30m. student updating an assignment denied', {
  expect: 'DENY',
  uid: 'student1',
  path: 'assignments/assign1',
  method: 'update',
  data: { ...TEST_ASSIGNMENT_DOC, title: 'عنوان من طالب' },
  existing: TEST_ASSIGNMENT_DOC,
  world: {
    ...WORLD,
    [`enrollments/student1_${OWNED_OFFERING}`]: OWNED_ENROLLMENT_DOC,
  },
});
t('30n. student deleting an assignment denied', {
  expect: 'DENY',
  uid: 'student1',
  path: 'assignments/assign1',
  method: 'delete',
  existing: TEST_ASSIGNMENT_DOC,
  world: {
    ...WORLD,
    [`enrollments/student1_${OWNED_OFFERING}`]: OWNED_ENROLLMENT_DOC,
  },
});

// ---- admin: global oversight, moderation only ----
t('30o. admin LIST over assignments allowed', {
  expect: 'ALLOW',
  uid: 'admin1',
  path: 'assignments/assign1',
  method: 'list',
  existing: TEST_ASSIGNMENT_DOC,
});
t('30p. admin changing description while archiving denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: 'assignments/assign1',
  method: 'update',
  data: {
    ...TEST_ASSIGNMENT_DOC,
    status: 'archived',
    description: 'تعليمات من المشرف',
  },
  existing: TEST_ASSIGNMENT_DOC,
});
t('30q. admin changing dueAt while archiving denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: 'assignments/assign1',
  method: 'update',
  data: {
    ...TEST_ASSIGNMENT_DOC,
    status: 'archived',
    dueAt: '2026-12-31T23:59:00Z',
  },
  existing: TEST_ASSIGNMENT_DOC,
});
t('30r. admin changing priority while archiving denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: 'assignments/assign1',
  method: 'update',
  data: { ...TEST_ASSIGNMENT_DOC, status: 'archived', priority: 'high' },
  existing: TEST_ASSIGNMENT_DOC,
});
/*
 * Moderation is one-directional by policy: an admin may hide an
 * assignment, but reinstating a teacher's academic content is the
 * teacher's decision, not the moderator's.
 */
t('30s. admin RESTORING an archived assignment denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: 'assignments/assign1',
  method: 'update',
  data: { ...TEST_ASSIGNMENT_DOC, status: 'active' },
  existing: { ...TEST_ASSIGNMENT_DOC, status: 'archived' },
});
t('30t. admin hard delete denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: 'assignments/assign1',
  method: 'delete',
  existing: TEST_ASSIGNMENT_DOC,
});

// ---- unauthenticated: every verb ----
t('30u. unauthenticated list denied', {
  expect: 'DENY',
  uid: null,
  path: 'assignments/assign1',
  method: 'list',
  existing: TEST_ASSIGNMENT_DOC,
});
t('30v. unauthenticated create denied', {
  expect: 'DENY',
  uid: null,
  path: 'assignments/new1',
  method: 'create',
  data: TEST_ASSIGNMENT_DOC,
});
t('30w. unauthenticated update denied', {
  expect: 'DENY',
  uid: null,
  path: 'assignments/assign1',
  method: 'update',
  data: { ...TEST_ASSIGNMENT_DOC, title: 'مجهول' },
  existing: TEST_ASSIGNMENT_DOC,
});
t('30x. unauthenticated delete denied', {
  expect: 'DENY',
  uid: null,
  path: 'assignments/assign1',
  method: 'delete',
  existing: TEST_ASSIGNMENT_DOC,
});

/*
 * Assignments must not have widened the neighbouring collections. These
 * two re-assert the boundaries most at risk from a shared-helper edit.
 */
t('30y. teacher still cannot write courseFiles for own offering', {
  expect: 'DENY',
  uid: 'teacher1',
  path: 'courseFiles/fA',
  method: 'delete',
  existing: { offeringId: OWNED_OFFERING, status: 'active' },
});
t('30z. teacher still cannot read a student personal task', {
  expect: 'DENY',
  uid: 'teacher1',
  path: 'tasks/t1',
  method: 'get',
  existing: { userId: 'student1', title: 'مهمة', status: 'pending' },
});

// --- 31. Shared space: posts / comments / likes / reports ----------------
//
// These rules came from a teammate's branch and were only ever present in
// the DEPLOYED ruleset — never in git. Deploying this file without them
// silently deleted them once already (and their branch's deploy deleted
// tasks, assignments and supportRequests in turn, which is what broke the
// app). They are pinned here so neither direction of that trade can happen
// again unnoticed.

t('31a. active user reads a post', {
  expect: 'ALLOW',
  uid: 'student1',
  path: 'posts/p1',
  method: 'get',
  existing: { authorId: 'student2' },
});
t('31b. author creates their own post', {
  expect: 'ALLOW',
  uid: 'student1',
  path: 'posts/p2',
  method: 'create',
  data: { authorId: 'student1' },
});
t('31c. creating a post as somebody else denied', {
  expect: 'DENY',
  uid: 'student1',
  path: 'posts/p2',
  method: 'create',
  data: { authorId: 'student2' },
});
t('31d. non-author editing a post denied', {
  expect: 'DENY',
  uid: 'student1',
  path: 'posts/p1',
  method: 'update',
  data: { authorId: 'student2', text: 'x' },
  existing: { authorId: 'student2' },
});
t('31e. author deletes their own post', {
  expect: 'ALLOW',
  uid: 'student1',
  path: 'posts/p1',
  method: 'delete',
  existing: { authorId: 'student1' },
});
t('31f. admin moderates any post', {
  expect: 'ALLOW',
  uid: 'admin1',
  path: 'posts/p1',
  method: 'delete',
  existing: { authorId: 'student2' },
});
t('31g. author creates a comment', {
  expect: 'ALLOW',
  uid: 'student1',
  path: 'posts/p1/comments/c1',
  method: 'create',
  data: { authorId: 'student1' },
});
t('31h. non-author deleting a comment denied', {
  expect: 'DENY',
  uid: 'student1',
  path: 'posts/p1/comments/c1',
  method: 'delete',
  existing: { authorId: 'student2' },
});
t('31i. a user likes as themselves', {
  expect: 'ALLOW',
  uid: 'student1',
  path: 'posts/p1/likes/student1',
  method: 'create',
  data: { createdAt: TIME },
});
t('31j. liking on behalf of someone else denied', {
  expect: 'DENY',
  uid: 'student1',
  path: 'posts/p1/likes/student2',
  method: 'create',
  data: { createdAt: TIME },
});
/*
 * The report collection is postReports, not reports.
 *
 * An earlier merge copied the teammate's block verbatim and pinned the
 * wrong collection name — PostService writes postReports, so the rules
 * being tested guarded a collection nothing uses while the real one fell
 * through to the default deny. These cases now follow the deployed shape:
 * reporterId (not reportedBy), and the five required keys.
 */
const REPORT_DOC = {
  postId: 'p1',
  courseId: COURSE,
  reporterId: 'student1',
  reason: 'محتوى غير لائق',
  status: 'pending',
};

t('31k. user files a report as themselves', {
  expect: 'ALLOW',
  uid: 'student1',
  path: 'postReports/r1',
  method: 'create',
  data: REPORT_DOC,
});
t('31k2. filing a report as somebody else denied', {
  expect: 'DENY',
  uid: 'student1',
  path: 'postReports/r1',
  method: 'create',
  data: { ...REPORT_DOC, reporterId: 'student2' },
});
t('31k3. a report created already resolved denied', {
  expect: 'DENY',
  uid: 'student1',
  path: 'postReports/r1',
  method: 'create',
  data: { ...REPORT_DOC, status: 'resolved' },
});
t('31l. reading reports is admin-only', {
  expect: 'DENY',
  uid: 'student1',
  path: 'postReports/r1',
  method: 'get',
  existing: REPORT_DOC,
});
t('31m. admin reads reports', {
  expect: 'ALLOW',
  uid: 'admin1',
  path: 'postReports/r1',
  method: 'get',
  existing: REPORT_DOC,
});
t('31m2. admin resolves a report', {
  expect: 'ALLOW',
  uid: 'admin1',
  path: 'postReports/r1',
  method: 'update',
  data: { ...REPORT_DOC, status: 'resolved' },
  existing: REPORT_DOC,
});
t('31m3. reporter resolving their own report denied', {
  expect: 'DENY',
  uid: 'student1',
  path: 'postReports/r1',
  method: 'update',
  data: { ...REPORT_DOC, status: 'resolved' },
  existing: REPORT_DOC,
});

/*
 * In-app notifications, adopted from the deployed ruleset in the same
 * reconciliation. The publisher writes the recipient's document — that is
 * why create is not owner-scoped — so the read and update rules are the
 * only thing standing between a user and someone else's notifications.
 */
const NOTIFICATION_DOC = {
  recipientId: 'student2',
  type: 'new_post',
  isRead: false,
};

t('31o. recipient reads their own notification', {
  expect: 'ALLOW',
  uid: 'student2',
  path: 'notifications/n1',
  method: 'get',
  existing: NOTIFICATION_DOC,
});
t('31p. reading another user notification denied', {
  expect: 'DENY',
  uid: 'student1',
  path: 'notifications/n1',
  method: 'get',
  existing: NOTIFICATION_DOC,
});
t('31q. active user notifies a classmate', {
  expect: 'ALLOW',
  uid: 'student1',
  path: 'notifications/n2',
  method: 'create',
  data: NOTIFICATION_DOC,
});
t('31r. a notification created already read denied', {
  expect: 'DENY',
  uid: 'student1',
  path: 'notifications/n2',
  method: 'create',
  data: { ...NOTIFICATION_DOC, isRead: true },
});
t('31s. recipient marks their notification read', {
  expect: 'ALLOW',
  uid: 'student2',
  path: 'notifications/n1',
  method: 'update',
  data: { ...NOTIFICATION_DOC, isRead: true },
  existing: NOTIFICATION_DOC,
});
t('31t. non-recipient marking a notification read denied', {
  expect: 'DENY',
  uid: 'student1',
  path: 'notifications/n1',
  method: 'update',
  data: { ...NOTIFICATION_DOC, isRead: true },
  existing: NOTIFICATION_DOC,
});
t('31u. deleting a notification denied for its recipient', {
  expect: 'DENY',
  uid: 'student2',
  path: 'notifications/n1',
  method: 'delete',
  existing: NOTIFICATION_DOC,
});
t('31n. unauthenticated post read denied', {
  expect: 'DENY',
  uid: null,
  path: 'posts/p1',
  method: 'get',
  existing: { authorId: 'student1' },
});

// --- 32. assignmentProgress: private per-student completion marks --------
//
// The whole point of this collection is that it is NOT a field on
// /assignments. These cases pin both halves of that: a student owns their
// own mark completely, and NOBODY else can read or write it — not a
// classmate, not the teacher who set the assignment, not an admin.

const ASSIGNMENT_ID = 'assign1';
const PROGRESS_ID = `student1_${ASSIGNMENT_ID}`;
const OTHER_PROGRESS_ID = `student2_${ASSIGNMENT_ID}`;

const PROGRESS_DOC = {
  studentId: 'student1',
  assignmentId: ASSIGNMENT_ID,
  isCompleted: true,
  updatedAt: TIME,
};

const OTHER_PROGRESS_DOC = { ...PROGRESS_DOC, studentId: 'student2' };

// ---- the owner has full control of their own mark ----
t('32a. student reads own progress', {
  expect: 'ALLOW',
  uid: 'student1',
  path: `assignmentProgress/${PROGRESS_ID}`,
  method: 'get',
  existing: PROGRESS_DOC,
});
t('32b. student creates own progress', {
  expect: 'ALLOW',
  uid: 'student1',
  path: `assignmentProgress/${PROGRESS_ID}`,
  method: 'create',
  data: PROGRESS_DOC,
});
t('32c. student updates own progress (undo)', {
  expect: 'ALLOW',
  uid: 'student1',
  path: `assignmentProgress/${PROGRESS_ID}`,
  method: 'update',
  data: { ...PROGRESS_DOC, isCompleted: false },
  existing: PROGRESS_DOC,
});
t('32d. student deletes own progress', {
  expect: 'ALLOW',
  uid: 'student1',
  path: `assignmentProgress/${PROGRESS_ID}`,
  method: 'delete',
  existing: PROGRESS_DOC,
});

// ---- nobody else, in either direction ----
t('32e. student reading a classmate progress denied', {
  expect: 'DENY',
  uid: 'student1',
  path: `assignmentProgress/${OTHER_PROGRESS_ID}`,
  method: 'get',
  existing: OTHER_PROGRESS_DOC,
});
t('32f. student writing a classmate progress denied', {
  expect: 'DENY',
  uid: 'student1',
  path: `assignmentProgress/${OTHER_PROGRESS_ID}`,
  method: 'update',
  data: { ...OTHER_PROGRESS_DOC, isCompleted: false },
  existing: OTHER_PROGRESS_DOC,
});
t('32g. student deleting a classmate progress denied', {
  expect: 'DENY',
  uid: 'student1',
  path: `assignmentProgress/${OTHER_PROGRESS_ID}`,
  method: 'delete',
  existing: OTHER_PROGRESS_DOC,
});

/*
 * Spoofing, both shapes.
 *
 * 32h writes somebody else's uid into a path that matches it — the ID is
 * consistent, the token is not. 32i keeps the caller's own path but claims
 * a different studentId, so the ID and the field disagree. Either alone
 * would be a hole; both are closed.
 */
t('32h. student creating progress as another student denied', {
  expect: 'DENY',
  uid: 'student1',
  path: `assignmentProgress/${OTHER_PROGRESS_ID}`,
  method: 'create',
  data: OTHER_PROGRESS_DOC,
});
t('32i. spoofed studentId that disagrees with the document ID denied', {
  expect: 'DENY',
  uid: 'student1',
  path: `assignmentProgress/${PROGRESS_ID}`,
  method: 'create',
  data: { ...PROGRESS_DOC, studentId: 'student2' },
});
t('32j. progress at a mismatched document ID denied', {
  expect: 'DENY',
  uid: 'student1',
  path: 'assignmentProgress/whatever',
  method: 'create',
  data: PROGRESS_DOC,
});

// ---- the pair is frozen; only the mark moves ----
t('32k. reassigning progress to another assignment denied', {
  expect: 'DENY',
  uid: 'student1',
  path: `assignmentProgress/${PROGRESS_ID}`,
  method: 'update',
  data: { ...PROGRESS_DOC, assignmentId: 'assign2' },
  existing: PROGRESS_DOC,
});
t('32l. a non-boolean completion flag denied', {
  expect: 'DENY',
  uid: 'student1',
  path: `assignmentProgress/${PROGRESS_ID}`,
  method: 'create',
  data: { ...PROGRESS_DOC, isCompleted: 'yes' },
});
t('32m. progress with no assignmentId denied', {
  expect: 'DENY',
  uid: 'student1',
  path: `assignmentProgress/${PROGRESS_ID}`,
  method: 'create',
  data: { ...PROGRESS_DOC, assignmentId: '' },
});

// ---- staff are outsiders here ----
//
// The teacher owns the ASSIGNMENT; they do not own the student's private
// note about it. This is the default expectation for the feature, and is
// asserted rather than assumed.
t('32n. teacher reading student progress denied', {
  expect: 'DENY',
  uid: 'teacher1',
  path: `assignmentProgress/${PROGRESS_ID}`,
  method: 'get',
  existing: PROGRESS_DOC,
});
t('32o. teacher writing student progress denied', {
  expect: 'DENY',
  uid: 'teacher1',
  path: `assignmentProgress/${PROGRESS_ID}`,
  method: 'update',
  data: { ...PROGRESS_DOC, isCompleted: false },
  existing: PROGRESS_DOC,
});
t('32p. admin reading student progress denied', {
  expect: 'DENY',
  uid: 'admin1',
  path: `assignmentProgress/${PROGRESS_ID}`,
  method: 'get',
  existing: PROGRESS_DOC,
});

// ---- disabled and unauthenticated ----
t('32q. a disabled student account has no access', {
  expect: 'DENY',
  uid: 'disabled1',
  path: 'assignmentProgress/disabled1_assign1',
  method: 'create',
  data: { ...PROGRESS_DOC, studentId: 'disabled1' },
});
t('32r. unauthenticated read denied', {
  expect: 'DENY',
  uid: null,
  path: `assignmentProgress/${PROGRESS_ID}`,
  method: 'get',
  existing: PROGRESS_DOC,
});
t('32s. unauthenticated write denied', {
  expect: 'DENY',
  uid: null,
  path: `assignmentProgress/${PROGRESS_ID}`,
  method: 'create',
  data: PROGRESS_DOC,
});

/*
 * The point of the whole design: completion never touches the shared
 * assignment document. If a student could write /assignments, none of the
 * isolation above would matter.
 */
t('32t. student still cannot write the shared assignment document', {
  expect: 'DENY',
  uid: 'student1',
  path: `assignments/${ASSIGNMENT_ID}`,
  method: 'update',
  data: { ...TEST_ASSIGNMENT_DOC, status: 'archived' },
  existing: TEST_ASSIGNMENT_DOC,
});

// ------------------------------------------------------------------- runner

const source = {
  files: [{ name: 'firestore.rules', content: fs.readFileSync(RULES, 'utf8') }],
};

const token = await accessToken();

/*
 * The :test endpoint rejects an oversized request with a bare
 * INVALID_ARGUMENT — no hint that size is the problem. Phase 8.3 crossed
 * that line (240 cases passed, 266 did not), so the suite is sent in
 * batches and the results are stitched back together in order.
 *
 * Batches are evaluated against the SAME ruleset source, so splitting
 * changes nothing about what is tested; only the transport is chunked.
 */
const BATCH_SIZE = 100;

async function runBatch(batch) {
  const response = await fetch(
    `https://firebaserules.googleapis.com/v1/projects/${PROJECT}:test`,
    {
      method: 'POST',
      headers: {
        authorization: `Bearer ${token}`,
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        source,
        testSuite: { testCases: batch.map((c) => c.testCase) },
      }),
    },
  );

  const payload = await response.json();

  if (!response.ok) {
    console.error('HTTP', response.status);
    console.error(JSON.stringify(payload, null, 2).slice(0, 4000));
    process.exit(1);
  }

  return payload;
}

const batches = [];
for (let i = 0; i < cases.length; i += BATCH_SIZE) {
  batches.push(cases.slice(i, i + BATCH_SIZE));
}

const payloads = [];
for (const batch of batches) {
  payloads.push(await runBatch(batch));
}

// Compilation issues are identical for every batch; one copy is enough.
const body = {
  issues: payloads[0]?.issues ?? [],
  testResults: payloads.flatMap((payload) => payload.testResults ?? []),
};

/*
 * ERROR fails the run; WARNING is surfaced but does not.
 *
 * The compiler reports a declared-but-not-yet-referenced helper as a
 * WARNING. Phase 8A introduces isActiveTeacher() ahead of the phases that
 * use it, so treating every issue as fatal would block a ruleset that
 * compiles and behaves correctly. Warnings stay printed on every run so
 * they cannot accumulate unnoticed.
 */
const issues = body.issues ?? [];
const blocking = issues.filter((issue) => issue.severity === 'ERROR');
const warnings = issues.filter((issue) => issue.severity !== 'ERROR');

if (warnings.length) {
  console.warn('RULES COMPILATION WARNINGS:');
  for (const warning of warnings) {
    console.warn(
      `  [${warning.severity}] line ${warning.sourcePosition?.line}: ${warning.description}`,
    );
  }
  console.warn('');
}

if (blocking.length) {
  console.error('RULES COMPILATION ERRORS:');
  console.error(JSON.stringify(blocking, null, 2));
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
