import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../models/notification_settings.dart';
import '../services/notification_settings_service.dart';

class NotificationSettingsProvider extends ChangeNotifier {
  final NotificationSettingsService _service;

  NotificationSettingsProvider(this._service);

  NotificationSettings? _settings;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  String? _errorMessage;
  String? _loadedUserId;

  NotificationSettings? get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSettings() {
    _settings = null;
    _loadedUserId = null;
    _errorMessage = null;
    _hasUnsavedChanges = false;
    _isLoading = false;
    _isSaving = false;
    notifyListeners();
  }

  Future<void> loadSettings({bool forceRefresh = false}) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    // Account switch check
    if (currentUid != _loadedUserId) {
      clearSettings();
      _loadedUserId = currentUid;
    } else if (_settings != null && !forceRefresh) {
      return;
    }

    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _settings = await _service.getCurrentSettings();
      _loadedUserId = currentUid;
      _hasUnsavedChanges = false;
    } on NotificationSettingsException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = AppStrings.notificationSettingsLoadError;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updateSettings(NotificationSettings newSettings) {
    if (_settings == null) return;
    _settings = newSettings;
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  void setAssignmentReminders(bool value) {
    if (_settings == null) return;
    _updateSettings(_settings!.copyWith(assignmentReminders: value));
  }

  void setLectureReminders(bool value) {
    if (_settings == null) return;
    _updateSettings(_settings!.copyWith(lectureReminders: value));
  }

  void setStudySessionReminders(bool value) {
    if (_settings == null) return;
    _updateSettings(_settings!.copyWith(studySessionReminders: value));
  }

  void setFileNotifications(bool value) {
    if (_settings == null) return;
    _updateSettings(_settings!.copyWith(fileNotifications: value));
  }

  void setSharedSpaceNotifications(bool value) {
    if (_settings == null) return;
    _updateSettings(_settings!.copyWith(sharedSpaceNotifications: value));
  }

  void setDailySummary(bool value) {
    if (_settings == null) return;
    _updateSettings(_settings!.copyWith(dailySummary: value));
  }

  void setQuietHoursStartMinutes(int value) {
    if (_settings == null) return;
    if (value < 0 || value > 1439) return; // Reject invalid values
    _updateSettings(_settings!.copyWith(quietHoursStartMinutes: value));
  }

  void setQuietHoursEndMinutes(int value) {
    if (_settings == null) return;
    if (value < 0 || value > 1439) return; // Reject invalid values
    _updateSettings(_settings!.copyWith(quietHoursEndMinutes: value));
  }

  Future<bool> saveSettings() async {
    if (_isSaving || _settings == null) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.saveSettings(_settings!);
      _hasUnsavedChanges = false;
      return true;
    } on NotificationSettingsException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = AppStrings.notificationSettingsSaveError;
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
