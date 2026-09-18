import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_tourist_guide/screens/login_screen.dart';
import 'package:ai_tourist_guide/screens/home_screen.dart';
import 'package:ai_tourist_guide/screens/landing_screen.dart';
import '../services/rating_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print('AuthWrapper: Connection state: ${snapshot.connectionState}');
        print('AuthWrapper: Has data: ${snapshot.hasData}');
        print('AuthWrapper: User: ${snapshot.data?.email}');
        
        // Show loading spinner while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // If user is signed in, show home screen
        if (snapshot.hasData) {
          print('AuthWrapper: Showing home screen for user: ${snapshot.data?.email}');
          // Clear session data when user logs in (start fresh session)
          RatingService.clearSession();
          return const HomeScreen();
        }
        
        // If user is not signed in, show landing screen first
        print('AuthWrapper: Showing landing screen');
        return const LandingScreen();
      },
    );
  }
}
