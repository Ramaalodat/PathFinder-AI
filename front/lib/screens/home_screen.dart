import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/rating_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Hero slider (keeping existing slider functionality)
  final _heroImages = <String>[
    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=1600&auto=format&fit=crop', // beach
    'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?q=80&w=1600&auto=format&fit=crop', // coast
    'https://images.unsplash.com/photo-1501785888041-af3ef285b470?q=80&w=1600&auto=format&fit=crop', // lake
  ];
  final _heroCtrl = PageController();
  Timer? _heroTimer;
  int _heroIndex = 0;

  final List<_Feature> _features = const [
    _Feature(
      title: 'Translate',
      subtitle: 'Text & voice',
      icon: Icons.translate,
      color: AppTheme.primaryBlue,
      route: '/translation',
    ),
    _Feature(
      title: 'Price Advisor',
      subtitle: 'Avoid scams',
      icon: Icons.attach_money,
      color: AppTheme.primaryOrange,
      route: '/price-advisor',
    ),
    _Feature(
      title: 'Recommendations',
      subtitle: 'AI suggestions',
      icon: Icons.recommend,
      color: AppTheme.lightBlue,
      route: '/recommendations',
    ),
    _Feature(
      title: 'Transport',
      subtitle: 'Get around',
      icon: Icons.directions_transit,
      color: AppTheme.darkBlue,
      route: '/transportation',
    ),
    // Currency converter feature
    _Feature(
      title: 'Currency Converter',
      subtitle: 'Live rates',
      icon: Icons.currency_exchange,
      color: AppTheme.primaryOrange,
      route: '/currency-converter',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _heroTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      _heroIndex = (_heroIndex + 1) % _heroImages.length;
      _heroCtrl.animateToPage(
        _heroIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _heroCtrl.dispose();
    super.dispose();
  }

  /// Navigate to feature and track usage
  void _navigateToFeature(_Feature feature) async {
    // Track feature usage
    await RatingService.trackFeatureUsage(feature.title);
    
    // Navigate to feature
    await Navigator.pushNamed(context, feature.route);
    
    // Always check if we should show rating prompt when returning
    await _checkAndShowRatingPrompt();
  }

  /// Check if rating prompt should be shown and show it
  Future<void> _checkAndShowRatingPrompt() async {
    print('🔍 Checking if rating prompt should show...');
    final shouldShow = await RatingService.shouldShowRatingPrompt();
    print('📋 Should show rating prompt: $shouldShow');
    
    if (shouldShow && mounted) {
      print('✅ Showing rating dialog!');
      await RatingService.markRatingPrompted();
      _showRatingDialog();
    } else {
      print('❌ Not showing rating prompt (shouldShow: $shouldShow, mounted: $mounted)');
    }
  }

  /// Show rating dialog
  void _showRatingDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.star, color: AppTheme.primaryOrange),
              const SizedBox(width: 8),
              const Text('Rate Us'),
            ],
          ),
          content: const Text(
            'How was your experience using our app? Your feedback helps us improve!',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Maybe Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/rating');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Rate Now'),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Decorative background shapes
          Positioned(
            top: -80,
            left: -60,
            child: _blob(180, AppTheme.primaryOrange.withOpacity(0.15)),
          ),
          Positioned(
            top: 120,
            right: -40,
            child: _blob(120, AppTheme.primaryBlue.withOpacity(0.12)),
          ),
          Positioned(
            bottom: 80,
            left: -50,
            child: _blob(140, AppTheme.lightBlue.withOpacity(0.10)),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  _buildTopBar(),
                  const SizedBox(height: 16),
                  _buildHeroBanner(context),
                  const SizedBox(height: 24),
                  _buildFeatureHeader(),
                  const SizedBox(height: 12),
                  _buildFeatureGrid(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          if (index == 0) {
            Navigator.pushNamed(context, '/chats');
          }
          if (index == 1) {
            // Match button tapped -> navigate to match screen
            Navigator.pushNamed(context, '/match');
          } else if (index == 2) {
            // Profile button tapped -> navigate to profile screen
            Navigator.pushNamed(context, '/profile');
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primaryOrange,
        unselectedItemColor: AppTheme.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline),
            label: 'Match',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, ${FirebaseAuth.instance.currentUser?.displayName ?? 'Traveler'}!',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              // Test rating button (for debugging)
              IconButton(
                onPressed: () async {
                  print('🧪 Testing rating system...');
                  await RatingService.resetRatingData();
                  await RatingService.trackFeatureUsage('Test Feature');
                  await _checkAndShowRatingPrompt();
                },
                icon: const Icon(Icons.star, color: AppTheme.primaryOrange, size: 32),
                tooltip: 'Test Rating System',
              ),
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primaryOrange,
                child: const Icon(Icons.explore, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Slider (keeping your existing slider functionality)
            SizedBox(
              height: 180,
              width: double.infinity,
              child: PageView.builder(
                controller: _heroCtrl,
                itemCount: _heroImages.length,
                itemBuilder: (_, i) => Image.network(
                  _heroImages[i],
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.15),
                      Colors.black.withOpacity(0.45),
                    ],
                  ),
                ),
              ),
            ),
            // Quote of the day overlay
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.format_quote,
                        color: Colors.white.withOpacity(0.9),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Quote of the Day',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '"The world is a book and those who do not travel read only one page."',
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '- Saint Augustine',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Features',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => AllFeaturesScreen(features: _features)),
              );
            },
            child: Text(
              'View All',
              style: GoogleFonts.inter(
                color: AppTheme.primaryOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _features.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _featureButton(f),
        )).toList(),
      ),
    );
  }

  Widget _featureButton(_Feature f) {
    return InkWell(
      onTap: () => _navigateToFeature(f),
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              f.color.withOpacity(0.14),
              f.color.withOpacity(0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: f.color.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: f.color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(f.icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      f.subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppTheme.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 24,
            spreadRadius: 6,
          ),
        ],
      ),
    );
  }
}

