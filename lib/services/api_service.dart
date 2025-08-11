import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../screens/debug_screen.dart';

class ApiService {
  static const String _baseUrl = 'https://test-backend-batchmate.medha-analytics.ai';
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<http.Response> _post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_baseUrl$path');
    print('Attempting POST to: $uri');
    DebugScreen.addLog('API: POST to $uri');
    
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        print('POST attempt ${attempt + 1}/3');
        DebugScreen.addLog('API: Attempt ${attempt + 1}/3');
        
        final resp = await _client.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 15)); // Reduced from 30 to 15 seconds
        
        print('Response status: ${resp.statusCode}');
        print('Response body: ${resp.body}');
        DebugScreen.addLog('API: Response status ${resp.statusCode}');
        DebugScreen.addLog('API: Response body: ${resp.body}');
        
        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          print('POST successful');
          DebugScreen.addLog('API: ✅ POST successful');
          return resp;
        } else {
          print('POST failed with status ${resp.statusCode}: ${resp.body}');
          DebugScreen.addLog('API: ❌ POST failed with status ${resp.statusCode}');
        }
      } catch (e) {
        print('POST attempt ${attempt + 1} failed: $e');
        String errorMsg = e.toString();
        
        // Better error messages for common network issues
        if (e is SocketException) {
          errorMsg = "Network connection failed. Please check your internet connection.";
        } else if (e is TimeoutException) {
          errorMsg = "Request timed out. Server may be slow or unreachable.";
        } else if (e is HttpException) {
          errorMsg = "HTTP error: ${e.message}";
        }
        
        DebugScreen.addLog('API: ❌ Attempt ${attempt + 1} failed: $errorMsg');
        
        if (attempt < 2) {
          final delay = Duration(milliseconds: 2000 * (attempt + 1)); // Increased delay between retries
          await Future.delayed(delay);
          DebugScreen.addLog('API: Retrying in ${delay.inMilliseconds}ms...');
        }
      }
    }
    DebugScreen.addLog('API: ❌ FAILED after 3 attempts');
    throw Exception('POST $path failed after 3 retries');
  }

  Future<http.Response> _get(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final resp = await _client.get(uri, headers: {'Content-Type': 'application/json'});
        if (resp.statusCode >= 200 && resp.statusCode < 300) return resp;
      } catch (_) {
        await Future.delayed(Duration(milliseconds: 300 * (attempt + 1)));
      }
    }
    throw Exception('GET $path failed after retries');
  }

  Future<http.Response> submitImage(Map<String, dynamic> payload) async {
    print('Submitting image with payload keys: ${payload.keys.toList()}');
    print('Session ID: ${payload['sessionId']}');
    print('Capture ID: ${payload['captureId']}');
    print('Image size: ${payload['image']?.length ?? 'null'} characters');
    
    DebugScreen.addLog('API: Submitting image...');
    DebugScreen.addLog('API: Session: ${payload['sessionId']}');
    DebugScreen.addLog('API: Capture: ${payload['captureId']}');
    DebugScreen.addLog('API: Image size: ${payload['image']?.length ?? 'null'} chars');
    
    return await _post('/api/submit', payload);
  }

  Future<http.Response> submitDirectResult(Map<String, dynamic> payload) async {
    print('📱 MOBILE_OCR: Submitting direct result with payload keys: ${payload.keys.toList()}');
    print('📱 Session ID: ${payload['sessionId']}');
    print('📱 Batch Number: ${payload['batchNumber']}');
    print('📱 Quantity: ${payload['quantity']}');
    print('📱 Confidence: ${payload['confidence']}');
    
    DebugScreen.addLog('MOBILE_OCR: Submitting direct batch result...');
    DebugScreen.addLog('MOBILE_OCR: Session: ${payload['sessionId']}');
    DebugScreen.addLog('MOBILE_OCR: Batch: ${payload['batchNumber']}');
    DebugScreen.addLog('MOBILE_OCR: Quantity: ${payload['quantity']}');
    DebugScreen.addLog('MOBILE_OCR: Source: ${payload['source']}');
    
    return await _post('/api/submit', payload);
  }

  Future<Map<String, dynamic>> getStatus(String sessionId) async {
    final r = await _get('/api/status/$sessionId');
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  // Simple connectivity test
  Future<bool> testConnectivity() async {
    try {
      DebugScreen.addLog('API: Testing connectivity to $_baseUrl...');
      final response = await _client.get(
        Uri.parse('$_baseUrl/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      DebugScreen.addLog('API: Connectivity test - Status: ${response.statusCode}');
      return response.statusCode < 500; // Accept any non-server-error response
    } catch (e) {
      DebugScreen.addLog('API: ❌ Connectivity test failed: $e');
      return false;
    }
  }
}
