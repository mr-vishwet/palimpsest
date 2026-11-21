import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';
import '../widgets/schematic_map.dart';
import '../widgets/story_card.dart';

/// Places (m12 / w12): four places, every story pinned — schematic,
/// not a street map.
class PlacesScreen extends StatefulWidget {
  /// Creates the places screen.
  const PlacesScreen({super.key});

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final archive = AppScope.of(context).archive;
    return ListenableBuilder(
      listenable: archive,
      builder: (context, _) {
        final places = archive.places;
        final selected = _selectedId == null
            ? null
            : archive.placeById(_selectedId!);
        final body = SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Schematic, not a street map', style: AppTheme.kicker()),
              const SizedBox(height: 6),
              Text(
                'Places',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Four places, every story pinned. The map shows where '
                'life happened — not the streets in between.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(color: Palette.v7.parchment),
              ),
              const SizedBox(height: 16),
              SchematicMap(
                places: places,
                selectedId: _selectedId,
                onSelect: (id) => setState(() => _selectedId = id),
              ),
              const SizedBox(height: 16),
              for (final place in places)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    borderColor: _selectedId == place.id
                        ? Palette.v7.gold.withValues(alpha: 0.6)
                        : null,
                    onTap: () => setState(
                      () => _selectedId =
                          _selectedId == place.id ? null : place.id,
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.location_on_outlined,
                          color: Palette.v7.gold,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                place.name,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                '${Format.count(place.photoCount)} photos · '
                                '${place.storyIds.length} '
                                '${place.storyIds.length == 1 ? 'story' : 'stories'}',
                                style: AppTheme.mono(size: 11),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Palette.v7.muted,
                        ),
                      ],
                    ),
                  ),
                ),
              if (selected != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  'Stories at ${selected.name}',
                  style: AppTheme.kicker(),
                ),
                const SizedBox(height: 8),
                for (final storyId in selected.storyIds)
                  if (archive.storyById(storyId) != null) ...<Widget>[
                    StoryCard(
                      story: archive.storyById(storyId)!,
                      onTap: () => Navigator.of(context).pushNamed(
                        Routes.story,
                        arguments: storyId,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
              ],
            ],
          ),
        );
        return ResponsiveScaffold(
          title: 'Places',
          tabIndex: 0,
          mobile: body,
          wide: body,
        );
      },
    );
  }
}
