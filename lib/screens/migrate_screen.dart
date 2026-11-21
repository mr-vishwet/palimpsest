import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/format.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';

/// Migrate (m27 / w27): 4 stories, 5,012 photos, 143 videos, 9 voice
/// notes — 0 left behind. The guest archive is checked item by item,
/// then the first backup begins.
class MigrateScreen extends StatefulWidget {
  /// Creates the migrate screen.
  const MigrateScreen({super.key});

  @override
  State<MigrateScreen> createState() => _MigrateScreenState();
}

class _MigrateScreenState extends State<MigrateScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppScope.of(context).auth.beginMigration();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.of(context).auth;
    final archive = AppScope.of(context).archive;
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        final progress = auth.migrationProgress;
        final done = !auth.migrationRunning && progress >= 1;
        final account = archive.account;

        final checks = <({String label, double at})>[
          (label: '4 stories', at: 0.2),
          (label: '5,012 photos', at: 0.45),
          (label: '143 videos', at: 0.65),
          (label: '9 voice notes', at: 0.85),
        ];

        final body = SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('0 left behind', style: AppTheme.kicker()),
              const SizedBox(height: 6),
              Text(
                'Moving your archive in',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Every item is checked as it moves into your account. Nothing is left behind — and the local copy stays put.',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge!
                    .copyWith(color: Palette.v7.parchment),
              ),
              const SizedBox(height: 20),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Checking the archive', style: AppTheme.kicker()),
                    const SizedBox(height: 8),
                    for (final check in checks)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              progress >= check.at
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              size: 18,
                              color: progress >= check.at
                                  ? Palette.v7.green
                                  : Palette.v7.muted,
                            ),
                            const SizedBox(width: 10),
                            Text(check.label),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      color: Palette.v7.gold,
                      backgroundColor: Palette.v7.glassStrong,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(progress * 100).round()}% · ${done ? 'complete' : 'checking…'}',
                      style: AppTheme.mono(size: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('First backup', style: AppTheme.kicker()),
                    const SizedBox(height: 8),
                    Text(
                      done
                          ? '${account.backupUploadedGb.toStringAsFixed(1)} of ${account.backupTotalGb.toStringAsFixed(1)} GB backed up (${(account.backupProgress * 100).round()}%)'
                          : 'Starts when the check finishes — ${Format.storage(AppConstants.storageUsedGb, AppConstants.storageTotalGb)} to back up.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: done ? account.backupProgress : 0,
                      color: Palette.v7.green,
                      backgroundColor: Palette.v7.glassStrong,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Encrypted with your key — the backup is your copy.',
                      style: AppTheme.mono(size: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              GradientButton(
                label: done ? 'Done — open your account' : 'Migrating…',
                expanded: true,
                onPressed: done
                    ? () => Navigator.of(context).pushNamedAndRemoveUntil(
                          Routes.account,
                          (route) => false,
                        )
                    : null,
              ),
            ],
          ),
        );
        return ResponsiveScaffold(
          title: 'Migrate',
          showNav: false,
          mobile: body,
          wide: body,
        );
      },
    );
  }
}
