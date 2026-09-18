// lib/onboarding_signup.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_tourist_guide/services/auth_service.dart';

/* =================== Brand =================== */
const kPrimary = Color(0xFFFC9D23); // orange
const kNavy    = Color(0xFF1C2F69); // deep blue

class TravelOnboardingSignUp extends StatefulWidget {
  const TravelOnboardingSignUp({super.key});

  @override
  State<TravelOnboardingSignUp> createState() => _TravelOnboardingSignUpState();
}

class _TravelOnboardingSignUpState extends State<TravelOnboardingSignUp> {
  // Background carousel
  final _heroImages = <String>[
    // coast cliffs
    'https://images.unsplash.com/photo-1493558103817-58b2924bce98?q=80&w=1600&auto=format&fit=crop',
    // desert road
    'https://images.unsplash.com/photo-1476610182048-b716b8518aae?q=80&w=1600&auto=format&fit=crop',
    // tropical lagoon
    'https://images.unsplash.com/photo-1500375592092-40eb2168fd21?q=80&w=1600&auto=format&fit=crop',
  ];
  final _bgCtrl = PageController();
  int _bgPage = 0;
  Timer? _bgTimer;

  // Steps
  final _stepsCtrl = PageController();
  int _step = 0; // 0..4

  // Form fields
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass  = TextEditingController();
  final _confirm = TextEditingController();

  bool _showPass = false, _showConfirm = false;
  bool _isLoading = false;
  StreamSubscription<User?>? _authSubscription;

  // Interests
  final _allInterests = const [
    'Beaches','Mountains','City breaks','Road trips',
    'History','Food','Nature','Safari','Skiing',
    'Islands','Backpacking','Luxury','Shopping','Photography',
  ];
  final _picked = <String>{};

  // Policies
  bool _agree = false;
  bool _newsletter = true;

