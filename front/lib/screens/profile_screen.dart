import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color accentOrange = const Color(0xFFFC9D23); // per request
    final Color accentBlue = const Color(0xFF1C2F69); // per request

    return Scaffold(
      backgroundColor: Colors.white, // match homepage scaffold
      appBar: AppBar(
        backgroundColor: AppTheme.darkBlue,
        title: const Text('Profile'),
      ),
      body: Stack(
        children: [
          // decorative blobs to mirror homepage style
          Positioned(
            top: -80,
            left: -60,
            child: _blob(180, accentOrange.withOpacity(0.15)),
          ),
          Positioned(
            top: 120,
            right: -40,
            child: _blob(120, accentBlue.withOpacity(0.12)),
          ),
          Positioned(
            bottom: 80,
            left: -50,
            child: _blob(140, AppTheme.lightBlue.withOpacity(0.10)),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(accentOrange, accentBlue, context),
                  const SizedBox(height: 20),
                  _aboutCard(accentBlue),
                  const SizedBox(height: 16),
                  _interestsCard(accentOrange, accentBlue),
                  const SizedBox(height: 16),
                  _settingsCard(accentOrange, accentBlue, context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(Color accentOrange, Color accentBlue, BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: accentBlue,
          backgroundImage: user?.photoURL != null 
              ? NetworkImage(user!.photoURL!) 
              : null,
          child: user?.photoURL == null 
              ? Text(
                  user?.displayName?.isNotEmpty == true 
                      ? user!.displayName![0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.displayName ?? 'User',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.email, size: 16, color: accentOrange),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      user?.email ?? 'No email',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.pushNamed(context, '/edit-account');
          },
          icon: Icon(Icons.edit, color: accentOrange),
        )
      ],
    );
  }

  Widget _aboutCard(Color accentBlue) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: accentBlue),
                const SizedBox(width: 8),
                Text(
                  'Bio',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Traveler, foodie, and photography enthusiast. Always exploring new cultures and hidden gems.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _interestsCard(Color accentOrange, Color accentBlue) {
    final interests = <String>[
      'Beaches',
      'Street Food',
      'Hiking',
      'Museums',
      'Photography',
      'Night Markets',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: accentOrange),
                const SizedBox(width: 8),
                Text(
                  'Interests',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in interests)
                  Chip(
                    label: Text(item),
                    backgroundColor: accentOrange.withOpacity(0.12),
                    labelStyle: GoogleFonts.inter(
                      color: accentBlue,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: accentOrange.withOpacity(0.4)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsCard(Color accentOrange, Color accentBlue, BuildContext context) {
    return Card(
      child: Column(
        children: [
          _settingsTile(
            icon: Icons.language,
            title: 'Language',
            subtitle: 'English',
            leadingColor: accentBlue,
            onTap: () {},
          ),
          const Divider(height: 1),
          _settingsTile(
            icon: Icons.logout,
            title: 'Log out',
            subtitle: 'Sign out of your account',
            leadingColor: Colors.redAccent,
            onTap: () async {
              try {
                await AuthService.signOut();
                // Navigate to landing page after successful logout
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context, 
                    '/landing', 
                    (route) => false
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error signing out: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color leadingColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: leadingColor.withOpacity(0.12),
        child: Icon(icon, color: leadingColor),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(color: AppTheme.textSecondary),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
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

 