import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';

/// Guest mode (m22 / w22): what works as a guest, and the three
/// things that need an account.
class GuestModeScreen extends StatelessWidget {
  /// Creates the guest-mode screen.
  const GuestModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const palette = Palette.v7;
    final works = <String>[
      'Import and index the whole library',
      'Ask questions — the archive answers on-device',
      'Stories, chapters, timelines, people, places',
      'Edit captions, tags and covers — layers included',
      'Voice notes, transcripts and search',
      'Export deterministic manifests',
    ];
    final needsAccount = <({String title, String body})>[
      (
        title: 'Share links',
        body: 'A link has to live somewhere — the account hosts it.',
      ),
      (
        title: 'Encrypted cloud backup',
        body: 'Your key, your copy — the archive survives the phone.',
      ),
      (
        title: 'Sync',
        body: 'The same archive on every device you own.',
      ),
    ];

    final body = SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Guest-first', style: AppTheme.kicker()),
          const SizedBox(height: 6),
          Text(
            'Guest mode',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'The archive on this device is fully yours as a guest. Three things need an account — everything else just works.',
            style: Theme.of(context)
                .textTheme
                .bodyLarge!
                .copyWith(color: palette.parchment),
          ),
          const SizedBox(height: 20),
          Text('Works as a guest', style: AppTheme.kicker()),
          const SizedBox(height: 8),
          GlassCard(
            child: Column(
              children: <Widget>[
                for (final item in works)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.check_circle,
                          size: 18,
                          color: V7Colors.green,
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(item)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Needs an account', style: AppTheme.kicker()),
          const SizedBox(height: 8),
          for (final need in needsAccount)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.lock_outline, color: V7Colors.gold),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            need.title,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            need.body,
                            style: AppTheme.mono(size: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          GradientButton(
            label: 'Create an account',
            expanded: true,
            onPressed: () =>
                Navigator.of(context).pushNamed(Routes.createAccount),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(Routes.signIn),
              child: const Text('I already have an account'),
            ),
          ),
        ],
      ),
    );
    return ResponsiveScaffold(
      title: 'Guest mode',
      showNav: false,
      mobile: body,
      wide: body,
    );
  }
}