class _Feature {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
  const _Feature({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });
}

class AllFeaturesScreen extends StatefulWidget {
  final List<_Feature> features;
  const AllFeaturesScreen({super.key, required this.features});

  @override
  State<AllFeaturesScreen> createState() => _AllFeaturesScreenState();
}

class _AllFeaturesScreenState extends State<AllFeaturesScreen> {
  /// Navigate to feature and track usage
  void _navigateToFeature(_Feature feature) async {
    // Track feature usage
    await RatingService.trackFeatureUsage(feature.title);
    
    // Navigate to feature
    await Navigator.pushNamed(context, feature.route);
    
    // Always check if we should show rating prompt when returning
    await _checkAndShowRatingPrompt();
  }

  /// Check if rating prompt should be shown and show it
  Future<void> _checkAndShowRatingPrompt() async {
    print('🔍 Checking if rating prompt should show...');
    final shouldShow = await RatingService.shouldShowRatingPrompt();
    print('📋 Should show rating prompt: $shouldShow');
    
    if (shouldShow && mounted) {
      print('✅ Showing rating dialog!');
      await RatingService.markRatingPrompted();
      _showRatingDialog();
    } else {
      print('❌ Not showing rating prompt (shouldShow: $shouldShow, mounted: $mounted)');
    }
  }

  /// Show rating dialog
  void _showRatingDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.star, color: AppTheme.primaryOrange),
              const SizedBox(width: 8),
              const Text('Rate Us'),
            ],
          ),
          content: const Text(
            'How was your experience using our app? Your feedback helps us improve!',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Maybe Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/rating');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Rate Now'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Features'),
        backgroundColor: AppTheme.primaryOrange,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: widget.features.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final f = widget.features[index];
          return ListTile(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: f.color.withOpacity(0.08),
            leading: CircleAvatar(
                backgroundColor: f.color,
                child: Icon(f.icon, color: Colors.white)),
            title: Text(f.title,
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            subtitle: Text(f.subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _navigateToFeature(f),
          );
        },
      ),
    );
  }
}