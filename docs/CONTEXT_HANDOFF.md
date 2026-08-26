# Akademia / أكاديميا — Context Handoff

> **Read this file completely before doing anything.** It is written from the
> actual repository, the live Firebase project, and test runs performed on
> 2026-08-20 — not from memory of earlier conversations.
>
> Everything here was verified. Where something could not be verified, it says
> so explicitly.

---

## 0. Verified state at time of writing

| | |
|---|---|
| **Branch** | `feature/teacher-role` |
| **HEAD** | `c07165362e94b070c160dce80b1160a52a8b3280` |
| **HEAD subject** | `fix Firestore rules and complete tasks assignments features` |
| **Working tree** | **clean** (`git status --short` empty) |
| **Remote tracking** | `origin/feature/teacher-role`, **0 ahead / 0 behind** |

Recent commits:

```
c071653 fix Firestore rules and complete tasks assignments features
28bd366 Integrate student tasks and academic assignments
f78610f Implement teacher course files and academic assignments
4828a70 Implement teacher management and assigned course workspace
ff2425b Establish tescher role foundation
```

Verified test results (run 2026-08-20 on this exact HEAD):

```
flutter analyze                  → No issues found!
flutter test                     → 428 passed, 0 failed   (33 test files)
node tool/rules_test/suite.js    → 280/280 passed
node tool/rules_test/selftest.js → 0/4 inverted (expected 0/4)
```

---

## 1. ✅ RESOLVED — local `firestore.rules` is back in sync with deployed

**Status: reconciled on 2026-08-20. Local is now byte-identical to the live
ruleset.** This section is kept because the *pattern* recurs, not because the
problem is open.

### What had happened

| | Ruleset | Size |
|---|---|---|
| **Deployed (live)** | `4b84c9bb-49eb-48a0-a9d2-bffd39547714` released 2026-08-20T16:06:43Z | 47,855 bytes |
| **Local at `c071653`** | stale | 45,562 bytes |

All 13 shared blocks were byte-identical (`users`, `tasks`, `assignments`,
`supportRequests`, `courseFiles`, `courses`, `courseOfferings`,
`enrollments`, `semesters`, `departments`, `majors`,
`curriculumCourses`, `posts`) — the §8 merge survived. But a teammate
deployed again afterwards and local never caught up:

| Block | Local (before) | Deployed | Local (now) |
|---|---|---|---|
| `notifications` | ❌ absent | ✅ present | ✅ adopted |
| `postReports` | ❌ absent | ✅ present (hardened) | ✅ adopted |
| `reports` | ✅ present (older, looser) | ❌ removed | ✅ removed |

### How it was fixed

The deployed ruleset was fetched read-only and written over local, so the
diff is confined to the tail (+62 / −4) and every shared block is untouched.
Nothing was deployed — production already runs this exact content.

The rules test suite also had to catch up: cases `31k/31l/31m` pinned the
**wrong collection name** (`reports` / `reportedBy`), while the app writes
`postReports` / `reporterId`. Those tests were guarding a collection
nothing uses. They now follow the deployed shape, and the `notifications`
block gained coverage it never had. Suite went **280 → 291**.

### The rule that still applies

`firestore.rules` is a single global file with multiple active developers,
and whoever deploys last wins. Every time, in this order:

1. Fetch the deployed ruleset (read-only — see §10 for how).
2. Diff it against local, block by block.
3. **Merge, never overwrite.** Adopt live-only blocks; drop dead ones.
4. Re-run `node tool/rules_test/suite.js` **and** `selftest.js` (must be `0/4`).
5. Commit the reconciled rules **before** deploying.

---

## 2. Project overview

- **Name:** Akademia / أكاديميا — a university student academic-management app.
- **Context:** graduation project. Keep the architecture at a
  beginner/intermediate level; simplicity beats cleverness.
- **Stack:** Flutter (Dart 3), Firebase. UI is **Arabic, RTL-forced**.
- **Firebase project ID:** `academia-app-7b8ef`
- **Configured platforms:** `android` and `ios` only.
  There is **no** `web/`, `windows/`, `linux/`, or `macos/` directory, and
  `lib/firebase_options.dart` has no web/desktop options. **You cannot run this
  app locally in this environment** — no emulator/device is available. Verify
  behaviour with tests, not by running the app.
