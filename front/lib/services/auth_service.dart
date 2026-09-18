import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  static Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      print('Signing in with email: $email');
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Sign-in successful: ${result.user?.email}');
      return result;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Exception during sign-in: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('Unexpected error during sign-in: $e');
      
      // Check if this is the known type casting error
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('List<Object?>') ||
          e.toString().contains('type cast')) {
        print('Known type casting error during sign-in - checking if user is signed in');
        // Check if user is actually signed in despite the error
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          print('Sign-in actually succeeded despite type casting error');
          // Return null and let the UI check the auth state
          return null;
        }
      }
      
      throw 'Sign-in failed: ${e.toString()}';
    }
  }

  // Create user with email and password
  static Future<UserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      print('Creating user with email: $email');
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('User created successfully: ${result.user?.email}');
      return result;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Exception during signup: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('Unexpected error during signup: $e');
      
      // Check if this is the known type casting error
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('List<Object?>') ||
          e.toString().contains('type cast')) {
        print('Known type casting error during signup - checking if user is signed in');
        // Check if user is actually signed in despite the error
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          print('Signup actually succeeded despite type casting error');
          // Return null and let the UI check the auth state
          return null;
        }
      }
      
      throw 'Account creation failed: ${e.toString()}';
    }
  }

  // Sign in with Google
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      print('Starting Google Sign-In...');
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        print('Google Sign-In cancelled by user');
        return null;
      }

      print('Google user obtained: ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      print('Google auth tokens obtained');

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      print('Firebase credential created');

      // Sign in to Firebase with the Google credential
      final UserCredential result = await _auth.signInWithCredential(credential);
      print('Firebase sign-in successful: ${result.user?.email}');
      return result;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Exception: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('Google Sign-In Error: $e');
      
      // Handle the specific type casting error that occurs but doesn't affect functionality
      if (e.toString().contains('PigeonUserDetails') || 
          e.toString().contains('List<Object?>') ||
          e.toString().contains('type cast')) {
        // This is a known issue with google_sign_in plugin version 6.3.0
        // The sign-in actually works despite this error
        print('Known google_sign_in plugin type casting error - ignoring');
        // Check if user is actually signed in
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          print('Sign-in actually succeeded despite error');
          // Return a successful result by creating a new UserCredential
          // We'll use a workaround by signing in again with the same credential
          try {
            final credential = GoogleAuthProvider.credential(
              accessToken: (await _googleSignIn.currentUser?.authentication)?.accessToken,
              idToken: (await _googleSignIn.currentUser?.authentication)?.idToken,
            );
            return await _auth.signInWithCredential(credential);
          } catch (retryError) {
            print('Retry failed: $retryError');
            // Even if retry fails, if we have a current user, return success
            if (_auth.currentUser != null) {
              print('User is signed in despite retry failure');
              // Return null and let the UI check the auth state
              return null;
            }
            return null;
          }
        }
        return null;
      }
      
      throw 'Google Sign-In failed: $e';
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      print('Starting sign out process...');
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      print('Sign out completed successfully');
    } catch (e) {
      print('Sign out error: $e');
      throw 'An error occurred while signing out. Please try again.';
    }
  }

  // Send password reset email
  static Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Update user profile
  static Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Update display name if provided and not empty
        if (displayName != null && displayName.trim().isNotEmpty) {
          await user.updateDisplayName(displayName.trim());
          print('Display name updated to: ${displayName.trim()}');
        }
        
        // Update photo URL if provided and not empty
        if (photoURL != null && photoURL.trim().isNotEmpty) {
          await user.updatePhotoURL(photoURL.trim());
          print('Photo URL updated to: ${photoURL.trim()}');
        }
        
        // Reload user to get updated data
        await user.reload();
        print('User profile reloaded successfully');
      } else {
        print('No current user found for profile update');
      }
    } catch (e) {
      print('Profile update error: $e');
      
      // Check if this is the known type casting error
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('PigeonUserInfo') ||
          e.toString().contains('List<Object?>') ||
          e.toString().contains('type cast')) {
        print('Known type casting error during profile update - ignoring');
        // Don't throw error for profile update failures, just log them
        // This allows account creation to succeed even if profile update fails
        return;
      }
      
      // Don't throw error for profile update failures, just log them
      // This allows account creation to succeed even if profile update fails
    }
  }

  // Handle Firebase Auth exceptions
  static String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Invalid email address. Please check your email.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in credentials.';
      case 'credential-already-in-use':
        return 'This credential is already associated with a different user account.';
      case 'invalid-verification-code':
        return 'Invalid verification code. Please try again.';
      case 'invalid-verification-id':
        return 'Invalid verification ID. Please try again.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return e.message ?? 'An authentication error occurred. Please try again.';
    }
  }
}
