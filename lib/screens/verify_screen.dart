import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';

/// Verify (m25 / w25): a 6-digit code, then the archive is checked
/// item by item. In v0.1 any 6-digit code verifies locally — the demo
/// code from the spec is 428195.
class VerifyScreen extends StatefulWidget {
  /// Creates the verify screen.
  const VerifyScreen({required this.email, super.key});

  /// The email being verified.
  final String email;

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  late final TextEditingController _codeController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _verify() {
    final auth = AppScope.of(context).auth;
    if (auth.verifyCode(_codeController.text)) {
      if (auth.pendingIsNewAccount || !auth.migrated) {
        Navigator.of(context).pushNamed(Routes.migrate);
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil(
          Routes.account,
          (route) => false,
        );
      }
    } else {
      setState(() => _error = 'That code does not work — 6 digits, please.');
    }
  }

  @override
  Widget build(BuildContext context) {
    const palette = Palette.v7;
    final body = SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('A 6-digit code, then the check', style: AppTheme.kicker()),
          const SizedBox(height: 6),
          Text(
            'Verify',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'We sent a code to ${widget.email}. It works for ${AppConstants.verifyCodeValidityMinutes} minutes.',
            style: Theme.of(context)
                .textTheme
                .bodyLarge!
                .copyWith(color: palette.parchment),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            textAlign: TextAlign.center,
            style: AppTheme.mono(size: 28, color: palette.ink),
            decoration: const InputDecoration(
              hintText: '––––––',
              counterText: '',
            ),
            onSubmitted: (_) => _verify(),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: palette.danger)),
          ],
          const SizedBox(height: 8),
          Text(
            'Demo build: any 6-digit code verifies — try ${AppConstants.demoVerifyCode}.',
            style: Theme.of(context)
                .textTheme
                .bodySmall!
                .copyWith(color: palette.muted),
          ),
          const SizedBox(height: 20),
          GradientButton(
            label: 'Verify',
            expanded: true,
            onPressed: _verify,
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'New code sent — demo build, any 6-digit code works',
                    ),
                  ),
                );
              },
              child: const Text('Resend code'),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'After the code, the archive is checked item by item — 4 stories, 5,012 photos, 143 videos, 9 voice notes — and nothing is left behind.',
            style: Theme.of(context)
                .textTheme
                .bodySmall!
                .copyWith(color: palette.muted),
          ),
        ],
      ),
    );
    return ResponsiveScaffold(
      title: 'Verify',
      showNav: false,
      mobile: body,
      wide: body,
    );
  }
}
