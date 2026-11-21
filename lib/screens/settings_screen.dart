import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/format.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';

/// Settings (m17 / w17): full quality, on-device grouping, local
/// transcription, no streaks. Plus the demo-library disclosure and
/// the account row.
class SettingsScreen extends StatelessWidget {
  /// Creates the settings screen.
  const SettingsScreen({super.key});

  void _resetDemo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset the demo library?'),
        content: const Text(
          'Your edits, moments and links will be replaced with the fresh seeded demo library. Your account stays signed in.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              AppScope.of(context).archive.resetDemoLibrary();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Demo library restored')),
              );
            },
            child: const Text('Reset'),
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
                    _ToggleRow(
                      title: 'Full quality',
                      subtitle: 'Keep originals at full quality, never recompress on import.',
                      value: settings.fullQuality,
                      onChanged: (v) => archive.updateSettings(
                        settings.copyWith(fullQuality: v),
                      ),
                    ),
                    _ToggleRow(
                      title: 'On-device grouping',
                      subtitle: 'Group faces on this device only — never on a server.',
                      value: settings.onDeviceGrouping,
                      onChanged: (v) => archive.updateSettings(
                        settings.copyWith(onDeviceGrouping: v),
                      ),
                    ),
                    _ToggleRow(
                      title: 'Local transcription',
                      subtitle: 'Transcribe voice notes on-device so they stay searchable.',
                      value: settings.localTranscription,
                      onChanged: (v) => archive.updateSettings(
                        settings.copyWith(localTranscription: v),
                      ),
                    ),
                    _ToggleRow(
                      title: 'Group only while charging',
                      subtitle: 'Face grouping waits for the charger.',
                      value: settings.groupingOnlyWhenCharging,
                      onChanged: (v) => archive.updateSettings(
                        settings.copyWith(groupingOnlyWhenCharging: v),
                      ),
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
                      subtitle: 'Disable sharing, backup and sync; everything stays on-device.',
                      value: settings.offlineMode,
                      onChanged: (v) => archive.updateSettings(
                        settings.copyWith(offlineMode: v),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Storage', style: AppTheme.kicker()),
              const SizedBox(height: 8),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      Format.storage(
                        AppConstants.storageUsedGb,
                        AppConstants.storageTotalGb,
                      ),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: AppConstants.storageUsedGb /
                          AppConstants.storageTotalGb,
                      color: Palette.v7.gold,
                      backgroundColor: Palette.v7.glassStrong,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Thumbnails + index ${AppConstants.thumbnailsAndIndexGb} GB · ${AppConstants.uploadedBytes} uploaded',
                      style: AppTheme.mono(size: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Account', style: AppTheme.kicker()),
              const SizedBox(height: 8),
              GlassCard(
                onTap: () =>
                    Navigator.of(context).pushNamed(Routes.account),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.person_outline, color: Palette.v7.gold),
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
                    const Icon(Icons.chevron_right, color: Palette.v7.muted),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Demo library', style: AppTheme.kicker()),
              const SizedBox(height: 8),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'This v0.1 build ships with a seeded demo library — four stories, the project weekend, five people, four places, nine voice notes. Headline totals (5,012 photos, 143 videos) are the demo archive’s numbers; the browsable subset is the curated seed.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => _resetDemo(context),
                      child: const Text('Reset demo library'),
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
