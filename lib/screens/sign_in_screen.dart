import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';

/// Sign in (m23 / w23): your backup and your shared links live here.
///
/// v0.1 has no backend: sign-in sends a code to the email and the
/// code is verified locally (any 6-digit code works in the demo).
/// The password field is collected for the future account backend
/// and is never sent anywhere in v0.1 — the screen says so.
class SignInScreen extends StatefulWidget {
  /// Creates the sign-in screen.
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _continue() {
    final email = _emailController.text.trim();
    if (!email.contains('@') || email.length < 5) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    AppScope.of(context).auth.beginSignIn(email);
    Navigator.of(context).pushNamed(Routes.verify, arguments: email);
  }

  void _social(String provider) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$provider sign-in'),
        content: const Text(
          'Social sign-in arrives with the account backend in phase 2. '
          'In this demo build, sign in with an email code instead — '
          'it works the same way.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Use email instead'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const palette = Palette.v7;
    final body = SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Your backup and your shared links live here',
              style: AppTheme.kicker()),
          const SizedBox(height: 6),
          Text(
            'Sign in',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'you@example.com',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              hintText: 'Your password',
            ),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: palette.danger),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Demo build: the password is not sent anywhere. A 6-digit code verifies the email locally.',
            style: Theme.of(context)
                .textTheme
                .bodySmall!
                .copyWith(color: palette.muted),
          ),
          const SizedBox(height: 20),
          GradientButton(
            label: 'Continue with email',
            expanded: true,
            onPressed: _continue,
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              const Expanded(child: Divider(color: V7Colors.hairline)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('or', style: AppTheme.mono(size: 12)),
              ),
              const Expanded(child: Divider(color: V7Colors.hairline)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _social('Google'),
                  child: const Text('Google'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _social('Apple'),
                  child: const Text('Apple'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(Routes.createAccount),
              child: const Text('No account yet? Create one'),
            ),
          ),
        ],
      ),
    );
    return ResponsiveScaffold(
      title: 'Sign in',
      showNav: false,
      mobile: body,
      wide: body,
    );
  }
}