- **State management:** `provider` (`ChangeNotifier` + `ChangeNotifierProvider` /
  `ChangeNotifierProxyProvider`). No Riverpod/Bloc/GetIt, no code generation.
- **Auth:** Firebase Authentication, email/password.
- **Database:** Cloud Firestore.

### Roles

Exact strings, as stored in `users/{uid}.role` and checked in
`firestore.rules`:

```
'student'   'teacher'   'admin'
```

In Dart these map to `UserRole.student | teacher | admin | unknown`
(`lib/features/auth/models/app_user_model.dart`).

**`UserRole.unknown` is a parse result, never a stored value.** The role parser
**fails closed**: any missing, empty, misspelled, or future role becomes
`unknown` and grants nothing. Do **not** reintroduce a permissive default.

Account status lives in `users/{uid}.status` — `'active'` or `'disabled'`. Rules
require `status == 'active'` for essentially everything.

---

## 3. Flutter architecture

### Established flow

```
Screen → Provider → Service → Firebase
```

**Screens never touch Firestore directly.** Services own all Firestore access;
providers own subscriptions and lifecycle; screens read provider state.

### Layout

```
lib/
  main.dart                      bootstrap: Firebase.initializeApp, MultiProvider
  firebase_options.dart          android + ios only
  app/
    akademia_app.dart            MaterialApp, RTL wrapper, named route table
    app_routes.dart              every route constant
    app_providers.dart           ALL providers registered here (order matters)
  core/
    constants/app_strings.dart   ~1500 lines; ALL user-facing Arabic
    navigation/main_navigation.dart   student bottom-nav dispatch
    services/admin_access.dart   shared "is this an active admin" check
    theme/                       app_colors, app_spacing, app_radius,
                                 app_sizes, app_text_styles, app_theme
    widgets/                     shared components (see §4)
  features/
    auth/         login, register, verification, splash, AuthProvider
    onboarding/   4-step student setup
    dashboard/    student home + TodayTasksCard
    courses/      student courses, course detail, StudentCoursesProvider
    tasks/        personal tasks + the unified «المهام والواجبات» screen
    assignments/  SHARED academic-assignment domain (all three roles)
    teacher/      teacher shell, offerings, roster, files, assignments
    admin/        admin shell + all admin screens
    files/        course files (Cloudinary binaries + Firestore metadata)
    enrollments/  enrollment service/providers
    academics/    departments + majors
    curriculum/   study-plan rows
    semesters/    semesters
    profile/      profile, study preferences, help/FAQ
    notifications/ study/ search/ shared_space/ analytics/   ← see §6
```

### Provider registration order — important

`lib/app/app_providers.dart` builds one root `MultiProvider` **above**
`MaterialApp`, so `dispose()` never runs during a session. Every provider that
opens a Firestore listener therefore **must** cancel it on logout/role change
via a `syncWithAuth(...)`-style method driven by `ChangeNotifierProxyProvider`.

`ChangeNotifierProxyProvider` dependencies must be registered **above** their
dependents. `CourseAssignmentProvider` depends on `StudentCoursesProvider` and
is deliberately registered after it. Do not reorder casually.

---

## 4. Design system — reuse it, do not invent

- Arabic, **RTL forced** app-wide in `akademia_app.dart`.
- Font: **Tajawal**.
- Constants live in `lib/core/theme/`:
  `AppColors`, `AppSpacing`, `AppRadius`, `AppSizes`, `AppTextStyles`,
  `AppTheme`.
- **All user-facing Arabic belongs in `AppStrings`.** Check for an existing
  constant before adding one — duplicate names have caused compile errors.
- Shared widgets in `lib/core/widgets/`: `app_card`, `app_status_badge`,
  `app_loading_state`, `empty_state`, `error_state`, `primary_button`,
  `secondary_button`, `app_destructive_button`, `app_menu_tile`,
  `app_text_field`, `app_top_bar`, `app_bottom_navigation`,
  `authenticated_page_scaffold`, `app_section`, `offline_banner`,
  `app_preference_switch_tile`.

