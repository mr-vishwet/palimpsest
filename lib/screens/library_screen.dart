import 'package:material_ui/material_ui.dart';

import '../core/constants.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../engine/archive_index.dart';
import '../models/memory_item.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';
import '../widgets/frame_tile.dart';

/// Media library (m06 / w06): the cutting-room grid — frames, aspect
/// ratios, filters. Ratios are data, not decoration.
class LibraryScreen extends StatefulWidget {
  /// Creates the library screen.
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _query = '';
  MediaKind? _kind;
  String? _ratio;

  @override
  Widget build(BuildContext context) {
    final archive = AppScope.of(context).archive;
    return ListenableBuilder(
      listenable: archive,
      builder: (context, _) {
        final index = ArchiveIndex(
          items: archive.items,
          voiceNotes: archive.voiceNotes,
          people: archive.people,
          places: archive.places,
          stories: archive.stories,
        );
        final hits = index.search(
          _query,
          kind: _kind,
          aspectRatio: _ratio,
        );
        final items = hits.map((hit) => hit.item).toList(growable: false);

        final ratioCounts = <String, int>{
          for (final ratio in AppConstants.aspectRatios) ratio: 0,
        };
        for (final item in archive.items) {
          ratioCounts[item.aspectRatio] =
              (ratioCounts[item.aspectRatio] ?? 0) + 1;
        }

        final grid = LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900
                ? 4
                : constraints.maxWidth >= 600
                    ? 3
                    : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) => FrameTile(
                item: items[i],
                onTap: () => Navigator.of(context).pushNamed(
                  Routes.media,
                  arguments: items[i].id,
                ),
              ),
            );
          },
        );

        final body = SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('The cutting room', style: AppTheme.kicker()),
              const SizedBox(height: 6),
              Text(
                'Media library',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  hintText: 'Search titles, tags, people, places…',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: <Widget>[
                  _FilterChip(
                    label: 'All',
                    selected: _kind == null,
                    onTap: () => setState(() => _kind = null),
                  ),
                  _FilterChip(
                    label: 'Photos',
                    selected: _kind == MediaKind.photo,
                    onTap: () => setState(() => _kind = MediaKind.photo),
                  ),
                  _FilterChip(
                    label: 'Videos',
                    selected: _kind == MediaKind.video,
                    onTap: () => setState(() => _kind = MediaKind.video),
                  ),
                  _FilterChip(
                    label: 'Voice',
                    selected: _kind == MediaKind.voiceNote,
                    onTap: () => setState(() => _kind = MediaKind.voiceNote),
                  ),
                  _FilterChip(
                    label: 'Notes',
                    selected: _kind == MediaKind.note,
                    onTap: () => setState(() => _kind = MediaKind.note),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: <Widget>[
                  _FilterChip(
                    label: 'Any ratio',
                    selected: _ratio == null,
                    onTap: () => setState(() => _ratio = null),
                  ),
                  for (final ratio in AppConstants.aspectRatios)
                    _FilterChip(
                      label: '$ratio · ${ratioCounts[ratio]}',
                      selected: _ratio == ratio,
                      onTap: () => setState(() => _ratio = ratio),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '${items.length} frames in the demo library',
                style: AppTheme.mono(size: 12),
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const EmptyState(
                  icon: Icons.photo_library_outlined,
                  title: 'Nothing here yet',
                  body:
                      'No frames match these filters. Clear a filter or try different words.',
                )
              else
                grid,
            ],
          ),
        );
        return ResponsiveScaffold(
          title: 'Library',
          tabIndex: 2,
          mobile: body,
          wide: body,
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const palette = Palette.v7;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? palette.gold : palette.glass,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? palette.gold : palette.hairline,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.mono(
            size: 12,
            color: selected ? palette.onGold : palette.parchment,
            weight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
