import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../core/format.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';

/// Share story (m16 / w16): a view-only link, downloads off —
/// sharing needs an account. Guests are routed to the upgrade
/// prompt instead of reaching this screen. There is no server yet,
/// so links are recorded on this device only and nobody can open
/// one — the screen says so plainly.
class ShareScreen extends StatefulWidget {
  /// Creates the share screen.
  const ShareScreen({required this.storyId, super.key});

  /// The story to share.
  final String storyId;

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  bool _downloadsAllowed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Route guard: sharing needs an account.
      if (!AppScope.of(context).auth.isSignedIn) {
        Navigator.of(context).pushReplacementNamed(
          Routes.upgrade,
          arguments: widget.storyId,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final archive = AppScope.of(context).archive;
    return ListenableBuilder(
      listenable: archive,
      builder: (context, _) {
        final story = archive.storyById(widget.storyId);
        if (story == null) {
          return const ResponsiveScaffold(
            title: 'Share',
            tabIndex: 0,
            mobile: EmptyState(
              icon: Icons.share_outlined,
              title: 'Story not found',
              body: 'This story is no longer in the archive.',
            ),
            wide: EmptyState(
              icon: Icons.share_outlined,
              title: 'Story not found',
              body: 'This story is no longer in the archive.',
            ),
          );
        }
        if (!archive.account.isSignedIn) {
          // Guard redirect is in flight; show nothing yet.
          return const ResponsiveScaffold(
            title: 'Share',
            tabIndex: 0,
            mobile: SizedBox.shrink(),
            wide: SizedBox.shrink(),
          );
        }
        final links = archive.shareLinks
            .where((link) => link.storyId == story.id)
            .toList(growable: false);

        final body = SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('A view-only link', style: AppTheme.kicker()),
              const SizedBox(height: 6),
              Text(
                'Share ${story.title}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Links are recorded on this device only — there is no server yet, so nobody can open a link you create. Sharing that works arrives with the account backend.',
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
                    Text(
                      'New link',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        const Expanded(
                          child: Text('Allow downloads'),
                        ),
                        Switch(
                          value: _downloadsAllowed,
                          onChanged: (value) =>
                              setState(() => _downloadsAllowed = value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _downloadsAllowed
                          ? 'When sharing works, recipients will be able to download the story’s media.'
                          : 'When sharing works, recipients will be able to view only — nothing downloads.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall!
                          .copyWith(color: Palette.v7.muted),
                    ),
                    const SizedBox(height: 12),
                    GradientButton(
                      label: 'Create link',
                      expanded: true,
                      onPressed: archive.settings.offlineMode
                          ? null
                          : () {
                              final link = archive.createShareLink(
                                story.id,
                                downloadsAllowed: _downloadsAllowed,
                              );
                              if (link == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Sharing is unavailable right now',
                                    ),
                                  ),
                                );
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Link created'),
                                ),
                              );
                            },
                    ),
                    if (archive.settings.offlineMode)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Offline mode is on — sharing is disabled.',
                          style: AppTheme.mono(
                            size: 11,
                            color: Palette.v7.amber,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Links for this story', style: AppTheme.kicker()),
              const SizedBox(height: 8),
              if (links.isEmpty)
                const Text(
                  'No links yet. Create one above — it will be recorded on this device only, and won’t open for anyone until the sharing backend exists.',
                  style: TextStyle(color: V7Colors.muted),
                )
              else
                for (final link in links)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SelectableText(
                            link.url,
                            style: AppTheme.mono(
                              size: 12,
                              color: Palette.v7.parchment,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Local-only — not shareable yet',
                            style: AppTheme.mono(
                              size: 11,
                              color: Palette.v7.amber,
                              weight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            link.isExpired
                                ? 'Expired'
                                : 'Expires in ${link.daysLeft} days · '
                                    'Downloads ${link.downloadsAllowed ? 'on' : 'off'} · '
                                    '${Format.count(link.viewCount)} views',
                            style: AppTheme.mono(size: 11),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: <Widget>[
                              TextButton.icon(
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: link.url),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Link copied'),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.copy, size: 16),
                                label: const Text('Copy'),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  archive.revokeShareLink(link.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Link revoked'),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.link_off, size: 16),
                                label: const Text('Revoke'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Palette.v7.danger,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        );
        return ResponsiveScaffold(
          title: 'Share',
          tabIndex: 0,
          mobile: body,
          wide: body,
        );
      },
    );
  }
}