### Student bottom navigation (actual)

`lib/core/widgets/app_bottom_navigation.dart`:

| Index | Constant | Label | Status |
|---|---|---|---|
| 0 | `homeIndex` | الرئيسية | working |
| 1 | `coursesIndex` | المقررات | working |
| 2 | `tasksIndex` | المهام | working (unified screen) |
| 3 | `studyIndex` | المذاكرة | **not routed** — shows "under development" |
| 4 | `profileIndex` | الملف | working |

Dispatch is `handleMainNavigation` in `lib/core/navigation/main_navigation.dart`.
It contains **hardcoded student indices** — never reuse it for teacher/admin.

**Layout rule:** every screen must survive **360 px width** with no
`RenderFlex` overflow. Use `Wrap` instead of `Row` for chip rows, and
scrollable tab bars for long Arabic labels. Tests assert this.

---

## 5. Firebase architecture

| Service | Status |
|---|---|
| Firebase Authentication (email/password) | **Implemented** |
| Cloud Firestore | **Implemented** |
| Firestore security rules | **Implemented + deployed** |
| Firebase Storage | **Configured but unused** — `firebase_storage` is in `pubspec.yaml` but has **zero usages** in `lib/`. Binaries go to Cloudinary instead. |
| Cloud Functions | **Not present.** No `functions/` directory; `firebase.json` declares only `firestore`. |
| App Check | **Not configured** (see §11) |
| Firestore indexes | `firestore.indexes.json` is `{"indexes": [], "fieldOverrides": []}` — **empty, and must stay that way** |

**Cloudinary** (not Firebase) stores course-file and profile-image binaries.
Unsigned upload presets; **no API secret in the app**, which is why the client
cannot delete Cloudinary assets — hence archive-over-delete everywhere.

### Why no indexes are needed

Every Firestore query in the app is **equality-only with no `orderBy`**;
sorting is done client-side. Multiple equality filters are served by
single-field indexes via zigzag merge join. Verified live: the
`offeringId == X AND status == 'active'` query returns HTTP 200 with no
`FAILED_PRECONDITION`. **Keep queries equality-only.**

---

## 6. Feature status — verified, not inferred

> "File exists" ≠ "feature works". The table below reflects routing and wiring
> checks, not directory listings.

### Student

| Area | Status |
|---|---|
| Auth (register/login/verify/reset) | **Complete** |
| Onboarding (4 steps) | **Complete** |
| Dashboard/home | **Complete** — includes `TodayTasksCard` merging tasks + assignments |
| Courses / course detail | **Complete** — overview, assignments tab, files tab |
| Personal tasks (CRUD) | **Complete** |
| Unified «المهام والواجبات» | **Complete** — 4 tabs: الكل / الواجبات / مهامي / مكتملة |
| Assignments (read) | **Complete** — read-only |
| Profile / study preferences / help | **Complete** |
| **Assignment details screen** | **Not started** (see §12) |
| المذاكرة (Study) tab | **Placeholder** — files exist under `lib/features/study/` but `/study` is **not a registered route**; the tab shows "under development" |
| Notifications inbox | **Placeholder** — app-bar bell intentionally inert |
| Search / shared space | **Placeholder** — code exists under `lib/features/search/`, `lib/features/shared_space/` but **no routes registered** |
| Analytics screen | ⚠️ **Displays fabricated data** (hardcoded 12 tasks / 24 hours / 85%). Reachable from Profile. Violates the no-fake-data rule. Should be removed or rebuilt. |

### Teacher — `lib/features/teacher/`

