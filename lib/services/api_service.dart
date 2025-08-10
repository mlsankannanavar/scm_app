import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../screens/debug_screen.dart';

class ApiService {
  static const String _baseUrl = 'https://test-batchmate.medha-analytics.ai';
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
        ).timeout(const Duration(seconds: 30));
        
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
        DebugScreen.addLog('API: ❌ Attempt ${attempt + 1} failed: $e');
        if (attempt < 2) {
          await Future.delayed(Duration(milliseconds: 1000 * (attempt + 1)));
          DebugScreen.addLog('API: Retrying in ${1000 * (attempt + 1)}ms...');
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

  Future<Map<String, dynamic>> getStatus(String sessionId) async {
    final r = await _get('/api/status/$sessionId');
    return jsonDecode(r.body) as Map<String, dynamic>;
  }
}
