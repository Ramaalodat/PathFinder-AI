import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/landing_screen.dart';
import 'screens/home_screen.dart';
import 'screens/translation_screen.dart';
import 'screens/price_advisor_screen.dart';
import 'screens/recommendations_screen.dart';
import 'screens/transportation_screen.dart';
import 'screens/currency_converter_screen.dart';
import 'screens/match_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/map_test_screen.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/auth_wrapper.dart';
import 'screens/chat_list_screen.dart';
import 'screens/edit_account_screen.dart';
import 'screens/rating_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Tourist Guide',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      // Entry point: AuthWrapper decides whether to show Landing/Login/Home
      home: const AuthWrapper(),
      routes: {
        '/landing': (context) => const LandingScreen(),
        '/home': (context) => const HomeScreen(),
        '/chats': (context) => const ChatListScreen(),
        '/translation': (context) => const TranslationScreen(),
        '/price-advisor': (context) => const PriceAdvisorScreen(),
        '/recommendations': (context) => const RecommendationsScreen(),
        '/transportation': (context) => const TransportationScreen(),
        '/currency-converter': (context) => const CurrencyConverterScreen(),
        '/match': (context) => const MatchScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/edit-account': (context) => const EditAccountScreen(),
        '/map-test': (context) => const MapTestScreen(),
        '/login': (context) => const TravelLoginPage(),
        '/rating': (context) => const RatingScreen(),
      },
    );
  }
}
