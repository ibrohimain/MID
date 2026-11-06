import 'package:flutter/material.dart';

import 'core/auth/auth_controller.dart';
import 'core/theme/mid_theme.dart';
import 'data/mid_store.dart';
import 'features/auth/login_page.dart';
import 'features/shell/app_shell.dart';

class MidApp extends StatefulWidget {
  const MidApp({super.key});

  @override
  State<MidApp> createState() => _MidAppState();
}

class _MidAppState extends State<MidApp> {
  late final MidStore _store = MidStore();
  late final AuthController _auth = AuthController(_store);

  @override
  void initState() {
    super.initState();
    // Faqat login/logout uchun — store o'zgarishi butun shellni qayta
    // qurmasin (aks holda scroll pastga siljiydi).
    _auth.addListener(_onAuthChanged);
  }

  void _onAuthChanged() => setState(() {});

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    _auth.dispose();
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MID',
      debugShowCheckedModeBanner: false,
      theme: MidTheme.light(),
      home: _auth.isAuthenticated
          ? AppShell(auth: _auth, store: _store)
          : LoginPage(auth: _auth),
    );
  }
}
