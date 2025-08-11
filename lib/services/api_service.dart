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
    final requestBodyStr = jsonEncode(body);
    
    print('📡 API_REQUEST: POST $uri');
    print('📡 API_REQUEST: Headers: Content-Type: application/json');
    print('📡 API_REQUEST: Body Keys: ${body.keys.toList()}');
    if (requestBodyStr.length > 1000) {
      print('📡 API_REQUEST: Body Size: ${requestBodyStr.length} characters (truncated for logs)');
    } else {
      print('📡 API_REQUEST: Body: $requestBodyStr');
    }
    DebugScreen.addLog('API: POST to $uri');
    
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        print('📡 API_REQUEST: Attempt ${attempt + 1}/3');
        DebugScreen.addLog('API: Attempt ${attempt + 1}/3');
        
        final startTime = DateTime.now();
        final resp = await _client.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: requestBodyStr,
        ).timeout(const Duration(seconds: 15));
        final responseTime = DateTime.now().difference(startTime).inMilliseconds;
        
        print('📡 API_RESPONSE: Status Code: ${resp.statusCode}');
        print('📡 API_RESPONSE: Response Time: ${responseTime}ms');
        print('📡 API_RESPONSE: Response Size: ${resp.body.length} characters');
        print('📡 API_RESPONSE: Body: ${resp.body.substring(0, resp.body.length > 500 ? 500 : resp.body.length)}${resp.body.length > 500 ? '...' : ''}');
        
        DebugScreen.addLog('API: Response status ${resp.statusCode} in ${responseTime}ms');
        DebugScreen.addLog('API: Response body: ${resp.body}');
        
        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          print('📡 API_RESPONSE: ✅ Success');
          DebugScreen.addLog('API: ✅ POST successful');
          return resp;
        } else {
          print('📡 API_RESPONSE: ❌ HTTP Error ${resp.statusCode}');
          DebugScreen.addLog('API: ❌ POST failed with status ${resp.statusCode}');
        }
      } catch (e) {
        print('📡 API_ERROR: Attempt ${attempt + 1} failed: $e');
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
          final delay = Duration(milliseconds: 2000 * (attempt + 1));
          print('📡 API_RETRY: Waiting ${delay.inMilliseconds}ms before retry...');
          await Future.delayed(delay);
          DebugScreen.addLog('API: Retrying in ${delay.inMilliseconds}ms...');
        }
      }
    }
    print('📡 API_ERROR: ❌ FAILED after 3 attempts');
    DebugScreen.addLog('API: ❌ FAILED after 3 attempts');
    throw Exception('POST $path failed after 3 retries');
  }

  Future<http.Response> _get(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    print('📡 API_REQUEST: GET $uri');
    print('📡 API_REQUEST: Headers: Content-Type: application/json');
    
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        print('📡 API_REQUEST: Attempt ${attempt + 1}/3');
        final startTime = DateTime.now();
        final resp = await _client.get(uri, headers: {'Content-Type': 'application/json'});
        final responseTime = DateTime.now().difference(startTime).inMilliseconds;
        
        print('📡 API_RESPONSE: Status Code: ${resp.statusCode}');
        print('📡 API_RESPONSE: Response Time: ${responseTime}ms');
        print('📡 API_RESPONSE: Response Size: ${resp.body.length} characters');
        
        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          print('📡 API_RESPONSE: ✅ Success');
          return resp;
        } else {
          print('📡 API_RESPONSE: ❌ HTTP Error ${resp.statusCode}');
        }
      } catch (e) {
        print('📡 API_ERROR: Attempt ${attempt + 1} failed: $e');
        if (attempt < 2) {
          await Future.delayed(Duration(milliseconds: 300 * (attempt + 1)));
        }
      }
    }
    print('📡 API_ERROR: ❌ GET $path failed after 3 attempts');
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
    print('📱 MOBILE_OCR_SUBMIT: Starting direct result submission');
    print('📱 MOBILE_OCR_SUBMIT: Session ID: ${payload['sessionId']}');
    print('📱 MOBILE_OCR_SUBMIT: Batch Number: ${payload['batchNumber']}');
    print('📱 MOBILE_OCR_SUBMIT: Quantity: ${payload['quantity']}');
    print('📱 MOBILE_OCR_SUBMIT: Confidence: ${payload['confidence']}');
    print('📱 MOBILE_OCR_SUBMIT: Source: ${payload['source']}');
    print('📱 MOBILE_OCR_SUBMIT: DirectSubmission: ${payload['directSubmission']}');
    print('📱 MOBILE_OCR_SUBMIT: Endpoint: POST $_baseUrl/api/submit');
    
    DebugScreen.addLog('MOBILE_OCR: Submitting direct batch result...');
    DebugScreen.addLog('MOBILE_OCR: Session: ${payload['sessionId']}');
    DebugScreen.addLog('MOBILE_OCR: Batch: ${payload['batchNumber']}');
    DebugScreen.addLog('MOBILE_OCR: Quantity: ${payload['quantity']}');
    DebugScreen.addLog('MOBILE_OCR: Source: ${payload['source']}');
    
    return await _post('/api/submit', payload);
  }

  Future<Map<String, dynamic>> getStatus(String sessionId) async {
    print('📡 STATUS_CHECK: Requesting status for session $sessionId');
    print('📡 STATUS_CHECK: Endpoint: GET $_baseUrl/api/status/$sessionId');
    
    final r = await _get('/api/status/$sessionId');
    final result = jsonDecode(r.body) as Map<String, dynamic>;
    
    print('📡 STATUS_CHECK: ✅ Status received: ${result.keys.toList()}');
    return result;
  }

  // Simple connectivity test
  Future<bool> testConnectivity() async {
    try {
      print('📡 CONNECTIVITY_TEST: Testing connection to $_baseUrl');
      print('📡 CONNECTIVITY_TEST: Endpoint: GET $_baseUrl/');
      
      DebugScreen.addLog('API: Testing connectivity to $_baseUrl...');
      final startTime = DateTime.now();
      final response = await _client.get(
        Uri.parse('$_baseUrl/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      
      print('📡 CONNECTIVITY_TEST: Status Code: ${response.statusCode}');
      print('📡 CONNECTIVITY_TEST: Response Time: ${responseTime}ms');
      
      DebugScreen.addLog('API: Connectivity test - Status: ${response.statusCode} in ${responseTime}ms');
      final isConnected = response.statusCode < 500;
      
      if (isConnected) {
        print('📡 CONNECTIVITY_TEST: ✅ Server is reachable');
      } else {
        print('📡 CONNECTIVITY_TEST: ❌ Server error detected');
      }
      
      return isConnected;
    } catch (e) {
      print('📡 CONNECTIVITY_TEST: ❌ Connection failed: $e');
      DebugScreen.addLog('API: ❌ Connectivity test failed: $e');
      return false;
    }
  }
}
