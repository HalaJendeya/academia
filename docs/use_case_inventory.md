# جرد حالات الاستخدام المنفَّذة فعليًا — Academia

كل سطر أدناه مُثبَت بشاشة مسجَّلة في `lib/app/akademia_app.dart` (أو تبويب داخل واجهة
مسجَّلة) **و** خدمة تقرأ من Cloud Firestore أو تكتب فيه **و** قاعدة أمان تسمح بالعملية.
ما لم تجتمع له الثلاثة فهو مستبعَد، ومذكور في القسم الأخير مع سبب الاستبعاد.

## الممثلون (Actors)

| الممثل | النوع | كيف تحقّقنا منه |
|---|---|---|
| **مستخدم النظام** (مجرَّد) | ممثل بشري — أب تعميم | الأدوار الثلاثة تشترك في الدخول والخروج واستعادة كلمة المرور (`AuthService`، `login_screen`، `forgot_password_screen`). |
| **الطالب** | ممثل بشري | `role == 'student'`؛ قاعدة `users` تفرض `role == 'student'` على كل تسجيل ذاتي. |
| **عضو هيئة التدريس** | ممثل بشري | `role == 'teacher'`؛ `isActiveTeacher()` + `teacherOwnsOffering()` في `firestore.rules`؛ واجهة `teacher_shell_screen`. |
| **المشرف** | ممثل بشري | `role == 'admin'`؛ `isActiveAdmin()`؛ واجهة `admin_shell_screen`. |
| Firebase Authentication | **خدمة خارجية** — ممثل مساعد | تُصدر الـ UID وترسل رسائل التأكيد واستعادة كلمة المرور مباشرةً إلى المستخدم. |
| Cloudinary | **خدمة خارجية** — ممثل مساعد | `cloudinary_upload_service.dart`؛ الملف يُخزَّن خارج Firebase. |
| Firebase Cloud Messaging | **خدمة خارجية** — ممثل مساعد | `fcm_gateway.dart`؛ تسليم الرسائل إلى الجهاز. |
| Cloud Firestore | **ليست ممثلًا** | هي قاعدة بيانات النظام نفسه، لا طرف خارجي يتفاعل معه؛ ولذلك لا تظهر في المخطط. |

> لا يوجد ممثل رابع بشري. لا يملك النظام دور «ولي أمر» ولا «مسؤول قسم» ولا «زائر»:
> كل مسار في `akademia_app.dart` ينتهي إلى إحدى الواجهات الثلاث أو يعود إلى شاشة الدخول.

---

## الطالب

| حالة الاستخدام | الدليل في المستودع |
|---|---|
| إنشاء حساب جديد | `register_screen.dart` → `AuthService.createStudentProfile` → `users` (قاعدة create تفرض الدور والحالة) |
| تأكيد البريد الإلكتروني | `student_verification_screen.dart`، `emailVerifiedMatchesToken()` في القواعد |
| تسجيل الدخول والخروج | `login_screen.dart`، `AuthService.signOut` عبر `sign_out_sequence.dart` |
| استعادة كلمة المرور | `forgot_password_screen.dart`، `reset_password_screen.dart` |
| ضبط التفضيلات الأولية | `onboarding/` (أيام المذاكرة، مدة الجلسة، تفضيلات الإشعارات) → `OnboardingService` |
| عرض وتعديل الملف الشخصي | `profile_screen.dart`، `edit_profile_screen.dart` → `ProfileService` |
| إدارة عناوين البريد | `email_settings_screen.dart` → `EmailSettingsProvider`؛ قاعدتا `secondaryEmailEdit()` و`primaryEmailSwap()` |
| ضبط تفضيلات المذاكرة | `study_preferences_screen.dart` → `StudyPreferencesService` |
| إرسال طلب دعم | `help_faq_screen.dart` → `SupportService.submitSupportRequest` → `supportRequests` |
| عرض المساقات المسجَّلة | `student_courses_screen.dart` → `EnrollmentService.watchMyEnrollments` |
| عرض تفاصيل المساق | `student_course_detail_screen.dart` (تبويبات: واجبات، ملفات، ساحة المشاركة) |
| عرض سجل المساقات السابقة | `student_courses_archive_screen.dart` |
| تصفح ملفات المساق ومعاينتها | `student_all_files_screen.dart`، `student_file_preview_screen.dart` → `CourseFileService` + Cloudinary |
| عرض الشاشة الموحّدة للمهام والواجبات | `tasks_screen.dart` + `student_work_item.dart` |
| عرض تفاصيل واجب أكاديمي | `student_assignment_details_screen.dart` → `CourseAssignmentService` |
| تعليم الواجب كمنجَز | `AssignmentProgressService.setCompleted` → `assignmentProgress` |
| إنشاء/تعديل/حذف/إنجاز مهمة شخصية | `create_edit_task_screen.dart`، `task_detail_screen.dart` → `TaskService` → `tasks` |
| إنشاء جلسة مذاكرة | `create_study_session_screen.dart` → `StudySessionService` |
| تنفيذ الجلسة الجارية وحفظ نتيجتها | `active_session_screen.dart`، `session_complete_screen.dart` |
| عرض سجل الجلسات | `session_history_screen.dart` |
| عرض الملخص الأسبوعي | `weekly_summary_screen.dart` |
| عرض لوحة التحليلات | `analytics_screen.dart` |
| عرض منشورات المساق | `shared_space_screen.dart` → `PostService.watchPostsForCourse` |
| نشر منشور (مع إرفاق ملف اختياريًا) | `create_post_screen.dart` → `posts` + `PostAttachment` |
| التعليق على منشور | `post_details_screen.dart` → `posts/{postId}/comments` |
| الإعجاب بمنشور وإلغاؤه | `PostService.toggleLike` → `posts/{postId}/likes/{uid}` داخل معاملة |
| الإبلاغ عن منشور | `report_post_sheet.dart` → `postReports` |
| عرض مركز الإشعارات وتعليمها مقروءة | `notifications_screen.dart` → `NotificationService` → `notifications` |
| ضبط تفضيلات الإشعارات | `notification_settings_screen.dart` → `users/{uid}.notificationPreferences` |

