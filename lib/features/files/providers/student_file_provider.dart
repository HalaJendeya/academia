// lib/features/files/providers/student_file_provider.dart

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../models/student_app_file.dart';
import '../services/student_file_service.dart';

class StudentFileProvider extends ChangeNotifier {
  final StudentFileService _fileService;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  StudentFileProvider(this._fileService, {Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity() {
    _checkInitialConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChanged,
    );
  }

  // ---------------------------------------------------------------------
  // Network connectivity (drives the "offline" badge color on file cards)
  // ---------------------------------------------------------------------

  bool _isOnline = false;

  bool get isOnline => _isOnline;

  Future<void> _checkInitialConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _handleConnectivityChanged(result);
    } catch (_) {
      _isOnline = false;
      notifyListeners();
    }
  }

  void _handleConnectivityChanged(List<ConnectivityResult> results) {
    final isOnline =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);
    if (isOnline != _isOnline) {
      _isOnline = isOnline;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------
  // All files (All Files screen)
  // ---------------------------------------------------------------------

  List<StudentAppFile> _allFiles = [];
  bool _isLoadingAllFiles = false;
  String? _allFilesErrorMessage;
  bool _hasLoadedAllFiles = false;

  List<StudentAppFile> get allFiles => _allFiles;
  bool get isLoadingAllFiles => _isLoadingAllFiles;
  String? get allFilesErrorMessage => _allFilesErrorMessage;

  // ---------------------------------------------------------------------
  // Downloaded files (Offline Files screen)
  // ---------------------------------------------------------------------

  List<StudentAppFile> _downloadedFiles = [];
  bool _isLoadingDownloadedFiles = false;
  String? _downloadedFilesErrorMessage;
  bool _hasLoadedDownloadedFiles = false;

  List<StudentAppFile> get downloadedFiles => _downloadedFiles;
  bool get isLoadingDownloadedFiles => _isLoadingDownloadedFiles;
  String? get downloadedFilesErrorMessage => _downloadedFilesErrorMessage;

  int get downloadedFilesCount => _downloadedFiles.length;

  // ---------------------------------------------------------------------
  // Selected file (File Preview screen)
  // ---------------------------------------------------------------------

  StudentAppFile? _selectedFile;
  bool _isLoadingSelectedFile = false;
  String? _selectedFileErrorMessage;

  StudentAppFile? get selectedFile => _selectedFile;
  bool get isLoadingSelectedFile => _isLoadingSelectedFile;
  String? get selectedFileErrorMessage => _selectedFileErrorMessage;

  // ---------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------

  void clearSelectedFile() {
    _selectedFile = null;
    _selectedFileErrorMessage = null;
    _isLoadingSelectedFile = false;
    notifyListeners();
  }

  Future<void> loadAllFiles({bool forceRefresh = false}) async {
    if (_hasLoadedAllFiles && !forceRefresh) return;
    if (_isLoadingAllFiles) return;

    _isLoadingAllFiles = true;
    _allFilesErrorMessage = null;
    notifyListeners();

    try {
      _allFiles = await _fileService.getAllFiles();
      _hasLoadedAllFiles = true;
    } on StudentFileException catch (e) {
      _allFilesErrorMessage = e.message;
    } catch (e) {
      _allFilesErrorMessage = AppStrings.filesLoadError;
    } finally {
      _isLoadingAllFiles = false;
      notifyListeners();
    }
  }

  Future<void> loadDownloadedFiles({bool forceRefresh = false}) async {
    if (_hasLoadedDownloadedFiles && !forceRefresh) return;
    if (_isLoadingDownloadedFiles) return;

    _isLoadingDownloadedFiles = true;
    _downloadedFilesErrorMessage = null;
    notifyListeners();

    try {
      _downloadedFiles = await _fileService.getDownloadedFiles();
      _hasLoadedDownloadedFiles = true;
    } on StudentFileException catch (e) {
      _downloadedFilesErrorMessage = e.message;
    } catch (e) {
      _downloadedFilesErrorMessage = AppStrings.filesLoadError;
    } finally {
      _isLoadingDownloadedFiles = false;
      notifyListeners();
    }
  }

  Future<void> loadFileById(String id, {bool forceRefresh = false}) async {
    if (_selectedFile?.id == id && !forceRefresh) return;
    if (_isLoadingSelectedFile) return;

    _isLoadingSelectedFile = true;
    _selectedFileErrorMessage = null;
    notifyListeners();

    try {
      _selectedFile = await _fileService.getFileById(id);
    } on StudentFileException catch (e) {
      _selectedFileErrorMessage = e.message;
    } catch (e) {
      _selectedFileErrorMessage = AppStrings.fileDetailLoadError;
    } finally {
      _isLoadingSelectedFile = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}