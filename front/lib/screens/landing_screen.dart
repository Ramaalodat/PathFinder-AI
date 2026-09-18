import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const TravelLoginPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onPanEnd: (details) {
          // Detect swipe left gesture
          if (details.velocity.pixelsPerSecond.dx < -500) {
            _navigateToLogin();
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(
                'https://images.unsplash.com/photo-1552832230-c0197dd311b5?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80',
              ),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.6),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  
                  const Spacer(),
                  
                  // Main content
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          // Main title
                          Padding(
                            padding: const EdgeInsets.only(left: 10, right: 40),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final screenHeight = MediaQuery.of(context).size.height;
                                // Make it a bit larger than before
                                final calculated = screenHeight / 14.5;

                                return Text(
                                  "Let's\nenjoy the\nbeautiful\nworld.",
                                  textAlign: TextAlign.left,
                                  style: GoogleFonts.playfairDisplay(
                                    color: Colors.white,
                                    fontSize: 75,
                                    fontWeight: FontWeight.w700,
                                    height: 1.02,
                                    letterSpacing: -0.8,
                                  ),
                                );
                              },
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Subtitle
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              "Travel freely No barriers No troubles \n let nothing stand between you and a perfect adventure.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                height: 1.5,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 60),
                          
                          // Swipe button
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 40),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _navigateToLogin,
                                borderRadius: BorderRadius.circular(30),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.chevron_right,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          Icon(
                                            Icons.chevron_right,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          Icon(
                                            Icons.chevron_right,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Swipe to Explore Now',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Privacy Policy
 
                          
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}