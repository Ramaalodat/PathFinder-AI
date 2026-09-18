import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/home');
                            },
                            icon: const Icon(Icons.arrow_back_ios,
                                color: Colors.black87),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Messages',
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.search,
                            color: Colors.black87, size: 28),
                        iconSize: 28,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _mockChats.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final chat = _mockChats[index];
                      return _ChatTile(chat: chat);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
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

class _ChatTile extends StatelessWidget {
  final _Chat chat;
  const _ChatTile({required this.chat});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: AppTheme.primaryBlue,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          chat.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        chat.timeLabel,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${chat.messageCount} messages',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.25,
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
}

class _Chat {
  final String name;
  final String lastMessage;
  final String timeLabel;
  final int unreadCount;
  final String avatarUrl;
  final int messageCount;
  const _Chat({
    required this.name,
    required this.lastMessage,
    required this.timeLabel,
    required this.unreadCount,
    required this.avatarUrl,
    required this.messageCount,
  });
}

const _mockChats = <_Chat>[
  _Chat(
    name: 'Shane Martinez',
    lastMessage: 'On my way home but I needed to stop by the book store to…',
    timeLabel: '5 min',
    unreadCount: 1,
    avatarUrl:
        'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?q=80&w=400&auto=format&fit=crop',
    messageCount: 3,
  ),
  _Chat(
    name: 'Katie Keller',
    lastMessage: "I'm watching Friends. What are you doing?",
    timeLabel: '15 min',
    unreadCount: 0,
    avatarUrl:
        'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=400&auto=format&fit=crop',
    messageCount: 7,
  ),
  _Chat(
    name: 'Stephen Mann',
    lastMessage: "I'm working now. I'm making a deposit for our company.",
    timeLabel: '1 hour',
    unreadCount: 0,
    avatarUrl:
        'https://images.unsplash.com/photo-1527980965255-d3b416303d12?q=80&w=400&auto=format&fit=crop',
    messageCount: 2,
  ),
  _Chat(
    name: 'Shane Martinez',
    lastMessage:
        'I really find the subject very interesting. I\'m enjoying all my…',
    timeLabel: '5 hour',
    unreadCount: 0,
    avatarUrl:
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?q=80&w=400&auto=format&fit=crop',
    messageCount: 5,
  ),
  _Chat(
    name: 'Melvin Pratt',
    lastMessage: "Great seeing you. I have to go now. I'll talk to you later.",
    timeLabel: '5 hour',
    unreadCount: 0,
    avatarUrl:
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=400&auto=format&fit=crop',
    messageCount: 1,
  ),
];
