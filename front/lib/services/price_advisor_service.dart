import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class PriceAdvisorService {
  static String get baseUrl => ApiConfig.scamPreventionUrl;
  
  /// Get price advice for an item
  static Future<Map<String, dynamic>> getPriceAdvice({
    required String item,
    required double price,
    String? location,
    String currency = 'USD',
    required String chatflowId,
    Map<String, dynamic>? context,
    List<Map<String, String>>? history,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/price-advice'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'item': item,
          'price': price,
          'location': location,
          'currency': currency,
          'chatflowId': chatflowId,
          'context': context,
          'history': history ?? [],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to get price advice',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Get general safety advice
  static Future<Map<String, dynamic>> getSafetyAdvice({
    required String query,
    String? location,
    required String chatflowId,
    String adviceType = 'general',
    List<Map<String, String>>? history,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/advice'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'query': query,
          'location': location,
          'chatflowId': chatflowId,
          'adviceType': adviceType,
          'history': history ?? [],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to get safety advice',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Test the price advisor API
  static Future<Map<String, dynamic>> testPriceAdvisor({
    String testType = 'price',
    String? chatflowId,
  }) async {
    chatflowId ??= ApiConfig.defaultPriceAdvisorChatflowId;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/test'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'testType': testType,
          'chatflowId': chatflowId,
          'history': [],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to test price advisor',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }
}
