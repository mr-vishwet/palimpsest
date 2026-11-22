import 'package:material_ui/material_ui.dart';

import '../core/format.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';

/// Migrate (m27 / w27): the guest archive is counted item by item
/// as the account is recorded locally. Nothing moves anywhere and
/// nothing is uploaded — there is no server yet, and the local copy
/// stays the only copy.
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
        final photos = ArchiveCounts.photos(archive.items);
        final videos = ArchiveCounts.videos(archive.items);

        final checks = <({String label, double at})>[
          (label: '${archive.stories.length} stories', at: 0.2),
          (label: '${Format.count(photos)} photos', at: 0.45),
          (label: '$videos videos', at: 0.65),
          (label: '${archive.voiceNotes.length} voice notes', at: 0.85),
        ];

        final body = SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Nothing leaves this device', style: AppTheme.kicker()),
              const SizedBox(height: 6),
              Text(
                'Welcome to your account',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Your archive is counted item by item as the account is recorded — locally, on this device. Nothing is uploaded, and the local copy stays the only copy.',
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
                    Text('Counting the archive', style: AppTheme.kicker()),
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
                      '${(progress * 100).round()}% · ${done ? 'complete' : 'counting…'}',
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
                          ? 'Nothing uploaded — there is no backup server in this build. Encrypted cloud backup arrives with the account backend; until then, your archive lives only on this device.'
                          : 'Backup arrives with the account backend — nothing will be uploaded in this build.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '0 bytes uploaded · local-first, always',
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
