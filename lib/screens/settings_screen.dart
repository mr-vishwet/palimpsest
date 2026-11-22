import 'package:material_ui/material_ui.dart';

import '../core/format.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';

/// Settings (m17 / w17): the two switches that do something
/// (resurface, offline) plus honest notes about the rules that are
/// fixed in this build — imports keep full quality, and face grouping
/// and transcription arrive with the mobile app. No switch claims an
/// effect it does not have. Plus the demo-media card and the account
/// row.
class SettingsScreen extends StatelessWidget {
  /// Creates the settings screen.
  const SettingsScreen({super.key});

  Future<void> _loadDemo(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final archive = AppScope.of(context).archive;
    final result = await archive.loadDemoMedia();
    final message = result.failures.isEmpty
        ? (result.loaded == 0
            ? 'Demo media is already loaded'
            : 'Loaded ${result.loaded} demo files')
        : 'Loaded ${result.loaded} demo files · '
            '${result.failures.length} couldn’t be read';
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  void _clearDemo(BuildContext context) {
    final archive = AppScope.of(context).archive;
    final count = archive.demoItemCount;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear demo data?'),
        content: Text(
          'The $count demo photos and videos will be removed, along with '
          'any demo stories and voice notes. Your own photos, stories '
          'and voice notes stay.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final removed = archive.clearDemoData();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Cleared $removed demo items')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final archive = AppScope.of(context).archive;
    return ListenableBuilder(
      listenable: archive,
      builder: (context, _) {
        final settings = archive.settings;
        final account = archive.account;

        final body = SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Archive rules', style: AppTheme.kicker()),
              const SizedBox(height: 6),
              Text(
                'Settings',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: <Widget>[
                    const _InfoRow(
                      title: 'Full quality',
                      subtitle:
                          'Imports keep originals at full quality — nothing is recompressed. There is no quality setting to switch; this is how imports work.',
                    ),
                    const _InfoRow(
                      title: 'On-device grouping',
                      subtitle:
                          'Face grouping arrives with the mobile app and will run on-device only, while charging — never on a server.',
                    ),
                    const _InfoRow(
                      title: 'Local transcription',
                      subtitle:
                          'Voice-note transcription arrives with the mobile app and will run on-device, so notes stay searchable without uploading.',
                    ),
                    _ToggleRow(
                      title: 'Resurface moments',
                      subtitle: 'Show “this week in past years” on Home.',
                      value: settings.resurfaceEnabled,
                      onChanged: (v) => archive.updateSettings(
                        settings.copyWith(resurfaceEnabled: v),
                      ),
                    ),
                    _ToggleRow(
                      title: 'Offline mode',
                      subtitle:
                          'Disable sharing, backup and sync; everything stays on-device.',
                      value: settings.offlineMode,
                      onChanged: (v) => archive.updateSettings(
                        settings.copyWith(offlineMode: v),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Your archive', style: AppTheme.kicker()),
              const SizedBox(height: 8),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${Format.count(ArchiveCounts.photos(archive.items))} photos · '
                      '${ArchiveCounts.videos(archive.items)} videos · '
                      '${archive.voiceNotes.length} voice notes · '
                      '${archive.stories.length} stories',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${Format.count(archive.items.length)} items on this device · 0 uploaded',
                      style: AppTheme.mono(size: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Account', style: AppTheme.kicker()),
              const SizedBox(height: 8),
              GlassCard(
                onTap: () => Navigator.of(context).pushNamed(Routes.account),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.person_outline, color: V7Colors.gold),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            account.isSignedIn
                                ? account.email ?? 'Account'
                                : 'Guest mode',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            account.isSignedIn
                                ? 'Backup ${account.backupEnabled ? 'on' : 'off'} · Sync ${account.syncEnabled ? 'on' : 'off'}'
                                : 'The whole archive works without an account',
                            style: AppTheme.mono(size: 11),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: V7Colors.muted),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Demo media', style: AppTheme.kicker()),
              const SizedBox(height: 8),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'A set of real photos and videos ships with the app so you can '
                      'see the archive working. They load through the same import '
                      'pipeline as your own files and are marked as demo.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    if (archive.hasDemoData)
                      Text(
                        '${archive.demoItemCount} demo items loaded.',
                        style: AppTheme.mono(size: 11),
                      ),
                    if (archive.hasDemoData) const SizedBox(height: 12),
                    if (archive.hasDemoData)
                      OutlinedButton(
                        onPressed: () => _clearDemo(context),
                        child: const Text('Clear demo data'),
                      )
                    else
                      OutlinedButton(
                        onPressed: () => _loadDemo(context),
                        child: const Text('Load demo media'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Palimpsest v0.1 · Build Specification',
                  style: AppTheme.mono(size: 11),
                ),
              ),
            ],
          ),
        );
        return ResponsiveScaffold(
          title: 'Settings',
          tabIndex: 0,
          mobile: body,
          wide: body,
        );
      },
    );
  }
}

/// An informational row for a rule that is fixed in this build: no
/// switch, because there is nothing to switch — the row says what
/// happens today instead of pretending a toggle controls it.
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(color: Palette.v7.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final void Function(bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(color: Palette.v7.muted),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
