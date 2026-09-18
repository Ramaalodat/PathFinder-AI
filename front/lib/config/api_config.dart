import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class ApiConfig {
  // Different base URLs for different environments
  static const String _androidEmulatorUrl = 'http://10.0.2.2:3000';
  static const String _iosSimulatorUrl = 'http://localhost:3000';
  static const String _webUrl = 'http://localhost:3000';

  // For physical devices, use your computer's LAN IP (set in a different config or env)

  // Get the appropriate base URL based on platform
  static String get baseUrl {
    if (kIsWeb) {
      return _webUrl;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android Emulator
        return _androidEmulatorUrl;
      case TargetPlatform.iOS:
        // iOS Simulator
        return _iosSimulatorUrl;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        // For desktop or others, assume local dev server
        return _webUrl;
    }
  }

  // API endpoints
  static const String scamPreventionEndpoint = '/api/scam-prevention';
  static const String translationEndpoint = '/api/translation';
  static const String recommendationsEndpoint = '/api/recommendations';
  static const String transportationEndpoint = '/api/transportation';
  static const String currencyEndpoint = '/api/currency';

  // Full URLs
  static String get scamPreventionUrl => '$baseUrl$scamPreventionEndpoint';
  static String get translationUrl => '$baseUrl$translationEndpoint';
  static String get recommendationsUrl => '$baseUrl$recommendationsEndpoint';
  static String get transportationUrl => '$baseUrl$transportationEndpoint';
  static String get currencyUrl => '$baseUrl$currencyEndpoint';
  
  // Chatflow IDs - can be moved to environment variables in production
  static const String defaultPriceAdvisorChatflowId = '07afcffe-f864-4a73-8a28-9cbf096919e5';
}
