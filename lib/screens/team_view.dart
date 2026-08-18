import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_tilt_card.dart';

class TeamView extends ConsumerStatefulWidget {
  final UserModel user;

  const TeamView({super.key, required this.user});

  @override
  ConsumerState<TeamView> createState() => _TeamViewState();
}

class _TeamViewState extends ConsumerState<TeamView> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final phone = _phoneController.text.trim();
    if (name.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter a name and valid email');
      return;
    }
    if (widget.user.isSuperAdmin) {
      final members = ref.read(teamMembersProvider);
      if (members.any((u) => u.email == email)) {
        setState(() => _error = 'This email is already in the team');
        return;
      }
      setState(() => _error = null);
      final err = await ref.read(teamRepositoryProvider).addTeamMember(
        UserModel(
          name: name,
          email: email,
          phone: phone.isEmpty ? '—' : phone,
          role: UserRole.subAdmin,
        ),
      );
      if (err != null) {
        setState(() => _error = err);
        return;
      }
    } else {
      final subTeam = ref.read(subTeamProvider(widget.user.email));
      if (subTeam.any((u) => u.email == email)) {
        setState(() => _error = 'This email is already in your team');
        return;
      }
      setState(() => _error = null);
      final err = await ref.read(teamRepositoryProvider).addSubTeamMember(
        widget.user.email,
        UserModel(
          name: name,
          email: email,
          phone: phone.isEmpty ? '—' : phone,
          role: UserRole.user,
        ),
      );
      if (err != null) {
        setState(() => _error = err);
        return;
      }
    }
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    if (mounted) setState(() {});
  }

  Future<void> _remove(UserModel member) async {
    if (widget.user.isSuperAdmin) {
      await ref.read(teamRepositoryProvider).removeTeamMember(member.email);
    } else {
      await ref.read(teamRepositoryProvider).removeSubTeamMember(widget.user.email, member.email);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isSuper = widget.user.isSuperAdmin;
    final members = isSuper
        ? ref.watch(teamMembersProvider)
        : ref.watch(subTeamProvider(widget.user.email));
    final title = isSuper
        ? 'Add New Sub Admin'
        : 'Add Member To My Team';
    final hint = isSuper
        ? 'Requests can be assigned to Sub Admins'
        : 'Your team members can chat with you';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        GlassTiltCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppPalette.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              SizedBox(height: 3),
              Text(
                hint,
                style: TextStyle(color: AppPalette.textMuted, fontSize: 12),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _nameController,
                style: TextStyle(color: AppPalette.textPrimary),
                decoration: _fieldDec('Naam'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _emailController,
                style: TextStyle(color: AppPalette.textPrimary),
                keyboardType: TextInputType.emailAddress,
                decoration: _fieldDec('Email'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _phoneController,
                style: TextStyle(color: AppPalette.textPrimary),
                keyboardType: TextInputType.phone,
                decoration: _fieldDec('Phone (optional)'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(
                      color: Color(0xFFD32F2F), fontSize: 12.5),
                ),
              ],
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _add,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                        colors: [Color(0xFF00C97D), Color(0xFF00A86B)]),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00A86B).withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSuper
                            ? Icons.person_add_alt_1_rounded
                            : Icons.group_add_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isSuper ? 'Add Sub Admin' : 'Add Team Member',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        Text(
          isSuper ? 'Team Members (Sub Admins)' : 'Meri Team',
          style: TextStyle(
            color: AppPalette.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        SizedBox(height: 8),
        if (members.isEmpty)
          GlassTiltCard(
            child: Text(
              isSuper ? 'No members in the team' : 'Team is empty',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppPalette.textMuted, fontSize: 13),
            ),
          ),
        for (final m in members)
          GlassTiltCard(
            margin: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                        colors: [Color(0xFF00C97D), Color(0xFF00A86B)]),
                  ),
                  child: Text(
                    m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.name,
                        style: TextStyle(
                          color: AppPalette.textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        m.email,
                        style: TextStyle(
                            color: AppPalette.textSecondary, fontSize: 12.5),
                      ),
                      SizedBox(height: 1),
                      Text(
                        m.phone,
                        style: TextStyle(
                            color: AppPalette.textFaint, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _remove(m),
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Color(0xFFE53935), size: 21),
                  tooltip: 'Remove',
                ),
              ],
            ),
          ),
      ],
    );
  }

  InputDecoration _fieldDec(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppPalette.textFaint),
      filled: true,
      fillColor: AppPalette.surfaceSoft,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppPalette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppPalette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF00A86B), width: 1.4),
      ),
    );
  }
}