**31 حالة استخدام.**

---

## عضو هيئة التدريس

كل عملية أدناه مقيَّدة بشرط `courseOfferings/{id}.teacherId == request.auth.uid`.

| حالة الاستخدام | الدليل في المستودع |
|---|---|
| تسجيل الدخول والخروج | مشترك عبر `AuthService`؛ التوجيه بحسب الدور في `splash_screen` |
| استعادة كلمة المرور | مشترك |
| عرض لوحة المؤشرات | `teacher_dashboard_screen.dart` (أعداد محسوبة من بياناته) |
| عرض الطروحات المسندة إليّ | `teacher_courses_screen.dart` → `CourseOfferingService` |
| عرض تفاصيل الطرح وقائمة الطلبة المسجّلين | `teacher_offering_detail_screen.dart` → `EnrollmentService` + قاعدة `get` على مستند الطالب |
| عرض قائمة الواجبات | `teacher_assignments_screen.dart` |
| إنشاء واجب أكاديمي | `teacher_add_assignment_screen.dart` → `assignments` (قاعدة create: `teacherOwnsOffering` + `matchesOffering` + تثبيت `createdBy`) |
| تعديل واجب | الشاشة نفسها بحجّة الواجب |
| عرض تفاصيل الواجب | `teacher_assignment_details_screen.dart` |
| أرشفة واجب | `CourseAssignmentService` (الأرشفة بدل الحذف — قاعدة delete مغلقة) |
| رفع ملف للطرح | `teacher_upload_file_screen.dart` → Cloudinary ثم `courseFiles` |
| تعديل بيانات ملف وأرشفته | `teacher_course_files_screen.dart` |
| عرض الملف الشخصي | `teacher_profile_screen.dart` — **عرض فقط**، لا تعديل |

**13 حالة استخدام.**

---

## المشرف

