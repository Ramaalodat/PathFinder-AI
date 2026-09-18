import 'dart:convert';
import 'package:http/http.dart' as http;

class TransportationService {
  static const String baseUrl = 'http://localhost:3000/api/transportation';
  
  // Get transportation options between two points
  static Future<Map<String, dynamic>> getTransportationOptions({
    required String from,
    required String to,
    String mode = 'all',
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/options'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'from': from,
          'to': to,
          'mode': mode,
          'preferences': preferences ?? {},
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'error': 'Failed to get transportation options',
          'message': 'Server returned ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error',
        'message': e.toString(),
      };
    }
  }

  // Get real-time transportation updates
  static Future<Map<String, dynamic>> getRealTimeUpdates({String transportType = 'all'}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/realtime?transportType=$transportType'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'error': 'Failed to get real-time updates',
          'message': 'Server returned ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error',
        'message': e.toString(),
      };
    }
  }

  // Get detailed directions for a specific transportation option
  static Future<Map<String, dynamic>> getDirections({
    required String from,
    required String to,
    required String transportType,
    String? routeId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/directions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'from': from,
          'to': to,
          'transportType': transportType,
          'routeId': routeId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'error': 'Failed to get directions',
          'message': 'Server returned ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error',
        'message': e.toString(),
      };
    }
  }

  // Get transportation system status
  static Future<Map<String, dynamic>> getSystemStatus() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/status'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'error': 'Failed to get system status',
          'message': 'Server returned ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error',
        'message': e.toString(),
      };
    }
  }

  // Track user's current location
  static Future<Map<String, dynamic>> trackLocation({
    required double latitude,
    required double longitude,
    double? accuracy,
    DateTime? timestamp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/location/track'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
          'accuracy': accuracy,
          'timestamp': timestamp?.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'error': 'Failed to track location',
          'message': 'Server returned ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error',
        'message': e.toString(),
      };
    }
  }

  // Get real-time data based on current location
  static Future<Map<String, dynamic>> getLocationBasedRealtime({
    required double latitude,
    required double longitude,
    int radius = 1000,
    String transportType = 'all',
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/location/realtime?latitude=$latitude&longitude=$longitude&radius=$radius&transportType=$transportType'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'error': 'Failed to get location-based real-time data',
          'message': 'Server returned ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error',
        'message': e.toString(),
      };
    }
  }

  // Get nearby transportation options
  static Future<Map<String, dynamic>> getNearbyTransportation({
    required double latitude,
    required double longitude,
    int radius = 1000,
    String transportType = 'all',
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/location/nearby?latitude=$latitude&longitude=$longitude&radius=$radius&transportType=$transportType'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'error': 'Failed to get nearby transportation',
          'message': 'Server returned ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error',
        'message': e.toString(),
      };
    }
  }
}
