import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../engine/exporter.dart';
import '../models/memory_item.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';
import '../widgets/frame_tile.dart';

/// Reconstructed moment (m05 / w05): the collection, in order, with
/// its reasons — and the items that look wrong, which the user can
/// remove to teach the archive.
class MomentScreen extends StatelessWidget {
  /// Creates the moment screen.
  const MomentScreen({required this.momentId, super.key});

  /// The reconstructed moment to show.
  final String momentId;

  void _export(BuildContext context) {
    final archive = AppScope.of(context).archive;
    final moment = archive.momentById(momentId);
    if (moment == null) {
      return;
    }
    final manifest = Exporter.manifestForMoment(moment, archive.items);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export manifest'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(manifest, style: AppTheme.mono(size: 11)),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: manifest));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Manifest copied')),
              );
            },
            child: const Text('Copy'),
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
        final moment = archive.momentById(momentId);
        if (moment == null) {
          return ResponsiveScaffold(
            title: 'Moment',
            tabIndex: 1,
            mobile: const EmptyState(
              icon: Icons.search_off_outlined,
              title: 'Moment not found',
              body: 'Ask a question and the archive will rebuild it.',
              actionLabel: 'Ask the archive',
              onAction: null,
            ),
            wide: const EmptyState(
              icon: Icons.search_off_outlined,
              title: 'Moment not found',
              body: 'Ask a question and the archive will rebuild it.',
            ),
          );
        }
        final items = moment.visibleItemIds
            .map(archive.itemById)
            .whereType<MemoryItem>()
            .toList(growable: false);
        final photos =
            items.where((i) => i.kind == MediaKind.photo).length;
        final videos =
            items.where((i) => i.kind == MediaKind.video).length;
        final voice =
            items.where((i) => i.kind == MediaKind.voiceNote).length;
        final notes = items.where((i) => i.kind == MediaKind.note).length;
        final flagged = moment.flaggedIds
            .where((id) => moment.visibleItemIds.contains(id))
            .toList(growable: false);

        final body = SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('The question, answered', style: AppTheme.kicker()),
              const SizedBox(height: 6),
              Text(
                moment.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                '“${moment.query}”',
                style: AppTheme.mono(size: 12, color: Palette.v7.parchment),
              ),
              const SizedBox(height: 4),
              Text(
                'Rebuilt on-device in ${moment.rebuildMs} ms',
                style: AppTheme.mono(size: 11),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(child: StatTile(value: '$photos', label: 'photos')),
                  const SizedBox(width: 8),
                  Expanded(child: StatTile(value: '$videos', label: 'videos')),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StatTile(value: '$voice', label: 'voice notes'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: StatTile(value: '$notes', label: 'notes')),
                ],
              ),
              if (flagged.isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                GlassCard(
                  borderColor: Palette.v7.amber.withValues(alpha: 0.6),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.flag_outlined, color: Palette.v7.amber),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${flagged.length} ${flagged.length == 1 ? 'item looks' : 'items look'} wrong. Removing ${flagged.length == 1 ? 'it' : 'them'} teaches the archive what you meant.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'The collection, in order',
                style: AppTheme.kicker(),
              ),
              const SizedBox(height: 8),
              if (items.isEmpty)
                const EmptyState(
                  icon: Icons.search_off_outlined,
                  title: 'Nothing matched',
                  body:
                      'No items in the library matched that question. Try different words, or a person, place or tag.',
                )
              else
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      padding: const EdgeInsets.all(12),
                      borderColor: flagged.contains(item.id)
                          ? Palette.v7.amber.withValues(alpha: 0.5)
                          : null,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(
                            width: 64,
                            height: 64,
                            child: FrameTile(
                              item: item,
                              onTap: () => Navigator.of(context).pushNamed(
                                Routes.media,
                                arguments: item.id,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  item.title,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  moment.reasonFor(item.id),
                                  style: AppTheme.mono(
                                    size: 11,
                                    color: Palette.v7.parchment,
                                  ),
                                ),
                                if (flagged.contains(item.id))
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Looks wrong',
                                      style: AppTheme.mono(
                                        size: 11,
                                        color: Palette.v7.amber,
                                        weight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            tooltip: 'Remove from this moment',
                            onPressed: () {
                              archive.removeItemFromMoment(
                                moment.id,
                                item.id,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Removed — the archive will remember',
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: GradientButton(
                      label: moment.savedAsStoryId != null
                          ? 'Open the story'
                          : 'Save as story',
                      expanded: true,
                      onPressed: () {
                        if (moment.savedAsStoryId != null) {
                          Navigator.of(context).pushNamed(
                            Routes.story,
                            arguments: moment.savedAsStoryId!,
                          );
                          return;
                        }
                        final storyId =
                            archive.saveMomentAsStory(moment.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Saved as a story')),
                        );
                        Navigator.of(context).pushNamed(
                          Routes.story,
                          arguments: storyId,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _export(context),
                      child: const Text('Export manifest'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pushNamed(Routes.ask),
                  child: const Text('Ask something else'),
                ),
              ),
            ],
          ),
        );
        return ResponsiveScaffold(
          title: 'Ask',
          tabIndex: 1,
          mobile: body,
          wide: body,
        );
      },
    );
  }
}
