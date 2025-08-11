import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/local_batch_data.dart';
import '../services/session_data_service.dart';

enum SessionDataStatus {
  idle,
  downloading,
  ready,
  error,
}

class SessionProvider extends ChangeNotifier {
  String? _sessionId;
  bool _loading = false;
  SessionDataStatus _dataStatus = SessionDataStatus.idle;
  SessionBatchData? _sessionData;
  String? _errorMessage;
  int _totalBatches = 0;

  final SessionDataService _sessionDataService = SessionDataService();

  // Getters
  String? get sessionId => _sessionId;
  bool get loading => _loading;
  SessionDataStatus get dataStatus => _dataStatus;
  SessionBatchData? get sessionData => _sessionData;
  String? get errorMessage => _errorMessage;
  int get totalBatches => _totalBatches;
  bool get hasSessionData => _sessionData != null && _sessionData!.batches.isNotEmpty;

  // Status helpers
  bool get isDownloading => _dataStatus == SessionDataStatus.downloading;
  bool get isReady => _dataStatus == SessionDataStatus.ready;
  bool get hasError => _dataStatus == SessionDataStatus.error;

  Future<void> loadSavedSession() async {
    _loading = true;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    _sessionId = prefs.getString('sessionId');
    
    // If we have a session ID, check for local batch data
    if (_sessionId != null && _sessionId!.isNotEmpty) {
      await _loadLocalSessionData();
    }
    
    _loading = false;
    notifyListeners();
  }

  Future<void> saveSession(String id) async {
    _sessionId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sessionId', id);
    
    // Clear previous session data
    _sessionData = null;
    _dataStatus = SessionDataStatus.idle;
    _errorMessage = null;
    _totalBatches = 0;
    
    notifyListeners();
    
    // Download batch data for this session
    await downloadSessionData();
  }

  Future<void> clearSession() async {
    final oldSessionId = _sessionId;
    
    _sessionId = null;
    _sessionData = null;
    _dataStatus = SessionDataStatus.idle;
    _errorMessage = null;
    _totalBatches = 0;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sessionId');
    
    // Clear local session data
    if (oldSessionId != null) {
      await _sessionDataService.clearSessionData(oldSessionId);
    }
    
    notifyListeners();
  }

  /// Download session batch data from server
  Future<void> downloadSessionData({bool forceRefresh = false}) async {
    if (_sessionId == null || _sessionId!.isEmpty) {
      _dataStatus = SessionDataStatus.error;
      _errorMessage = 'No session ID available';
      notifyListeners();
      return;
    }

    _dataStatus = SessionDataStatus.downloading;
    _errorMessage = null;
    notifyListeners();

    try {
      final sessionData = await _sessionDataService.getSessionData(
        _sessionId!,
        forceRefresh: forceRefresh,
      );

      if (sessionData != null) {
        _sessionData = sessionData;
        _totalBatches = sessionData.totalBatches;
        _dataStatus = SessionDataStatus.ready;
        _errorMessage = null;
        
        print('✅ SESSION_PROVIDER: Downloaded ${_totalBatches} batches for session $_sessionId');
      } else {
        _dataStatus = SessionDataStatus.error;
        _errorMessage = 'Failed to download session data. Please check if item codes have been submitted.';
      }
    } catch (e) {
      _dataStatus = SessionDataStatus.error;
      _errorMessage = 'Error downloading session data: $e';
      print('❌ SESSION_PROVIDER: Error downloading session data: $e');
    }

    notifyListeners();
  }

  /// Load local session data if available
  Future<void> _loadLocalSessionData() async {
    if (_sessionId == null) return;

    try {
      final hasLocal = await _sessionDataService.hasLocalSessionData(_sessionId!);
      if (hasLocal) {
        final sessionData = await _sessionDataService.getSessionData(_sessionId!);
        if (sessionData != null) {
          _sessionData = sessionData;
          _totalBatches = sessionData.totalBatches;
          _dataStatus = SessionDataStatus.ready;
          print('📂 SESSION_PROVIDER: Loaded cached data for session $_sessionId');
        }
      }
    } catch (e) {
      print('⚠️ SESSION_PROVIDER: Error loading cached session data: $e');
    }
  }

  /// Get batches for OCR matching
  Future<Map<String, LocalBatchData>> getBatchesForMatching() async {
    if (_sessionId == null || !hasSessionData) {
      return {};
    }
    
    return await _sessionDataService.getBatchesForSession(_sessionId!);
  }

  /// Submit batch result directly to server
  Future<bool> submitBatchResult({
    required String captureId,
    required String batchNumber,
    required int quantity,
  }) async {
    if (_sessionId == null) {
      _errorMessage = 'No session ID available';
      notifyListeners();
      return false;
    }

    try {
      final success = await _sessionDataService.submitBatchResult(
        sessionId: _sessionId!,
        captureId: captureId,
        batchNumber: batchNumber,
        quantity: quantity,
      );

      if (!success) {
        _errorMessage = 'Failed to submit batch result';
        notifyListeners();
      }

      return success;
    } catch (e) {
      _errorMessage = 'Error submitting batch result: $e';
      notifyListeners();
      return false;
    }
  }

  /// Get session statistics
  Future<Map<String, int>> getStats() async {
    return await _sessionDataService.getStats();
  }
}
