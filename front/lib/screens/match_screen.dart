import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Nearby', 'Similar', 'Saved'];

  final List<Map<String, dynamic>> _travelers = [
    {
      'name': 'Sarah',
      'age': 28,
      'country': 'USA',
      'location': 'Shibuya',
      'distance': '0.5 km',
      'tag': 'Budget Backpacker',
      'languages': ['English', 'Spanish'],
      'interests': ['Photography', 'Food', 'History'],
      'bio':
          'Adventure seeker exploring the world one city at a time. Love capturing moments and trying local cuisines.',
      'profileImage':
          'https://images.unsplash.com/photo-1494790108755-2616b612b786?q=80&w=400&auto=format&fit=crop',
      'isOnline': true,
    },
    {
      'name': 'Marco',
      'age': 32,
      'country': 'Italy',
      'location': 'Harajuku',
      'distance': '1.2 km',
      'tag': 'Cultural Explorer',
      'languages': ['Italian', 'English'],
      'interests': ['Art', 'Wine', 'Architecture'],
      'bio':
          'Passionate about art and culture. Always looking for hidden gems and authentic experiences.',
      'profileImage':
          'https://images.unsplash.com/photo-1494790108755-2616b612b786?q=80&w=400&auto=format&fit=crop',
      'isOnline': true,
    },
    {
      'name': 'Emma',
      'age': 25,
      'country': 'Australia',
      'location': 'Ginza',
      'distance': '2.1 km',
      'tag': 'Solo Traveler',
      'languages': ['English', 'Japanese'],
      'interests': ['Nature', 'Technology', 'Music'],
      'bio':
          'Tech enthusiast who loves hiking and discovering new music scenes in every city.',
      'profileImage':
          'https://images.unsplash.com/photo-1494790108755-2616b612b786?q=80&w=400&auto=format&fit=crop',
      'isOnline': false,
    },
    {
      'name': 'Alex',
      'age': 30,
      'country': 'Canada',
      'location': 'Roppongi',
      'distance': '3.5 km',
      'tag': 'Foodie',
      'languages': ['English', 'French'],
      'interests': ['Cooking', 'Travel', 'Sports'],
      'bio':
          'Chef by profession, traveler by passion. Love exploring local markets and street food.',
      'profileImage':
          'https://images.unsplash.com/photo-1494790108755-2616b612b786?q=80&w=400&auto=format&fit=crop',
      'isOnline': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Decorative background shapes (matching home screen)
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
          Positioned(
            bottom: -60,
            right: -80,
            child: _blob(100, AppTheme.primaryOrange.withOpacity(0.08)),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildFilterBar(),
                Expanded(
                  child: _buildTravelerCards(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/home'),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: AppTheme.textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: AppTheme.textPrimary,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryOrange : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isSelected)
                      const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    if (isSelected) const SizedBox(width: 4),
                    Text(
                      filter,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            isSelected ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTravelerCards() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: _travelers.length,
      itemBuilder: (context, index) {
        final traveler = _travelers[index];
        return _buildTravelerCard(traveler);
      },
    );
  }

  Widget _buildTravelerCard(Map<String, dynamic> traveler) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 240),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar on left side
            Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(35),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: Image.network(
                          traveler['profileImage'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // Online status
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color:
                              traveler['isOnline'] ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    traveler['tag'],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            // Content on right side
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and details
                  Text(
                    traveler['name'],
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${traveler['age']} • ${traveler['country']}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: AppTheme.primaryOrange,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${traveler['location']} • ${traveler['distance']}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Bio
                  Text(
                    traveler['bio'],
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Languages and interests
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...traveler['languages'].map<Widget>((lang) => _buildTag(
                          lang, Colors.blue[100]!, Colors.blue[800]!)),
                      ...traveler['interests'].map<Widget>((interest) =>
                          _buildTag(
                              interest, Colors.grey[200]!, Colors.grey[700]!)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Match Up button
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Meet Up',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
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

  Widget _buildTag(String text, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
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
