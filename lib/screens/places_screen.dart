import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';

import '../core/format.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../models/memory_item.dart';
import '../models/place.dart';
import '../services/place_clustering.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';
import '../widgets/schematic_map.dart';
import '../widgets/story_card.dart';

/// Places (m12 / w12): every story pinned — schematic, not a
/// street map. The count is the real number of places; an empty
/// archive shows an empty state.
///
/// Places come from real GPS too: imported photos carry EXIF
/// coordinates, nearby coordinates cluster into a place, and the user
/// names it. Unnamed clusters show with their coordinates until
/// named. There is no reverse-geocoding — names are the user's own,
/// and no location ever leaves the device.
class PlacesScreen extends StatefulWidget {
  /// Creates the places screen.
  const PlacesScreen({super.key});

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  String? _selectedId;

  /// Merges stored places with GPS clusters derived from imported
  /// items. A cluster already covered by a stored place (same id, or
  /// a stored GPS place within one cell) refreshes that place's
  /// counts; every other cluster appears as an unnamed place with
  /// its coordinates.
  List<Place> _mergedPlaces(List<Place> stored, List<MemoryItem> items) {
    final points = <GpsPoint>[
      for (final item in items)
        if (item.gpsLat != null && item.gpsLng != null)
          GpsPoint(
            lat: item.gpsLat!,
            lng: item.gpsLng!,
            itemId: item.id,
            storyId: item.storyId,
            takenAt: item.takenAt,
          ),
    ];
    final clusters = PlaceClusterer.cluster(points);
    final positions = PlaceClusterer.fitPositions(clusters);
    final covered = <String>{};
    final merged = <Place>[];
    for (final place in stored) {
      final match = clusters.where((c) {
        if (c.id == place.id) {
          return true;
        }
        return place.hasGps &&
            PlaceClusterer.distanceDegrees(
                  place.gpsLat!,
                  place.gpsLng!,
                  c.centerLat,
                  c.centerLng,
                ) <
                PlaceClusterer.defaultCellDegrees;
      }).firstOrNull;
      if (match == null) {
        merged.add(place);
        continue;
      }
      covered.add(match.id);
      final storyIds = <String>{...place.storyIds, ...match.storyIds}
          .toList(growable: false)
        ..sort();
      merged.add(
        place.copyWith(photoCount: match.count, storyIds: storyIds),
      );
    }
    for (final cluster in clusters) {
      if (covered.contains(cluster.id)) {
        continue;
      }
      final position = positions[cluster.id] ?? (0.5, 0.5);
      merged.add(
        Place(
          id: cluster.id,
          name: 'Unnamed place',
          storyIds: cluster.storyIds,
          x: position.$1,
          y: position.$2,
          photoCount: cluster.count,
          gpsLat: cluster.centerLat,
          gpsLng: cluster.centerLng,
          isDemo: false,
        ),
      );
    }
    return merged;
  }

  /// Asks the user to name a place. Stored places are renamed;
  /// unnamed GPS clusters are saved as new places under their name.
  Future<void> _namePlace(Place place) async {
    final archive = AppScope.of(context).archive;
    final controller = TextEditingController(
      text: place.name == 'Unnamed place' ? '' : place.name,
    );
    final saved = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          place.name == 'Unnamed place'
              ? 'Name this place'
              : 'Rename ${place.name}',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (place.hasGps)
              Text(
                PlaceClusterer.formatCoordinates(
                  place.gpsLat!,
                  place.gpsLng!,
                ),
                style: AppTheme.mono(size: 12, color: Palette.v7.muted),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'e.g. Grandma’s kitchen',
              ),
              onSubmitted: (value) => Navigator.of(context).pop(value),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (saved == null) {
      return;
    }
    final name = saved.trim();
    if (name.isEmpty) {
      return;
    }
    if (archive.placeById(place.id) != null) {
      archive.renamePlace(place.id, name);
    } else {
      archive.addPlace(place.copyWith(name: name));
    }
    if (mounted) {
      setState(() => _selectedId = place.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved as $name')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final archive = AppScope.of(context).archive;
    return ListenableBuilder(
      listenable: archive,
      builder: (context, _) {
        final places = _mergedPlaces(archive.places, archive.items);
        final selected = _selectedId == null
            ? null
            : places.where((p) => p.id == _selectedId).firstOrNull;
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
                '${places.length} ${places.length == 1 ? 'place' : 'places'}, every story pinned. The map shows where '
                'life happened — not the streets in between.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(color: Palette.v7.parchment),
              ),
              const SizedBox(height: 16),
              if (places.isEmpty)
                const EmptyState(
                  icon: Icons.location_on_outlined,
                  title: 'No places yet',
                  body:
                      'Import photos with locations and they will appear on the map here.',
                )
              else
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
                          color: V7Colors.gold,
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
                              if (place.hasGps)
                                Text(
                                  PlaceClusterer.formatCoordinates(
                                    place.gpsLat!,
                                    place.gpsLng!,
                                  ),
                                  style: AppTheme.mono(
                                    size: 11,
                                    color: Palette.v7.muted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (place.hasGps)
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            tooltip: place.name == 'Unnamed place'
                                ? 'Name this place'
                                : 'Rename place',
                            onPressed: () => _namePlace(place),
                          ),
                        const Icon(
                          Icons.chevron_right,
                          color: V7Colors.muted,
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
