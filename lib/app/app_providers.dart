import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/auth/providers/auth_provider.dart';
import '../features/onboarding/providers/onboarding_provider.dart';
import '../features/profile/providers/profile_provider.dart';
import '../features/profile/services/profile_service.dart';
import '../features/profile/providers/study_preferences_provider.dart';
import '../features/profile/services/study_preferences_service.dart';
import '../features/profile/providers/support_provider.dart';
import '../features/profile/services/support_service.dart';
import '../features/notifications/providers/notification_settings_provider.dart';
import '../features/notifications/services/notification_settings_service.dart';
import '../features/courses/providers/course_provider.dart';
import '../features/courses/services/course_service.dart';
import '../features/enrollments/providers/enrollment_provider.dart';
import '../features/enrollments/services/enrollment_service.dart';

final List<SingleChildWidget> appProviders = [
  ChangeNotifierProvider(create: (_) => AuthProvider()),
  ChangeNotifierProvider(create: (_) => OnboardingProvider()),
  ChangeNotifierProvider(create: (_) => ProfileProvider(ProfileService())),
  ChangeNotifierProvider(
    create: (_) => StudyPreferencesProvider(StudyPreferencesService()),
  ),
  ChangeNotifierProvider(create: (_) => SupportProvider(SupportService())),
  ChangeNotifierProvider(
    create: (_) => NotificationSettingsProvider(NotificationSettingsService()),
  ),
  ChangeNotifierProvider(create: (_) => CourseProvider(CourseService())),
  ChangeNotifierProvider(
    create: (_) => EnrollmentProvider(EnrollmentService()),
  ),
];
