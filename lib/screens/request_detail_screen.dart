import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_message.dart';
import '../models/service_request.dart';
import '../models/user.dart';
import '../providers.dart';
import '../utils/ids.dart';
import '../widgets/app_background.dart';
import '../widgets/chat_parts.dart';
import '../widgets/glass_tilt_card.dart';
import '../theme/app_theme.dart';

class RequestDetailScreen extends ConsumerStatefulWidget {
  final ServiceRequest request;
  final UserModel user;

  const RequestDetailScreen({
    super.key,
    required this.request,
    required this.user,
  });

  @override
  ConsumerState<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends ConsumerState<RequestDetailScreen> {
  late ServiceRequest _request;
  final _chatController = TextEditingController();
  final _scrollController = ScrollController();
  final _commentController = TextEditingController();
  double _rating = 0;

  @override
  void initState() {
    super.initState();
    _request = widget.request;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    // Fresh data from Firestore when the request chat opens — receiver side
    // (ChatScreen wala hi pattern). Warna app-init load mein jo kuch bhi
    // aya tha usi par reh jata hai.
    _refreshChat();
  }

  Future<void> _refreshChat() async {
    final repo = ref.read(chatRepositoryProvider);
    repo.resetLoaded();
    try {
      await repo.load(user: widget.user);
    } catch (_) {
      // permission/network — empty state dikhega
    }
    if (mounted) ref.invalidate(messagesProvider('request:${_request.id}'));
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _send() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    _chatController.clear();
    try {
      await ref.read(chatRepositoryProvider).addMessage(
        ChatMessage(
          id: generateId(),
          channel: 'request:${_request.id}',
          senderEmail: widget.user.email,
          senderName: widget.user.name,
          text: text,
          sentAt: DateTime.now(),
          // Rules ki read gate in fields par chalti hai (get() ke bina) —
          // owner userEmail, assigned subAdmin assignedTo se chat padh sakta hai.
          userEmail: _request.userEmail,
          assignedTo: _request.assignedTo,
          // SEC-01 v2: rules channel parse nahi karti — requestId se doc path.
          requestId: _request.id,
        ),
      );
    } catch (e) {
      // Silent fail na ho — text restore karke asli error dikhao taake
      // pata chale (aam taur par ye rules deny hota hai).
      _chatController.text = text;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Message send nahi hua — $e',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() {});
    _scrollToBottom();
  }

  Future<void> _assign(String? email) async {
    if (email == null) return;
    final unassigned = email == 'none';
    final String targetEmail;
    final String targetName;
    if (unassigned) {
      targetEmail = '';
      targetName = '';
    } else {
      final members = ref.read(teamMembersProvider);
      final member = members.firstWhere(
        (u) => u.email == email,
        orElse: () => UserModel(
            name: 'Unknown',
            email: email,
            phone: '',
            role: UserRole.subAdmin),
      );
      targetEmail = member.email;
      targetName = member.name;
    }
    await ref.read(requestRepositoryProvider).assign(_request.id, targetEmail, targetName);
    if (!mounted) return;
    setState(() {
      _request = _request.copyWith(
        assignedTo: targetEmail,
        assignedByName: targetName,
      );
    });
  }

  String _formatDate(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day}/${d.month}/${d.year}  $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final mine = widget.user.email == _request.userEmail;
    // Chat sirf in teeno ko: request ka owner, assigned sub-admin, ya CEO.
    // Kisi aur sub-admin ko request chat nahi dikhti (rules bhi yahi gate
    // karti hain — unassigned sub-admin ko messages query deny ho jati).
    final canChat = _request.status != RequestStatus.resolved &&
        (widget.user.isSuperAdmin ||
            mine ||
            _request.assignedTo == widget.user.email);
    final messages = ref.watch(messagesProvider('request:${_request.id}'));
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _header(),
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  children: [
                    GlassTiltCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: _catColor(_request.category)
                                      .withValues(alpha: 0.14),
                                ),
                                child: Icon(
                                  _request.category.icon,
                                  color: _catColor(_request.category),
                                  size: 18,
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _request.category.label,
                                      style: TextStyle(
                                        color: AppPalette.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      _request.priority == 'Urgent'
                                          ? 'Urgent Priority'
                                          : 'Normal Priority',
                                      style: TextStyle(
                                        color: _request.priority == 'Urgent'
                                            ? Color(0xFFE53935)
                                            : AppPalette.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: _request.status.color
                                      .withValues(alpha: 0.12),
                                  border: Border.all(
                                    color: _request.status.color
                                        .withValues(alpha: 0.45),
                                  ),
                                ),
                                child: Text(
                                  _request.status.label,
                                  style: TextStyle(
                                    color: _request.status.color,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_request.subCategory.isNotEmpty) ...[
                            Text(
                              _request.subCategory,
                              style: TextStyle(
                                color: Color(0xFF00A86B),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                          ],
                          Text(
                            _request.description,
                            style: TextStyle(
                              color: AppPalette.textSecondary,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          if (_request.address.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 15, color: AppPalette.textMuted),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _request.address,
                                    style: TextStyle(
                                        color: AppPalette.textMuted,
                                        fontSize: 12.5,
                                        height: 1.3),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (_request.phone.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.phone_outlined,
                                    size: 15, color: AppPalette.textMuted),
                                const SizedBox(width: 6),
                                Text(
                                  _request.phone,
                                  style: TextStyle(
                                      color: AppPalette.textMuted,
                                      fontSize: 12.5),
                                ),
                              ],
                            ),
                          ],
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(Icons.schedule_rounded,
                                  size: 13, color: AppPalette.textFaint),
                              SizedBox(width: 5),
                              Text(
                                _formatDate(_request.createdAt),
                                style: TextStyle(
                                    color: AppPalette.textFaint, fontSize: 12),
                              ),
                              Spacer(),
                              Text(
                                mine ? 'Aap' : _request.userName,
                                style: TextStyle(
                                    color: AppPalette.textFaint, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (widget.user.isSuperAdmin) ...[
                      const SizedBox(height: 12),
                      _assignCard(),
                    ] else if (widget.user.isSubAdmin &&
                        _request.assignedByName.isNotEmpty) ...[
                      SizedBox(height: 12),
                      GlassTiltCard(
                        child: Row(
                          children: [
                            Icon(Icons.person_pin_rounded,
                                color: Color(0xFF00A86B), size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _request.assignedTo == widget.user.email
                                    ? 'This request is assigned to you'
                                    : 'Is kaam par: ${_request.assignedByName}',
                                style: TextStyle(
                                    color: AppPalette.textSecondary,
                                    fontSize: 13.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    if (mine &&
                        _request.status == RequestStatus.resolved &&
                        !_request.isRated) ...[
                      _rateCard(),
                      SizedBox(height: 18),
                    ],
                    if (_request.isRated) ...[
                      _ratingView(),
                      SizedBox(height: 18),
                    ],
                    if (canChat) ...[
                      Text(
                        'Chat',
                        style: TextStyle(
                          color: AppPalette.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._messages(messages),
                    ] else ...[
                      const SizedBox(height: 18),
                      GlassTiltCard(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock_outline_rounded,
                                  color: AppPalette.textFaint, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Chat is only available for pending/in-progress requests — request owner, assigned sub-admin, or CEO',
                                style: TextStyle(
                                    color: AppPalette.textMuted,
                                    fontSize: 12.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (canChat) _inputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: AppPalette.textPrimary, size: 20),
          ),
          SizedBox(width: 4),
          Text(
            'Request Detail',
            style: TextStyle(
              color: AppPalette.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _assignCard() {
    final members = ref.watch(teamMembersProvider);
    final current = _request.assignedTo.isEmpty ? 'none' : _request.assignedTo;
    return GlassTiltCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assign To',
            style: TextStyle(
              color: AppPalette.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: current,
            style: TextStyle(color: AppPalette.textPrimary),
            iconEnabledColor: Color(0xFF00A86B),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppPalette.surfaceSoft,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppPalette.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppPalette.border),
              ),
            ),
            items: [
              const DropdownMenuItem(
                  value: 'none', child: Text('— Unassigned —')),
              ...members.map((m) => DropdownMenuItem(
                    value: m.email,
                    child: Text('${m.name}  (${m.email})'),
                  )),
            ],
            onChanged: _assign,
          ),
        ],
      ),
    );
  }

  Widget _rateCard() {
    return GlassTiltCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rate your experience',
            style: TextStyle(
              color: AppPalette.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Service kaisi rahi?',
            style: TextStyle(color: AppPalette.textMuted, fontSize: 12.5),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _rating = star.toDouble()),
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    star <= _rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: Color(0xFFFFB300),
                    size: 34,
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _commentController,
            maxLines: 3,
            maxLength: 200,
            style: TextStyle(color: AppPalette.textPrimary, fontSize: 13.5),
            decoration: InputDecoration(
              hintText: 'Comment (optional)',
              hintStyle: TextStyle(color: AppPalette.textFaint),
              filled: true,
              fillColor: AppPalette.surfaceSoft,
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppPalette.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppPalette.border),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00A86B),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                disabledBackgroundColor:
                    const Color(0xFF00A86B).withValues(alpha: 0.4),
              ),
              onPressed: _rating == 0 ? null : _submitRating,
              child: const Text(
                'Submit Rating',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitRating() async {
    await ref.read(requestRepositoryProvider).rate(
      _request.id,
      _rating,
      _commentController.text.trim(),
    );
    if (!mounted) return;
    final updated = ref.read(requestRepositoryProvider).all
        .where((r) => r.id == _request.id)
        .firstOrNull;
    setState(() {
      if (updated != null) _request = updated;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Thank you! Your rating has been submitted',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF00A86B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _ratingView() {
    return GlassTiltCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 20),
              SizedBox(width: 6),
              Text(
                _request.rating.toStringAsFixed(1),
                style: TextStyle(
                  color: AppPalette.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return Icon(
                    star <= _request.rating.round()
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: Color(0xFFFFB300),
                    size: 17,
                  );
                }),
              ),
              Spacer(),
              Text(
                'Rating',
                style: TextStyle(color: AppPalette.textFaint, fontSize: 12),
              ),
            ],
          ),
          if (_request.review.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              _request.review,
              style: TextStyle(
                color: AppPalette.textSecondary,
                fontSize: 13,
                height: 1.35,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _messages(List<ChatMessage> messages) {
    if (messages.isEmpty) {
      return [
        GlassTiltCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline_rounded,
                    color: AppPalette.textFaint, size: 18),
                SizedBox(width: 8),
                Text(
                  'No messages yet — send the first one',
                  style: TextStyle(color: AppPalette.textMuted, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ),
      ];
    }
    return [
      for (final m in messages)
        ChatBubble(message: m, mine: m.senderEmail == widget.user.email),
    ];
  }

  Widget _inputBar() {
    return ChatInputBar(
      controller: _chatController,
      onSend: _send,
    );
  }

  Color _catColor(RequestCategory c) {
    switch (c) {
      case RequestCategory.complaint:
        return const Color(0xFFFFB300);
      case RequestCategory.inspection:
        return const Color(0xFF00838F);
      case RequestCategory.panelWashing:
        return const Color(0xFF2E7D32);
    }
  }
}