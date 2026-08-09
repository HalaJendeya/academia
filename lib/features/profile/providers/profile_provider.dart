import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../models/student_profile.dart';
import '../services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _profileService;

  ProfileProvider(this._profileService);

  StudentProfile? _profile;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _loadedUserId;
  Uint8List? _localPhotoBytes;

  StudentProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  Uint8List? get localPhotoBytes => _localPhotoBytes;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearProfile() {
    _profile = null;
    _errorMessage = null;
    _isLoading = false;
    _isSaving = false;
    _loadedUserId = null;
    _localPhotoBytes = null;
    notifyListeners();
  }

  Future<void> loadProfile({bool forceRefresh = false}) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    // Account switch check
    if (currentUid != _loadedUserId) {
      _profile = null;
      _errorMessage = null;
      _localPhotoBytes = null;
      _loadedUserId = currentUid;
    } else if (_profile != null && !forceRefresh) {
      // Avoid duplicate fetches if profile is already loaded
      return;
    }

    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _profileService.getCurrentProfile();
      _loadedUserId = currentUid;
    } on ProfileException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = AppStrings.profileLoadError;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String fullName,
    String? major,
    int? academicLevel,
  }) async {
    if (_isSaving) return false;

    final trimmedName = fullName.trim();
    if (trimmedName.isEmpty) {
      _errorMessage = AppStrings.fullNameRequired;
      notifyListeners();
      return false;
    }
    if (trimmedName.length < 2) {
      _errorMessage = AppStrings.fullNameTooShort;
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _profileService.updateProfile(
        fullName: trimmedName,
        major: major,
        academicLevel: academicLevel,
      );

      // Normalize optional values locally
      final normalizedMajor = (major != null && major.trim().isNotEmpty)
          ? major.trim()
          : null;
      final normalizedAcademicLevel = (academicLevel != null && academicLevel > 0)
          ? academicLevel
          : null;

      // Immediate local cache update to prevent duplicate fetches
      _profile = _profile?.copyWith(
        fullName: trimmedName,
        major: normalizedMajor ?? _profile?.major,
        academicLevel: normalizedAcademicLevel ?? _profile?.academicLevel,
      );

      notifyListeners();
      return true;
    } on ProfileException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = AppStrings.profileUpdateError;
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> uploadProfilePicture(Uint8List bytes) async {
    // Save locally in memory for session-only preview
    _localPhotoBytes = bytes;
    notifyListeners();
    return true;
  }
}