| Area | Status | File |
|---|---|---|
| Role recognition, routing, guard | **Complete** | `widgets/teacher_access_guard.dart` |
| Shell (4 tabs) | **Complete** | `screens/teacher_shell_screen.dart` |
| Dashboard (real counts) | **Complete** | `screens/teacher_dashboard_screen.dart` |
| My courses (assigned offerings) | **Complete** | `screens/teacher_courses_screen.dart` |
| Offering detail + roster | **Complete** | `screens/teacher_offering_detail_screen.dart` |
| Course files (upload/edit/archive) | **Complete** | `screens/teacher_course_files_screen.dart`, `teacher_upload_file_screen.dart` |
| Assignments list | **Complete** | `screens/teacher_assignments_screen.dart` |
| Assignment create/edit | **Complete** | `screens/teacher_add_assignment_screen.dart` |
| **Assignment details** | **Already exists** | `screens/teacher_assignment_details_screen.dart` (route `AppRoutes.teacherAssignmentDetails`) |
| Profile + logout | **Complete** | `screens/teacher_profile_screen.dart` |

⚠️ Note for §12: the **teacher** assignment-details screen already exists. The
gap is the **student** side.

### Admin — `lib/features/admin/`

| Area | Status |
|---|---|
| Role detection + `AdminAccessGuard` | **Complete** |
| Admin shell (5 tabs) | **Complete** |
| Dashboard with real counts (students, courses, files, assignments) | **Complete** |
| Departments / majors / curriculum / semesters | **Complete** |
| Course catalog | **Complete** |
| Course offerings (+ teacher assignment dropdown) | **Complete** |
| Enrollments, roster, result recording | **Complete** |
| Course files | **Complete** |
| Student list / details | **Complete** |
| **Teacher list + details + enable/disable** | **Complete** — `admin_teacher_list_screen.dart`, `admin_teacher_details_screen.dart`, `providers/admin_teacher_provider.dart`, `services/admin_teacher_service.dart`, routes `adminTeachers`, `adminTeacherDetails` |
| **Teacher account CREATION from the app** | ❌ **NOT IMPLEMENTED** — this is planned work (§13) |
| Assignment oversight (global read + archive-only moderation) | **Complete** |
| Announcements / reported posts | **Mock only** |

**Current teacher provisioning workaround:** `tool/provision_teacher/` — a
zero-dependency Node script using the Firebase Admin REST APIs via the
`firebase-tools` OAuth token. It creates the Auth user + the `users/{uid}`
document, is idempotent, and rolls back the Auth user if the Firestore write
fails. It **refuses** to convert an existing non-teacher account. Read
`tool/provision_teacher/README.md` before touching the planned in-app feature.

---

## 7. Firestore schema (real, schematic — no personal data)

```
users/{uid}                       ← doc ID IS the Firebase Auth UID
  role: 'student' | 'teacher' | 'admin'
  status: 'active' | 'disabled'
  fullName, email, emailVerified
  onboardingCompleted, onboardingStatus
  studentId?, major?, majorId?, academicLevel?   (student-only)
  photoUrl?, createdAt, updatedAt
  ── role is writable by NO client, not even admin

departments/{id}                  name, code, status
majors/{id}                       name, code, departmentId, totalLevels, status

courses/{autoId}                  ← permanent catalog; NO semester, NO instructor
  courseCode (unique business key), title, description,
  creditHours, departmentId, status, createdBy

semesters/semester_{year}_{n}     academicYear, semesterNumber,
                                  semesterName, status ('current' | ...)

courseOfferings/{courseId}_{semesterId}_{section}   ← deterministic ID
  courseId, semesterId, section, status
  teacherId?      ← OWNERSHIP. Nullable = "unowned" (legacy).
  instructorName  ← display only, free text, denormalised from the teacher
  source, createdBy, createdAt, updatedAt

enrollments/{userId}_{offeringId} ← deterministic ID
  userId, offeringId, courseId, semesterId
  attemptNumber (int ≥ 1)
  status: 'active' | 'completed' | 'removed'
  completionStatus?: 'passed'|'failed'|'incomplete', grade?
  assignedBy, assignedAt, updatedAt

curriculumCourses/{...}           study-plan rows (course OR unfilled slot)

assignments/{autoId}              ← ACADEMIC homework, teacher-authored
  offeringId    ← authoritative relationship
  courseId, semesterId            ← denormalised, verified against the offering
  title, description
  dueAt: Timestamp
  priority: 'low' | 'medium' | 'high'
  status: 'active' | 'archived'
  createdBy     ← pinned to the authoring teacher's uid
  createdAt, updatedAt

tasks/{autoId}                    ← PERSONAL productivity, student-authored
  userId        ← owner
  title, description
  enrollmentId?, offeringId?, courseId?   (optional link to a real enrolment)
  dueAt?, priority, status: 'pending'|'completed', type
  createdAt, updatedAt, completedAt?

courseFiles/{autoId}              Cloudinary metadata, offering-scoped
  offeringId, courseId, semesterId, title, category,
  fileName/Extension/mimeType/fileSize,
  cloudinaryUrl, cloudinaryPublicId, cloudinaryResourceType,
  uploadedBy, status: 'active'|'archived'

supportRequests/{autoId}          uid, fullName, email, subject, message,
                                  status: 'open'|'resolved', source

── teammate's shared-space feature (rules deployed; app code NOT on this branch)
posts/{postId}                    authorId, ...
  posts/{postId}/comments/{id}    authorId, ...
  posts/{postId}/likes/{userId}   (doc ID is the liker's uid)
postReports/{id}                  postId, courseId, reporterId, reason,
                                  status: 'pending'|'resolved'   ← LIVE ONLY
notifications/{id}                recipientId, type, isRead        ← LIVE ONLY
```

