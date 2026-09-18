import 'dart:convert';
import 'package:http/http.dart' as http;

class RecommendationsService {
  RecommendationsService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? 'http://10.0.2.2:3000';

  final http.Client _client;
  final String _baseUrl;

  Future<Map<String, dynamic>> getPersonalized({
    required String userMessage,
    required String chatflowId,
    List<Map<String, String>>? chatHistory,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/recommendations/personalized');
    final payload = <String, dynamic>{
      'userMessage': userMessage,
      'chatflowId': chatflowId,
      'chatHistory': chatHistory ?? <Map<String, String>>[],
    };
    final res = await _client.post(
      uri,
      headers: <String, String>{'Content-Type': 'application/json'},
      body: json.encode(payload),
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return json.decode(res.body) as Map<String, dynamic>;
    }
    try {
      final Map<String, dynamic> body = json.decode(res.body) as Map<String, dynamic>;
      final String message = body['message']?.toString() ?? 'Request failed';
      return <String, dynamic>{'success': false, 'message': message};
    } catch (_) {
      return <String, dynamic>{'success': false, 'message': 'HTTP ${res.statusCode}'};
    }
  }

  Future<Map<String, dynamic>> getCulturalEtiquette({
    required String location,
    required String chatflowId,
    List<String>? specificTopics,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/recommendations/cultural-etiquette');
    final payload = <String, dynamic>{
      'location': location,
      'chatflowId': chatflowId,
      'specificTopics': specificTopics ?? <String>[],
    };
    final res = await _client.post(
      uri,
      headers: <String, String>{'Content-Type': 'application/json'},
      body: json.encode(payload),
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return json.decode(res.body) as Map<String, dynamic>;
    }
    try {
      final Map<String, dynamic> body = json.decode(res.body) as Map<String, dynamic>;
      final String message = body['message']?.toString() ?? 'Request failed';
      return <String, dynamic>{'success': false, 'message': message};
    } catch (_) {
      return <String, dynamic>{'success': false, 'message': 'HTTP ${res.statusCode}'};
    }
  }
}


