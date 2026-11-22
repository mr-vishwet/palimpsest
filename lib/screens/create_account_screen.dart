import 'package:material_ui/material_ui.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';

/// Create account (m24 / w24): one account for backup, sync, and
/// shared links — once the backend exists. Verified with a 6-digit
/// code, then the guest archive is counted in. In this build the
/// account is recorded locally and unlocks nothing yet.
class CreateAccountScreen extends StatefulWidget {
  /// Creates the create-account screen.
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _create() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (!email.contains('@') || email.length < 5) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    if (password.length < 8) {
      setState(() => _error = 'Passwords need at least 8 characters.');
      return;
    }
    if (password != _confirmController.text) {
      setState(() => _error = 'The passwords do not match.');
      return;
    }
    AppScope.of(context).auth.beginSignIn(email, isNewAccount: true);
    Navigator.of(context).pushNamed(Routes.verify, arguments: email);
  }

  @override
  Widget build(BuildContext context) {
    const palette = Palette.v7;
    final body = SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
              'One account for backup, sync, and shared links — when the backend exists',
              style: AppTheme.kicker()),
          const SizedBox(height: 6),
          Text(
            'Create account',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          const GlassCard(
            child: Column(
              children: <Widget>[
                _BenefitRow(
                  icon: Icons.link_outlined,
                  text: 'Share links that live somewhere',
                ),
                SizedBox(height: 8),
                _BenefitRow(
                  icon: Icons.cloud_upload_outlined,
                  text: 'Encrypted cloud backup — your key, your copy',
                ),
                SizedBox(height: 8),
                _BenefitRow(
                  icon: Icons.sync_outlined,
                  text: 'Sync across your devices',
                ),
              ],
            ),
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
              hintText: 'At least 8 characters',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirm password',
            ),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: palette.danger)),
          ],
          const SizedBox(height: 8),
          Text(
            'Demo build: the account is recorded locally and the password is not sent anywhere. The code step verifies the email on-device — and an account doesn’t unlock anything yet.',
            style: Theme.of(context)
                .textTheme
                .bodySmall!
                .copyWith(color: palette.muted),
          ),
          const SizedBox(height: 20),
          GradientButton(
            label: 'Create account',
            expanded: true,
            onPressed: _create,
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pushNamed(Routes.signIn),
              child: const Text('Already have an account? Sign in'),
            ),
          ),
        ],
      ),
    );
    return ResponsiveScaffold(
      title: 'Create account',
      showNav: false,
      mobile: body,
      wide: body,
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: Palette.v7.gold),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    );
  }
}