### 🔴 `/tasks` and `/assignments` are NOT the same thing

- `/tasks` — **student-created personal** productivity items. Owner = student.
- `/assignments` — **teacher-created academic** homework. Owner = teacher.

Never merge them, never duplicate assignments into tasks, never auto-create a
task when a teacher posts homework. They are combined **only** at the
presentation layer via `StudentWorkItem`
(`lib/features/tasks/models/student_work_item.dart`), which wraps one model or
the other, has **no serializer**, and never reaches Firestore.

### Live data snapshot (2026-08-20, for orientation only)

`users` 6 · `courseOfferings` 4 (only 1 has a `teacherId`) · `enrollments` 2 ·
`tasks` 1 · `assignments` 0 · `posts` 4 · `supportRequests` 1.

**`/assignments` is empty**, so student/teacher assignment lists will legitimately
show empty states until a teacher creates one. That is not a bug.

---

## 8. 🔴 The Tasks/Assignments PERMISSION_DENIED incident — do not re-investigate

**Symptoms:** `PERMISSION_DENIED — Missing or insufficient permissions` on
`/tasks` reads, `/assignments` reads, and teacher `/assignments` writes.

**Root cause — proven, single cause for all three:**
The deployed ruleset had been **replaced by a ruleset from another development
lineage**. That ruleset contained social/shared-space rules (`posts`,
`comments`, `likes`, `reports`) but **omitted `/tasks`, `/assignments`, and
`/supportRequests` entirely**, so those paths fell through to Firestore's
default-deny.

**It was NOT:** Flutter code, the data model, field-name mismatch, Firebase
Auth, networking, App Check, or missing indexes. All were checked and ruled out
with evidence:

- The exact failing operations were replayed against both rulesets using real
  production document IDs: **15/23 against the deployed ruleset** (failing
  precisely the operations that failed on device) → **23/23 after the fix**.
- Enrollment document IDs match the rule path `{uid}_{offeringId}` exactly.
- `users/{student}` had `role: 'student'`, `status: 'active'`.
- The query shapes returned **HTTP 200** live — no index required.

**The fix was a MERGE, not an overwrite.** The teammate's social blocks were
copied verbatim into the project rules, and our `/tasks`, `/assignments`,
`/supportRequests` blocks were restored. Overwriting either side would have
broken the other — `posts` had live documents.

**Verification at the time of the fix:**

```
Firestore rules tests : 280/280 PASS
Flutter tests         : 428/428 PASS
flutter analyze       : clean
```

These counts are **still accurate on the current HEAD** (re-verified
2026-08-20).

**Deployment:** the merged rules were deployed manually by the user with

```bash
firebase deploy --only firestore:rules --project academia-app-7b8ef
```

Firebase reported `rules file firestore.rules compiled successfully`,
`released rules firestore.rules to cloud.firestore`, `Deploy complete`. The user
then manually verified Tasks/Assignments work for all roles.