  @override
  void initState() {
    super.initState();
    _bgTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _bgPage = (_bgPage + 1) % _heroImages.length;
      if (mounted) {
        _bgCtrl.animateToPage(
          _bgPage,
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOutCubic,
        );
      }
    });
    
    // Add listeners to text controllers to trigger UI updates
    _name.addListener(() => setState(() {}));
    _email.addListener(() => setState(() {}));
    _pass.addListener(() => setState(() {}));
    _confirm.addListener(() => setState(() {}));
    
    // Listen for auth state changes to handle successful signup
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null && mounted) {
        print('User signed in during signup, closing signup screen');
        // Add a small delay to ensure the signup process completes
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _bgTimer?.cancel();
    _bgCtrl.dispose();
    _stepsCtrl.dispose();
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _confirm.dispose();
    _authSubscription?.cancel();
    super.dispose();
  }

  /* =================== Validation =================== */
  bool get _okStart => true; // Always ok
  bool get _okNameEmail {
    final nameOk = _name.text.trim().length >= 3;
    final emailOk = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(_email.text.trim());
    return nameOk && emailOk;
  }
  bool get _okPassword => _pass.text.length >= 6 && _pass.text == _confirm.text;
  bool get _okInterests => _picked.length >= 3;
  bool get _okPolicies => _agree;

  double get _strength {
    // Naive strength: length + variety
    final p = _pass.text;
    if (p.isEmpty) return 0;
    int s = 0;
    if (p.length >= 6) s++;
    if (p.length >= 10) s++;
    if (RegExp(r'[A-Z]').hasMatch(p)) s++;
    if (RegExp(r'[0-9]').hasMatch(p)) s++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(p)) s++;
    return (s / 5).clamp(0, 1);
  }

  /* =================== Step control =================== */
  Future<void> _next() async {
    final ok = [_okStart, _okNameEmail, _okPassword, _okInterests, _okPolicies][_step];
    if (!ok) return;
    
    if (_step < 4) {
      setState(() => _step++);
      await _stepsCtrl.animateToPage(_step,
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  Future<void> _back() async {
    if (_step == 0) {
      Navigator.maybePop(context);
      return;
    }
    setState(() => _step--);
    _stepsCtrl.animateToPage(_step,
        duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
  }

  Future<void> _createAccount() async {
    if (!_okPolicies) return;
    setState(() => _isLoading = true);
    
    try {
      print('Starting account creation...');
      
      // Create user with email and password
      final userCredential = await AuthService.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _pass.text,
      );
      
      // Check if sign-up was successful (either result is not null or user is signed in)
      if (mounted && (userCredential != null || AuthService.currentUser != null)) {
        print('User account created successfully: ${userCredential?.user?.email ?? AuthService.currentUser?.email}');
        
        // Update user profile with name (non-blocking)
        if (_name.text.trim().isNotEmpty) {
          try {
            print('Updating profile with name: ${_name.text.trim()}');
            await AuthService.updateUserProfile(
              displayName: _name.text.trim(),
            );
            print('Profile updated successfully');
          } catch (e) {
            print('Profile update failed but continuing: $e');
            // Continue with signup even if profile update fails
          }
        }
        
         print('Account creation completed successfully');
         print('Current user after signup: ${AuthService.currentUser?.email}');
         print('Current user display name: ${AuthService.currentUser?.displayName}');
         
         // Show success message only if widget is still mounted
         if (mounted) {
           print('Showing success message...');
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
               content: Text('Account created successfully!'),
               backgroundColor: Colors.green,
               duration: Duration(seconds: 2),
             ),
           );
         }
         
         // The auth listener will close this screen and AuthWrapper will show home
      }
    } catch (e) {
      print('Account creation error: $e');
      if (!mounted) return;
      
      // Check if this is the known type casting error
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('List<Object?>') ||
          e.toString().contains('type cast')) {
        print('Known type casting error during signup - ignoring in UI');
        // Don't show error message for this known issue
        return;
      }
      
      // Only show error for actual failures
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account creation failed: ${e.toString()}'),
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

  Future<void> _googleFlow() async {
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
            duration: Duration(seconds: 2),
          ),
        );
        
        // Navigate to home
        // Don't navigate manually - AuthWrapper will handle the redirect
        // The AuthWrapper will automatically show the home screen when user is signed in
      }
    } catch (e) {
      if (!mounted) return;
      
      print('Google Sign-In Error in Signup UI: $e');
      
      // Check if this is the known type casting error
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('List<Object?>') ||
          e.toString().contains('type cast')) {
        print('Known google_sign_in plugin type casting error - ignoring in Signup UI');
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

  /* =================== UI =================== */
  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.interTextTheme(Theme.of(context).textTheme);

    return Scaffold(
      backgroundColor: kNavy,
      body: Stack(
        children: [
          // ---- BACKDROP with overlay ----
          _Backdrop(images: _heroImages, controller: _bgCtrl),
          const _BackdropOverlay(),
          const _BrandRibbon(),

          // ---- Top bar ----
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  _GlassIcon(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.maybePop(context),
                  ),
                  const Spacer(),
                  _GlassIcon(
                    icon: Icons.help_outline_rounded,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),

          // ---- Card ----
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 520),
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.82),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: Colors.white.withOpacity(.6)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.12),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(textTheme: textTheme),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Brand mark
                          Center(
                            child: Image.asset(
                              'assets/images/logopath.png',
                              height: 90,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Step dots
                          _StepDots(total: 5, active: _step),

                          const SizedBox(height: 8),

                          // Steps
                          SizedBox(
                            height: 410, // keeps card height stable
                            child: PageView(
                              controller: _stepsCtrl,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                _StepStart(onGoogle: _googleFlow, onEmail: _next),
                                _StepNameEmail(
                                  nameCtrl: _name,
                                  emailCtrl: _email,
                                ),
                                _StepPassword(
                                  passCtrl: _pass,
                                  confirmCtrl: _confirm,
                                  showPass: _showPass,
                                  showConfirm: _showConfirm,
                                  onTogglePass: () => setState(() => _showPass = !_showPass),
                                  onToggleConfirm: () => setState(() => _showConfirm = !_showConfirm),
                                  strength: _strength,
                                ),
                                _StepInterests(
                                  all: _allInterests,
                                  picked: _picked,
                                  onToggle: (s) => setState(() {
                                    if (_picked.contains(s)) {
                                      _picked.remove(s);
                                    } else {
                                      _picked.add(s);
                                    }
                                  }),
                                ),
                                _StepPolicies(
                                  agree: _agree,
                                  newsletter: _newsletter,
                                  onAgree: (v) => setState(() => _agree = v),
                                  onNews: (v) => setState(() => _newsletter = v),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Bottom actions
                          Row(
                            children: [
                              TextButton(
                                onPressed: _back,
                                child: const Text('Back', style: TextStyle(color: kNavy, fontWeight: FontWeight.w700)),
                              ),
                              const Spacer(),
                              if (_step <= 3)
                                _PrimaryButton(
                                  label: 'Next',
                                  enabled: [_okStart, _okNameEmail, _okPassword, _okInterests][_step],
                                  onTap: _next,
                                ),
                              if (_step == 4)
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 180),
                                  child: _agree
                                      ? _PrimaryButton(
                                          key: const ValueKey('create'),
                                          label: _isLoading ? 'Creating...' : 'Create account',
                                          onTap: _isLoading ? null : _createAccount,
                                          showSpinner: _isLoading,
                                        )
                                      : const SizedBox.shrink(key: ValueKey('hidden')),
                                ),
                            ],
                          ),
                        ],
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

/* =================== Steps =================== */

class _StepStart extends StatelessWidget {
  const _StepStart({required this.onGoogle, required this.onEmail});
  final VoidCallback onGoogle;
  final VoidCallback onEmail;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Create your account',
            style: t.titleLarge!.copyWith(
              color: kNavy,
              fontWeight: FontWeight.w800,
              letterSpacing: .2,
            )),
        const SizedBox(height: 6),
        Text('Start with Google or continue with email.',
            style: t.bodyMedium!.copyWith(color: kNavy.withOpacity(.7))),
        const SizedBox(height: 18),

        // Google
        OutlinedButton.icon(
          onPressed: onGoogle,
          icon: const Icon(Icons.g_mobiledata_rounded, color: kNavy, size: 28),
          label: Text('Continue with Google',
              style: t.titleMedium!.copyWith(color: kNavy, fontWeight: FontWeight.w800)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: kNavy.withOpacity(.25)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: Colors.white,
          ),
        ),

        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: Divider(color: kNavy.withOpacity(.15))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('or', style: t.bodySmall!.copyWith(color: kNavy.withOpacity(.6))),
            ),
            Expanded(child: Divider(color: kNavy.withOpacity(.15))),
          ],
        ),
        const SizedBox(height: 12),

        // Email
        _PrimaryButton(label: 'Create with email', onTap: onEmail),
        const Spacer(),
        Center(
          child: Text('By continuing you agree to our Terms & Privacy.',
              textAlign: TextAlign.center,
              style: t.labelSmall!.copyWith(color: kNavy.withOpacity(.7))),
        ),
      ],
    );
  }
}

