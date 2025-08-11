import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/local_batch_data.dart';
import 'local_batch_database.dart';

/// Service for downloading and managing session batch data
class SessionDataService {
  static final SessionDataService _instance = SessionDataService._internal();
  factory SessionDataService() => _instance;
  SessionDataService._internal();

  final LocalBatchDatabase _database = LocalBatchDatabase();
  final String baseUrl = 'https://batchmate.medha-analytics.ai';  // Update with your server URL

  /// Download session data from server
  Future<SessionBatchData?> downloadSessionData(String sessionId) async {
    try {
      final endpoint = '$baseUrl/api/session-data/$sessionId';
      print('📡 SESSION_API: Requesting batch data from server');
      print('📡 SESSION_API: Endpoint: GET $endpoint');
      print('📡 SESSION_API: Session ID: $sessionId');
      print('📡 SESSION_API: Headers: Content-Type: application/json');
      
      final startTime = DateTime.now();
      final response = await http.get(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;

      print('📡 SESSION_API: Response received in ${responseTime}ms');
      print('📡 SESSION_API: Status Code: ${response.statusCode}');
      print('📡 SESSION_API: Response Size: ${response.body.length} characters');

      if (response.statusCode == 200) {
        print('📡 SESSION_API: ✅ Success response received');
        final data = jsonDecode(response.body);
        print('📡 SESSION_API: Response Body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}${response.body.length > 500 ? '...' : ''}');
        
        if (data['success'] == true) {
          final sessionData = SessionBatchData.fromServerResponse(sessionId, data);
          
          // Store locally for offline use
          await _database.storeSessionData(sessionData);
          
          print('📡 SESSION_API: ✅ Downloaded ${sessionData.totalBatches} batches for session $sessionId');
          print('📡 SESSION_API: ✅ Data stored locally for offline use');
          return sessionData;
        } else {
          print('📡 SESSION_API: ❌ Server returned success=false');
          print('📡 SESSION_API: ❌ Error message: ${data['message']}');
          return null;
        }
      } else if (response.statusCode == 404) {
        print('📡 SESSION_API: ❌ HTTP 404 - Session not found');
        print('📡 SESSION_API: ❌ This means session has no batch data or doesn\'t exist');
        print('📡 SESSION_API: Response Body: ${response.body}');
        return null;
      } else {
        print('📡 SESSION_API: ❌ HTTP Error ${response.statusCode}');
        print('📡 SESSION_API: ❌ Response Body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('📡 SESSION_API: ❌ Network/Exception Error: $e');
      print('📡 SESSION_API: ❌ Falling back to cached data...');
      
      // Try to get cached data if network fails
      final cachedData = await _database.getSessionData(sessionId);
      if (cachedData != null) {
        print('📂 SESSION_DATA: Using cached data for session $sessionId');
        return cachedData;
      }
      
      return null;
    }
  }

  /// Get session data (from cache or download)
  Future<SessionBatchData?> getSessionData(String sessionId, {bool forceRefresh = false}) async {
    try {
      // Check if we have cached data and don't need to refresh
      if (!forceRefresh) {
        final cachedData = await _database.getSessionData(sessionId);
        if (cachedData != null) {
          // Check if data is still fresh (less than 1 hour old)
          final age = DateTime.now().difference(cachedData.downloadedAt);
          if (age.inHours < 1) {
            print('📂 SESSION_DATA: Using fresh cached data for session $sessionId');
            return cachedData;
          }
        }
      }

      // Download fresh data
      return await downloadSessionData(sessionId);
    } catch (e) {
      print('❌ SESSION_DATA: Error getting session data: $e');
      return null;
    }
  }

  /// Check if session data is available locally
  Future<bool> hasLocalSessionData(String sessionId) async {
    return await _database.hasSessionData(sessionId);
  }

  /// Get batches for session (for OCR matching)
  Future<Map<String, LocalBatchData>> getBatchesForSession(String sessionId) async {
    return await _database.getBatchesForSession(sessionId);
  }

  /// Clear session data
  Future<void> clearSessionData(String sessionId) async {
    await _database.clearSession(sessionId);
    print('🗑️ SESSION_DATA: Cleared data for session $sessionId');
  }

  /// Submit batch result directly to server (mobile direct submission)
  Future<bool> submitBatchResult({
    required String sessionId,
    required String captureId,
    required String batchNumber,
    required int quantity,
  }) async {
    try {
      print('📤 SESSION_DATA: Submitting direct result - Batch: $batchNumber, Quantity: $quantity');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/submit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sessionId': sessionId,
          'captureId': captureId,
          'batchNumber': batchNumber,
          'quantity': quantity,
          'directSubmission': true,  // Flag for mobile direct submission
          'submitTimestamp': DateTime.now().millisecondsSinceEpoch,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('✅ SESSION_DATA: Direct submission successful');
          return true;
        } else {
          print('❌ SESSION_DATA: Server error in direct submission: ${data['message']}');
          return false;
        }
      } else {
        print('❌ SESSION_DATA: HTTP error in direct submission ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ SESSION_DATA: Network error in direct submission: $e');
      return false;
    }
  }

  /// Test server connectivity
  Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final supportsLocalProcessing = data['mobile_local_processing'] == true;
        
        print('✅ SESSION_DATA: Server connected. Local processing support: $supportsLocalProcessing');
        return true;
      } else {
        print('❌ SESSION_DATA: Server health check failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ SESSION_DATA: Connection test failed: $e');
      return false;
    }
  }

  /// Get database statistics
  Future<Map<String, int>> getStats() async {
    return await _database.getStats();
  }
}
