import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../providers.dart';
import '../widgets/glass_tilt_card.dart';
import 'chat_screen.dart';
import '../theme/app_theme.dart';

class ChatsScreen extends ConsumerStatefulWidget {
  final UserModel user;

  const ChatsScreen({super.key, required this.user});

  @override
  ConsumerState<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends ConsumerState<ChatsScreen> {
  @override
  Widget build(BuildContext context) {
    final channels = ref.watch(channelsProvider(widget.user));
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        children: [
          Text(
            'Chats',
            style: TextStyle(
              color: AppPalette.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'You can only see chats you are part of',
            style: TextStyle(color: AppPalette.textMuted, fontSize: 12.5),
          ),
          const SizedBox(height: 14),
          for (final c in channels)
            GlassTiltCard(
              margin: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      channel: c.id,
                      title: c.title,
                      user: widget.user,
                    ),
                  ),
                ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                          colors: [Color(0xFF00C97D), Color(0xFF00A86B)]),
                    ),
                    child: Icon(Icons.forum_rounded,
                        color: Colors.white, size: 20),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.title,
                          style: TextStyle(
                            color: AppPalette.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14.5,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          c.subtitle,
                          style: TextStyle(
                              color: AppPalette.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: AppPalette.textFaint),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}