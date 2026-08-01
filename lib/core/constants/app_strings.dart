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
}