> ⚠️ A **further** teammate deployment has happened since. See §1 — local rules
> are now behind live again.

---

## 9. `courseFiles` delete decision — resolved

During the merge, the deployed lineage allowed **hard delete** of `courseFiles`
for admins/owning teachers, while the project rules keep archive-over-delete:

```
allow delete: if false;
```

The project behaviour was intentionally preserved. **As of 2026-08-20 both
local and deployed now agree on `allow delete: if false`** — the teammate
adopted it. The earlier divergence is closed.

Do not casually change this. Hard-deleting a course file orphans the Cloudinary
asset (the client has no API secret and cannot delete it) and destroys material
students may depend on. Archive-over-delete applies to `courses`, `departments`,
`courseFiles`, and `assignments`.

---

## 10. Testing infrastructure

### Flutter

```bash
flutter analyze
flutter test
flutter test test/<file>.dart          # focused
```

33 test files in `test/`. Notable ones:

- `course_assignment_test.dart` — assignment model + provider
- `student_work_item_test.dart` — merge/sort adapter + subscription scoping
- `tasks_screen_unified_test.dart` — the 4-tab screen (fakes **providers**)
- `tasks_screen_integration_test.dart` — same screen with **real providers**,
  fakes only the **services**; this layer exists because provider-level fakes
  once hid a real wiring bug
- `assignment_screens_test.dart` — teacher/admin assignment UI
- `teacher_workspace_test.dart`, `teacher_role_foundation_test.dart`
- `navigation_repair_test.dart` — admin dashboard counts + navigation
- `student_course_assignments_tab_test.dart`

### Firestore rules

**No Firebase Emulator Suite.** The emulator needs JDK 21 and this machine has
JDK 17. Instead the project uses the **Firebase Rules Test API**
(`firebaserules.googleapis.com/v1/projects/{project}:test`), which compiles and
evaluates a ruleset server-side. It is **read-only** — it never writes data and
never publishes a ruleset.

```bash
node tool/rules_test/suite.js       # 280/280 expected
node tool/rules_test/selftest.js    # MUST report 0/4
```

- `token.js` mints a short-lived Google token from the refresh token that
  `firebase login` already stored. **No secret lives in this repository.** If a
  call returns 401, run `firebase login` again.
- **Stateless harness:** there is no database, so every `exists()`/`get()` the
  rules perform must be mocked per test case from the `WORLD` fixture. A `DENY`
  test that forgets a mock can pass *for the wrong reason* — keep the world
  complete.
- **`selftest.js` must report `0/4`.** It runs four cases with deliberately
  wrong expectations; a suite that passes everything is only meaningful if the
  harness can fail. Run it whenever the suite changes.
- The suite **batches** requests (100 cases per call). The `:test` endpoint
  rejects oversized requests with a bare `INVALID_ARGUMENT` — this bit us at
  266 cases.
- The suite fails on **ERROR** severity only; WARNINGs are printed.

### Reading deployed rules (read-only)

There is no `firebase firestore:rules:get` command. Use the REST API:
`GET /v1/projects/{p}/releases/cloud.firestore` → `rulesetName`, then
`GET /v1/{rulesetName}`, authenticated with `tool/rules_test/token.js`.

---

## 11. Known warnings — already investigated, unrelated

```
No AppCheckProvider installed
Unknown calling package name 'com.google.android.gms'
```

These appear in the Android run log. They were **not** the cause of the
Tasks/Assignments `PERMISSION_DENIED` incident — that was proven to be rules
content (§8), reproduced deterministically against ruleset text with no App
Check involved.

This does not mean they can never matter. It means: do not chase them while
diagnosing a Firestore authorization failure, and do not add App Check merely
to silence a warning.

Also outstanding: `AdminProfileScreen` and `AppRoutes.adminDashboard` are
registered but unreachable, and `AdminProfileScreen` is the only admin screen
without `AdminAccessGuard`.

---

## 12. Git workflow

- Active branch is **`feature/teacher-role`**. Work is **not** on `main`.
- **Do not merge into `main`** unless explicitly asked.
- **Do not switch branches** during a task without being asked.
- Run `git status` before changing anything.
- Commit logical checkpoints. **Commit `firestore.rules` changes through git** —
  the incident in §8 happened because rules diverged outside version control.
