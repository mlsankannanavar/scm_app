import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'https://test-backend-batchmate.medha-analytics.ai:9099';
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<http.Response> _post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_baseUrl$path');
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final resp = await _client.post(uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body));
        if (resp.statusCode >= 200 && resp.statusCode < 300) return resp;
      } catch (_) {
        await Future.delayed(Duration(milliseconds: 300 * (attempt + 1)));
      }
    }
    throw Exception('POST $path failed after retries');
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

  Future<void> submitImage(Map<String, dynamic> payload) async {
    await _post('/api/submit', payload);
  }

  Future<Map<String, dynamic>> getStatus(String sessionId) async {
    final r = await _get('/api/status/$sessionId');
    return jsonDecode(r.body) as Map<String, dynamic>;
  }
}
