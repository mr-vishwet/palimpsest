import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/format.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';

/// Offline (m15 / w15): the whole archive works with no connection;
/// backup is optional. Offline is a state, not a failure.
class OfflineScreen extends StatelessWidget {
  /// Creates the offline screen.
  const OfflineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final archive = AppScope.of(context).archive;
    return ListenableBuilder(
      listenable: archive,
      builder: (context, _) {
        final settings = archive.settings;
        final account = archive.account;
        final used = AppConstants.storageUsedGb;
        final total = AppConstants.storageTotalGb;

        final body = SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('A state, not a failure', style: AppTheme.kicker()),
              const SizedBox(height: 6),
              Text(
                'Offline',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'The whole archive works with no connection. Search, stories, timelines, edits — all on-device. Backup and sync are yours to switch on.',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge!
                    .copyWith(color: Palette.v7.parchment),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          'Work offline',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Switch(
                          value: settings.offlineMode,
                          onChanged: (value) => archive.updateSettings(
                            settings.copyWith(offlineMode: value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      settings.offlineMode
                          ? 'Offline mode is on: sharing, backup and sync are disabled until you switch it off.'
                          : 'Turn on to disable sharing, backup and sync and keep everything on this device.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall!
                          .copyWith(color: Palette.v7.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('On this device', style: AppTheme.kicker()),
              const SizedBox(height: 8),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _StatusRow(
                      icon: Icons.search,
                      label: 'Search index',
                      value: 'Ready · ${Format.count(AppConstants.totalPhotos)} photos indexed',
                      ok: true,
                    ),
                    const SizedBox(height: 12),
                    _StatusRow(
                      icon: Icons.storage_outlined,
                      label: 'Storage',
                      value: Format.storage(used, total),
                      ok: true,
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: used / total,
                      color: Palette.v7.gold,
                      backgroundColor: Palette.v7.glassStrong,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Thumbnails + index ${AppConstants.thumbnailsAndIndexGb} GB',
                      style: AppTheme.mono(size: 11),
                    ),
                    const SizedBox(height: 12),
                    _StatusRow(
                      icon: Icons.cloud_upload_outlined,
                      label: 'Backup',
                      value: account.isSignedIn && account.backupEnabled
                          ? 'On · ${account.backupUploadedGb.toStringAsFixed(1)} of ${account.backupTotalGb.toStringAsFixed(1)} GB'
                          : 'Off until you sign in',
                      ok: account.isSignedIn && account.backupEnabled,
                    ),
                    const SizedBox(height: 12),
                    _StatusRow(
                      icon: Icons.sync_outlined,
                      label: 'Sync',
                      value: account.isSignedIn && account.syncEnabled
                          ? 'On · ${account.devices} devices'
                          : 'Off until you sign in',
                      ok: account.isSignedIn && account.syncEnabled,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (!account.isSignedIn)
                GradientButton(
                  label: 'Sign in to switch backup on',
                  expanded: true,
                  onPressed: () =>
                      Navigator.of(context).pushNamed(Routes.signIn),
                )
              else
                OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(Routes.account),
                  child: const Text('Manage backup & sync'),
                ),
            ],
          ),
        );
        return ResponsiveScaffold(
          title: 'Offline',
          tabIndex: 0,
          mobile: body,
          wide: body,
        );
      },
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.ok,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 20, color: Palette.v7.gold),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label, style: Theme.of(context).textTheme.titleSmall),
              Text(value, style: AppTheme.mono(size: 11)),
            ],
          ),
        ),
        Icon(
          ok ? Icons.check_circle : Icons.circle_outlined,
          size: 18,
          color: ok ? Palette.v7.green : Palette.v7.muted,
        ),
      ],
    );
  }
}