- **Never deploy uncommitted or divergent rules.**
- **Do not commit, push, or deploy unless explicitly asked.** This has been the
  standing rule for the whole project.

---

## 13. Project constraints (established, non-negotiable)

1. **Inspect before rewriting.** Read the actual files; don't trust commit
   messages or memory.
2. **Reuse existing models/services/providers.** Extend, don't duplicate.
3. **No duplicate backends.** One collection, one service, one provider per
   domain. (A parallel mock Files backend was removed once already.)
4. **No Firestore access from screens.** UI → Provider → Service → Firebase.
5. **Provider only.** No new state-management package, no DI framework, no
   code generation, no new packages without justification.
6. **Role-scoped provider lifecycle.** Any provider opening a listener must
   cancel it on logout/role change via `syncWithAuth` + `ChangeNotifierProxyProvider`.
7. **Cloudinary for binaries, Firestore for metadata.** Never switch to Firebase
   Storage. Never embed a Cloudinary API secret. Never rewrite a stored
   `secure_url`.
8. **Archive over delete.**
9. **Personal tasks ≠ academic assignments.**
10. **Admin owns structure; teachers own content.** Teachers never write the
    course catalog, curriculum, semesters, or offerings. Admins never author
    assignments.
11. **Teacher access is always scoped by `courseOfferings/{id}.teacherId`** —
    never by `instructorName`, name, email, or UI state.
12. **Student access derives from enrolment** (`active` or `completed`;
    `removed` grants nothing).
13. **Unknown roles fail closed.**
14. **No fabricated data.** No fake counts/progress/analytics. Show `—` when a
    value is unknown, never `0`. `0` means "none"; `—` means "we don't know yet".
15. **Never weaken Firestore rules to make UI work** — change the query shape.
16. **Every query stays equality-only** so `firestore.indexes.json` stays empty.
17. **360 px must not overflow.** Add a viewport test for every new screen.
18. **Arabic strings live in `AppStrings`.**
19. **Diagnose → reproduce → prove → smallest fix → retest.** Do not stop when
    the error disappears; verify both the allowed and the denied paths.

---

## 14. NEXT PLANNED WORK

> Neither item below has been started. Do **not** assume any of it exists.

### A. Assignment Details

**Goal:** `assignment card → assignment details`, for student and teacher entry
points.

**Current reality (verified):**

- The **teacher** details screen **already exists**:
  `lib/features/teacher/screens/teacher_assignment_details_screen.dart`,
  route `AppRoutes.teacherAssignmentDetails`. It shows title, offering, section,
  deadline, derived state, priority, instructions, createdAt, plus Edit and
  Archive actions.
- The **student** side has **no details screen**. `AssignmentPreviewCard`
  (`lib/features/courses/widgets/student_assignment_preview_card.dart`) accepts
  an optional `onViewDetailsTap`, and **all three call sites pass nothing**, so
  the button is hidden by design. The three call sites are
  `student_course_detail_screen.dart:521` and `tasks_screen.dart:328, 399`.

So the real work is **the student read-only details screen** plus wiring
`onViewDetailsTap` at those three call sites — and reviewing whether the teacher
screen needs anything more.

**Expected behaviour:**
- **Student:** strictly read-only. No edit, archive, delete, or completion
  control. There is **no per-student completion state** anywhere in the system.
- **Teacher:** details plus only the actions the architecture and rules already
  support (edit mutable fields, archive). Never hard delete.

**Inspect first:** `CourseAssignmentModel`, `CourseAssignmentService`,
`CourseAssignmentProvider` (note its **two scopes** — `aggregate` vs
`selected`, see below), `AssignmentPreviewCard`, `AssignmentListCard`,
`app_routes.dart`, and the teacher assignment flow.

**Do not fabricate fields.** The stored fields are exactly those in §7. All
temporal state (`isOverdue`, `isDueToday`, `isDueSoon`, date labels) is
**derived at render time** and must never be persisted.

