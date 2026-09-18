import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ai_tourist_guide/screens/signup_page.dart';
import 'package:ai_tourist_guide/services/auth_service.dart';
import '../theme/app_theme.dart';

class TravelLoginPage extends StatefulWidget {
  const TravelLoginPage({super.key});

  @override
  State<TravelLoginPage> createState() => _TravelLoginPageState();
}

class _TravelLoginPageState extends State<TravelLoginPage> {
  // Brand colors
  static const kPrimary = AppTheme.primaryOrange; // Orange
  static const kNavy = Color(0xFF1C2F69);    // Deep blue

  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _showPassword = false;
  bool _rememberMe = true;
  bool _isLoading = false;

  // Header image carousel (Unsplash — replace with your own later if you want)
  final _images = <String>[
    // tropical beach
    'https://images.unsplash.com/photo-1500375592092-40eb2168fd21?q=80&w=1600&auto=format&fit=crop',
    // mountain lake
    'https://images.unsplash.com/photo-1501785888041-af3ef285b470?q=80&w=1600&auto=format&fit=crop',
    // city night
    'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?q=80&w=1600&auto=format&fit=crop',
  ];
  final _pageController = PageController();
  int _page = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _page = (_page + 1) % _images.length;
      if (mounted) {
        _pageController.animateToPage(
          _page,
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      final userCredential = await AuthService.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      
      // Check if sign-in was successful (either result is not null or user is signed in)
      if ((userCredential != null || AuthService.currentUser != null) && mounted) {
        print('Login successful: ${userCredential?.user?.email ?? AuthService.currentUser?.email}');
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome back!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
        
        // Navigate to home screen after successful login
        await Future.delayed(const Duration(milliseconds: 500)); // Small delay to show success message
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      if (!mounted) return;
      
      print('Login Error in UI: $e');
      
      // Check if this is the known type casting error
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('List<Object?>') ||
          e.toString().contains('type cast')) {
        print('Known type casting error during login - ignoring in UI');
        // Don't show error message for this known issue
        return;
      }
      
      // Only show error for actual failures
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  VoidCallback? get _onGoogleSignIn => _isLoading ? null : () {
    _signInWithGoogle();
  };

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await AuthService.signInWithGoogle();
      
      // Check if sign-in was successful (either result is not null or user is signed in)
      if ((result != null || AuthService.currentUser != null) && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
        
        // Navigate to home screen after successful Google sign-in
        await Future.delayed(const Duration(milliseconds: 500)); // Small delay to show success message
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      if (!mounted) return;
      
      print('Google Sign-In Error in UI: $e');
      
      // Check if this is the known type casting error
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('List<Object?>') ||
          e.toString().contains('type cast')) {
        print('Known google_sign_in plugin type casting error - ignoring in UI');
        // Don't show error message for this known issue
        return;
      }
      
      // Only show error for actual failures
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Sign-In Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.interTextTheme(Theme.of(context).textTheme);

    return Scaffold(
      backgroundColor: kNavy,
      body: Stack(
        children: [
          // ======= Hero header (images + gradient glaze) =======
          _HeaderCarousel(
            controller: _pageController,
            images: _images,
            overlay: const _HeaderOverlay(),
          ),

          // ======= Curved gradient top (brand ribbon) =======
          const _BrandRibbon(),

          // ======= Top app bar (transparent) =======
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  _GlassIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.maybePop(context),
                  ),
                  const Spacer(),
                  _GlassIconButton(
                    icon: Icons.help_outline_rounded,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),

          // ======= Glassy login card =======
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 520),
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.82),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(textTheme: textTheme),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // App logo
                            Center(
                              child: Image.asset(
                                'assets/images/logopath.png',
                                height: 104,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: kPrimary.withOpacity(.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.flight_takeoff_rounded, color: kNavy),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Welcome back, Explorer!',
                                    style: textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: kNavy,
                                      letterSpacing: .2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Log in to manage trips, get smart deals, and continue planning.',
                              style: textTheme.bodyMedium?.copyWith(
                                color: kNavy.withOpacity(.70),
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 22),

                            // Email
                            _FieldLabel('Email'),
                            _FrostField(
                              controller: _email,
                              hint: 'you@travelmail.com',
                              keyboardType: TextInputType.emailAddress,
                              icon: Icons.mail_outline_rounded,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Please enter your email';
                                }
                                final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v);
                                if (!ok) return 'Enter a valid email';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Password
                            _FieldLabel('Password'),
                            _FrostField(
                              controller: _password,
                              hint: '••••••••',
                              icon: Icons.lock_outline_rounded,
                              obscureText: !_showPassword,
                              suffix: IconButton(
                                onPressed: () => setState(() {
                                  _showPassword = !_showPassword;
                                }),
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: kNavy.withOpacity(.8),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (v.length < 6) {
                                  return 'At least 6 characters';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 8),

                            // Remember + Forgot
                            Row(
                              children: [
                                InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                                  child: Row(
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: _rememberMe ? kPrimary : Colors.transparent,
                                          border: Border.all(color: kPrimary, width: 2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: _rememberMe
                                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                                            : null,
                                      ),
                                      const SizedBox(width: 8),
                                      Text('Remember me',
                                          style: textTheme.labelLarge?.copyWith(color: kNavy)),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    'Forgot password?',
                                    style: textTheme.labelLarge?.copyWith(color: kPrimary),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Login button
                            SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimary,
                                  disabledBackgroundColor: kPrimary.withOpacity(.6),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.login_rounded),
                                            const SizedBox(width: 8),
                                            Text('Login',
                                                style: textTheme.titleMedium?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w800,
                                                )),
                                          ],
                                        ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Divider
                            Row(
                              children: [
                                Expanded(child: Divider(color: kNavy.withOpacity(.15))),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Text('or continue with',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: kNavy.withOpacity(.6),
                                      )),
                                ),
                                Expanded(child: Divider(color: kNavy.withOpacity(.15))),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Socials
                            Row(
                              children: [
                                Expanded(
                                  child: _SocialButton(
                                    label: 'Google',
                                    icon: Icons.g_mobiledata_rounded,
                                    onTap: _isLoading ? () {} : _onGoogleSignIn!,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Sign up link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "New to Travelio? ",
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: kNavy.withOpacity(.85),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => const TravelOnboardingSignUp(),
                                      ),
                                    );
                                  },
                                  child: Text('Create an account',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: kPrimary,
                                        fontWeight: FontWeight.w800,
                                      )),
                                ),
                              ],
                            ),

                            const SizedBox(height: 2),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCarousel extends StatelessWidget {
  const _HeaderCarousel({
    required this.controller,
    required this.images,
    this.overlay,
  });

  final PageController controller;
  final List<String> images;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: controller,
            itemCount: images.length,
            itemBuilder: (context, index) {
              return Image.network(
                images[index],
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) => AnimatedOpacity(
                  opacity: progress == null ? 1 : 0.6,
                  duration: const Duration(milliseconds: 300),
                  child: child,
                ),
              );
            },
          ),
          if (overlay != null) overlay!,
        ],
      ),
    );
  }
}

class _HeaderOverlay extends StatelessWidget {
  const _HeaderOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black38,
            Colors.transparent,
            Colors.transparent,
            Colors.black45,
          ],
          stops: [0.0, 0.35, 0.65, 1.0],
        ),
      ),
    );
  }
}

class _BrandRibbon extends StatelessWidget {
  const _BrandRibbon();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        height: 220,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x66FC9D23), Color(0x331C2F69)],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.white.withOpacity(0.25),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: theme.labelLarge?.copyWith(
          color: _TravelLoginPageState.kNavy.withOpacity(.9),
          fontWeight: FontWeight.w700,
          letterSpacing: .2,
        ),
      ),
    );
  }
}

class _FrostField extends StatelessWidget {
  const _FrostField({
    required this.controller,
    required this.hint,
    this.icon,
    this.suffix,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(.6)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          prefixIcon: icon != null
              ? Icon(icon, color: _TravelLoginPageState.kNavy.withOpacity(.8))
              : null,
          suffixIcon: suffix,
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: _TravelLoginPageState.kNavy,
        side: BorderSide(color: _TravelLoginPageState.kNavy.withOpacity(.25)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: _TravelLoginPageState.kNavy,
            ),
          ),
        ],
      ),
    );
  }
}
