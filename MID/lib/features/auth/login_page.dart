import 'package:flutter/material.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/theme/mid_colors.dart';
import '../../widgets/mid_logo.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.auth});

  final AuthController auth;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _login = TextEditingController(text: 'direktor');
  final _password = TextEditingController(text: '1234');
  bool _obscure = true;

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await widget.auth.signIn(_login.text, _password.text);
    if (!ok && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A2A2A), MidColors.navy, Color(0xFF16324A)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                decoration: BoxDecoration(
                  color: MidColors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth > 720;
                    final left = _BrandSide(wide: wide);
                    final right = Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Tizimga kirish',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Login va parol Direktor tomonidan beriladi.",
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: MidColors.navyMuted),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _login,
                            decoration: const InputDecoration(
                              labelText: 'Login',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            onSubmitted: (_) => _submit(),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _password,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: 'Parol',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                icon: Icon(_obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined),
                              ),
                            ),
                            onSubmitted: (_) => _submit(),
                          ),
                          if (widget.auth.error != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              widget.auth.error!,
                              style: const TextStyle(color: MidColors.coral),
                            ),
                          ],
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: widget.auth.busy ? null : _submit,
                              child: widget.auth.busy
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Kirish'),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Direktor: direktor / 1234\n'
                            'Rahbar A: rahbar_a / a12345\n'
                            'Rahbar B: rahbar_b / b12345\n'
                            'Xodim/o‘quvchi: jasur yoki madina / 1234',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: MidColors.navyMuted),
                          ),
                        ],
                      ),
                    );
                    if (!wide) {
                      return SingleChildScrollView(
                        child: Column(children: [left, right]),
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: left),
                        Expanded(child: right),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandSide extends StatelessWidget {
  const _BrandSide({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(wide ? 40 : 28),
      decoration: BoxDecoration(
        color: MidColors.sand,
        borderRadius: BorderRadius.horizontal(
          left: const Radius.circular(24),
          right: Radius.circular(wide ? 0 : 24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const MidLogo(height: 52),
          const SizedBox(height: 28),
          Text(
            'MID boshqaruv paneli',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            "Direktor va 2 rahbar (A/B sektor). Xodim, o'quvchi va shogirtlar "
            "berilgan login-parol bilan kiradi.",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: MidColors.navyMuted,
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }
}