class _StepNameEmail extends StatelessWidget {
  const _StepNameEmail({required this.nameCtrl, required this.emailCtrl});
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Tell us about you',
            style: t.titleLarge!.copyWith(
              color: kNavy, fontWeight: FontWeight.w800, letterSpacing: .2)),
        const SizedBox(height: 6),
        Text('We’ll personalize recommendations.',
            style: t.bodyMedium!.copyWith(color: kNavy.withOpacity(.7))),
        const SizedBox(height: 18),

        _FieldLabel('Full name'),
        _FrostField(
          controller: nameCtrl,
          hint: 'Jane Traveler',
          icon: Icons.badge_outlined,
        ),
        const SizedBox(height: 12),

        _FieldLabel('Email'),
        _FrostField(
          controller: emailCtrl,
          hint: 'you@travelmail.com',
          keyboardType: TextInputType.emailAddress,
          icon: Icons.mail_outline_rounded,
        ),
        const Spacer(),
      ],
    );
  }
}

class _StepPassword extends StatelessWidget {
  const _StepPassword({
    required this.passCtrl,
    required this.confirmCtrl,
    required this.showPass,
    required this.showConfirm,
    required this.onTogglePass,
    required this.onToggleConfirm,
    required this.strength,
  });

  final TextEditingController passCtrl;
  final TextEditingController confirmCtrl;
  final bool showPass, showConfirm;
  final VoidCallback onTogglePass, onToggleConfirm;
  final double strength;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Create a password',
            style: t.titleLarge!.copyWith(
              color: kNavy, fontWeight: FontWeight.w800, letterSpacing: .2)),
        const SizedBox(height: 6),
        Text('Use 6+ characters and mix things up.',
            style: t.bodyMedium!.copyWith(color: kNavy.withOpacity(.7))),
        const SizedBox(height: 18),

        _FieldLabel('Password'),
        _FrostField(
          controller: passCtrl,
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          obscureText: !showPass,
          suffix: IconButton(
            onPressed: onTogglePass,
            icon: Icon(showPass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: kNavy.withOpacity(.85)),
          ),
        ),
        const SizedBox(height: 8),

        // Strength bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 8,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: kNavy.withOpacity(.10)),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: strength.clamp(0, 1),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [kPrimary, Color(0xFFFF8A65)]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        _FieldLabel('Confirm password'),
        _FrostField(
          controller: confirmCtrl,
          hint: '••••••••',
          icon: Icons.lock_person_outlined,
          obscureText: !showConfirm,
          suffix: IconButton(
            onPressed: onToggleConfirm,
            icon: Icon(showConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: kNavy.withOpacity(.85)),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

class _StepInterests extends StatelessWidget {
  const _StepInterests({
    required this.all,
    required this.picked,
    required this.onToggle,
  });

  final List<String> all;
  final Set<String> picked;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('What do you like?',
            style: t.titleLarge!.copyWith(
              color: kNavy, fontWeight: FontWeight.w800, letterSpacing: .2)),
        const SizedBox(height: 6),
        Text('Pick at least 3 interests.',
            style: t.bodyMedium!.copyWith(color: kNavy.withOpacity(.7))),
        const SizedBox(height: 12),

        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in all)
                  _InterestChip(
                    label: s,
                    selected: picked.contains(s),
                    onTap: () => onToggle(s),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _StepPolicies extends StatelessWidget {
  const _StepPolicies({
    required this.agree,
    required this.newsletter,
    required this.onAgree,
    required this.onNews,
  });
  final bool agree, newsletter;
  final ValueChanged<bool> onAgree, onNews;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Final step',
            style: t.titleLarge!.copyWith(
              color: kNavy, fontWeight: FontWeight.w800, letterSpacing: .2)),
        const SizedBox(height: 6),
        Text('Review & accept to continue.',
            style: t.bodyMedium!.copyWith(color: kNavy.withOpacity(.7))),
        const SizedBox(height: 18),

        _PolicyTile(
          value: agree,
          onChanged: (v) => onAgree(v ?? false),
          title: 'I agree to the Terms & Privacy Policy',
        ),
        _PolicyTile(
          value: newsletter,
          onChanged: (v) => onNews(v ?? false),
          title: 'Send me travel deals & inspiration',
          subtitle: 'Optional – you can unsubscribe anytime.',
        ),
        const Spacer(),
      ],
    );
  }
}

