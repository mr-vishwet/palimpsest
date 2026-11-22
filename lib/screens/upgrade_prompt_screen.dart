import 'package:material_ui/material_ui.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';

/// Upgrade prompt (m26 / w26): share this story? Links need a
/// server to live on, and there is not one yet — so the screen says
/// sharing arrives with the account backend instead of promising an
/// account unlocks it today. Shown when a guest tries to share.
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
            'Sharing isn’t ready yet',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            story == null
                ? 'A share link has to live on a server — and there isn’t one yet. An account doesn’t unlock sharing in this build; everything else works as a guest.'
                : 'To share “${story.title}”, the link has to live on a server — and there isn’t one yet. An account doesn’t unlock sharing in this build; everything else works as a guest.',
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
                  'When the account backend arrives',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const _Row(
                  icon: Icons.link_outlined,
                  text: 'Share links that open anywhere',
                ),
                const SizedBox(height: 6),
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
            label: 'Stay a guest',
            expanded: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () =>
                Navigator.of(context).pushNamed(Routes.createAccount),
            child: const Text('Create an account anyway'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pushNamed(Routes.signIn),
            child: const Text('Sign in'),
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
