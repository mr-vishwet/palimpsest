import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';

/// Sign out (m30 / w30): the local archive stays; delete removes
/// the cloud copy only.
class SignOutScreen extends StatelessWidget {
  /// Creates the sign-out screen.
  const SignOutScreen({super.key});

  void _signOut(BuildContext context, {required bool deleteCloudCopy}) {
    AppScope.of(context).auth.signOut(deleteCloudCopy: deleteCloudCopy);
    Navigator.of(context).pushNamedAndRemoveUntil(
      Routes.home,
      (route) => false,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleteCloudCopy
              ? 'Signed out — cloud copy deleted, local archive kept'
              : 'Signed out — your local archive stays',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const palette = Palette.v7;
    final account = AppScope.of(context).archive.account;
    final body = SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const SizedBox(height: 24),
          const Icon(Icons.logout, size: 48, color: V7Colors.gold),
          const SizedBox(height: 16),
          Text(
            'Sign out?',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            account.email == null
                ? 'You are signed in as a guest — there is nothing to sign out of.'
                : 'Signed in as ${account.email}.',
            style: Theme.of(context)
                .textTheme
                .bodyLarge!
                .copyWith(color: palette.parchment),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: const <Widget>[
                    Icon(Icons.check_circle, color: V7Colors.green, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'The local archive stays — every story, layer and voice note remains on this device.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: const <Widget>[
                    Icon(Icons.cloud_off_outlined,
                        color: V7Colors.amber, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Delete removes the cloud copy only. Sign back in later to restore backup and sync.',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GradientButton(
            label: 'Sign out',
            expanded: true,
            onPressed: account.isSignedIn
                ? () => _signOut(context, deleteCloudCopy: false)
                : null,
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: account.isSignedIn
                ? () => _signOut(context, deleteCloudCopy: true)
                : null,
            child: const Text('Sign out and delete cloud copy'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    return ResponsiveScaffold(
      title: 'Sign out',
      showNav: false,
      mobile: body,
      wide: body,
    );
  }
}
