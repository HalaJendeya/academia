import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/study_day_constants.dart';
import '../models/study_preferences.dart';
import '../services/study_preferences_service.dart';

class StudyPreferencesProvider extends ChangeNotifier {
  final StudyPreferencesService _service;

  StudyPreferencesProvider(this._service);

  StudyPreferences? _preferences;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  String? _errorMessage;
  String? _loadedUserId;

  StudyPreferences? get preferences => _preferences;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearPreferences() {
    _preferences = null;
    _loadedUserId = null;
    _errorMessage = null;
    _hasUnsavedChanges = false;
    _isLoading = false;
    _isSaving = false;
    notifyListeners();
  }

  Future<void> loadPreferences({bool forceRefresh = false}) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    // Account switch check
    if (currentUid != _loadedUserId) {
      clearPreferences();
      _loadedUserId = currentUid;
    } else if (_preferences != null && !forceRefresh) {
      return;
    }

    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _preferences = await _service.getCurrentPreferences();
      _loadedUserId = currentUid;
      _hasUnsavedChanges = false;
    } on StudyPreferencesException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = AppStrings.studyPreferencesLoadError;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleStudyDay(String day) {
    if (_preferences == null) return;
    if (!StudyDayConstants.orderedDays.contains(day)) return;

    final daysSet = _preferences!.studyDays.toSet();
    if (daysSet.contains(day)) {
      daysSet.remove(day);
    } else {
      daysSet.add(day);
    }

    // Convert Set back to a sorted list
    final sortedList = daysSet.toList();
    sortedList.sort((a, b) {
      final indexA = StudyDayConstants.orderedDays.indexOf(a);
      final indexB = StudyDayConstants.orderedDays.indexOf(b);
      return indexA.compareTo(indexB);
    });

    _preferences = _preferences!.copyWith(studyDays: sortedList);
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  void setPreferredSessionDuration(int duration) {
    if (_preferences == null) return;
    if (duration < 5 || duration > 180) return;

    _preferences = _preferences!.copyWith(preferredSessionDuration: duration);
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  Future<bool> savePreferences() async {
    if (_isSaving || _preferences == null) return false;

    if (_preferences!.studyDays.isEmpty) {
      _errorMessage = AppStrings.selectAtLeastOneStudyDay;
      notifyListeners();
      return false;
    }

    if (_preferences!.preferredSessionDuration < 5 ||
        _preferences!.preferredSessionDuration > 180) {
      _errorMessage = AppStrings.invalidCustomDuration;
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.savePreferences(_preferences!);
      _hasUnsavedChanges = false;
      return true;
    } on StudyPreferencesException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = AppStrings.studyPreferencesSaveError;
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