**`CourseAssignmentProvider` has two independent subscription scopes** — this
matters if you add a details screen that subscribes:

| Scope | Used by | Getters |
|---|---|---|
| **aggregate** | unified Tasks screen, dashboard, teacher assignments, admin oversight | `assignments`, `isLoading`, `errorMessage` |
| **selected** | Course Detail assignments tab (one offering, possibly historical) | `selectedAssignments`, `isLoadingSelected`, `selectedErrorMessage` |

They were split precisely because a single shared list caused one screen to
empty another. Do not re-merge them.

### B. Admin-managed Teacher Accounts

**Goal:** `Admin → Teachers → Add Teacher` → create Firebase Auth account +
matching Firestore teacher profile, **without logging the admin out**.

**🔴 Architectural decision already established — do not relitigate:**

`createUserWithEmailAndPassword()` on the default `FirebaseAuth` instance
**signs the caller into the newly created account**. An admin tapping "add
teacher" would silently become that teacher. There is no client-side way around
this. Separately, `firestore.rules` forbids **every** client — admins included —
from writing the `role` field, so the app could not finish the job even if Auth
creation worked.

Teacher creation must therefore be a **privileged backend operation**.

**Planned design (NOT implemented):**

```
Admin Flutter UI
  → callable Firebase Function
    → verify caller is authenticated
    → verify caller role == 'admin'
    → Firebase Admin SDK creates the Auth user
    → Firestore teacher profile created
    → admin remains logged in
```

**Before committing to this, inspect the current state:** there is **no
`functions/` directory** and `firebase.json` declares only `firestore`. Adding
Cloud Functions means the **Blaze plan** plus new deploy/CI surface — a real
cost for a graduation project. The existing `tool/provision_teacher/` script
already does this job safely from a terminal. Weigh a Function against keeping
the script before building anything.

**Minimum teacher `users/{uid}` document** (from the working script):

```
role: 'teacher', status: 'active', fullName, email,
emailVerified: true,
onboardingCompleted: true, onboardingStatus: 'completed',   ← BOTH REQUIRED
createdAt, updatedAt
```

`onboardingCompleted`/`onboardingStatus` are **not optional** — without them the
splash screen routes the teacher into *student* onboarding. Deliberately absent:
`studentId`, `major`, `majorId`, `academicLevel`, study preferences.

### Security requirements for teacher creation

- Client cannot choose an arbitrary privileged role.
- A student cannot promote themselves to teacher/admin.
- A teacher cannot create another teacher.
- An unauthenticated caller cannot create a teacher.
- The backend verifies `role == 'admin'` server-side.
- **Admin SDK credentials never enter Flutter.**
- **Service-account files never enter `assets/` or the repository.**
- Duplicate email handled gracefully.
- Duplicate teacher identifier handled if the schema requires uniqueness.
- Auth creation + profile creation must avoid orphan accounts: if the profile
  write fails after the Auth user is created, **delete the Auth user**. An
  orphaned account is not harmless — the fail-closed role parser rejects it at
  login with "unsupported role" and the teacher cannot fix it themselves.
- The admin must remain authenticated throughout.

---

## 15. A note on the pending implementation prompt

A detailed implementation prompt for **Assignment Details + Admin Teacher
Account Management** was prepared in an earlier context. **Do not blindly trust
its assumptions** — this project has changed underneath such prompts more than
once (see §1 and §6, where the teacher assignment-details screen already exists
and the rules have moved again).

Read this handoff, verify the specific files and Firebase state relevant to the
task, and then execute against the current source of truth.

---

## 16. Fresh-session startup checklist

```
1.  Read docs/CONTEXT_HANDOFF.md completely.
2.  Run git status and confirm feature/teacher-role.
3.  Inspect latest commits.
4.  Do not modify/deploy firestore.rules without checking existing feature blocks.
5.  Run baseline flutter analyze/tests before major work.
6.  Inspect the specific files relevant to the next feature.
7.  Verify assumptions against the actual Firebase schema where needed.
8.  Implement the smallest correct change.
9.  Run focused tests.
10. Run full regression tests.
11. Report exactly what changed and what was deployed.
```
