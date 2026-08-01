import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/study_day_constants.dart';
import '../models/onboarding_preferences.dart';
import '../services/onboarding_service.dart';

class OnboardingProvider extends ChangeNotifier {
  final OnboardingService _onboardingService;

  String? _activeUserId;

  // Editable temporary values
  late Set<String> _studyDays;
  late int _preferredSessionDuration;
  late bool _taskReminders;
  late bool _studySessionReminders;
  late bool _deadlineReminders;
  late bool _dailySummary;
  late bool _courseNotifications;

  bool _isLoading = false;
  String? _errorMessage;

  OnboardingProvider({OnboardingService? onboardingService})
    : _onboardingService = onboardingService ?? OnboardingService() {
    _applyDefaults();
  }

  // Getters
  Set<String> get studyDays => _studyDays;
  int get preferredSessionDuration => _preferredSessionDuration;
  bool get taskReminders => _taskReminders;
  bool get studySessionReminders => _studySessionReminders;
  bool get deadlineReminders => _deadlineReminders;
  bool get dailySummary => _dailySummary;
  bool get courseNotifications => _courseNotifications;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _applyDefaults() {
    final defaults = OnboardingPreferences.defaults();
    _studyDays = defaults.studyDays.toSet();
    _preferredSessionDuration = defaults.preferredSessionDuration;
    _taskReminders = defaults.taskReminders;
    _studySessionReminders = defaults.studySessionReminders;
    _deadlineReminders = defaults.deadlineReminders;
    _dailySummary = defaults.dailySummary;
    _courseNotifications = defaults.courseNotifications;
    _errorMessage = null;
    _isLoading = false;
  }

  void initializeForUser(String uid) {
    if (_activeUserId == uid) return;
    _activeUserId = uid;
    _applyDefaults();
    notifyListeners();
  }

  void reset() {
    _applyDefaults();
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void toggleStudyDay(String day) {
    if (_studyDays.contains(day)) {
      _studyDays.remove(day);
    } else {
      _studyDays.add(day);
    }
    notifyListeners();
  }

  void setPreferredSessionDuration(int duration) {
    _preferredSessionDuration = duration;
    notifyListeners();
  }

  void setTaskReminders(bool value) {
    _taskReminders = value;
    notifyListeners();
  }

  void setStudySessionReminders(bool value) {
    _studySessionReminders = value;
    notifyListeners();
  }

  void setDeadlineReminders(bool value) {
    _deadlineReminders = value;
    notifyListeners();
  }

  void setDailySummary(bool value) {
    _dailySummary = value;
    notifyListeners();
  }

  void setCourseNotifications(bool value) {
    _courseNotifications = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> checkOnboardingCompleted() async {
    _errorMessage = null;
    try {
      return await _onboardingService.isOnboardingCompleted();
    } catch (_) {
      _errorMessage = AppStrings.onboardingStatusError;
      return false;
    }
  }

  Future<bool> completeOnboarding() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // Build sorted list representing the Set choices
      final sortedDays = StudyDayConstants.orderedDays
          .where((day) => _studyDays.contains(day))
          .toList(growable: false);

      final preferences = OnboardingPreferences(
        studyDays: sortedDays,
        preferredSessionDuration: _preferredSessionDuration,
        taskReminders: _taskReminders,
        studySessionReminders: _studySessionReminders,
        deadlineReminders: _deadlineReminders,
        dailySummary: _dailySummary,
        courseNotifications: _courseNotifications,
      );

      await _onboardingService.completeOnboarding(preferences);
      reset();
      return true;
    } on OnboardingException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = AppStrings.onboardingSaveError;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> skipOnboarding() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _onboardingService.skipOnboarding();
      reset();
      return true;
    } on OnboardingException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = AppStrings.onboardingSkipError;
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
