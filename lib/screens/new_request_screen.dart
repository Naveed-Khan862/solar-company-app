import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/service_request.dart';
import '../models/user.dart';
import '../providers.dart';
import '../utils/ids.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_tilt_card.dart';
import '../theme/app_theme.dart';

class NewRequestScreen extends ConsumerStatefulWidget {
  final UserModel user;

  const NewRequestScreen({super.key, required this.user});

  @override
  ConsumerState<NewRequestScreen> createState() => _NewRequestScreenState();
}

class _NewRequestScreenState extends ConsumerState<NewRequestScreen> {
  RequestCategory _category = RequestCategory.complaint;
  String _subCategory = 'Inverter Issue';
  String _priority = 'Normal';
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _submitting = false;
  bool _error = false;
  bool _addressError = false;
  bool _phoneError = false;

  static const _complaintSubs = ['Inverter Issue', 'Battery Issue', 'Other Issue'];

  @override
  void initState() {
    super.initState();
    final prefill = ref.read(displayPhoneProvider(widget.user));
    if (prefill.isNotEmpty) {
      _phoneController.text = prefill;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
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

  Future<void> _submit() async {
    final desc = _descriptionController.text.trim();
    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim();
    var valid = true;
    if (desc.isEmpty) {
      _error = true;
      valid = false;
    }
    if (address.isEmpty) {
      _addressError = true;
      valid = false;
    }
    if (phone.isEmpty || phone.replaceAll(RegExp(r'[^0-9]'), '').length != 11) {
      _phoneError = true;
      valid = false;
    }
    if (!valid) {
      setState(() {});
      return;
    }
    setState(() {
      _submitting = true;
      _error = false;
      _addressError = false;
      _phoneError = false;
    });

    await Future.delayed(const Duration(milliseconds: 600));

    final request = ServiceRequest(
      id: generateId(),
      userEmail: widget.user.email,
      userName: widget.user.name,
      category: _category,
      subCategory: _category == RequestCategory.complaint ? _subCategory : '',
      priority: _priority,
      description: desc,
      address: address,
      phone: phone,
      status: RequestStatus.pending,
      createdAt: DateTime.now(),
    );
    // SEC-03: add() throttle/error message return karta hai (null = success).
    final error = await ref.read(requestRepositoryProvider).add(request);
    if (!mounted) return;
    if (error != null) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppPalette.textPrimary, size: 20),
                    ),
                    Text(
                      'New Request',
                      style: TextStyle(
                        color: AppPalette.textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _SectionLabel('Category'),
                      const SizedBox(height: 10),
                      Row(
                        children: RequestCategory.values.map((c) {
                          final selected = _category == c;
                          final color = _catColor(c);
                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: GestureDetector(
                                onTap: () => setState(() => _category = c),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOut,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    gradient: selected
                                        ? LinearGradient(
                                            colors: [
                                              color,
                                              color.withValues(alpha: 0.75),
                                            ],
                                          )
                                        : null,
                                    color: selected
                                        ? null
                                        : Colors.white.withValues(alpha: 0.85),
                                    border: Border.all(
                                      color: selected
                                          ? color.withValues(alpha: 0.6)
                                          : AppPalette.border,
                                    ),
                                    boxShadow: selected
                                        ? [
                                            BoxShadow(
                                              color: color
                                                  .withValues(alpha: 0.35),
                                              blurRadius: 18,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        c.icon,
                                        color: selected
                                            ? Colors.white
                                            : AppPalette.textMuted,
                                        size: 22,
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        c.label,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: selected
                                              ? Colors.white
                                              : AppPalette.textSecondary,
                                          fontSize: 11.5,
                                          fontWeight: selected
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (_category == RequestCategory.complaint) ...[
                        SizedBox(height: 22),
                        const _SectionLabel('Sub-Category'),
                        SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: _subCategory,
                          style: TextStyle(color: AppPalette.textPrimary),
                          iconEnabledColor: Color(0xFF00A86B),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide:
                                  BorderSide(color: AppPalette.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide:
                                  BorderSide(color: AppPalette.border),
                            ),
                          ),
                          items: _complaintSubs
                              .map((s) => DropdownMenuItem(
                                  value: s, child: Text(s)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _subCategory = v ?? _subCategory),
                        ),
                      ],
                      const SizedBox(height: 22),
                      const _SectionLabel('Priority'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          for (final p in ['Normal', 'Urgent'])
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _priority = p),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 13),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: _priority == p
                                          ? (p == 'Urgent'
                                              ? const LinearGradient(
                                                  colors: [
                                                    Color(0xFFE53935),
                                                    Color(0xFFC62828),
                                                  ],
                                                )
                                              : const LinearGradient(
                                                  colors: [
                                                    Color(0xFF00C97D),
                                                    Color(0xFF00A86B),
                                                  ],
                                                ))
                                          : null,
                                      color: _priority == p
                                          ? null
                                          : Colors.white
                                              .withValues(alpha: 0.85),
                                      border: Border.all(
                                        color: _priority == p
                                            ? (p == 'Urgent'
                                                ? Color(0xFFE53935)
                                                : Color(0xFF00A86B))
                                            : AppPalette.border,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          p == 'Urgent'
                                              ? Icons.local_fire_department_rounded
                                              : Icons.timelapse_rounded,
                                          color: _priority == p
                                              ? Colors.white
                                              : AppPalette.textMuted,
                                          size: 17,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          p,
                                          style: TextStyle(
                                            color: _priority == p
                                                ? Colors.white
                                                : AppPalette.textSecondary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 22),
                      const _SectionLabel('Address (Required)'),
                      SizedBox(height: 10),
                      GlassTiltCard(
                        padding: const EdgeInsets.all(2),
                        child: TextField(
                          controller: _addressController,
                          maxLines: 2,
                          keyboardType: TextInputType.streetAddress,
                          // Fix #11: length limit.
                          maxLength: 500,
                          style: TextStyle(color: AppPalette.textPrimary),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: 'Enter full address — street, area, city',
                            hintStyle: TextStyle(
                                color: AppPalette.textFaint, fontSize: 14),
                            prefixIcon: Icon(Icons.location_on_outlined,
                                color: AppPalette.textMuted, size: 20),
                            filled: true,
                            fillColor: Colors.transparent,
                            errorText: _addressError
                                ? 'Address is required'
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const _SectionLabel('Phone Number (Required)'),
                      SizedBox(height: 10),
                      GlassTiltCard(
                        padding: const EdgeInsets.all(2),
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(color: AppPalette.textPrimary),
                          decoration: InputDecoration(
                            hintText: '0300-1234567',
                            hintStyle: TextStyle(
                                color: AppPalette.textFaint, fontSize: 14),
                            prefixIcon: Icon(Icons.phone_outlined,
                                color: AppPalette.textMuted, size: 20),
                            filled: true,
                            fillColor: Colors.transparent,
                            errorText: _phoneError
                                ? 'Enter a valid 11-digit phone number'
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 22),
                      const _SectionLabel('Description'),
                      SizedBox(height: 10),
                      GlassTiltCard(
                        padding: const EdgeInsets.all(2),
                        child: TextField(
                          controller: _descriptionController,
                          maxLines: 4,
                          // Fix #11: length limit — quota abuse se bachao.
                          maxLength: 2000,
                          style: TextStyle(color: AppPalette.textPrimary),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: 'Describe the issue in detail...',
                            hintStyle: TextStyle(
                                color: AppPalette.textFaint, fontSize: 14),
                            filled: true,
                            fillColor: Colors.transparent,
                            errorText:
                                _error ? 'Description is required' : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      GestureDetector(
                        onTap: _submitting ? null : _submit,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00C97D), Color(0xFF00A86B)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00A86B)
                                    .withValues(alpha: 0.4),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_submitting) ...[
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                ),
                                const SizedBox(width: 10),
                              ] else ...[
                                const Icon(Icons.send_rounded,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                _submitting
                                    ? 'Submitting...'
                                    : 'Submit Request',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15.5,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: LinearGradient(
                colors: [Color(0xFF00C97D), Color(0xFF00A86B)]),
          ),
        ),
        SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: AppPalette.textPrimary,
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
