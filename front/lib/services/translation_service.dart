import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class TranslationService {
  TranslationService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? 'http://10.0.2.2:3000';

  final http.Client _client;
  final String _baseUrl;

  Future<String> translateText({
    required String text,
    required String sourceLanguageCode,
    required String targetLanguageCode,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/translation/text');
    final payload = <String, dynamic>{
      'message': text,
      'sourceLanguage': sourceLanguageCode,
      'targetLanguage': targetLanguageCode,
    };

    final res = await _client.post(
      uri,
      headers: <String, String>{'Content-Type': 'application/json'},
      body: json.encode(payload),
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final Map<String, dynamic> body = json.decode(res.body) as Map<String, dynamic>;
      final Map<String, dynamic> data = (body['data'] as Map<String, dynamic>? ?? <String, dynamic>{});
      final String translated = (data['translatedText']?.toString() ?? '').trim();
      if (translated.isEmpty) {
        throw Exception('Empty translation received');
      }
      return translated;
    }

    try {
      final Map<String, dynamic> body = json.decode(res.body) as Map<String, dynamic>;
      final String message = body['message']?.toString() ?? 'Translation failed';
      throw Exception(message);
    } catch (_) {
      throw Exception('Translation failed (HTTP ${res.statusCode})');
    }
  }

  Future<Uint8List> textToSpeech({
    required String text,
    required String languageCode,
    String audioFormat = 'mp3',
  }) async {
    final uri = Uri.parse('$_baseUrl/api/translation/text-to-speech');
    final res = await _client.post(
      uri,
      headers: <String, String>{'Content-Type': 'application/json'},
      body: json.encode(<String, dynamic>{
        'text': text,
        'languageCode': languageCode,
        'audioFormat': audioFormat,
      }),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.bodyBytes;
    }
    throw Exception('text-to-speech failed (HTTP ${res.statusCode})');
  }
}


