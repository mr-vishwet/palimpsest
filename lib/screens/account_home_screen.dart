import 'package:material_ui/material_ui.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';

/// Account home (m28 / w28): what the account is, honestly — in
/// this build an account unlocks nothing yet; backup, sync and
/// sharing arrive with the account backend. Guests see that plainly
/// instead of a promise.
class AccountHomeScreen extends StatelessWidget {
  /// Creates the account home screen.
  const AccountHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final archive = AppScope.of(context).archive;
    final auth = AppScope.of(context).auth;
    return ListenableBuilder(
      listenable: archive,
      builder: (context, _) {
        final account = archive.account;
        final links = archive.shareLinks;

        final body = SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Account', style: AppTheme.kicker()),
              const SizedBox(height: 6),
              Text(
                account.isSignedIn
                    ? (account.email ?? 'Account')
                    : 'Guest mode',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              if (!account.isSignedIn) ...<Widget>[
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'The whole archive works as a guest.',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'An account doesn’t unlock anything yet — share links, encrypted cloud backup and sync arrive with the account backend. Everything works as a guest.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      GradientButton(
                        label: 'Create an account',
                        expanded: true,
                        onPressed: () => Navigator.of(context)
                            .pushNamed(Routes.createAccount),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: () =>
                              Navigator.of(context).pushNamed(Routes.signIn),
                          child: const Text('Sign in'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  onTap: () =>
                      Navigator.of(context).pushNamed(Routes.guestMode),
                  child: const Row(
                    children: <Widget>[
                      Icon(Icons.info_outline, color: V7Colors.gold),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text('What works as a guest?'),
                      ),
                      Icon(Icons.chevron_right, color: V7Colors.muted),
                    ],
                  ),
                ),
              ] else ...<Widget>[
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _AccountRow(
                        icon: Icons.cloud_upload_outlined,
                        title: 'Backup',
                        subtitle: account.backupEnabled
                            ? 'On · nothing uploaded yet — no backup server in this build'
                            : 'Off',
                        trailing: Switch(
                          value: account.backupEnabled,
                          onChanged: auth.setBackup,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _AccountRow(
                        icon: Icons.sync_outlined,
                        title: 'Sync',
                        subtitle: account.syncEnabled
                            ? 'On · this device only — no sync server in this build'
                            : 'Off',
                        trailing: Switch(
                          value: account.syncEnabled,
                          onChanged: auth.setSync,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Backup and sync are recorded locally in this build — there is no server yet, so nothing is uploaded or synced.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .copyWith(color: Palette.v7.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Shared links · ${links.length}',
                  style: AppTheme.kicker(),
                ),
                const SizedBox(height: 8),
                if (links.isEmpty)
                  const Text(
                    'No shared links yet — links are recorded on this device only, and there is no server yet, so a link can’t be opened by anyone else.',
                    style: TextStyle(color: V7Colors.muted),
                  )
                else
                  for (final link in links)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        child: Row(
                          children: <Widget>[
                            const Icon(
                              Icons.link_outlined,
                              color: V7Colors.gold,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    archive.storyById(link.storyId)?.title ??
                                        'Story',
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                  Text(
                                    link.isExpired
                                        ? 'Expired'
                                        : 'Expires in ${link.daysLeft} days',
                                    style: AppTheme.mono(size: 11),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => archive.revokeShareLink(link.id),
                              child: const Text('Revoke'),
                            ),
                          ],
                        ),
                      ),
                    ),
                if (links.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Links are recorded on this device only — there is no server yet, so nobody can open one.',
                      style: TextStyle(color: V7Colors.muted),
                    ),
                  ),
                const SizedBox(height: 16),
                GlassCard(
                  onTap: () =>
                      Navigator.of(context).pushNamed(Routes.connected),
                  child: const Row(
                    children: <Widget>[
                      Icon(Icons.link_outlined, color: V7Colors.gold),
                      SizedBox(width: 12),
                      Expanded(child: Text('Connected accounts')),
                      Icon(Icons.chevron_right, color: V7Colors.muted),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                GlassCard(
                  onTap: () => Navigator.of(context).pushNamed(Routes.signOut),
                  child: const Row(
                    children: <Widget>[
                      Icon(Icons.logout, color: V7Colors.danger),
                      SizedBox(width: 12),
                      Expanded(child: Text('Sign out')),
                      Icon(Icons.chevron_right, color: V7Colors.muted),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              GlassCard(
                onTap: () => Navigator.of(context).pushNamed(Routes.settings),
                child: const Row(
                  children: <Widget>[
                    Icon(Icons.settings_outlined, color: V7Colors.gold),
                    SizedBox(width: 12),
                    Expanded(child: Text('Settings')),
                    Icon(Icons.chevron_right, color: V7Colors.muted),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              GlassCard(
                onTap: () => Navigator.of(context).pushNamed(Routes.offline),
                child: const Row(
                  children: <Widget>[
                    Icon(Icons.wifi_off_outlined, color: V7Colors.gold),
                    SizedBox(width: 12),
                    Expanded(child: Text('Offline & storage')),
                    Icon(Icons.chevron_right, color: V7Colors.muted),
                  ],
                ),
              ),
            ],
          ),
        );
        return ResponsiveScaffold(
          title: 'Account',
          tabIndex: 4,
          mobile: body,
          wide: body,
        );
      },
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, color: Palette.v7.gold),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              Text(subtitle, style: AppTheme.mono(size: 11)),
            ],
          ),
        ),
        trailing,
      ],
    );
  }
}
