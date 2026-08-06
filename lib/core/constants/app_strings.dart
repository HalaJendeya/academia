abstract final class AppStrings {
  AppStrings._();

  static const String appName = 'أكاديميا';
  static const String splashSubtitle = 'رفيقك الذكي لتنظيم الدراسة';

  // Login & Register Screen Strings
  static const String loginTitle = 'تسجيل الدخول';
  static const String loginSubtitle =
      'مرحباً بعودتك، تابع تنظيم يومك الدراسي بسهولة';
  static const String emailLabel = 'البريد الجامعي';
  static const String emailHint = 'أدخل بريدك الجامعي';
  static const String emailHintUniversity = 'example@university.edu';
  static const String passwordLabel = 'كلمة المرور';
  static const String passwordHint = '************';
  static const String forgotPassword = 'نسيت كلمة المرور؟';
  static const String loginErrorInvalid =
      'البريد الإلكتروني أو كلمة المرور غير صحيحة';
  static const String noAccount = 'لا تملك حساباً؟ ';
  static const String createAccount = 'إنشاء حساب';

  // Registration Strings
  static const String registerSubtitle =
      'مرحباً بك! قم بإنشاء حسابك للبدء في رحلتك التعليمية';
  static const String fullNameLabel = 'الاسم الكامل';
  static const String fullNameHint = 'أدخل اسمك الثلاثي';
  static const String studentIdLabel = 'الرقم الجامعي';
  static const String studentIdHint = 'مثال: 20241234';
  static const String confirmPasswordLabel = 'تأكيد كلمة المرور';
  static const String confirmPasswordHint = 'أعد إدخال كلمة المرور';
  static const String termsText = 'بالنقر على إنشاء حساب، أنت توافق على ';
  static const String termsLink = 'شروط الخدمة';
  static const String hasAccountText = 'لديك حساب بالفعل؟ ';

  // Forgot Password Screen Strings
  static const String forgotPasswordTitle = 'استعادة كلمة المرور';
  static const String forgotPasswordHeading = 'نسيت كلمة المرور؟';
  static const String forgotPasswordSubtitle =
      'أدخل بريدك الإلكتروني الجامعي وسنرسل لك رابطاً لإعادة تعيين كلمة المرور.';
  static const String sendRecoveryLink = 'إرسال رابط الاستعادة';
  static const String backToLogin = 'العودة لتسجيل الدخول';

  // Validation & Auth Errors (Arabic)
  static const String errorNameRequired = 'الاسم الكامل مطلوب';
  static const String errorStudentIdRequired = 'الرقم الجامعي مطلوب';
  static const String errorEmailRequired = 'البريد الجامعي مطلوب';
  static const String errorInvalidEmail = 'صيغة البريد الجامعي غير صحيحة';
  static const String errorPasswordRequired = 'كلمة المرور مطلوبة';
  static const String errorPasswordTooShort =
      'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
  static const String errorConfirmPasswordRequired = 'تأكيد كلمة المرور مطلوب';
  static const String errorPasswordMismatch = 'كلمة المرور غير متطابقة';
  static const String errorEmailAlreadyInUse =
      'البريد الجامعي مستخدم بالفعل لحساب آخر';
  static const String errorWeakPassword = 'كلمة المرور ضعيفة جداً';
  static const String errorUserNotFound = 'لا يوجد حساب بهذه البيانات';
  static const String errorNetwork = 'لا يوجد اتصال بالإنترنت';
  static const String errorUnknown = 'حدث خطأ، حاول مرة أخرى';

  // Student Verification Screen Strings
  static const String verificationTitle = 'التحقق من الطالب';
  static const String verificationHeader = 'رابط التحقق الأكاديمي';
  static const String verificationSubtitle =
      'لقد أرسلنا رابط تأكيد الحساب إلى بريدك الإلكتروني الجامعي التالي. يرجى مراجعة صندوق الوارد والضغط على الرابط لتفعيل حسابك.';
  static const String verificationInstruction =
      'اضغط على رابط التفعيل في بريدك الإلكتروني ثم تحقق أدناه.';
  static const String verifyButton = 'تحقق';
  static const String openEmailSim = 'افتح البريد الإلكتروني (محاكاة)';
  static const String resendButton = 'إعادة إرسال الرابط';
  static const String verificationFooter =
      'إذا كنت تواجه مشكلة في الوصول إلى بريدك الجامعي، يرجى التواصل مع الدعم الفني بالجامعة.';
  static const String verificationSuccess =
      'تم تفعيل حسابك الجامعي بنجاح. يمكنك الآن تسجيل الدخول.';
  static const String verificationErrorNotVerified =
      'البريد الإلكتروني لم يتم تفعيله بعد. يرجى التحقق من صندوق الوارد والضغط على الرابط المرسل.';
  static const String verificationTimerLockout = 'تجاوزت الحد. يرجى الانتظار';
  static const String verificationTimerMinutes = 'دقيقة';
  static const String verificationTimerResendIn =
      'لم يصلك الرابط؟ يمكنك إعادة الإرسال بعد';
  static const String verificationTimerSeconds = 'ثانية';
  static const String verificationTimerCanResend =
      'يمكنك إعادة إرسال رابط التأكيد الآن';
  static const String verificationLockoutMessage =
      'لقد تجاوزت الحد الأقصى للمحاولات. يرجى الانتظار لمدة ساعة.';
  static const String verificationResendSuccess =
      'تم إعادة إرسال رابط التأكيد إلى';

  // Mock Inbox Strings
  static const String inboxTitle = 'صندوق الوارد (Inbox)';
  static const String inboxSenderName = 'أكاديميا (Academia)';
  static const String inboxTimeNow = 'الآن';
  static const String inboxEmailSubject = 'تأكيد البريد الإلكتروني لحسابك';
  static const String inboxEmailSnippet =
      'مرحباً بك! اضغط هنا لتأكيد حسابك وتفعيله...';
  static const String inboxBackToInbox = 'العودة إلى صندوق الوارد';
  static const String inboxFromLabel = 'من: ';
  static const String inboxFromEmail = 'no-reply@academia.com';
  static const String inboxEmailSalutation =
      'مرحباً بك في أكاديميا، رفيقك الذكي لتنظيم الدراسة.';
  static const String inboxEmailBody =
      'لتفعيل حسابك والبدء في استخدام التطبيق، يرجى الضغط على رابط التأكيد أدناه لتفعيل حسابك الجامعي:';
  static const String inboxVerifyButton = 'تأكيد الحساب (Verify Account)';

  // Welcome Screen Strings
  static const String welcomeHeading = 'نظّم دراستك بذكاء';
  static const String welcomeSubtitleText =
      'تابع مساقاتك، مهامك، وجلساتك الدراسية في مكان واحد';
  static const String welcomeAlreadyHaveAccount = 'لدي حساب بالفعل';
  static const String welcomeFootnote =
      'صُمم لمساعدتك على إدارة يومك الدراسي بسهولة';

  // Dashboard Screen Strings
  static const String dashboardTitle = 'شاشة الرئيسية (Dashboard)';

  // Reset Password Screen Strings
  static const String resetPasswordTitle = 'اعادة تعيين كلمة المرور';
  static const String resetPasswordHeading = 'تعيين كلمة مرور جديدة';
  static const String resetPasswordSubtitle =
      'يرجى إدخال كلمة المرور الجديدة وتأكيدها لتتمكن من الدخول إلى حسابك';
  static const String newPasswordLabel = 'كلمة المرور الجديدة';
  static const String newPasswordHint = 'أدخل كلمة المرور الجديدة';
  static const String confirmNewPasswordLabel = 'تأكيد كلمة المرور الجديدة';
  static const String confirmNewPasswordHint = 'أعد إدخال كلمة المرور';
  static const String passwordLengthNotice =
      'يجب أن تحتوي كلمة المرور على 8 أحرف على الأقل';
  static const String savePasswordButton = 'حفظ كلمة المرور';
  static const String successDialogTitle = 'تم تغيير كلمة المرور';
  static const String successDialogBody =
      'تم حفظ كلمة المرور الجديدة بنجاح. يمكنك الآن تسجيل الدخول باستخدام كلمة المرور الجديدة.';
  static const String errorPasswordTooShort8 =
      'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
  static const String resetPasswordResendSuccess =
      'تم إرسال رابط استعادة كلمة المرور إلى بريدك الإلكتروني بنجاح.';

  // Onboarding Screen Strings
  static const String onboardingWelcomeTitle = 'لنجهز مساحتك الدراسية';
  static const String onboardingWelcomeDescription =
      'سنساعدك في إعداد أيام دراستك، وتحديد مدة جلساتك، وتخصيص تفضيلات الإشعار، لضمان أفضل تجربة تعليمية مخصصة لك.';
  static const String startSetup = 'ابدأ الإعداد';
  static const String skipForNow = 'تخطي مؤقتًا';
  static const String studyDaysTitle = 'أيام الدراسة';
  static const String studyDaysDescription =
      'حدد الأيام التي تدرس فيها عادة لتنظيم جدولك';
  static const String saturday = 'السبت';
  static const String sunday = 'الأحد';
  static const String monday = 'الاثنين';
  static const String tuesday = 'الثلاثاء';
  static const String wednesday = 'الأربعاء';
  static const String thursday = 'الخميس';
  static const String friday = 'الجمعة';
  static const String selectAtLeastOneStudyDay = 'اختر يومًا واحدًا على الأقل';
  static const String studySessionPreferencesTitle = 'تفضيلات جلسة دراسة';
  static const String studySessionDurationTitle = 'مدة الجلسة الدراسية';
  static const String studySessionDurationDescription =
      'اختر المدة المفضلة لجلسات دراستك لاستخدامها في مؤقت التركيز.';
  static const String minutes = 'دقيقة';
  static const String customDuration = 'مدة مخصصة';
  static const String customDurationTitle = 'مدة مخصصة';
  static const String invalidCustomDuration = 'أدخل مدة صحيحة بين 5 و180 دقيقة';
  static const String confirm = 'تأكيد';
  static const String cancel = 'إلغاء';
  static const String notificationPreferencesTitle = 'تفضيلات الإشعارات';
  static const String notificationPreferencesDescription =
      'اختر التنبيهات التي ترغب في استقبالها للبقاء على اطلاع بآخر المستجدات الأكاديمية.';
  static const String taskRemindersTitle = 'تذكير بالمهام';
  static const String taskRemindersDescription =
      'تنبيهات قبل مواعيد تسليم الواجبات';
  static const String studySessionRemindersTitle = 'تذكير بالجلسات الدراسية';
  static const String studySessionRemindersDescription =
      'إشعارات لمواعيد الدراسة والجلسات';
  static const String deadlineRemindersTitle = 'مواعيد التسليم';
  static const String deadlineRemindersDescription =
      'تنبيهات للمشاريع والواجبات والامتحانات';
  static const String dailySummaryTitle = 'ملخص يومي';
  static const String dailySummaryDescription = 'إشعار واحد يلخص نشاطك اليومي';
  static const String courseNotificationsTitle = 'تنبيهات المساقات';
  static const String courseNotificationsDescription =
      'تحديثات وإعلانات من مساقاتك';
  static const String savePreferences = 'حفظ التفضيلات';
  static const String setupCompleteTitle = 'تم تجهيز مساحتك الدراسية';
  static const String setupCompleteDescription =
      'يمكنك الآن متابعة مساقاتك ومهامك بكل سهولة';
  static const String goToDashboard = 'الانتقال إلى الرئيسية';
  static const String next = 'التالي';
  static const String back = 'رجوع';

  static const String onboardingSaveError = 'تعذر حفظ إعداداتك، حاول مرة أخرى';
  static const String onboardingSkipError =
      'تعذر تخطي الإعداد الآن، حاول مرة أخرى';
  static const String onboardingStatusError =
      'تعذر التحقق من حالة إعداد الحساب';
  static const String authenticationRequired = 'يرجى تسجيل الدخول مرة أخرى';

  static const String homeTab = 'الرئيسية';
  static const String coursesTab = 'المقررات';
  static const String tasksTab = 'المهام';
  static const String studyTab = 'المذاكرة';
  static const String profileTab = 'الملف';
  static const String screenUnderDevelopment = 'هذه الشاشة قيد التطوير';
  static const String retry = 'إعادة المحاولة';
  static const String search = 'بحث';
  static const String notifications = 'الإشعارات';
  static const String profile = 'الملف الشخصي';
  static const String profileTitle = 'الملف الشخصي';
  static const String mockProfileName = 'أحمد محمود';
  static const String mockProfileEmail = 'ahmed.m@university.edu';
  static const String notificationSettingsTitle = 'إعدادات الإشعارات';
  static const String notificationSettingsSubtitle =
      'تنبيهات المحاضرات، الواجبات، والرسائل';
  static const String studyPreferencesTitle = 'تفضيلات الدراسة';
  static const String studyPreferencesSubtitle =
      'طرق العرض، المؤقتات، وأهداف المذاكرة';
  static const String analyticsDashboardTitle = 'لوحة التحليلات';
  static const String analyticsDashboardSubtitle =
      'إدارة الملفات المحملة والبيانات المؤقتة';
  static const String helpSupportTitle = 'المساعدة والدعم الفني';
  static const String helpSupportSubtitle =
      'الحصول على المساعدة والإبلاغ عن مشاكل';
  static const String aboutAppTitle = 'عن التطبيق';
  static const String aboutAppSubtitle = 'الإصدار، الشروط، وسياسة الخصوصية';
  static const String appVersionLabel = 'v2.1.0';
  static const String logout = 'تسجيل الخروج';
  static const String logoutConfirmation = 'هل تريد تسجيل الخروج من حسابك؟';
  static const String logoutConfirmAction = 'خروج';
  static const String logoutLogicComingSoon = 'سيتم ربط تسجيل الخروج لاحقًا';
  static const String editProfileTooltip = 'تعديل الملف الشخصي';

  static const String editProfileTitle = 'تعديل الملف الشخصي';
  static const String universityEmailLabel = 'البريد الجامعي';
  static const String majorLabel = 'التخصص';
  static const String academicLevelLabel = 'المستوى الأكاديمي';
  static const String studentIdReadOnlyHint =
      'لا يمكن تعديل الرقم الجامعي من هنا';
  static const String emailReadOnlyHint = 'لا يمكن تغيير البريد الجامعي من هنا';
  static const String changeProfilePicture = 'تغيير الصورة الشخصية';
  static const String profileImageComingSoon =
      'سيتم إضافة اختيار الصورة لاحقًا';
  static const String saveChanges = 'حفظ التغييرات';
  static const String profileUpdatedSuccessfully =
      'تم تحديث الملف الشخصي بنجاح';
  static const String profileLoadError = 'تعذر تحميل بيانات الملف الشخصي';
  static const String profileUpdateError =
      'تعذر تحديث الملف الشخصي، حاول مرة أخرى';
  static const String profileNotFound = 'لم يتم العثور على بيانات الملف الشخصي';
  static const String fullNameRequired = 'يرجى إدخال الاسم الكامل';
  static const String fullNameTooShort =
      'يجب أن يتكون الاسم من حرفين على الأقل';
  static const String profileNameUnavailable = 'الاسم غير متوفر';
  static const String profileEmailUnavailable = 'البريد غير متوفر';

  static const String uploadingProfileImage = 'جاري رفع الصورة الشخصية...';
  static const String profileImageUpdatedSuccessfully =
      'تم تحديث الصورة الشخصية بنجاح';
  static const String profileImageUploadError = 'تعذر رفع الصورة الشخصية';
  static const String profileImageUploadErrorDetails =
      'تعذر رفع الصورة الشخصية، حاول مرة أخرى';
  static const String profileImagePickOrUploadError =
      'تعذر اختيار أو رفع الصورة الشخصية';
  static const String loadingProfileData = 'جاري تحميل بيانات الملف الشخصي...';
  static const String studentAvatarSemantics = 'الصورة الشخصية للطالب';
  static const String invalidFileType = 'نوع ملف غير صالح';

  static const List<String> majorsList = [
    'هندسة البرمجيات',
    'علوم الحاسوب',
    'نظم المعلومات',
    'الأمن السيبراني',
    'هندسة الحاسوب',
  ];

  static const List<String> academicLevelsList = [
    'المستوى ١',
    'المستوى ٢',
    'المستوى ٣',
    'المستوى ٤',
    'المستوى ٥',
  ];

  static const String profileImageUpdatedLocally =
      'تم تحديث الصورة مؤقتًا على هذا الجهاز';
  static const String profileImageTemporaryNote =
      '* تم حفظ الصورة مؤقتًا على هذا الجهاز ولن تستمر بعد إعادة تشغيل التطبيق';

  static const String notificationSettingsHeroTitle =
      'تحكم في تنبيهاتك الدراسية';
  static const String generalNotificationsTitle = 'التنبيهات العامة';
  static const String assignmentRemindersTitle = 'تذكير الواجبات';
  static const String assignmentRemindersDescription =
      'تذكيرك بالواجبات قبل موعد التسليم';
  static const String lectureRemindersTitle = 'تذكير قبل المحاضرة';
  static const String lectureRemindersDescription = 'إشعار قبل بدء المحاضرة';
  static const String studySessionRemindersSettingsTitle =
      'تذكير جلسات الدراسة';
  static const String studySessionRemindersSettingsDescription =
      'تنبيهك بموعد جلسات المذاكرة';
  static const String fileNotificationsTitle = 'تنبيهات الملفات';
  static const String fileNotificationsDescription =
      'إشعارات عند توفر ملفات جديدة';
  static const String sharedSpaceNotificationsTitle =
      'تنبيهات المساحة المشتركة';
  static const String sharedSpaceNotificationsDescription =
      'تنبيهات المنشورات والتحديثات المشتركة';
  static const String dailySummarySettingsTitle = 'الملخص اليومي';
  static const String dailySummarySettingsDescription =
      'ملخص يومي لأهم مهامك ونشاطك';
  static const String quietHoursTitle = 'أوقات الهدوء';
  static const String quietHoursDescription =
      'سيتم كتم صوت الإشعارات خلال هذه الفترة لضمان تركيزك أو راحتك';
  static const String fromLabel = 'من';
  static const String toLabel = 'إلى';
  static const String saveNotificationSettings = 'حفظ الإعدادات';
  static const String notificationSettingsSavedTemporarily =
      'تم حفظ إعدادات الإشعارات مؤقتًا';

  static const String notificationSettingsLoadError =
      'تعذر تحميل إعدادات الإشعارات';
  static const String notificationSettingsSaveError =
      'تعذر حفظ إعدادات الإشعارات، حاول مرة أخرى';
  static const String notificationSettingsSavedSuccessfully =
      'تم حفظ إعدادات الإشعارات بنجاح';
  static const String notificationSettingsNotAvailable =
      'إعدادات الإشعارات غير متوفرة';

  static const String studyDaysSectionDescription =
      'حدد الأيام التي تدرس فيها عادة';
  static const String studySessionDurationSectionTitle = 'مدة جلسة الدراسة';
  static const String studySessionDurationSectionDescription =
      'اختر المدة الافتراضية لجلسات المذاكرة';
  static const String studyPreferencesInfo =
      'سيتم استخدام هذه الإعدادات كتفضيلات افتراضية داخل مؤقت الدراسة والجدول الدراسي.';
  static const String saveStudyPreferences = 'حفظ التفضيلات';

  static const String studyPreferencesLoadError = 'تعذر تحميل تفضيلات الدراسة';
  static const String studyPreferencesSaveError =
      'تعذر حفظ تفضيلات الدراسة، حاول مرة أخرى';
  static const String studyPreferencesSavedSuccessfully =
      'تم حفظ تفضيلات الدراسة بنجاح';
  static const String studyPreferencesNotAvailable =
      'تفضيلات الدراسة غير متوفرة';

  static const String analyticsDashboardDescription =
      'نظرة عامة على تقدمك الدراسي وأدائك';
  static const String completedTasksTitle = 'المهام المكتملة';
  static const String weeklyTasksIncrease = '+3 هذا الأسبوع';
  static const String studyHoursTitle = 'ساعات الدراسة';
  static const String studyHoursGoal = 'الهدف: 30 س';
  static const String commitmentRateTitle = 'نسبة الالتزام';
  static const String mostStudiedCourseTitle = 'أكثر مساق تمت دراسته';
  static const String mostStudiedCourseMockName = 'هندسة البرمجيات';

  static const String helpSupportScreenTitle = 'الدعم والمساعدة';
  static const String helpSupportHeroTitle = 'كيف يمكننا مساعدتك اليوم؟';
  static const String faqTitle = 'الأسئلة الشائعة';
  static const String contactSupportTitle = 'تواصل مباشرة مع الدعم';
  static const String contactSupportDescription =
      'فريقنا متاح لمساعدتك على مدار الساعة';
  static const String feedbackSubject = 'موضوع الملاحظة';
  static const String feedbackSubjectHint = 'مثال: مشكلة في تسجيل الدخول';
  static const String feedbackDetails = 'التفاصيل';
  static const String feedbackDetailsHint = 'اشرح لنا ما تواجهه...';
  static const String sendFeedback = 'إرسال الملاحظة';

  static const String supportRequestSuccess = 'تم إرسال ملاحظتك بنجاح';
  static const String supportRequestError = 'تعذر إرسال ملاحظتك، حاول مرة أخرى';
  static const String supportRequestSubjectRequired =
      'يرجى إدخال موضوع الملاحظة';
  static const String supportRequestSubjectTooShort =
      'يجب أن يتكون الموضوع من 3 أحرف على الأقل';
  static const String supportRequestSubjectTooLong =
      'يجب ألا يتجاوز الموضوع 120 حرفًا';
  static const String supportRequestMessageRequired =
      'يرجى إدخال تفاصيل الملاحظة';
  static const String supportRequestMessageTooShort =
      'يجب أن تتكون التفاصيل من 10 أحرف على الأقل';
  static const String supportRequestMessageTooLong =
      'يجب ألا تتجاوز التفاصيل 2000 حرف';

  static const String faqQuestion1 = 'كيف أضيف مهمة جديدة؟';
  static const String faqAnswer1 =
      'يمكنك إضافة مهمة جديدة من شاشة المهام عبر الضغط على زر الإضافة ثم تعبئة بيانات المهمة.';
  static const String faqQuestion2 = 'كيف أحمل ملفًا بدون إنترنت؟';
  static const String faqAnswer2 =
      'الملفات التي تم تنزيلها مسبقًا يمكن الوصول إليها بدون اتصال بالإنترنت.';
  static const String faqQuestion3 = 'هل يمكنني تغيير لغة التطبيق؟';
  static const String faqAnswer3 =
      'سيتم دعم تغيير اللغة في إصدار مستقبلي من التطبيق.';


  // lib/core/constants/app_strings.dart

// lib/core/constants/app_strings.dart

// lib/core/constants/app_strings.dart

  // lib/core/constants/app_strings.dart

  // Courses feature
  static const String courseProgressLabel = 'نسبة الإنجاز';
  static const String continueCourseAction = 'متابعة المساق';
  static const String activeCoursesFilter = 'نشط';
  static const String archivedCoursesFilter = 'مؤرشف';
  static const String myCoursesTitle = 'مقرراتي الدراسية';
  static const String courseSearchHint = 'ابحث عن مساق...';
  static const String coursesFilesButtonLabel = 'الملفات';
  static const String noCoursesFoundMessage = 'لا توجد مقررات لعرضها';
  static const String coursesLoadError = 'تعذر تحميل المقررات الدراسية';
  static const String courseDetailLoadError = 'تعذر تحميل بيانات المقرر';
  static const String courseAssignmentsLoadError = 'تعذر تحميل واجبات المقرر';
  static const String courseFilesLoadError = 'تعذر تحميل ملفات المقرر';
  static const String viewDetailsAction = 'عرض التفاصيل';
  static const String newFileBadgeLabel = 'جديد';
  static const String courseDetailAppBarTitle = 'المساقات';
  static const String courseOverviewTab = 'نظرة عامة';
  static const String courseAssignmentsTab = 'الواجبات';
  static const String courseFilesTab = 'الملفات';
  static const String courseSharedSpaceTab = 'المساحة';
  static const String noAssignmentsFoundMessage = 'لا توجد واجبات لعرضها';
  static const String noFilesFoundMessage = 'لا توجد ملفات لعرضها';
  static const String fileSearchHint = 'ابحث عن ملف...';
  static const String reactivateCourseAction = 'إعادة تنشيط';
  static const String coursesArchiveTitle = 'أرشيف المساقات';
  static const String coursesArchiveFilterLabel = 'تصفية';
  static const String coursesArchiveCompletedPrefix = 'تم إنجاز';
  static const String coursesArchiveCompletedSuffix = 'مساقات';
  static const String noArchivedCoursesMessage = 'لا توجد مقررات مؤرشفة';
}
