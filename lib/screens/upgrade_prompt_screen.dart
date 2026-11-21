import 'package:material_ui/material_ui.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';

/// Upgrade prompt (m26 / w26): share this story? The link has to
/// live somewhere. Shown when a guest tries to share.
class UpgradePromptScreen extends StatelessWidget {
  /// Creates the upgrade prompt screen.
  const UpgradePromptScreen({this.storyId, super.key});

  /// The story the share was requested from, if any.
  final String? storyId;

  @override
  Widget build(BuildContext context) {
    const palette = Palette.v7;
    final archive = AppScope.of(context).archive;
    final story = storyId == null ? null : archive.storyById(storyId!);
    final body = SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const SizedBox(height: 32),
          const Icon(Icons.link_outlined, size: 56, color: V7Colors.gold),
          const SizedBox(height: 20),
          Text(
            'Share this story?',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            story == null
                ? 'The link has to live somewhere — and that somewhere is your account.'
                : 'To share “${story.title}”, the link has to live somewhere — and that somewhere is your account.',
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
                Text(
                  'An account also unlocks',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const _Row(
                  icon: Icons.cloud_upload_outlined,
                  text: 'Encrypted cloud backup — your key, your copy',
                ),
                const SizedBox(height: 6),
                const _Row(
                  icon: Icons.sync_outlined,
                  text: 'Sync across your devices',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GradientButton(
            label: 'Create an account',
            expanded: true,
            onPressed: () =>
                Navigator.of(context).pushNamed(Routes.createAccount),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () =>
                Navigator.of(context).pushNamed(Routes.signIn),
            child: const Text('Sign in'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Stay a guest'),
          ),
        ],
      ),
    );
    return ResponsiveScaffold(
      title: 'Share',
      showNav: false,
      mobile: body,
      wide: body,
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.text});

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