/* =================== Atoms =================== */

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.showSpinner = false,
  });
  final String label;
  final VoidCallback? onTap;
  final bool enabled;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    final child = showSpinner
        ? const SizedBox(
            height: 22, width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ))
        : Text(label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: .2,
            ));
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: enabled ? 1 : .6,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [kPrimary, Color(0xFFFF8A65)]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Color(0x33FC9D23), blurRadius: 18, offset: Offset(0, 10))],
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  const _InterestChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? kPrimary.withOpacity(.18) : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? kPrimary : kNavy.withOpacity(.18), width: 1.2),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (selected) const Icon(Icons.check_rounded, size: 16, color: kPrimary),
            if (selected) const SizedBox(width: 6),
            Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: kNavy)),
          ]),
        ),
      ),
    );
  }
}

class _PolicyTile extends StatelessWidget {
  const _PolicyTile({required this.value, required this.onChanged, required this.title, this.subtitle});
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(.6)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 10, offset: const Offset(0, 6))],
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        activeColor: kPrimary,
        title: Text(title, style: t.bodyLarge!.copyWith(color: kNavy, fontWeight: FontWeight.w700)),
        subtitle: subtitle == null ? null : Text(subtitle!, style: t.bodySmall!.copyWith(color: kNavy.withOpacity(.7))),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: t.labelLarge!.copyWith(
            color: kNavy.withOpacity(.9),
            fontWeight: FontWeight.w800,
            letterSpacing: .2,
          )),
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
  });

  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(.6)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 10, offset: const Offset(0, 6))],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          prefixIcon: icon == null ? null : Icon(icon, color: kNavy.withOpacity(.85)),
          suffixIcon: suffix,
        ),
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.total, required this.active});
  final int total, active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final on = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          height: 8,
          width: on ? 22 : 8,
          decoration: BoxDecoration(
            color: on ? kPrimary : kNavy.withOpacity(.2),
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }
}

/* =================== Backdrop =================== */

class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.images, required this.controller});
  final List<String> images;
  final PageController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: PageView.builder(
        controller: controller,
        itemCount: images.length,
        itemBuilder: (_, i) => Image.network(
          images[i],
          fit: BoxFit.cover,
          loadingBuilder: (_, child, p) => AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: p == null ? 1 : .6,
            child: child,
          ),
          errorBuilder: (_, __, ___) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [kNavy, kPrimary],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackdropOverlay extends StatelessWidget {
  const _BackdropOverlay();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.black38, Colors.transparent, Colors.transparent, Colors.black45],
          stops: [0.0, .35, .65, 1.0],
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
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0x66FC9D23), Color(0x331C2F69)],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40),
          ),
        ),
      ),
    );
  }
}

class _GlassIcon extends StatelessWidget {
  const _GlassIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.white.withOpacity(.25),
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
