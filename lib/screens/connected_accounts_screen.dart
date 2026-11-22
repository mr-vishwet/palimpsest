import 'package:material_ui/material_ui.dart';

import '../core/theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';

/// Connected accounts (m29 / w29): connections pull media in, never
/// push the archive out.
class ConnectedAccountsScreen extends StatelessWidget {
  /// Creates the connected-accounts screen.
  const ConnectedAccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final archive = AppScope.of(context).archive;
    final auth = AppScope.of(context).auth;
    return ListenableBuilder(
      listenable: archive,
      builder: (context, _) {
        final connected = archive.account.connectedSources;
        const sources = <({String name, String hint, IconData icon})>[
          (
            name: 'Photos',
            hint: 'Your device photo library',
            icon: Icons.photo_library_outlined,
          ),
          (
            name: 'Google Photos',
            hint: 'Import from your Google library',
            icon: Icons.cloud_outlined,
          ),
          (
            name: 'iCloud Photos',
            hint: 'Import from your iCloud library',
            icon: Icons.cloud_outlined,
          ),
        ];

        final body = SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Pull in, never push out', style: AppTheme.kicker()),
              const SizedBox(height: 6),
              Text(
                'Connected accounts',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Connections pull media into the archive. They never push the archive out — nothing you curate here leaves the device through a connection.',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge!
                    .copyWith(color: Palette.v7.parchment),
              ),
              const SizedBox(height: 16),
              for (final source in sources)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    child: Row(
                      children: <Widget>[
                        Icon(source.icon, color: Palette.v7.gold),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                source.name,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(source.hint, style: AppTheme.mono(size: 11)),
                            ],
                          ),
                        ),
                        if (connected.contains(source.name))
                          OutlinedButton(
                            onPressed: () {
                              auth.disconnectSource(source.name);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${source.name} disconnected',
                                  ),
                                ),
                              );
                            },
                            child: const Text('Disconnect'),
                          )
                        else
                          FilledButton(
                            onPressed: () {
                              auth.connectSource(source.name);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${source.name} recorded locally — real connection arrives with the account backend',
                                  ),
                                ),
                              );
                            },
                            child: const Text('Connect'),
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Demo build: connections are recorded locally. Real OAuth and import arrive with the account backend in phase 2.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall!
                    .copyWith(color: Palette.v7.muted),
              ),
            ],
          ),
        );
        return ResponsiveScaffold(
          title: 'Connected accounts',
          tabIndex: 4,
          mobile: body,
          wide: body,
        );
      },
    );
  }
}
