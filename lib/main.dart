// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app/akademia_app.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/onboarding/providers/onboarding_provider.dart';
import 'features/profile/providers/profile_provider.dart';
import 'features/profile/services/profile_service.dart';
import 'features/profile/providers/study_preferences_provider.dart';
import 'features/profile/services/study_preferences_service.dart';
import 'features/profile/providers/support_provider.dart';
import 'features/profile/services/support_service.dart';
import 'features/notifications/providers/notification_settings_provider.dart';
import 'features/notifications/services/notification_settings_service.dart';
import 'features/courses/providers/student_course_provider.dart';
import 'features/courses/services/student_course_service.dart';
import 'features/courses/providers/student_course_file_provider.dart';
import 'features/courses/services/student_course_file_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider(
          create: (_) => ProfileProvider(ProfileService()),
        ),
        ChangeNotifierProvider(
          create: (_) => StudyPreferencesProvider(StudyPreferencesService()),
        ),
        ChangeNotifierProvider(
          create: (_) => SupportProvider(SupportService()),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              NotificationSettingsProvider(NotificationSettingsService()),
        ),
        ChangeNotifierProvider(
          create: (_) => CourseProvider(CourseService()),
        ),
        ChangeNotifierProvider(
          create: (_) => CourseFileProvider(CourseFileService()),
        ),
      ],
      child: const AkademiaApp(),
    ),
  );
}