| حالة الاستخدام | الدليل في المستودع |
|---|---|
| تسجيل الدخول والخروج، استعادة كلمة المرور | مشترك |
| عرض مؤشرات النظام | `admin_dashboard_screen.dart` |
| إدارة الأقسام | `admin_department_list/form_screen.dart` → `departments` |
| إدارة التخصصات | `admin_major_list/form_screen.dart` → `majors` |
| إدارة الخطة الدراسية | `admin_curriculum_screen.dart`، `admin_curriculum_entry_form_screen.dart` → `curriculumCourses` |
| إدارة الفصول الدراسية | `admin_semester_list/form_screen.dart` → `semesters` |
| إدارة كتالوج المساقات | `admin_course_list/form/details_screen.dart` → `courses` |
| إدارة الطروحات وإسناد عضو هيئة تدريس | `admin_offering_list/form_screen.dart` → `courseOfferings.teacherId` |
| تسجيل الطلبة في الطروحات | `admin_assign_courses_screen.dart` → `enrollments` |
| عرض قوائم التسجيل ورصد النتائج | `admin_offering_roster_screen.dart` |
| عرض قائمة الطلبة وتفاصيلهم | `admin_student_list/details_screen.dart` |
| إدارة حسابات أعضاء هيئة التدريس (تفعيل/تعطيل) | `admin_teacher_list/details_screen.dart` → `users.status` فقط |
| إدارة ملفات المساقات | `admin_course_files_screen.dart`، `admin_upload_file_screen.dart` |
| الإشراف على الواجبات وأرشفتها | `admin_assignment_list/details_screen.dart` — أرشفة فقط، **لا إنشاء** |
| مراجعة بلاغات المنشورات | `admin_reported_posts_screen.dart` → `postReports` (أرشفة المنشور أو تجاهل البلاغ) |
| مراجعة طلبات الدعم | `admin_support_requests_screen.dart` → `supportRequests` |
| عرض الملف الشخصي | `admin_profile_screen.dart` — عرض فقط |

**17 حالة استخدام.**

> **قيدان يستحقّان الذكر في المناقشة:** المشرف **لا يستطيع** تعديل حقل الدور `role` —
> القاعدة تمنع كل العملاء منه — و**لا يستطيع** كتابة `fcmToken` لمستخدم آخر. وهو
> كذلك **لا يؤلّف** محتوى أكاديميًا: إنشاء الواجبات مقصور على عضو هيئة التدريس المالك
> للطرح، والقاعدة تمنع المشرف بالإغفال المتعمَّد.

---

## ما استُبعد من المخطط، ولماذا

| الميزة | الحالة في المستودع | القرار |
|---|---|---|
| المساعد الأكاديمي الذكي | `smart_assistant_screen.dart` ملف فارغ (سطر واحد)، لا مزوّد ولا خدمة | **مستبعدة** — لا وجود لها في الإصدار |
| توليد خطة المذاكرة | `study_plan_screen.dart` منفَّذة كنموذج إدخال، والتوليد **معطَّل عمدًا** وموثَّق في الملف؛ `generate_plan_screen.dart` فارغ | **مستبعدة** — النموذج حقيقي والوظيفة غير موجودة |
| البحث الشامل | `search_screen.dart` وكل ودجات `search/` ملفات فارغة | **مستبعدة** |
| التقويم الدراسي | `calendar_screen.dart` و`calendar_day_cell.dart` فارغان، ولا مسار مسجَّل | **مستبعدة** |
| جدول الدراسة | لا شاشة ولا خدمة | **مستبعدة** |
| إدارة الإعلانات | `admin_announcements_screen.dart` واجهة فقط بقائمة فارغة ثابتة، ولا مجموعة `announcements` في القواعد ولا في الكود | **مستبعدة** — واجهة بلا قاعدة بيانات |
| مزامنة Moodle | لا كود، حقول `source`/`externalId` مهيّأة فقط | **مستبعدة** |
| إشعارات الدفع التلقائية | البنية مهيّأة ومختبَرة يدويًا، ولا Cloud Functions منشورة (خطة Spark) | **مستبعدة كحالة استخدام تلقائية**، ومذكورة كقدرة مهيّأة |
| تعديل الملف الشخصي لعضو هيئة التدريس والمشرف | القواعد تسمح، ولا مدخل في الواجهة | **مستبعدة** — لا مسار مستخدم |
| مشاركة عضو هيئة التدريس في المساحة التشاركية | القواعد تسمح، ولا مدخل في واجهته | **مستبعدة** — لا مسار مستخدم |

بالإضافة إلى ملفات فارغة أخرى لا تمثّل ميزات: `app_settings_screen.dart`،
`tasks/calendar_screen.dart`، `tasks/create_task_screen.dart`، `tasks/edit_task_screen.dart`،
`tasks/task_details_screen.dart`، `tasks/assignment_details_screen.dart`،
`study/study_sessions_screen.dart`، `onboarding/notification_preferences_screen.dart` —
وكلها بقايا هيكلة أولى استُبدلت بشاشات مسجَّلة فعلًا في جدول المسارات.
