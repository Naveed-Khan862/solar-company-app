import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../theme/app_theme.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool mine;

  const ChatBubble({super.key, required this.message, required this.mine});

  String _formatDate(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day}/${d.month}/${d.year}  $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final align = mine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 3),
            child: Text(
              mine ? 'You' : message.senderName,
              style: const TextStyle(
                  color: Color(0xFF00A86B),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600),
            ),
          ),
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(mine ? 16 : 4),
                bottomRight: Radius.circular(mine ? 4 : 16),
              ),
              gradient: mine
                  ? LinearGradient(
                      colors: [Color(0xFF00C97D), Color(0xFF00A86B)])
                  : null,
              color: mine ? null : AppPalette.surface,
              border: mine ? null : Border.all(color: AppPalette.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.text,
                  style: TextStyle(
                    color: mine ? Colors.white : AppPalette.textPrimary,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  _formatDate(message.sentAt),
                  style: TextStyle(
                    color: mine
                        ? Colors.white.withValues(alpha: 0.75)
                        : AppPalette.textFaint,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: AppPalette.surface.withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: AppPalette.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(color: AppPalette.textPrimary),
              onSubmitted: (_) => onSend(),
              // Fix #11: message length limit — storage/quota abuse se bachao.
              maxLength: 1000,
              decoration: InputDecoration(
                counterText: '',
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: AppPalette.textFaint),
                filled: true,
                fillColor: AppPalette.surfaceSoft,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(color: AppPalette.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(color: AppPalette.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide:
                      const BorderSide(color: Color(0xFF00A86B), width: 1.4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSend,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                    colors: [Color(0xFF00C97D), Color(0xFF00A86B)]),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00A86B).withValues(alpha: 0.4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child:
                  const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
