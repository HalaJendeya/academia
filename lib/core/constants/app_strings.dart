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

  // ===== المرحلة 8A: دور المعلّم =====

  /// يُعرض عند تسجيل الدخول بحساب دوره غير مدعوم في هذا الإصدار.
  static const String unsupportedAccountRole =
      'دور هذا الحساب غير مدعوم في هذا الإصدار. يرجى مراجعة إدارة النظام.';

  static const String teacherRoleLabel = 'معلّم';

  // تبويبات واجهة المعلّم.
  static const String teacherHomeTab = 'الرئيسية';
  static const String teacherCoursesTab = 'مساقاتي';
  static const String teacherAssignmentsTab = 'الواجبات';
  static const String teacherProfileTab = 'الملف';

  static const String teacherDashboardTitle = 'لوحة المعلّم';
  static const String teacherCoursesTitle = 'مساقاتي';
  static const String teacherAssignmentsTitle = 'الواجبات';
  static const String teacherProfileTitle = 'الملف الشخصي';

  static const String welcomeTeacherPrefix = 'مرحبًا، ';

  /// حالات مؤجَّلة صريحة: لا أعداد ولا إحصاءات قبل وجود بياناتها.
  static const String teacherCoursesDeferredTitle = 'لم تُسند إليك مساقات بعد';
  static const String teacherCoursesDeferredDesc =
      'إسناد المساقات للمعلّمين يصل في مرحلة لاحقة.';
  static const String teacherAssignmentsDeferredTitle = 'الواجبات غير متاحة بعد';
  static const String teacherAssignmentsDeferredDesc =
      'إنشاء الواجبات ومتابعتها يصل في مرحلة لاحقة.';
  static const String teacherDashboardDeferredTitle = 'لا توجد بيانات بعد';
  static const String teacherDashboardDeferredDesc =
      'ستظهر هنا مساقاتك وواجباتك بعد إسنادها إليك.';
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
    'المستوى ٦',
    'المستوى ٧',
    'المستوى ٨',
  ];

  /// المستوى الأكاديمي يُخزَّن في Firestore كرقم صحيح، والنص العربي
  /// يُبنى في طبقة العرض فقط ولا يُحفظ في قاعدة البيانات.
  ///
  /// الخطة الدراسية الرسمية موزَّعة على ثمانية مستويات، لذلك تنتهي القائمة
  /// عند 8 لا عند 5 كما كانت قبل ترحيل المرحلة 7C.
  static const List<int> academicLevelValues = [1, 2, 3, 4, 5, 6, 7, 8];

  static String academicLevelDisplay(int level) {
    if (level >= 1 && level <= academicLevelsList.length) {
      return academicLevelsList[level - 1];
    }
    return 'المستوى $level';
  }

  // ===== Phase 7H1: profile image upload (Cloudinary) =====

  /// حدود الصورة الشخصية معروضة للمستخدم، ومصدرها CloudinaryConfig.
  static const String profileImageTypeNotAllowed =
      'نوع الصورة غير مسموح. الأنواع المقبولة: JPG و PNG و WEBP.';
  static const String profileImageTooLarge =
      'حجم الصورة يتجاوز الحد المسموح (5 ميغابايت).';
  static const String profileImageEmpty = 'الصورة فارغة.';

  /// يُعرض عندما ينجح الرفع إلى Cloudinary ثم تفشل كتابة الرابط في Firestore.
  ///
  /// الحالة تُذكر صراحةً لأن الصورة تكون قد وصلت فعلًا إلى التخزين بينما لا
  /// يعرفها الملف الشخصي، والحذف من العميل غير ممكن برفع غير موقَّع.
  static const String profileImageSavedButProfileNotUpdated =
      'تم رفع الصورة لكن تعذر تحديث ملفك الشخصي. أعيدي المحاولة.';

  static const String profileImageNoProfileLoaded =
      'تعذر تحديد الحساب الحالي. أعيدي فتح الصفحة ثم حاولي مرة أخرى.';

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

  // Course Management
  static const String adminCoursesTitle = 'إدارة المساقات';
  static const String addCourseLabel = 'إضافة مساق';
  static const String editCourseLabel = 'تعديل مساق';
  static const String saveChangesLabel = 'حفظ التغييرات';
  static const String courseCodeLabel = 'رمز المساق';
  static const String courseTitleLabel = 'اسم المساق';
  static const String courseDescriptionLabel = 'الوصف';
  static const String instructorNameLabel = 'اسم المدرس';
  static const String departmentLabel = 'التخصص';
  static const String semesterLabel = 'الفصل الدراسي';
  static const String academicYearLabel = 'العام الأكاديمي';
  static const String creditHoursLabel = 'عدد الساعات';
  static const String statusLabel = 'الحالة';
  static const String activeStatus = 'نشط';
  static const String archivedStatus = 'مؤرشف';
  static const String deleteCourseConfirm =
      'هل أنت متأكد من حذف هذا المساق نهائياً؟';
  static const String archiveCourseConfirm =
      'هل أنت متأكد من أرشفة هذا المساق؟';
  static const String confirmAction = 'تأكيد';
  static const String cancelAction = 'إلغاء';
  static const String courseTitleRequired = 'يرجى إدخال اسم المساق';
  static const String courseCodeRequired = 'يرجى إدخال رمز المساق';
  static const String instructorRequired = 'يرجى إدخال اسم المدرس';
  static const String departmentRequired = 'يرجى إدخال التخصص';
  static const String semesterInvalid = 'يجب أن يكون الفصل الدراسي أكبر من 0';
  static const String creditHoursInvalid = 'يجب أن يكون عدد الساعات أكبر من 0';
  static const String academicYearRequired = 'يرجى إدخال العام الأكاديمي';
  static const String courseAddedSuccess = 'تم إضافة المساق بنجاح';
  static const String courseUpdatedSuccess = 'تم تحديث المساق بنجاح';
  static const String courseArchivedSuccess = 'تم أرشفة المساق بنجاح';
  static const String courseDeletedSuccess = 'تم حذف المساق بنجاح';
  static const String courseLoadError = 'حدث خطأ أثناء تحميل المساقات';
  static const String courseSaveError = 'حدث خطأ أثناء حفظ المساق';
  static const String noCoursesFound = 'لا توجد مساقات مضافة حالياً';
  static const String retryLabel = 'إعادة المحاولة';
  static const String unauthorizedAccess = 'غير مصرح لك بالوصول إلى هذه الصفحة';

  // Enrollment Management
  static const String adminStudentsTitle = 'إدارة الطلاب';
  static const String studentEmailLabel = 'البريد الإلكتروني';
  static const String onboardingCompletedLabel = 'حالة التهيئة';
  static const String completedOnboarding = 'مكتمل';
  static const String pendingOnboarding = 'معلق';
  static const String assignedCoursesLabel = 'المساقات المسجلة';
  static const String activeEnrollmentStatus = 'مسجل';
  static const String removedEnrollmentStatus = 'تمت إزالته';
  static const String notEnrolledStatus = 'غير مسجل';
  static const String manageCoursesLabel = 'إدارة المساقات';
  static const String assignCourseLabel = 'تسجيل مساق';
  static const String removeCourseConfirm =
      'هل أنت متأكد من إلغاء تسجيل هذا المساق؟';
  static const String restoreCourseConfirm =
      'هل أنت متأكد من إعادة تسجيل هذا المساق؟';
  static const String courseAssignedSuccess = 'تم تسجيل المساق بنجاح';
  static const String courseRestoredSuccess = 'تم إعادة تسجيل المساق بنجاح';
  static const String courseRemovedSuccess = 'تم إلغاء تسجيل المساق بنجاح';
  static const String noStudentsFound = 'لا يوجد طلاب مسجلون حالياً';

  // Admin UI Constants & Placeholders
  static const String adminDashboardTitle = 'لوحة التحكم للمشرف';
  static const String adminRoleLabel = 'مدير النظام';
  static const String welcomeAdminPrefix = 'مرحباً بك، ';
  static const String quickActionsLabel = 'الإجراءات السريعة';
  static const String addCourseQuickAction = 'إضافة مساق جديد';
  static const String manageStudentsQuickAction = 'إدارة شؤون الطلاب';
  static const String addAssignmentQuickAction = 'إضافة واجب دراسي';
  static const String uploadFileQuickAction = 'رفع ملف مساق';
  static const String courseStatusSummary = 'ملخص حالة المساقات';
  static const String activeCoursesLabel = 'مساقات نشطة';
  static const String archivedCoursesLabel = 'مساقات مؤرشفة';
  static const String recentActivitiesLabel = 'النشاطات الأخيرة';
  static const String noRecentActivities = 'لا توجد نشاطات مؤخراً';
  static const String courseNotFound = 'تعذر العثور على المساق المحدد.';
  static const String courseBasicInfoSection = 'معلومات المساق الأساسية';
  static const String courseSemesterInfoSection = 'معلومات الفصل الدراسي';
  static const String courseAcademicInfoSection = 'المعلومات الأكاديمية';
  static const String courseAcademicStatusSection = 'حالة المساق الدراسية';

  static const String courseTitleHintValue = 'مثال: إدارة قواعد البيانات';
  static const String courseCodeHintValue = 'مثال: MIS4310';
  static const String instructorHintValue = 'مثال: د. أحمد محمد';
  static const String departmentHintValue = 'مثال: نظم المعلومات الإدارية';
  static const String courseDescriptionHint = 'اكتب وصفاً مختصراً للمساق...';
  static const String semesterHintValue = 'مثال: 7';
  static const String academicYearHintValue = 'مثال: 2025-2026';
  static const String creditHoursSuffix = 'ساعات معتمدة';

  static const String viewAction = 'عرض';
  static const String editAction = 'تعديل';
  static const String archiveAction = 'أرشفة';
  static const String deleteAction = 'حذف';
  static const String archiveCourseTitle = 'أرشفة المساق';
  static const String removeCourseTitle = 'إلغاء تسجيل المساق';
  static const String restoreCourseTitle = 'إعادة تسجيل المساق';
  static const String noCoursesEnrolledForStudent =
      'لا يوجد مساقات مسجلة حالياً لهذا الطالب.';
  static const String unknownCourse = 'مساق غير معروف';
  static const String cancelEnrollmentAction = 'إلغاء التسجيل';
  static const String restoreEnrollmentAction = 'إعادة التسجيل';
  static const String coursePrefix = 'المساق:';
  static const String deadlinePrefix = 'تاريخ التسليم:';
  static const String demoFeatureAlertTitle = 'تنبيه ميزة تجريبية';
  static const String attachmentsUnavailable = 'تحميل المرفقات غير متاح';
  static const String assignmentTitleRequired = 'حقل العنوان مطلوب';
  static const String assignmentCourseRequired = 'الرجاء اختيار المساق';
  static const String assignmentDeadlineRequired =
      'الرجاء اختيار تاريخ التسليم';
  static const String fileSizePrefix = 'حجم الملف:';
  static const String uploadedAtPrefix = 'تاريخ الرفع:';
  static const String fileTitleRequired = 'اسم الملف مطلوب';
  static const String attachedFileLabel = 'الملف المرفق';
  static const String fileRequiredAlert = 'الرجاء اختيار ملف لرفعه';
  static const String contentManagementDesc =
      'مرحباً بك في مركز إدارة المحتوى للمشرف، هنا يمكنك إدارة الإعلانات ومتابعة بلاغات الطلاب.';
  static const String announcementsTileDesc =
      'نشر وتعديل الإعلانات الموجهة لجميع الطلاب أو لطلاب مساقات محددة.';
  static const String reportedPostsTileDesc =
      'مراجعة وإجراءات المنشورات والتعليقات التي تم الإبلاغ عنها من قبل الطلاب.';
  static const String announcementTargetAllValue = 'عام';
  static const String courseLabelPrefix = 'مساق: ';
  static const String publishedAtPrefix = 'تاريخ النشر: ';
  static const String targetCourseLabel = 'المساق المستهدف';
  static const String targetCourseSelectHint = 'اختر المساق المستهدف...';
  static const String announcementBodyRequired = 'حقل نص الإعلان مطلوب';
  static const String logoutFailed = 'فشل تسجيل الخروج';
  static const String appInformationTitle = 'معلومات التطبيق';
  static const String appVersionValue = 'الإصدار 1.0.0';
  static const String adminPersonalInfoTitle = 'معلومات المشرف الشخصية';
  static const String platformRoleLabel = 'الدور بالمنصة';
  static const String platformRoleAdminValue = 'مدير نظام';
  static const String adminDashboardTab = 'لوحة التحكم';
  static const String adminCoursesTab = 'المساقات';
  static const String adminStudentsTab = 'الطلاب';
  static const String adminContentTab = 'المحتوى';
  static const String adminSettingsTab = 'الإعدادات';
  static const String enrolledStudentsTab = 'الطلاب';
  static const String assignmentsTab = 'الواجبات';
  static const String filesTab = 'الملفات';
  static const String announcementsTab = 'الإعلانات';
  static const String enrolledStudentsNotConnectedTitle =
      'قائمة الطلاب غير متصلة';
  static const String enrolledStudentsNotConnectedDesc =
      'سيتم تفعيل ميزة عرض الطلاب المسجلين بالمساق لاحقاً.';
  static const String noAssignmentsTitle = 'لا توجد واجبات للمساق';
  static const String noAssignmentsDesc =
      'لم يتم تعيين أي واجبات دراسية لهذا المساق بعد.';
  static const String noFilesTitle = 'لا توجد ملفات للمساق';
  static const String noFilesDesc =
      'لم يتم رفع أي ملفات أو محاضرات لهذا المساق بعد.';
  static const String noAnnouncementsTitle = 'لا توجد إعلانات للمساق';
  static const String noAnnouncementsDesc =
      'لم يتم نشر أي إعلانات موجهة لطلاب هذا المساق بعد.';

  static const String filterAll = 'الكل';
  static const String filterActive = 'نشط';
  static const String filterArchived = 'مؤرشف';
  static const String filterDisabled = 'معطل';
  static const String filterOnboarded = 'مكتمل الإعداد';
  static const String filterPendingOnboard = 'غير مكتمل';

  static const String searchCourseHint = 'ابحث باسم أو رمز المساق...';
  static const String searchStudentHint = 'ابحث باسم أو رقم الطالب...';
  static const String searchCourseToAssignHint = 'ابحث عن مساق لتسجيله...';

  static const String accountActionsTitle = 'إجراءات الحساب (قريباً)';
  static const String accountActionsDesc =
      'هذه الخيارات معطلة حالياً وسيتم ربطها بآلية التحكم بالدخول لاحقاً.';
  static const String disableAccountAction = 'تعطيل الحساب';
  static const String activateAccountAction = 'تنشيط الحساب';
  static const String studentNotFound = 'تعذر تحميل بيانات الطالب.';
  static const String studentDetailsTitle = 'تفاصيل الطالب';

  static const String assignmentsManagementTitle = 'الواجبات الدراسية';
  static const String noAssignmentsAddedTitle = 'لا توجد واجبات دراسية مضافة';
  static const String noAssignmentsAddedDesc =
      'لم تقم بإضافة أي واجبات دراسية للمساقات حتى الآن.';
  static const String addNewAssignmentAction = 'إضافة واجب جديد';
  static const String assignmentDetailsTitle = 'تفاصيل الواجب الدراسي';
  static const String assignmentFeatureNotConnected =
      'ميزة الواجبات قيد التطوير حالياً وغير متصلة بقاعدة البيانات.';
  static const String assignmentTitleLabel = 'عنوان الواجب';
  static const String assignmentTitleHint = 'أدخل عنوان الواجب...';
  static const String assignmentCourseLabel = 'المساق الدراسي';
  static const String assignmentCourseSelectHint = 'اختر المساق الدراسي...';
  static const String assignmentDeadlineLabel = 'تاريخ التسليم الأقصى';
  static const String assignmentDeadlineHint = 'اختر تاريخ التسليم...';
  static const String assignmentInstructionsLabel = 'الوصف والتعليمات';
  static const String assignmentInstructionsHint =
      'أدخل تفاصيل الواجب والتعليمات...';
  static const String assignmentSaveAction = 'حفظ الواجب (قريباً)';
  static const String assignmentMockTitle = 'واجب تجريبي غير متاح';

  static const String filesManagementTitle = 'ملفات المساقات';
  static const String noFilesUploadedTitle = 'لا توجد ملفات مرفوعة';
  static const String noFilesUploadedDesc =
      'لم يتم رفع أي ملفات أو محاضرات دراسية حتى الآن.';
  static const String uploadNewFileAction = 'رفع ملف جديد';
  static const String uploadFeatureNotConnected =
      'خدمة الرفع غير متصلة حالياً. سيتم ربط ميزة رفع الملفات بخدمة Cloudinary لاحقاً.';
  static const String fileTitleLabel = 'اسم الملف';
  static const String fileTitleHint = 'أدخل عنوان أو اسم الملف...';
  static const String filePickerPrompt = 'اختر ملفاً لرفعه (معطل حالياً)';
  static const String uploadFileAction = 'بدء الرفع (معطل)';

  static const String contentManagementTitle = 'إدارة المحتوى';
  static const String contentManagementCenter = 'مركز إدارة المحتوى';
  static const String announcementsManagementTitle = 'الإعلانات';
  static const String noAnnouncementsPublishedTitle = 'لا توجد إعلانات منشورة';
  static const String noAnnouncementsPublishedDesc =
      'لم يتم نشر أي إعلانات عامة أو موجهة للمساقات بعد.';
  static const String createNewAnnouncementAction = 'إنشاء إعلان جديد';
  static const String announcementFeatureNotConnected =
      'ميزة الإعلانات قيد التطوير حالياً وغير متصلة بقاعدة البيانات.';
  static const String announcementTitleLabel = 'عنوان الإعلان';
  static const String announcementTitleHint = 'أدخل عنوان الإعلان...';
  static const String announcementTargetLabel = 'الفئة المستهدفة';
  static const String announcementTargetAll = 'جميع الطلاب';
  static const String announcementTargetCourses = 'طلاب مساقات محددة';
  static const String announcementBodyLabel = 'نص الإعلان';
  static const String announcementBodyHint = 'اكتب نص الإعلان هنا...';
  static const String announcementPublishAction = 'نشر الإعلان (قريباً)';

  static const String reportedPostsTitle = 'المنشورات المبلغ عنها';
  static const String noReportsTitle = 'لا توجد بلاغات معلقة';
  static const String noReportsDesc =
      'جميع منشورات الطلاب سليمة ولم يتم تقديم أي بلاغات حالياً.';

  static const String settingsTitle = 'الإعدادات';
  static const String accountInformation = 'معلومات الحساب';
  static const String profileTitleAdmin = 'الملف الشخصي للمشرف';
  static const String adminRoleValue = 'مدير النظام';
  static const String accountStatusLabel = 'حالة الحساب';
  static const String accountStatusValue = 'نشط';

  // Semesters (Phase 6B)
  static const String semestersManagementTitle = 'إدارة الفصول الدراسية';
  static const String semestersTileDesc =
      'إنشاء الفصول الدراسية وتحديد الفصل الحالي';
  static const String addSemesterLabel = 'إضافة فصل دراسي';
  static const String editSemesterLabel = 'تعديل الفصل الدراسي';
  static const String semesterNameLabel = 'اسم الفصل الدراسي';
  static const String semesterNameHintValue = 'مثال: الفصل الأول 2026';
  static const String academicYearOnlyLabel = 'السنة الأكاديمية';
  static const String academicYearHintOnlyValue = 'مثال: 2026';
  static const String semesterNumberLabel = 'رقم الفصل الدراسي';
  static const String semesterNumberHintValue = 'مثال: 1';
  static const String semesterStatusLabel = 'حالة الفصل الدراسي';
  static const String semesterStartDateLabel = 'تاريخ البداية (اختياري)';
  static const String semesterEndDateLabel = 'تاريخ النهاية (اختياري)';
  static const String selectDatePrompt = 'اختر التاريخ';
  static const String generatedIdLabel = 'معرّف المستند';

  static const String semesterStatusUpcoming = 'قادم';
  static const String semesterStatusCurrent = 'الفصل الحالي';
  static const String semesterStatusCompleted = 'منتهٍ';

  static const String setAsCurrentAction = 'تعيين كفصل حالي';
  static const String setCurrentSemesterTitle = 'تعيين الفصل الدراسي الحالي';
  static const String setCurrentSemesterConfirm =
      'سيتم تحويل الفصل الدراسي الحالي السابق إلى "منتهٍ" وتعيين هذا الفصل '
      'كفصل حالي. هل تريد المتابعة؟';
  static const String semesterSetAsCurrentSuccess =
      'تم تعيين الفصل الدراسي الحالي بنجاح';
  static const String semesterAddedSuccess = 'تمت إضافة الفصل الدراسي بنجاح';
  static const String semesterUpdatedSuccess = 'تم تحديث الفصل الدراسي بنجاح';

  static const String noSemestersFound = 'لا توجد فصول دراسية';
  static const String noSemestersDesc =
      'أضيفي فصلًا دراسيًا واحدًا على الأقل قبل إنشاء المساقات.';

  static const String semesterLoadError = 'تعذر تحميل الفصول الدراسية';
  static const String semesterSaveError = 'تعذر حفظ الفصل الدراسي';
  static const String semesterNotFound = 'الفصل الدراسي غير موجود';
  static const String semesterAlreadyExists = 'هذا الفصل الدراسي موجود بالفعل';
  static const String semesterNameRequired = 'اسم الفصل الدراسي مطلوب';
  static const String semesterNumberInvalid =
      'يجب أن يكون رقم الفصل الدراسي أكبر من 0';
  static const String semesterStatusInvalid = 'حالة الفصل الدراسي غير صحيحة';
  static const String semesterIdentityLockedNote =
      'لا يمكن تعديل السنة الأكاديمية أو رقم الفصل لأنهما يشكّلان معرّف المستند.';

  // Course <-> semester (Phase 6C)
  static const String unknownSemester = 'فصل غير محدد';
  static const String allSemestersFilter = 'كل الفصول';
  static const String courseSemesterLabel = 'الفصل الدراسي';
  static const String courseSemesterSelectHint = 'اختر الفصل الدراسي';
  static const String courseSemesterRequired = 'يرجى اختيار الفصل الدراسي';
  static const String courseStatusInvalid = 'حالة المساق غير صحيحة';
  static const String courseSemesterMissingForUpdate =
      'هذا المساق غير مرتبط بفصل دراسي. يرجى تعديله وتحديد الفصل الدراسي أولًا.';
  static const String noSemestersForCourseTitle =
      'لا يمكن إنشاء مساق بدون فصل دراسي';
  static const String noSemestersForCourseDesc =
      'يجب إنشاء فصل دراسي واحد على الأقل قبل إضافة المساقات.';
  static const String goToSemestersAction = 'الانتقال إلى الفصول الدراسية';

  // Enrollments (Phase 6D)
  static const String alreadyEnrolledError =
      'الطالب مسجل بالفعل في هذا المساق';
  static const String enrollmentNotFoundError =
      'سجل التسجيل غير موجود. قد يكون قد حُذف بالفعل.';
  static const String enrollmentStatusInvalid = 'حالة التسجيل غير صحيحة';
  static const String courseSemesterMissingForEnrollment =
      'لا يمكن تسجيل الطالب في مساق غير مرتبط بفصل دراسي. يرجى تعديل المساق '
      'وتحديد الفصل الدراسي أولًا.';
  static const String completedEnrollmentStatus = 'مكتمل';
  static const String markCompletedAction = 'تعليم كمكتمل';
  static const String markCompletedTitle = 'تعليم المساق كمكتمل';
  static const String markCompletedConfirm =
      'سيتم تسجيل أن الطالب أنهى هذا المساق. هل تريد المتابعة؟';
  static const String enrollmentCompletedSuccess = 'تم تعليم المساق كمكتمل';
  static const String legacyEnrollmentNote =
      'سجل تسجيل قديم غير مرتبط بطرح مساق. يلزم إعادة تسجيل الطالب في طرح '
      'الفصل الدراسي المناسب.';

  // ===== Phase 7A: academic structure =====

  // Departments
  static const String departmentsManagementTitle = 'إدارة الأقسام';
  static const String departmentNameLabel = 'اسم القسم';
  static const String departmentNameRequired = 'اسم القسم مطلوب';
  static const String departmentNotFound = 'القسم غير موجود';
  static const String departmentLoadError = 'تعذر تحميل الأقسام';
  static const String departmentSaveError = 'تعذر حفظ القسم';
  static const String departmentStatusInvalid = 'حالة القسم غير صحيحة';
  static const String courseDepartmentRequired = 'يرجى اختيار القسم';
  static const String unknownDepartment = 'قسم غير محدد';
  static const String allDepartmentsFilter = 'كل الأقسام';
  static const String courseDepartmentLabel = 'القسم';
  static const String courseDepartmentSelectHint = 'اختر القسم';
  static const String noDepartmentsForCourseTitle =
      'لا يمكن إنشاء مساق بدون قسم';
  static const String noDepartmentsForCourseDesc =
      'يجب إنشاء قسم أكاديمي واحد على الأقل قبل إضافة المساقات.';

  // Majors
  static const String majorsManagementTitle = 'إدارة التخصصات';
  static const String majorNameLabel = 'اسم التخصص';
  static const String majorNameRequired = 'اسم التخصص مطلوب';
  static const String majorCodeRequired = 'رمز التخصص مطلوب';
  static const String majorNotFound = 'التخصص غير موجود';
  static const String majorLoadError = 'تعذر تحميل التخصصات';
  static const String majorSaveError = 'تعذر حفظ التخصص';
  static const String majorStatusInvalid = 'حالة التخصص غير صحيحة';
  static const String majorTotalLevelsInvalid =
      'يجب أن يكون عدد المستويات أكبر من 0';
  static const String noMajorAssigned =
      'لم يتم تحديد برنامجك الأكاديمي. يرجى مراجعة المشرف.';
  static const String unknownMajor = 'تخصص غير محدد';

  // Course catalog
  static const String courseCodeAlreadyExists =
      'رمز المساق مستخدم بالفعل في مساق آخر';

  // Course offerings
  static const String offeringsManagementTitle = 'طروحات المساقات';
  static const String offeringSectionLabel = 'الشعبة';
  static const String offeringNotFound = 'طرح المساق غير موجود';
  static const String offeringAlreadyExists =
      'يوجد طرح لهذا المساق في هذا الفصل الدراسي بنفس الشعبة';
  static const String offeringLoadError = 'تعذر تحميل طروحات المساقات';
  static const String offeringSaveError = 'تعذر حفظ طرح المساق';
  static const String offeringStatusInvalid = 'حالة الطرح غير صحيحة';
  static const String offeringCourseRequired = 'يرجى اختيار المساق';
  static const String offeringSemesterRequired = 'يرجى اختيار الفصل الدراسي';
  static const String offeringInstructorRequired = 'اسم المدرّس مطلوب';
  static const String offeringCancelledCannotEnroll =
      'لا يمكن التسجيل في طرح ملغى';
  static const String duplicateOfferingsAction = 'نسخ من فصل سابق';
  static const String courseNotOfferedThisSemester =
      'هذا المساق غير مطروح في الفصل الدراسي الحالي';
  static const String noCurrentSemesterForAssignment =
      'لا يوجد فصل دراسي حالي. يرجى تعيين الفصل الحالي قبل تسجيل المساقات.';

  // Curriculum
  static const String curriculumManagementTitle = 'الخطة الدراسية';
  static const String curriculumLoadError = 'تعذر تحميل الخطة الدراسية';
  static const String curriculumSaveError = 'تعذر حفظ الخطة الدراسية';
  static const String curriculumEntryNotFound = 'عنصر الخطة الدراسية غير موجود';
  static const String curriculumEntryTypeInvalid = 'نوع عنصر الخطة غير صحيح';
  static const String requirementTypeInvalid = 'نوع المتطلب غير صحيح';
  static const String academicLevelInvalid =
      'يجب أن يكون المستوى الأكاديمي بين 1 و 8';
  static const String curriculumSlotLabelRequired = 'اسم خانة المتطلب مطلوب';
  static const String curriculumSlotHoursRequired =
      'عدد ساعات خانة المتطلب مطلوب';
  static const String curriculumCourseRequired = 'يرجى اختيار المساق';
  static const String curriculumEntryAlreadyExists =
      'هذا المساق مضاف بالفعل إلى الخطة الدراسية';

  // Requirement type labels
  static const String requirementMajorRequired = 'متطلب تخصص إجباري';
  static const String requirementMajorElective = 'متطلب تخصص اختياري';
  static const String requirementCollegeRequired = 'متطلب كلية إجباري';
  static const String requirementUniversityRequired = 'متطلب جامعة إجباري';
  static const String requirementUniversityElective = 'متطلب جامعة اختياري';
  static const String requirementFreeElective = 'مساق حر';

  static String requirementTypeDisplay(String requirementType) {
    switch (requirementType) {
      case 'major_required':
        return requirementMajorRequired;
      case 'major_elective':
        return requirementMajorElective;
      case 'college_required':
        return requirementCollegeRequired;
      case 'university_required':
        return requirementUniversityRequired;
      case 'university_elective':
        return requirementUniversityElective;
      case 'free_elective':
        return requirementFreeElective;
      default:
        return requirementType;
    }
  }

  static const String prerequisiteLabel = 'متطلب سابق';
  static const String noPrerequisite = 'لا يوجد';

  // ===== Phase 7D: admin academic-structure UI =====

  // Departments
  static const String departmentsTileDesc =
      'إضافة الأقسام الأكاديمية وتعديلها';
  static const String addDepartmentLabel = 'إضافة قسم';
  static const String editDepartmentLabel = 'تعديل القسم';
  static const String departmentCodeLabel = 'رمز القسم (اختياري)';
  static const String departmentCodeHint = 'مثال: MIS';
  static const String departmentAddedSuccess = 'تمت إضافة القسم بنجاح';
  static const String departmentUpdatedSuccess = 'تم تحديث القسم بنجاح';
  static const String departmentArchivedSuccess = 'تمت أرشفة القسم';
  static const String archiveDepartmentTitle = 'أرشفة القسم';
  static const String archiveDepartmentConfirm =
      'سيتم إخفاء القسم من قوائم الاختيار مع بقاء مساقاته كما هي. هل تريد المتابعة؟';
  static const String noDepartmentsFound = 'لا توجد أقسام';
  static const String noDepartmentsDesc =
      'أضيفي قسمًا أكاديميًا واحدًا على الأقل قبل إنشاء التخصصات والمساقات.';

  // Majors
  static const String majorsTileDesc = 'إدارة البرامج الدراسية وخططها';
  static const String addMajorLabel = 'إضافة تخصص';
  static const String editMajorLabel = 'تعديل التخصص';
  static const String majorCodeLabel = 'رمز التخصص';
  static const String majorCodeHint = 'مثال: MIS';
  static const String majorTotalLevelsLabel = 'عدد المستويات';
  static const String majorAddedSuccess = 'تمت إضافة التخصص بنجاح';
  static const String majorUpdatedSuccess = 'تم تحديث التخصص بنجاح';
  static const String majorArchivedSuccess = 'تمت أرشفة التخصص';
  static const String archiveMajorTitle = 'أرشفة التخصص';
  static const String archiveMajorConfirm =
      'سيتم إخفاء التخصص من قوائم الاختيار مع بقاء خطته الدراسية كما هي. '
      'هل تريد المتابعة؟';
  static const String noMajorsFound = 'لا توجد تخصصات';
  static const String noMajorsDesc =
      'أضيفي تخصصًا واحدًا على الأقل ليمكن بناء خطته الدراسية.';
  static const String levelsSuffix = 'مستويات';

  // Curriculum
  static const String curriculumTileDesc =
      'عرض وتعديل خطة التخصص الدراسية بالمستويات';
  static const String selectMajorLabel = 'التخصص';
  static const String selectMajorHint = 'اختاري التخصص';
  static const String selectMajorPrompt =
      'اختاري تخصصًا لعرض خطته الدراسية.';
  static const String curriculumEmptyForMajor =
      'لا توجد صفوف في خطة هذا التخصص بعد.';
  static const String academicLevelSectionLabel = 'المستوى';
  static const String curriculumTotalHoursLabel = 'مجموع الساعات';
  static const String curriculumRowsLabel = 'عدد الصفوف';
  static const String creditHoursShort = 'س.م';
  static const String slotEntryBadge = 'خانة متطلب';
  static const String slotNotSelectableNote =
      'خانة متطلب لم يُختَر لها مساق بعد';

  // Curriculum entry form
  static const String addCurriculumEntryLabel = 'إضافة صف للخطة';
  static const String editCurriculumEntryLabel = 'تعديل صف الخطة';
  static const String curriculumEntryTypeLabel = 'نوع الصف';
  static const String entryTypeCourseLabel = 'مساق محدد';
  static const String entryTypeSlotLabel = 'خانة متطلب';
  static const String curriculumCoursePickerLabel = 'المساق';
  static const String curriculumCoursePickerHint = 'اختاري المساق';
  static const String slotLabelFieldLabel = 'اسم خانة المتطلب';
  static const String slotLabelHint = 'مثال: متطلب جامعة اختياري (1)';
  static const String requirementTypeLabel = 'نوع المتطلب';
  static const String sequenceLabel = 'الترتيب داخل المستوى';
  static const String prerequisiteTextLabel = 'نص المتطلب السابق (اختياري)';
  static const String prerequisiteTextHint =
      'يُحفظ كما ورد في الخطة الرسمية، ولا يُطبَّق في التطبيق';
  static const String prerequisiteNotEnforcedNote =
      'المتطلبات السابقة تُعرض للاطلاع فقط ولا تمنع التسجيل.';
  static const String curriculumEntryAddedSuccess = 'تمت إضافة الصف بنجاح';
  static const String curriculumEntryUpdatedSuccess = 'تم تحديث الصف بنجاح';
  static const String curriculumEntryRemovedSuccess = 'تم حذف الصف من الخطة';
  static const String removeCurriculumEntryTitle = 'حذف صف من الخطة';
  static const String removeCurriculumEntryConfirm =
      'سيُحذف هذا الصف من الخطة الدراسية نهائيًا. لن يتأثر مستند المساق نفسه. '
      'هل تريد المتابعة؟';
  static const String sequenceInvalid =
      'يجب أن يكون الترتيب رقمًا صحيحًا أكبر من أو يساوي 0';
  static const String curriculumIdentityChangeNote =
      'تغيير المساق أو المستوى أو الترتيب يغيّر معرّف المستند، لذلك يُنشأ صف '
      'جديد ويُحذف القديم ضمن العملية نفسها.';
  static const String noCoursesForCurriculum =
      'لا توجد مساقات في الكتالوج بعد. أضيفي مساقًا قبل بناء الخطة.';
  static const String allCurriculumCoursesUsed =
      'كل مساقات الكتالوج مضافة بالفعل إلى خطة هذا التخصص.';

  // ===== Phase 7S2: student Courses =====
  //
  // الصياغة العربية للبطاقات والتبويبات منقولة كما كتبها فريق الواجهة في
  // فرع courses-ui، مع استبدال ما كان يصف بيانات وهمية (نسبة الإنجاز،
  // التقييم، الجلسة القادمة) بمفاهيم المعمارية الحالية.

  static const String myCoursesTitle = 'مقرراتي الدراسية';
  static const String courseSearchHint = 'ابحث عن مساق...';
  static const String coursesLoadError = 'تعذر تحميل المقررات الدراسية';
  static const String courseDetailLoadError = 'تعذر تحميل بيانات المقرر';
  static const String viewDetailsAction = 'عرض التفاصيل';

  // التبويبات الأربعة
  static const String studentTabProgram = 'برنامجي';
  static const String studentTabAvailableNow = 'المتاحة الآن';
  static const String studentTabCurrent = 'مساقاتي الحالية';
  static const String studentTabHistory = 'السجل';

  // برنامجي
  static const String programTotalHoursLabel = 'مجموع ساعات الخطة';
  static const String programRowsLabel = 'عدد المقررات والمتطلبات';
  static const String programLevelHoursSuffix = 'ساعة';
  static const String noMajorTitle = 'لم يتم تحديد برنامجك الأكاديمي';
  static const String noMajorDesc =
      'خطتك الدراسية تُبنى على برنامجك الأكاديمي. يرجى مراجعة المشرف لربط '
      'حسابك بالتخصص.';
  static const String programEmptyTitle = 'لا توجد خطة دراسية بعد';
  static const String programEmptyDesc =
      'لم تُضَف صفوف إلى خطة تخصصك حتى الآن.';

  // المتاحة الآن
  static const String availableNowEmptyTitle = 'لا توجد مساقات مطروحة الآن';
  static const String availableNowEmptyDesc =
      'لا يوجد حاليًا أي مساق من خطتك الدراسية مطروح في الفصل الدراسي الحالي. '
      'ستظهر المساقات هنا فور طرحها.';
  static const String noCurrentSemesterTitle = 'لا يوجد فصل دراسي حالي';
  static const String noCurrentSemesterDesc =
      'لم يُحدَّد فصل دراسي حالي بعد، لذلك لا يمكن عرض المساقات المطروحة.';

  // مساقاتي الحالية
  static const String currentCoursesEmptyTitle = 'لا توجد مساقات مسجلة';
  static const String currentCoursesEmptyDesc =
      'لم يتم تسجيلك في أي مساق لهذا الفصل الدراسي بعد. التسجيل يتم عبر '
      'المشرف الأكاديمي.';

  // السجل
  static const String coursesArchiveTitle = 'سجل المساقات';
  static const String historyEmptyTitle = 'لا يوجد سجل دراسي بعد';
  static const String historyEmptyDesc =
      'ستظهر هنا المساقات التي أنهيتها في الفصول السابقة.';
  static const String attemptsCountLabel = 'عدد المحاولات';
  static const String viewFullArchiveAction = 'عرض السجل كاملًا';

  // بطاقات المساق
  static const String sectionLabel = 'الشعبة';
  static const String courseNotInProgramNote = 'مساق خارج خطتك الدراسية';
  static const String slotNotACourseNote =
      'خانة متطلب لم يُختَر لها مساق بعد';

  // تفاصيل المساق
  static const String courseDetailAppBarTitle = 'تفاصيل المساق';
  static const String courseOverviewTab = 'نظرة عامة';
  static const String courseAssignmentsTab = 'الواجبات';
  static const String courseFilesTab = 'الملفات';
  static const String courseSharedSpaceTab = 'المساحة';
  static const String courseAttemptSectionTitle = 'بيانات التسجيل';
  static const String courseProgramSectionTitle = 'موقع المساق في الخطة';
  static const String featureNotAvailableYetTitle = 'غير متاح بعد';
  static const String featureNotAvailableYetDesc =
      'هذا القسم لم يُفعَّل بعد في هذه النسخة من التطبيق.';
  static const String courseNotFoundStudent = 'تعذر العثور على هذا المساق.';

  // ===== Phase 7S3: student dashboard =====
  //
  // اللوحة شاشة تجميع لا مجال بيانات جديد: كل رقم فيها مشتق من مزوّد قائم،
  // وما لا مصدر له يُعرض كحالة "قريبًا" بدل رقم مختلق.

  static const String dashboardGreeting = 'مرحبًا';
  static const String dashboardSemesterLabel = 'الفصل الدراسي الحالي';
  static const String dashboardNoSemester = 'لم يُحدَّد فصل دراسي حالي';

  // ملخص الخطة
  static const String dashboardPlanSummaryTitle = 'خطتك الدراسية';
  static const String dashboardPlanTotalHours = 'إجمالي الخطة';
  static const String dashboardCurrentLevel = 'المستوى الحالي';
  static const String dashboardLevelHours = 'ساعات المستوى';
  static const String dashboardPlanUnavailable =
      'لم يتم تحديد برنامجك الأكاديمي بعد، لذلك لا يمكن عرض خطتك الدراسية. '
      'يرجى مراجعة المشرف الأكاديمي.';
  static const String dashboardLevelUnknown = 'غير محدد';

  // ملخص المساقات
  static const String dashboardCoursesTitle = 'مساقاتك';
  static const String dashboardCurrentCoursesLabel = 'مسجّلة حاليًا';
  static const String dashboardAvailableNowLabel = 'متاحة للتسجيل';
  static const String dashboardNoCurrentCourses =
      'لم يتم تسجيلك في أي مساق لهذا الفصل بعد.';
  static const String dashboardNoAvailableCourses =
      'لا توجد مساقات مطروحة لك في الفصل الحالي حاليًا.';
  static const String dashboardOpenCoursesAction = 'عرض المساقات';

  // الموصى لمستواك
  static const String dashboardRecommendedTitle = 'مقررات مستواك';
  static const String dashboardRecommendedDesc =
      'ما تتضمّنه خطتك الدراسية في مستواك الحالي.';
  static const String dashboardRecommendedEmpty =
      'لا توجد مقررات مسجّلة لمستواك في الخطة.';
  static const String dashboardMoreItems = 'والمزيد';

  // أقسام مؤجّلة
  static const String dashboardComingSoonBadge = 'قريبًا';

  // ===== المرحلة 7H4: ملخص مهام الطالب في اللوحة =====
  //
  // القسم كان بطاقة "قريبًا"؛ صار ملخصًا حقيقيًا مصدره TaskProvider نفسه
  // الذي تعتمد عليه شاشة المهام. الصيغ العربية تُبنى هنا لا في الودجت.

  static const String dashboardTasksTitle = 'مهام اليوم';
  static const String dashboardTasksViewAll = 'عرض الكل';

  static const String dashboardTasksEmpty = 'لا توجد مهام مستحقة اليوم';
  static const String dashboardTasksEmptyHint =
      'أضيفي مهمة جديدة لتنظيم وقتك الدراسي.';

  static const String dashboardTasksNoDueDate = 'بدون موعد تسليم';

  /// عدد المهام المستحقة اليوم، بصيغة عربية سليمة (مفرد/مثنى/جمع).
  ///
  /// تُبنى وقت العرض من قائمة المهام المحمَّلة؛ لا يُخزَّن أي عدّاد في
  /// قاعدة البيانات، ولا يُعرض رقم قبل اكتمال التحميل.
  static String dashboardTasksTodaySummary(int count) {
    if (count == 0) return dashboardTasksEmpty;
    if (count == 1) return 'مهمة واحدة مستحقة اليوم';
    if (count == 2) return 'مهمتان مستحقتان اليوم';
    if (count <= 10) return '$count مهام مستحقة اليوم';
    return '$count مهمة مستحقة اليوم';
  }

  /// عدد المهام المتأخرة. لا يُعرض إطلاقًا حين يكون صفرًا.
  static String dashboardTasksOverdueSummary(int count) {
    if (count == 1) return 'مهمة متأخرة';
    if (count == 2) return 'مهمتان متأخرتان';
    if (count <= 10) return '$count مهام متأخرة';
    return '$count مهمة متأخرة';
  }

  // إجراءات سريعة
  static const String dashboardQuickActionsTitle = 'إجراءات سريعة';
  static const String dashboardActionCourses = 'المساقات';
  static const String dashboardActionProfile = 'ملفي الشخصي';
  static const String dashboardActionStudyPreferences = 'تفضيلات الدراسة';
  static const String dashboardActionNotifications = 'إعدادات الإشعارات';

  // ===== Phase 7E: offerings, attempts and retakes =====

  static const String offeringsTileDesc =
      'طرح المساقات في الفصول الدراسية وتسجيل الطلاب فيها';
  static const String addOfferingLabel = 'إضافة طرح';
  static const String editOfferingLabel = 'تعديل الطرح';
  static const String offeringCourseLabel = 'المساق';
  static const String offeringInstructorLabel = 'اسم المدرّس';
  static const String offeringInstructorHint = 'مثال: م. حمزة السويركي';
  static const String offeringSectionHint = 'مثال: 1';
  static const String offeringSectionRequired = 'رقم الشعبة مطلوب';
  static const String offeringAddedSuccess = 'تمت إضافة الطرح بنجاح';
  static const String offeringUpdatedSuccess = 'تم تحديث الطرح بنجاح';
  static const String offeringArchivedSuccess = 'تمت أرشفة الطرح';
  static const String archiveOfferingTitle = 'أرشفة الطرح';
  static const String archiveOfferingConfirm =
      'سيُخفى الطرح من قوائم التسجيل مع بقاء تسجيلات الطلاب الحالية كما هي. '
      'هل تريد المتابعة؟';
  static const String noOfferingsForSemester = 'لا توجد طروحات في هذا الفصل';
  static const String noOfferingsForSemesterDesc =
      'أضيفي طرحًا واحدًا على الأقل ليتمكّن المشرف من تسجيل الطلاب.';
  static const String offeringIdentityLockedNote =
      'لا يمكن تعديل المساق أو الفصل أو الشعبة لأنها تشكّل معرّف المستند. '
      'لتغييرها أنشئي طرحًا جديدًا.';
  static const String offeringStatusCancelled = 'ملغى';
  static const String selectSemesterFirst = 'اختاري فصلًا دراسيًا لعرض طروحه.';

  // نسخ الطروحات
  static const String duplicateOfferingsTitle = 'نسخ طروحات فصل سابق';
  static const String duplicateOfferingsSourceLabel = 'الفصل المصدر';
  static const String duplicateOfferingsDesc =
      'تُنسخ طروحات الفصل المصدر إلى الفصل الحالي مع أسماء المدرّسين والشعب. '
      'الطروحات الملغاة لا تُنسخ، وإعادة التنفيذ لا تُنشئ نسخًا مكررة.';
  static const String duplicateOfferingsConfirm = 'نسخ';
  static const String duplicateOfferingsSuccessPrefix = 'تم نسخ';
  static const String duplicateOfferingsSuccessSuffix = 'طرحًا';
  static const String duplicateOfferingsNone =
      'لا توجد طروحات قابلة للنسخ في الفصل المصدر';
  static const String duplicateOfferingsSameSemester =
      'اختاري فصلًا مصدرًا مختلفًا عن الفصل الحالي';

  // قائمة المسجَّلين في الطرح
  static const String offeringRosterTitle = 'الطلاب المسجّلون';
  static const String offeringRosterEmpty = 'لا يوجد طلاب مسجّلون في هذا الطرح';
  static const String offeringRosterEmptyDesc =
      'سيظهر الطلاب هنا بعد تسجيلهم في هذا الطرح من شاشة الطالب.';
  static const String offeringRosterCountLabel = 'عدد المسجّلين';
  static const String viewRosterAction = 'المسجّلون';

  // نتيجة المحاولة
  static const String recordResultAction = 'تسجيل النتيجة';
  static const String recordResultTitle = 'تسجيل نتيجة المساق';
  static const String recordResultDesc =
      'تُسجَّل النتيجة على هذه المحاولة وتُنهيها. التقدير نص للعرض فقط ولا '
      'يُحتسب منه معدل.';
  static const String completionStatusLabel = 'النتيجة';
  static const String gradeOptionalLabel = 'التقدير (اختياري)';
  static const String gradeHint = 'مثال: ممتاز';
  static const String resultRecordedSuccess = 'تم تسجيل النتيجة بنجاح';
  static const String completionStatusRequired = 'يرجى اختيار النتيجة';

  // المحاولات وإعادة الدراسة
  static const String previousAttemptsLabel = 'محاولات سابقة';
  static const String retakeBadgeLabel = 'إعادة دراسة';
  static const String willBeAttemptPrefix = 'سيُسجَّل كالمحاولة';
  static const String noPreviousAttempts = 'لا توجد محاولات سابقة';

  // ===== Admin student details (rebuilt) =====

  static const String academicProgramTitle = 'البرنامج الأكاديمي';
  static const String majorNotAssigned = 'لم يتم تحديد التخصص';
  static const String legacyMajorTextNote =
      'نص قديم أدخله الطالب عند التسجيل، وليس مرتبطًا ببرنامج أكاديمي.';
  static const String notProvidedValue = 'غير محدد';
  static const String disabledStatus = 'معطل';
  static const String currentEnrollmentsTitle = 'المساقات الحالية';
  static const String enrollmentHistoryTitle = 'السجل الدراسي';
  static const String noCurrentEnrollmentsForStudent =
      'لا توجد مساقات مسجّلة حاليًا لهذا الطالب.';
  static const String noEnrollmentHistoryForStudent =
      'لا توجد محاولات سابقة في سجل هذا الطالب.';
  static const String assignOfferingDesc =
      'التسجيل يتم في طرح المساق ضمن الفصل الدراسي الحالي.';

  // ===== Phase 7F1A: course files =====

  static const String fileTypeNotAllowed =
      'نوع الملف غير مسموح. الأنواع المقبولة: PDF، Word، PowerPoint، Excel، '
      'نص، وصور JPG و PNG.';
  static const String fileTooLargeError =
      'حجم الملف يتجاوز الحد المسموح (10 ميغابايت).';
  static const String fileEmptyError = 'الملف فارغ.';
  static const String fileUploadError = 'تعذر رفع الملف';
  static const String fileUploadNetworkError =
      'تعذر الاتصال بخدمة التخزين. تحققي من الاتصال وحاولي مرة أخرى.';

  /// يُعرض عندما ينجح الرفع ثم تفشل كتابة البيانات الوصفية.
  ///
  /// الحالة تُذكر صراحةً لأن الملف يكون قد وصل فعلًا إلى التخزين بينما لا
  /// يظهر في التطبيق، والحذف من العميل غير ممكن برفع غير موقَّع.
  static const String fileMetadataFailedAfterUpload =
      'تم رفع الملف لكن تعذر حفظ بياناته. أعيدي المحاولة، وقد تحتاجين إلى '
      'حذف النسخة الزائدة من لوحة التخزين.';

  static const String fileLoadError = 'تعذر تحميل ملفات المساق';

  // ===== ملفات الطالب =====

  static const String courseFilesNoOfferingTitle = 'لا توجد ملفات لهذا المساق';
  static const String courseFilesNoOfferingDesc =
      'ملفات المساق تُتاح بعد تسجيلك في طرحه ضمن فصل دراسي.';
  static const String courseFilesEmptyDesc =
      'لم يرفع المشرف أي ملف لهذا الطرح بعد.';
  static const String noEnrolledCoursesForFiles =
      'لا توجد مساقات مسجَّلة، لذلك لا توجد ملفات لعرضها.';
  static const String filePreviewTitle = 'معاينة الملف';
  static const String fileSaveError = 'تعذر حفظ بيانات الملف';
  static const String fileNotFound = 'الملف غير موجود';

  /// عنوان العرض للملف، غير اسم الملف نفسه (fileTitleRequired أعلاه).
  static const String courseFileTitleRequired = 'عنوان الملف مطلوب';
  static const String fileCategoryInvalid = 'تصنيف الملف غير صحيح';
  static const String fileStatusInvalid = 'حالة الملف غير صحيحة';
  static const String fileArchivedSuccess = 'تمت أرشفة الملف';
  static const String fileUploadedSuccess = 'تم رفع الملف بنجاح';
  static const String fileUpdatedSuccess = 'تم تحديث بيانات الملف';

  // تصنيفات الملفات
  static const String fileCategoryLecture = 'محاضرة';
  static const String fileCategorySummary = 'ملخص';
  static const String fileCategoryAssignmentMaterial = 'مادة تكليف';
  static const String fileCategoryReference = 'مرجع';
  static const String fileCategoryOther = 'أخرى';

  static String fileCategoryDisplay(String category) {
    switch (category) {
      case 'lecture':
        return fileCategoryLecture;
      case 'summary':
        return fileCategorySummary;
      case 'assignment_material':
        return fileCategoryAssignmentMaterial;
      case 'reference':
        return fileCategoryReference;
      case 'other':
        return fileCategoryOther;
      default:
        return category;
    }
  }

  // ===== Phase 7F1B: admin course-files management =====

  static const String offeringFilesTitle = 'ملفات الطرح';
  static const String offeringFilesAction = 'الملفات';
  static const String offeringFilesCountLabel = 'عدد الملفات';
  static const String noOfferingFilesTitle = 'لا توجد ملفات لهذا الطرح';
  static const String noOfferingFilesDesc =
      'ارفعي محاضرات المساق وملخصاته ليتمكن الطلاب المسجّلون من الاطلاع عليها.';

  static const String uploadFileTitle = 'رفع ملف';
  static const String courseAssignmentsLoadError = 'تعذر تحميل واجبات المقرر';
  static const String courseFilesLoadError = 'تعذر تحميل ملفات المقرر';
  /// فعل الإرسال في نموذج الرفع، مميَّز عن عنوان الشاشة حتى لا يتشابه
  /// العنوان مع الزر في الواجهة.
  static const String confirmUploadAction = 'رفع الملف';
  static const String selectFileAction = 'اختيار ملف';
  static const String changeFileAction = 'تغيير الملف';
  static const String noFileSelected = 'لم يتم اختيار ملف بعد';
  /// عنوان عرض الملف، مقابل fileTitleLabel أعلاه الذي يصف اسم الملف.
  static const String courseFileTitleLabel = 'عنوان الملف';
  static const String courseFileTitleHint = 'مثال: المحاضرة الأولى';
  static const String fileDescriptionLabel = 'الوصف (اختياري)';
  static const String fileCategoryLabel = 'التصنيف';
  static const String fileUploadingLabel = 'جارٍ الرفع…';

  /// يُبنى نصه في العرض من CloudinaryConfig حتى لا تتكرر الأرقام.
  static String fileConstraintsNote(int maxMegabytes, String extensions) =>
      'الحد الأقصى $maxMegabytes ميغابايت. الصيغ المسموحة: $extensions';

  static const String editFileTitle = 'تعديل بيانات الملف';
  static const String fileStatusLabel = 'حالة الملف';
  static const String fileStatusActive = 'ظاهر للطلاب';
  static const String fileStatusArchived = 'مؤرشف';
  static const String openFileAction = 'فتح';
  static const String archiveFileTitle = 'أرشفة الملف';
  static const String archiveFileConfirm =
      'سيُخفى الملف عن الطلاب مع بقائه محفوظًا. لا يمكن حذف الملف نهائيًا من '
      'التخزين من داخل التطبيق. هل تريد المتابعة؟';
  static const String fileOpenError = 'تعذر فتح الملف';
  static const String fileUploadedAtLabel = 'تاريخ الرفع';

  // Catalog / course details
  static const String courseOfferingsTileTitle = 'العروض الفصلية';
  static const String courseOfferingsTileDesc =
      'إدارة طرح المساقات في الفصول الدراسية';
  static const String courseCodeUniqueNote =
      'رمز المساق فريد ولا يمكن تكراره في مساق آخر.';

  // Enrollment attempts
  static const String attemptLabel = 'المحاولة';
  static const String completionPassedLabel = 'ناجح';
  static const String completionFailedLabel = 'راسب';
  static const String completionIncompleteLabel = 'غير مكتمل';
  static const String gradeLabel = 'التقدير';
  static const String completionStatusInvalid = 'نتيجة المساق غير صحيحة';

  static String completionStatusDisplay(String? completionStatus) {
    switch (completionStatus) {
      case 'passed':
        return completionPassedLabel;
      case 'failed':
        return completionFailedLabel;
      case 'incomplete':
        return completionIncompleteLabel;
      default:
        return '';
    }
  }
  static const String profileImageUpdatedLocally =
      'تم تحديث الصورة مؤقتًا على هذا الجهاز';
  static const String profileImageTemporaryNote =
      '* تم حفظ الصورة مؤقتًا على هذا الجهاز ولن تستمر بعد إعادة تشغيل التطبيق';

  // ===== Files feature (Student view) =====
  static const String filesLoadError = 'تعذر تحميل الملفات';
  static const String fileDetailLoadError = 'تعذر تحميل بيانات الملف';
  static const String offlineFileBadgeLabel = 'بدون إنترنت';
  static const String newFileBadgeLabel = 'جديد';
  static const String noFilesFoundMessage = 'لا توجد ملفات لعرضها';
  static const String fileInfoSectionTitle = 'معلومات الملف';
  static const String fileInfoSubjectLabel = 'المساق';
  static const String fileInfoSizeLabel = 'حجم الملف';
  static const String fileInfoDateLabel = 'تاريخ الإضافة';
  static const String storageUsageTitle = 'المساحة المستخدمة';
  static const String storageUsageFilesSuffix = 'ملفات';
  static const String fileAllFilter = 'كل الملفات';
  static const String filePdfFilter = 'PDF';
  static const String fileDownloadedFilter = 'المحملة';
  static const String filePresentationsFilter = 'عروض';
  static const String allFilesTitle = 'الملفات';
  static const String allFilesSearchHint = 'ابحث عن ملف، مساق...';
  static const String fileOpenExternalAction = 'فتح خارجي';
  static const String fileShareAction = 'مشاركة';
  static const String fileDownloadAction = 'تحميل';
  static const String offlineFilesTitle = 'الملفات المحملة';
  static const String noOfflineFilesMessage = 'لا توجد ملفات محملة بعد';
  static const String downloadProgressSheetTitle = 'جاري تحميل الملف';
  static const String downloadProgressCompleteLabel = 'مكتمل';
  static const String cancelDownloadAction = 'إلغاء التحميل';
  static const String downloadRemainingTimeLabel = 'يتبقى حوالي 10 ثوان...';
  static const String deleteFileAction = 'حذف';
  static const String downloadCompleteTitle = 'اكتمل التحميل';
  static const String fileDownloadError = 'تعذر تحميل الملف';
  static const String downloadSavedToPrefix = 'حُفظ الملف في: ';
  // Courses archive (Student view)
  static const String noArchivedCoursesMessage = 'لا توجد مقررات مؤرشفة';
  static const String coursesArchiveFilterLabel = 'تصفية';
  static const String coursesArchiveCompletedPrefix = 'تم إنجاز';
  static const String coursesArchiveCompletedSuffix = 'مساقات';
  static const String reactivateCourseAction = 'إعادة تنشيط';
}
