import 'package:flutter/material.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/safe_mutate.dart';
import '../../core/theme/mid_colors.dart';
import '../../data/mid_store.dart';
import '../../models/app_user.dart';
import '../../models/user_role.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/section_header.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.user,
    required this.store,
    required this.auth,
  });

  final AppUser user;
  final MidStore store;
  final AuthController auth;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _currentPass;
  late final TextEditingController _newPass;
  late final TextEditingController _confirmPass;
  String? _message;
  bool _ok = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user.fullName);
    _email = TextEditingController(text: widget.user.email ?? '');
    _phone = TextEditingController(text: widget.user.phone ?? '');
    _currentPass = TextEditingController();
    _newPass = TextEditingController();
    _confirmPass = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _currentPass.dispose();
    _newPass.dispose();
    _confirmPass.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _message = null;
      _ok = false;
    });

    if (_name.text.trim().isEmpty) {
      setState(() => _message = 'Ism bo‘sh bo‘lmasligi kerak');
      return;
    }

    final changingPass = _newPass.text.trim().isNotEmpty;
    if (changingPass) {
      if (_currentPass.text != widget.user.password) {
        setState(() => _message = 'Joriy parol noto‘g‘ri');
        return;
      }
      if (_newPass.text.trim().length < 4) {
        setState(() => _message = 'Yangi parol kamida 4 belgi bo‘lsin');
        return;
      }
      if (_newPass.text.trim() != _confirmPass.text.trim()) {
        setState(() => _message = 'Yangi parol tasdiqlanmadi');
        return;
      }
    }

    await safeMutate(context, () async {
      await widget.store.updateProfile(
        userId: widget.user.id,
        fullName: _name.text,
        email: _email.text,
        phone: _phone.text,
        password: changingPass ? _newPass.text : null,
      );
      if (changingPass) {
        widget.user.password = _newPass.text.trim();
      }
      widget.auth.refreshUser();
    });
    if (!mounted) return;
    _currentPass.clear();
    _newPass.clear();
    _confirmPass.clear();
    setState(() {
      _ok = true;
      _message = changingPass
          ? 'Profil va parol yangilandi'
          : 'Profil saqlandi';
    });
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    return PageScaffold(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Profil sozlamalari',
              subtitle: 'Shaxsiy ma’lumot va parolni yangilang',
            ),
            const SizedBox(height: 16),
            SurfaceBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: MidColors.teal.withValues(alpha: 0.15),
                        foregroundColor: MidColors.teal,
                        child: Text(
                          u.fullName.isNotEmpty ? u.fullName[0] : '?',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              u.fullName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              '${u.role.label}'
                              '${u.sector != null ? ' · ${u.sector!.label}' : ''}'
                              '${u.position != null ? ' · ${u.position}' : ''}',
                              style: const TextStyle(color: MidColors.navyMuted),
                            ),
                            Text(
                              'Login: ${u.login}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (u.role == UserRole.rahbar) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: MidColors.teal.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Siz rahbarsiz — ikkinchi rahbar bilan teng huquqli. '
                        'Yuqorida yagona Direktor turadi.',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            SurfaceBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Asosiy ma’lumotlar',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'F.I.Sh'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _phone,
                    decoration: const InputDecoration(labelText: 'Telefon'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SurfaceBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Parolni o‘zgartirish',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Faqat parolni yangilamoqchi bo‘lsangiz to‘ldiring.',
                    style: TextStyle(color: MidColors.navyMuted),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _currentPass,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'Joriy parol'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _newPass,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'Yangi parol'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _confirmPass,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Yangi parolni tasdiqlang',
                    ),
                  ),
                ],
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(
                _message!,
                style: TextStyle(
                  color: _ok ? MidColors.success : MidColors.coral,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Saqlash'),
            ),
          ],
        ),
      ),
    );
  }
}
